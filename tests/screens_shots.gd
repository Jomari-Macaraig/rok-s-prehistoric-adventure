extends SceneTree
## Screenshots of the Encyclopedia (Field Guide) and the Camp (the
## "Dinosaurs" button) with some progress, for polishing: every Encyclopedia
## tab with an entry open, and every Camp tab plus a dinosaur compared with
## the equipped one. Files: enc_<n>_<tab>.png, camp_<n>_<tab>.png.
##   godot --path . --fixed-fps 60 --resolution 1280x720 -s tests/screens_shots.gd -- <out_dir>
## (It needs a window; use --resolution 1560x720 for a wide phone.)
var main
var out := "user://screens_shots"
var frame := 0
var jobs := []
var job := -1
var job_frame := 0
const SETTLE := 45   # frames before a shot (screens fade in, the Elder's bubble compacts)


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0:
		out = a[0]
	DirAccess.make_dir_recursive_absolute(out)
	AudioServer.set_bus_mute(0, true)
	SaveData.path = "user://screens_shots.cfg"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveData.path))
	main = load("res://main.tscn").instantiate()
	main.pause_for_info = false
	main.tutorial_run_done = true
	root.add_child(main)
	# Encyclopedia: [tab index, entry title to open (or ""), file name]
	for e in [[0, "Raptor", "dinosaurs"], [1, "Boulders", "hazards_terrain"], [2, "", "items"],
			[3, "", "power_ups"], [4, "", "zones"], [5, "", "badges"], [6, "Raptor Card", "cards"], [6, "Gallimimus Card", "cards_no_art"]]:
		jobs.append(["enc"] + e)
	# Camp: [tab, dinosaur to select (or "" = the equipped one), file name]
	for cat in Herd.tabs():
		jobs.append(["camp", cat, "", Herd.tab_name(cat).to_lower()])
	jobs.append(["camp", "runner", "gallimimus", "runner_compare"])


## Some progress so the screens aren't empty: every button, a long best run,
## everything taught, a few expansion dinosaurs owned, the club, some badges.
func _progress() -> void:
	main.unlocked = Forms.ORDER.duplicate()
	main.best_m = 6000.0
	main.seen = Progression.INTROS.map(func(e): return e[1]) + ["zone_forest", "zone_desert", "zone_volcanic", "combo", "chest"]
	for id in ["gallimimus", "carnotaurus", "ankylosaurus", "dimorphodon"]:
		if Dinos.ids().has(id) and not main.dinos_owned.has(id):
			main.dinos_owned.append(id)
	main.meat_bank = 640
	for id in ["raptor", "triceratops", "gallimimus"]:   # some cards found
		main.grant_card(id)
		main.seen.append("card_" + id)
	main.gear_owned.append("club")
	main.equip_gear("rok", "weapon", "club")
	for i in 40:
		main.badge_event("smashed")
	main.hud.clear_banner()
	main._to_title()


func _next() -> void:
	job += 1
	job_frame = frame
	if job >= jobs.size():
		return
	var j: Array = jobs[job]
	if j[0] == "enc":
		if main.herd.visible:
			main.herd.close_herd()
		if not main.codex.visible:
			main.open_guide()
		main.codex._show_tab(int(j[1]))
		if String(j[2]) != "":
			for i in main.codex.grid.get_child_count():
				if String(main.codex.grid.get_child(i).get_meta("title", "")) == String(j[2]):
					main.codex.select(i)
	else:
		if main.codex.visible:
			main.codex.close_guide()
		if not main.herd.visible:
			main.open_herd(String(j[1]))
		main.herd.show_tab(String(j[1]))
		if String(j[2]) != "":
			main.herd._drag_dist = 0.0
			main.herd.select(String(j[2]))


func _process(_d: float) -> bool:
	frame += 1
	if main.state == main.State.PAUSED:
		main._resume()
	if frame == 5:
		_progress()
	if frame == 20:
		_next()
	if job >= 0 and job < jobs.size() and frame - job_frame == SETTLE:
		var j: Array = jobs[job]
		var name := "%s_%d_%s" % [j[0], job + 1 - (0 if j[0] == "enc" else 8), j[3]]
		root.get_texture().get_image().save_png("%s/%s.png" % [out, name])
		_next()
	return job >= jobs.size() or frame > 60 * 120
