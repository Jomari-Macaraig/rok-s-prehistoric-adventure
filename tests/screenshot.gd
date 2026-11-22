extends SceneTree
## Renders the game in a window and saves screenshots to the given folder.
##   godot --path . --fixed-fps 60 -s tests/screenshot.gd -- <out_dir>

var main
var bot
var frame := 0
var _pit_shot := false
var _slide_shot := false
var _gate_shots := {}
var out := "user://shots"
const SHOTS := {20: "title", 230: "intro_banner", 200: "run_a", 480: "run_b", 760: "run_c", 900: "run_d", 1100: "run_e", 1300: "run_f", 1500: "run_g"}


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	DirAccess.make_dir_recursive_absolute(out)
	AudioServer.set_bus_mute(0, true)   # silent while capturing
	SaveData.path = "user://screenshot_rok_runner.cfg"   # fresh progress, never the real save
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveData.path))
	main = load("res://main.tscn").instantiate()
	main.pause_for_info = false   # info cards would wait for a tap
	root.add_child(main)


func _process(_d: float) -> bool:
	frame += 1
	if frame == 21:
		main.best_m = 1000
		main.unlocked = Forms.ORDER.duplicate()
		main.open_guide()
	if frame == 24:
		root.get_texture().get_image().save_png("%s/024_guide_dinos.png" % out)
		main.codex._show_tab(1)
	if frame == 26:
		root.get_texture().get_image().save_png("%s/026_guide_hazards.png" % out)
		for k in 6:   # simulated finger drag upwards
			var e := InputEventScreenDrag.new()
			e.position = Vector2(640, 500 - k * 40)
			e.relative = Vector2(0, -40)
			e.velocity = Vector2(0, -800)
			Input.parse_input_event(e)
	if frame == 29:
		root.get_texture().get_image().save_png("%s/029_guide_scrolled.png" % out)
		main.codex.close_guide()
		main.best_m = 0
		main.unlocked = [Forms.ROK]
	if frame == 30:
		main.start_run()   # with the T-rex intro
	if frame == 66 or frame == 95:
		root.get_texture().get_image().save_png("%s/%03d_intro.png" % [out, frame])
		bot = load("res://tests/autopilot.gd").new(main)
	if bot:
		if main.state == main.State.PAUSED:
			main._resume()   # the capture window may lose focus, which auto-pauses
		bot.tick()
		if frame > 800 and main.state == main.State.PLAYING:
			for m in main.course.markers:
				var f: int = m.get_meta("form")
				var gx := Course.gate_x0(m)
				if not _gate_shots.has(f) and gx > 760.0 and gx < 1000.0:
					_gate_shots[f] = true
					root.get_texture().get_image().save_png("%s/gate_%s.png" % [out, Forms.get_data(f).id])
			if not _gate_shots.has("big_hill") and main.player.on_ground and main.player.position.y < Tuning.GROUND_Y - 110.0:
				_gate_shots["big_hill"] = true
				root.get_texture().get_image().save_png("%s/big_hill.png" % out)
			if not _gate_shots.has("big_hill_slide") and main.player.is_low() and main.terrain.slope_at(main.player.position.x) > 0.05:
				_gate_shots["big_hill_slide"] = true
				root.get_texture().get_image().save_png("%s/big_hill_slide.png" % out)
			for b in main.terrain.bridges:
				var bx: float = b.x0 + main.terrain.position.x
				if b.sturdy and not _gate_shots.has("bridge") and bx > 500.0 and bx < 800.0:
					_gate_shots["bridge"] = true
					root.get_texture().get_image().save_png("%s/sturdy_bridge.png" % out)
		if not _slide_shot and main.player.low == Player.Low.GLIDE:
			for o in main.course.obstacles:
				if o.kind == "overhead" and absf(o.position.x - main.player.position.x) < 120.0:
					_slide_shot = true
					root.get_texture().get_image().save_png("%s/slide.png" % out)
		if main.state == main.State.OVER:
			main.start_run(false)
	if frame == 380 and main.state == main.State.PLAYING:
		main.distance = (Progression.UNLOCKS[Forms.RAPTOR] + 1.0) * Tuning.PX_PER_M   # cross the Raptor unlock
	if frame == 400:
		root.get_texture().get_image().save_png("%s/400_unlock.png" % out)
	if frame > 400 and frame < 590 and not _gate_shots.has("after_unlock"):
		for m in main.course.markers:
			if Course.gate_x0(m) < 900.0:
				_gate_shots["after_unlock"] = true
				root.get_texture().get_image().save_png("%s/%d_gate_after_unlock.png" % [out, frame])
	if frame == 590:
		main.unlocked = Forms.ORDER.duplicate()
		main.distance = 1700.0 * Tuning.PX_PER_M
		main.course.skip_intros_before(1700.0)
	if frame == 600 and main.state == main.State.PLAYING:
		main.energy = Tuning.ENERGY_MAX
		main._request_form(Forms.PTERANODON)
	if frame == 605:
		main.player.press_jump()
	if frame == 700:
		main.player.release_jump()
	if frame == 690 or frame == 760:
		root.get_texture().get_image().save_png("%s/%d_fly.png" % [out, frame])
	if frame in SHOTS:
		var img := root.get_texture().get_image()
		img.save_png("%s/%03d_%s.png" % [out, frame, SHOTS[frame]])
	if bot and not _pit_shot:
		var pit: Vector2 = main.terrain.next_pit(main.player.position.x)
		if pit.x > 560.0 and pit.x < 760.0 and main.state == main.State.PLAYING:
			_pit_shot = true
			root.get_texture().get_image().save_png("%s/pit.png" % out)

	return frame > 9000 or (frame > 1520 and _gate_shots.size() >= 8)
