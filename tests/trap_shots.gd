extends SceneTree
## Captures the trap expansion: each zone's traps set up just ahead of Rok.
##   godot --path . --fixed-fps 60 --resolution 1280x720 -s tests/trap_shots.gd -- <out_dir>

var main
var out := "user://trap_shots"
var frame := 0
var stop := -1
var t0 := 0
var shots := {}
const STOPS := ["forest", "water", "desert", "quicksand", "volcanic", "lava"]


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	DirAccess.make_dir_recursive_absolute(out)
	AudioServer.set_bus_mute(0, true)
	SaveData.path = "user://trap_shots.cfg"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveData.path))
	main = load("res://main.tscn").instantiate()
	main.pause_for_info = false   # info cards would wait for a tap
	root.add_child(main)


func _begin(m: float) -> void:
	main.unlocked = Forms.ORDER.duplicate()
	main.seen = Progression.INTROS.map(func(e): return e[1])   # no banners in the shots
	main.start_run(false)
	main.distance = m * Tuning.PX_PER_M
	main.terrain.metres = m
	main.course.metres = m
	main.course.skip_intros_before(m)
	main.course.next_gate_m = 1e9
	# fresh ground in this zone right away
	main.terrain.reset()
	main.terrain.metres = m
	main.terrain.features[0].style = Zones.zone_at(m).ground
	main.course._ground = Tuning.GROUND_Y


func _next() -> void:
	stop += 1
	t0 = frame
	var c: Course = main.course
	match STOPS[stop]:
		"forest":
			_begin(150.0)
			c.ledge(760.0)
			c.boulder_wall(1180.0)
			c.log_(560.0)
		"water":
			_begin(Zones.ZONE_LEN_M * 3.15)
			main.terrain.request_gate("gate_spino")
			main.player.shift_to(Forms.SPINOSAURUS)
		"desert":
			_begin(Zones.ZONE_LEN_M * 1.25)
			c.ledge(700.0)
			c.boulder_wall(1120.0)
		"quicksand":
			_begin(Zones.ZONE_LEN_M * 1.3)
			main.terrain._quicksand(640.0)
		"volcanic":
			_begin(Zones.ZONE_LEN_M * 2.3)
			c.steam_vent(620.0)
			c.steam_vent(900.0)
			c.rolling_boulder(1250.0)
		"lava":
			_begin(Zones.ZONE_LEN_M * 2.35)
			main.terrain.request_gate("gate_ptera")


func _process(_d: float) -> bool:
	frame += 1
	if frame == 5:
		_next()
	if stop < 0:
		return false
	if main.state == main.State.PAUSED:
		main._resume()
	main.chase_gap = Tuning.CHASE_GAP_MAX
	main.energy = 100.0
	var name: String = STOPS[stop]
	# keep the scene alive without invulnerability (which makes Rok blink)
	if name in ["forest", "desert", "volcanic"]:
		for o in main.course.obstacles.duplicate():
			if o.position.x < Tuning.PLAYER_X + 140.0 and o.kind != "steam":
				if name == "forest" and o.size.y > 400.0:
					continue
				main.course.remove_obstacle(o)
	if main.state != main.State.PLAYING and not shots.has(name):
		shots[name] = true
		root.get_texture().get_image().save_png("%s/%s_end.png" % [out, name])
	var dt := frame - t0
	var shoot := false
	match name:
		"forest", "desert":
			shoot = dt == 40
		"volcanic":
			shoot = dt == 28
		"water":
			shoot = main.player.swimming and dt > 20
		"quicksand":
			main.sink = minf(main.sink, 0.6)   # show the sinking without dying
			shoot = main.sink > 0.5
		"lava":
			shoot = main.terrain.liquid_at(Tuning.PLAYER_X + 260.0) == "lava"
			if main.player.form != Forms.PTERANODON and dt > 10:
				main.player.shift_to(Forms.PTERANODON)
				main.player.press_jump()
	if shoot and not shots.has(name):
		shots[name] = true
		root.get_texture().get_image().save_png("%s/%s.png" % [out, name])
	if shots.has(name) or dt > 600:
		if stop + 1 >= STOPS.size():
			return true
		_next()
	return false
