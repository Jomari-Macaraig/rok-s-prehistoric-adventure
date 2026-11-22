extends SceneTree
## Captures the learning facts: the dinosaur tab of the Field Guide (scrolled to
## a few cards), the T-rex hazard card, the info card shown on a dino unlock,
## and the HUD's booster slots (one open, one at a distance, one Market).
##   godot --path . --fixed-fps 60 --resolution 1280x720 -s tests/facts_shots.gd -- <out_dir>

var main
var out := "user://facts_shots"
var frame := 0
var _dino_card_at := -1


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	DirAccess.make_dir_recursive_absolute(out)
	AudioServer.set_bus_mute(0, true)
	SaveData.path = "user://facts_shots.cfg"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveData.path))
	main = load("res://main.tscn").instantiate()
	root.add_child(main)


func _shot(name: String) -> void:
	root.get_texture().get_image().save_png("%s/%s.png" % [out, name])


func _process(_delta: float) -> bool:
	frame += 1
	if frame > 52:
		# tap past lesson / zone cards until the dino unlock card shows up
		if main.state == main.State.INFO and main._info_t > 0.7 and _dino_card_at < 0:
			if main.hud.info_title.text.begins_with("NEW DINO"):
				_dino_card_at = frame
			else:
				main._dismiss_info()
		if main.state == main.State.PLAYING:
			main.player.invuln = 99.0
			main.chase_gap = Tuning.CHASE_GAP_MAX
		if _dino_card_at > 0 and frame == _dino_card_at + 20:
			_shot("facts_unlock_card")
			main._info_queue.clear()
			main._dismiss_info()
		if _dino_card_at > 0 and frame == _dino_card_at + 60:
			_shot("slots_hud")
			return true
		return frame > 3000
	match frame:
		10:
			main.unlocked = Forms.ORDER.duplicate()
			main.codex.boosters_owned = main.boosters_owned
			main.codex.open_guide(main.unlocked, 5000.0, [], [])
			main.codex._show_tab(0)
		20:
			_shot("facts_rok")
		22:
			main.codex.scroll.scroll_vertical = 560
		30:
			_shot("facts_raptor")
		32:
			main.codex.scroll.scroll_vertical = 1700
		40:
			_shot("facts_later")
		42:
			main.codex._show_tab(1)
			main.codex.scroll.scroll_vertical = 0
		50:
			_shot("facts_trex")
		52:
			main.codex.close_guide()
			main.unlocked = [Forms.ROK]
			main.start_run(false)
			main.distance = (Progression.unlock_m(Forms.RAPTOR) - 15) * Tuning.PX_PER_M
	return false
