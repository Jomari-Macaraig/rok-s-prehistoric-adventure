class_name Preloader
extends CanvasLayer
## The loading screen (the user's request: no hitches in the game itself).
## When the game starts it covers the screen (the boot splash's green and the
## app icon, a progress bar and a tip) while it loads what a run will draw:
##   1. LOAD: every sheet of the forms on the buttons (Rok or the hero you play
##      and the four equipped dinosaurs: body, attack and hit-reaction
##      sheets), the hunters, effects, traps, items, power-ups, gear, the
##      flag, props, wind and terrain, on background threads
##      (ResourceLoader.load_threaded_request). They stay referenced (`keep`)
##      so later load() calls are instant.
##   2. TEXTURES: SpriteLib.tex for every character, attack and reaction sheet
##      (it decodes each @2x twin into a texture: the slow part, done on the
##      main thread a few at a time per frame so the bar keeps moving).
##   3. FRAMES: the SpriteFrames the run builds (each form's body and death,
##      attacks, reactions, the T-rex, the zone hunters, the shapeshift burst
##      and the power-up effects) via SpriteLib's caches.
## Then it fades out and frees itself. Only on a normal launch (main.tscn as
## the main scene); test and screenshot scripts skip it. main.start_run calls
## warm_forms() so a dinosaur equipped later is ready before the run moves.

signal finished

const BG := Color(0.07, 0.16, 0.1)   # the boot splash's colour (project.godot)
const BUDGET_MS := 12                 # main-thread work per frame
## Folders loaded whole (relative to res://assets/).
const WHOLE := ["fx", "hunters", "characters/trex", "traps", "items", "powerups", "best_flag", "gear", "wind", "props", "terrain", "bg"]
## Folders whose sheets go through SpriteLib.tex (the @2x twins).
const TEX_DIRS := ["characters", "attacks", "reactions"]
## The hints (the user's request): config/hints.cfg, each [text, needs];
## only hints the player is ready for are shown (hint_ready), one at a time,
## changing every [settings] seconds.
const HINTS_PATH := "res://config/hints.cfg"
const FALLBACK_HINT := "Hold JUMP to leap higher. Tap twice for a double jump."

static var keep: Array = []   # everything loaded, held so it stays cached

var game   # main.gd
var _paths: Array = []        # resource paths to load (stage 1)
var _tex: Array = []          # SpriteLib.tex keys (stage 2)
var _jobs: Array = []         # Callables building SpriteFrames (stage 3)
var _i := 0
var _stage := 0
var _total := 1
var _done := 0
var bar: ProgressBar
var label: Label
var tip: Label
var root: Control


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP   # taps wait until it's done
	add_child(root)
	var bg := ColorRect.new()
	bg.color = BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 14)
	box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	box.grow_vertical = Control.GROW_DIRECTION_BOTH
	root.add_child(box)
	var icon := TextureRect.new()
	icon.texture = load("res://assets/icon_1024.png")
	icon.custom_minimum_size = Vector2(300, 300)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	box.add_child(icon)
	bar = ProgressBar.new()
	bar.name = "Bar"
	bar.custom_minimum_size = Vector2(520, 26)
	bar.show_percentage = false
	bar.max_value = 1.0
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(1.0, 0.72, 0.25)
	fill.set_corner_radius_all(13)
	var back := StyleBoxFlat.new()
	back.bg_color = Color(0.03, 0.08, 0.05)
	back.border_color = Color(0.55, 0.38, 0.18)
	back.set_border_width_all(3)
	back.set_corner_radius_all(13)
	bar.add_theme_stylebox_override("fill", fill)
	bar.add_theme_stylebox_override("background", back)
	box.add_child(bar)
	label = _label("Loading...", 24, Color(1.0, 0.95, 0.82))
	box.add_child(label)
	tip = _label("", 20, Color(0.85, 0.9, 0.75))
	tip.name = "Tip"
	tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tip.custom_minimum_size = Vector2(620, 0)
	box.add_child(tip)
	_hints = hints_for(float(game.best_m) if game else 0.0)
	_hint_every = hint_seconds()
	_next_hint()
	_plan()


