extends SceneTree
## Reports how often each dino gate appears per zone over 6000 m (all dinos
## unlocked; pass "-- fresh" for a new save that unlocks by distance):
##   godot --headless --path . --fixed-fps 60 -s tests/gate_probe.gd
var main
var frame := 0
var counts := {}
var seen := {}
var first := {}
func _initialize() -> void:
	SaveData.path = "user://gate_probe.cfg"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveData.path))
	main = load("res://main.tscn").instantiate()
	main.pause_for_info = false   # info cards would wait for a tap
	root.add_child(main)
func _process(_d: float) -> bool:
	frame += 1
	if frame == 3:
		main.unlocked = Forms.ORDER.duplicate() if OS.get_cmdline_user_args().size() == 0 else [Forms.ROK]
		main.start_run(false)
	if frame > 3:
		main.player.invuln = 99.0
		main.chase_gap = Tuning.CHASE_GAP_MAX
		main.sink = 0.0
		if main.player.position.y > 600.0:
			main.player.position.y = 300.0
			main.player.vy = 0.0
		if main.state != main.State.PLAYING:
			main.state = main.State.PLAYING
		for m in main.course.markers:
			if not seen.has(m):
				seen[m] = true
				var key := "%s @ %s" % [Forms.get_data(m.get_meta("form")).name, Zones.zone_at(main.metres()).name]
				counts[key] = counts.get(key, 0) + 1
				var f: String = Forms.get_data(m.get_meta("form")).name
				if not first.has(f):
					first[f] = int(main.metres())
		main.speed = Tuning.MAX_SPEED   # cover distance faster
	if main.metres() > 6000.0 or frame > 60 * 600:
		print("metres=%d" % int(main.metres()))
		var keys := counts.keys()
		keys.sort()
		var total := 0
		for k in keys:
			print("  ", k, ": ", counts[k])
			total += counts[k]
		print("total gates: %d (one every %d m)" % [total, int(main.metres() / maxf(total, 1))])
		print("first seen: ", first)
		return true
	return false
