extends SceneTree
## Captures each zone at different times of day.
##   godot --path . --fixed-fps 60 --resolution 1280x720 -s tests/zone_shots.gd -- <out_dir>

## Distances for 1500 m zones (lap 6000 m: Forest, Desert, Canyon, Volcanic)
## on the 3600 m day cycle; move them if [zones] length_m, the zones or
## Zones.DAY_CYCLE_M change.
const STOPS := [[300, "forest_day"], [7900, "desert_day"], [1700, "desert_sunset"],
		[3800, "canyon_day"], [9500, "canyon_night"], [4600, "volcanic_day"],
		[10900, "volcanic_night"], [6400, "forest_night"]]
const RUN_FRAMES := 330

var main
var out := "user://zone_shots"
var frame := 0
var stop := -1
var t0 := 0


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	DirAccess.make_dir_recursive_absolute(out)
	AudioServer.set_bus_mute(0, true)
	SaveData.path = "user://zone_shots.cfg"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveData.path))
	main = load("res://main.tscn").instantiate()
	main.pause_for_info = false   # info cards would wait for a tap
	root.add_child(main)


func _next_stop() -> void:
	stop += 1
	t0 = frame
	var m: float = STOPS[stop][0] - 140.0
	main.unlocked = Forms.ORDER.duplicate()
	main.start_run(false)
	main.distance = m * Tuning.PX_PER_M
	main.terrain.metres = m
	main.course.skip_intros_before(m)
	main.seen = []


func _process(_d: float) -> bool:
	frame += 1
	if frame == 5:
		_next_stop()
	if stop < 0:
		return false
	if main.state == main.State.PAUSED:
		main._resume()
	main.player.invuln = 999.0
	main.chase_gap = Tuning.CHASE_GAP_MAX
	main.energy = 100.0
	if main.player.position.y > 600.0:
		main.player.position.y = 300.0
		main.player.vy = 0.0
	if main.state != main.State.PLAYING:
		main.start_run(false)
	if frame - t0 == RUN_FRAMES:
		root.get_texture().get_image().save_png("%s/%s.png" % [out, STOPS[stop][1]])
		if stop + 1 >= STOPS.size():
			return true
		_next_stop()
	return false