var _hints: Array = []
var _hint_every := 3.5
var _hint_t := 0.0


## Every hint in config/hints.cfg: [[text, needs], ...] (in file order).
static func all_hints() -> Array:
	var c := ConfigFile.new()
	if c.load(HINTS_PATH) != OK or not c.has_section("hints"):
		return [[FALLBACK_HINT, ""]]
	var out: Array = []
	for k in c.get_section_keys("hints"):
		var v: Variant = c.get_value("hints", k)
		if v is Array and (v as Array).size() >= 1:
			out.append([String(v[0]), String(v[1]) if (v as Array).size() > 1 else ""])
	return out if not out.is_empty() else [[FALLBACK_HINT, ""]]


static func hint_seconds() -> float:
	var c := ConfigFile.new()
	return float(c.get_value("settings", "seconds", 3.5)) if c.load(HINTS_PATH) == OK else 3.5


## Is the player ready for a hint? (its "needs": "", a distance, "dino:<id>",
## "intro:<key>", "bench", "slot2", "charge"; see config/hints.cfg)
static func hint_ready(needs: String, best_m: float) -> bool:
	if needs == "":
		return true
	if needs.is_valid_float():
		return best_m >= float(needs)
	var arg := needs.get_slice(":", 1)
	match needs.get_slice(":", 0):
		"dino":
			for f in Forms.ORDER:
				if Forms.DATA[f].id == arg:
					return best_m >= Progression.unlock_m(f)
			return false
		"intro":
			return best_m >= Progression.intro_m(arg)
		"bench":
			return best_m >= Crafting.bench_m()
		"slot2":
			return best_m >= Progression.SLOT_UNLOCK_M
		"charge":
			return not Progression.TREX_CHARGE_M.is_empty() and best_m >= float(Progression.TREX_CHARGE_M[0])
	return false


## The hints a player with this best distance is ready for (texts).
static func hints_for(best_m: float) -> Array:
	return all_hints().filter(func(h): return hint_ready(String(h[1]), best_m)).map(func(h): return String(h[0]))


func _next_hint() -> void:
	if _hints.is_empty():
		_hints = [FALLBACK_HINT]
	var pick: String = _hints.pick_random()
	while _hints.size() > 1 and pick == tip.text:
		pick = _hints.pick_random()
	tip.text = pick
	_hint_t = _hint_every


