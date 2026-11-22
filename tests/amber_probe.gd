extends SceneTree
## Counts how much meat (Market currency), amber and power-ups appear per distance (Rok kept alive, all dinos
## unlocked), to tune Market prices in config/progression.cfg [market]:
##   godot --headless --path . --fixed-fps 60 -s tests/amber_probe.gd
## A real player collects only part of what appears.
var main
var frame := 0
var seen := {}
var amber := 0
var meat := 0
var boosters := 0
var marks := [500, 1000, 2000, 3000, 4000]


func _initialize() -> void:
	SaveData.path = "user://amber_probe.cfg"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveData.path))
	main = load("res://main.tscn").instantiate()
	main.pause_for_info = false
	root.add_child(main)


func _process(_d: float) -> bool:
	frame += 1
	if frame == 3:
		main.unlocked = Forms.ORDER.duplicate()
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
		for k in main.course.pickups:
			if not seen.has(k):
				seen[k] = true
				if k.kind == "amber":
					amber += 1
				elif k.kind == "meat":
					meat += 1
				else:
					boosters += 1
		pass   # normal speed ramp, as a player sees it
		if not marks.is_empty() and main.metres() >= marks[0]:
			print("%5d m: %4d meat, %4d amber, %d power-ups appeared" % [marks[0], meat, amber, boosters])
			marks.pop_front()
	return marks.is_empty() or frame > 60 * 900
