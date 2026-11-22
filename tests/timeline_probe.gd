extends SceneTree
## Prints when each new thing first appears for a brand-new player in one
## long run, using config/progression.cfg: hazard lessons, dino traps, dino
## unlocks, zones, the booster slot and Market items. Keeps Rok alive and
## runs at the normal speed ramp. Flags gaps under 120 m between moments
## that show a card (Market items are game-over news, so they don't count).
##   godot --headless --path . --fixed-fps 60 -s tests/timeline_probe.gd [-- <metres>]
var main
var frame := 0
var events := []
var known := {}
var until := 5200.0


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		until = float(args[0])
	SaveData.path = "user://timeline_probe.cfg"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveData.path))
	main = load("res://main.tscn").instantiate()
	main.pause_for_info = false
	root.add_child(main)


func _add(key: String, label: String, card := true) -> void:
	if known.has(key):
		return
	known[key] = true
	events.append([int(main.metres()), label, card])


func _process(_d: float) -> bool:
	frame += 1
	if frame == 3:
		main.start_run(false)
	if frame > 3:
		main.player.invuln = 99.0
		main.chase_gap = Tuning.CHASE_GAP_MAX
		main.sink = 0.0
		main.energy = 100.0
		if main.player.position.y > 600.0:
			main.player.position.y = 300.0
			main.player.vy = 0.0
		if main.state != main.State.PLAYING:
			main.state = main.State.PLAYING
		main.speed = maxf(main.speed, Tuning.START_SPEED)
		for k in main.seen:
			if String(k).begins_with("zone_"):
				if k != "zone_forest":
					_add(k, "ZONE " + String(k).substr(5).capitalize())
			else:
				_add(k, "new  " + k)
		for f in main.unlocked:
			if f != Forms.ROK:
				_add("dino%d" % f, "DINO " + Forms.get_data(f).name)
		if main.slot_count >= 2:
			_add("slot2", "SLOT 2nd booster slot")
		for id in main.new_market:
			_add("m_" + id, "market " + Market.item_name(id) + " (game-over news)", false)
	if main.metres() > until or frame > 60 * 1200:
		var last := -9999
		var tight := 0
		for e in events:
			var gap: int = e[0] - last if last > -9999 else 0
			var warn := ""
			if e[2] and last > -9999 and gap < 120:
				warn = "   <-- close"
				tight += 1
			print("%5d m  %-44s (+%d m)%s" % [e[0], e[1], gap, warn])
			if e[2]:
				last = e[0]
		print("%d close pairs (dino + its own trap count as one moment)" % tight)
		return true
	return false