func _label(t: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = t
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_font_override("font", SpriteLib.ui_font("heading"))
	return l


## The ids of the forms on the buttons right now (Rok or the played hero and
## the four equipped dinosaurs).
static func form_ids() -> Array:
	var ids: Array = []
	for f in Forms.ORDER:
		ids.append(String(Forms.get_data(f).id))
	return ids


## Every image file in a res:// folder and its subfolders (exported games
## list "<name>.png.import" instead of the .png), as .png paths.
static func pngs(dir: String) -> Array:
	var out: Array = []
	var d := DirAccess.open(dir)
	if d == null:
		return out
	for f in d.get_files():
		var n := f.trim_suffix(".import").trim_suffix(".remap")
		if n.ends_with(".png") and not out.has(dir.path_join(n)):
			out.append(dir.path_join(n))
	for sub in d.get_directories():
		out.append_array(pngs(dir.path_join(sub)))
	return out


## What a run needs: [resource paths to load, SpriteLib.tex keys].
static func collect() -> Array:
	var load_paths: Array = []
	var tex_keys: Array = []
	var dirs: Array = []
	for id in form_ids():
		for t in TEX_DIRS:
			dirs.append("res://assets/%s/%s" % [t, id])
	for dir in dirs:
		for p in pngs(dir):
			if p.contains("@2x"):
				continue
			var hi: String = p.get_basename() + "@2x.png"
			load_paths.append(hi if ResourceLoader.exists(hi) else p)
			tex_keys.append(p)
	for w in WHOLE:
		for p in pngs("res://assets/" + w):
			if not load_paths.has(p):
				load_paths.append(p)
	return [load_paths.filter(func(p): return ResourceLoader.exists(p)), tex_keys]


## The SpriteFrames a run builds, one Callable each (SpriteLib caches them).
static func frame_jobs() -> Array:
	var jobs: Array = []
	for f in Forms.ORDER:
		jobs.append(SpriteLib.character.bind(f))
		jobs.append(SpriteLib.death.bind(f))
	for id in form_ids():
		jobs.append(SpriteLib.attacks.bind(id))
		jobs.append(SpriteLib.reactions.bind(id))
	jobs.append(SpriteLib.trex)
	jobs.append(SpriteLib.transform_fx)
	jobs.append(SpriteLib.powerup_fx)
	for h in Hunters.DATA:
		if h != "trex":
			jobs.append(Hunters.frames.bind(h))
	return jobs


## Build the equipped forms' frames now (start_run: a dinosaur equipped at the
## Camp since the loading screen is ready before the run moves; cached ones
## cost nothing).
static func warm_forms() -> void:
	for f in Forms.ORDER:
		SpriteLib.character(f)


func _plan() -> void:
	var c := collect()
	_paths = c[0]
	_tex = c[1]
	_jobs = frame_jobs()
	_total = maxi(_paths.size() + _tex.size() + _jobs.size(), 1)
	for p in _paths:
		ResourceLoader.load_threaded_request(p, "", true)
	_stage = 0


func _process(delta: float) -> void:
	_hint_t -= delta
	if _hint_t <= 0.0:
		_next_hint()
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < BUDGET_MS:
		if not step():
			_finish()
			return
		if _stage == 0 and _i < _paths.size() and ResourceLoader.load_threaded_get_status(_paths[_i]) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			break   # wait for the threads (keeps the bar animating)
	bar.value = float(_done) / float(_total)
	label.text = "Loading... %d%%" % int(round(bar.value * 100.0))


## One unit of work. Returns false when everything is done. (Tests call it
## in a loop: `while pl.step(): pass`.)
func step() -> bool:
	match _stage:
		0:   # threaded loads, collected in order
			if _i >= _paths.size():
				_stage = 1
				_i = 0
				return true
			var p: String = _paths[_i]
			var st := ResourceLoader.load_threaded_get_status(p)
			if st == ResourceLoader.THREAD_LOAD_IN_PROGRESS and not _blocking:
				return true
			if st != ResourceLoader.THREAD_LOAD_INVALID_RESOURCE and st != ResourceLoader.THREAD_LOAD_FAILED:
				var r := ResourceLoader.load_threaded_get(p)   # (blocks until that one is in)
				if r:
					keep.append(r)
			_i += 1
			_done += 1
		1:   # decode the @2x sheets into textures
			if _i >= _tex.size():
				_stage = 2
				_i = 0
				return true
			SpriteLib.tex(_tex[_i])
			_i += 1
			_done += 1
		2:   # build the SpriteFrames
			if _i >= _jobs.size():
				_stage = 3
				return false
			(_jobs[_i] as Callable).call()
			_i += 1
			_done += 1
		_:
			return false
	return true


var _blocking := false   # (tests) wait for each threaded load instead of yielding


## Run every step now (tests).
func run_all() -> void:
	_blocking = true
	while step():
		pass
	_blocking = false


func _finish() -> void:
	set_process(false)
	bar.value = 1.0
	label.text = "Ready!"
	var tw := create_tween()
	tw.tween_property(root, "modulate:a", 0.0, 0.35)
	tw.tween_callback(func():
		finished.emit()
		queue_free())
