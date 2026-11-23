extends SceneTree
## Screenshots of the whole tutorial for polishing: plays the training run
## like a person (real taps on the buttons, a long press for the hold step)
## and then the menu tour, saving every moment that shows tutorial UI: each
## step's intro note, each button hint, each HUD note, the finish card and
## every menu-tour step. Files are numbered in order: NN_<step>_<what>.png.
##   godot --path . --fixed-fps 60 --resolution 1280x720 -s tests/tutorial_shots.gd -- <out_dir>
## (It needs a window; use --resolution 1560x720 for a wide phone.)
var main
var out := "user://tutorial_shots"
var frame := 0
var n := 0
var key := ""
var key_since := 0
var shot_keys := {}
var hold_frames := 0
var done_at := -1      # frame the tour ended (the last shot is taken a little later)


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0:
		out = a[0]
	DirAccess.make_dir_recursive_absolute(out)
	AudioServer.set_bus_mute(0, true)
	SaveData.path = "user://tutorial_shots.cfg"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveData.path))
	main = load("res://main.tscn").instantiate()
	main.tutorial_run_done = false   # a fresh save: the first tap starts the training run
	root.add_child(main)


func _touch(pos: Vector2, down: bool) -> void:
	var e := InputEventScreenTouch.new()
	e.index = 0
	e.position = pos
	e.pressed = down
	main._input(e)


func _tap(pos: Vector2) -> void:
	_touch(pos, true)
	_touch(pos, false)


func _btn(action: String) -> Vector2:
	for b in main.hud.buttons:
		if b.action == action and b.visible:
			return b.global_position + b.size * 0.5
	return Vector2(-1, -1)


func _shot(name: String) -> void:
	if shot_keys.has(name):
		return
	shot_keys[name] = true
	root.get_texture().get_image().save_png("%s/%02d_%s.png" % [out, n, name])
	n += 1


## What tutorial UI is up now ("" = nothing worth a picture).
func _moment() -> String:
	var tr = main.tutorial_run
	if main.state == main.State.INFO:
		return "finish_card"
	if tr != null:
		var id: String = TutorialRun.STEPS[tr.i].id
		if tr.phase == "note":
			var part: String = tr.note_list[tr.note_i][0]
			return "%s_%s" % [id, "intro" if part == "" else "note_" + part]
		if tr.frozen:
			if tr.phase == "back":
				return id + "_hint_back_to_rok"
			return id + ("_hint" if main.player.on_ground else "_hint_mid_air")
		return ""
	if main.menu_tour != null:
		var t = main.menu_tour
		var scr: String = MenuTour.STEPS[t.i].screen
		return "tour_%d_%s_%s" % [t.i + 1, scr, "button" if t.phase == "point" else "inside"]
	return ""


func _process(_d: float) -> bool:
	frame += 1
	if main.state == main.State.PAUSED:
		main._resume()   # (the window losing focus pauses the game)
	if frame == 10:
		_shot("title")
		_tap(Vector2(640, 400))
	if frame < 12:
		return false
	if done_at > 0:
		if frame - done_at == 20:
			_shot("tour_done")
			return true
		return false
	# take a picture once a moment has settled (bubbles fade in)
	var m := _moment()
	if m != key:
		key = m
		key_since = frame
	if m != "" and frame - key_since == 30:
		_shot(m)
	# then move on, like a player would
	var tr = main.tutorial_run
	if hold_frames > 0:
		hold_frames -= 1
		if hold_frames == 0:
			_touch(_btn("jump"), false)
	if m == "" or frame - key_since < 45:
		return frame > 60 * 300
	if main.state == main.State.INFO and main._info_t > 1.0:
		_tap(Vector2(640, 400))
	elif tr != null and tr.phase == "note":
		_tap(Vector2(640, 450))
	elif tr != null and tr.frozen:
		var want: String = "form_0" if tr.phase == "back" else String(TutorialRun.STEPS[tr.i].get("button", ""))
		_touch(_btn(want), true)
		if want == "jump":
			hold_frames = 36 if TutorialRun.STEPS[tr.i].get("hold", false) else 4
		else:
			_touch(_btn(want), false)
	elif main.menu_tour != null:
		var t = main.menu_tour
		if t.phase == "point":
			main._touch_pressed(t.want())
		else:
			match String(MenuTour.STEPS[t.i].screen):
				"market": main.market.close_market()
				"herd": main.herd.close_herd()
				"codex": main.codex.close_guide()
			if t.i == MenuTour.STEPS.size() - 1:
				done_at = frame
	key_since = frame   # (wait for the next moment)
	key = "__moved"
	return frame > 60 * 300
