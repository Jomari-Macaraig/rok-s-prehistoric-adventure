class_name SpriteLib
## Builds and caches SpriteFrames from the 4x2 sprite sheets.

const CHAR_ANIMS := {
	"idle": [300, 200, 200, 200, 200, 80, 180, 300],
	"walk": [120, 120, 120, 120, 120, 120, 120, 120],
	"run": [80, 80, 80, 80, 80, 80, 80, 80],
	"jump": [120, 80, 100, 160, 100, 80, 120, 320],
	"duck": [200, 200, 200, 200, 200, 200, 200, 200],
	"slide": [80, 80, 100, 180, 180, 100, 100, 180],
}

static var _cache := {}
static var _wind_meta := {}
static var _tex_cache := {}


## Loads an art file, preferring its hi-res twin <name>@2x.png when one exists
## (tools/prepare_rok_hires.gd: the same art at twice the pixels). The twin is
## wrapped in an ImageTexture whose size is overridden to half its pixels, so
## frame sizes, pivots and atlas regions stay in 1x units while the GPU samples
## the sharper pixels. Use it for any character or portrait art.
static func tex(path: String) -> Texture2D:
	if _tex_cache.has(path):
		return _tex_cache[path]
	var hi := path.get_basename() + "@2x." + path.get_extension()
	var t: Texture2D
	if ResourceLoader.exists(hi):
		var src: Texture2D = load(hi)
		var it := ImageTexture.create_from_image(src.get_image())
		it.set_size_override(Vector2i(src.get_size()) / 2)
		t = it
	else:
		t = load(path)
	_tex_cache[path] = t
	return t


static func _sheet_frames(frames: SpriteFrames, anim: String, sheet_tex: Texture2D,
		frame_size: Vector2, durations_ms: Array, loop: bool) -> void:
	frames.add_animation(anim)
	frames.set_animation_loop(anim, loop)
	# speed 1000 fps + per-frame duration in ms => real milliseconds
	frames.set_animation_speed(anim, 1000.0)
	for i in durations_ms.size():
		var at := AtlasTexture.new()
		at.atlas = sheet_tex
		at.region = Rect2(Vector2(i % 4, i / 4) * frame_size, frame_size)
		frames.add_frame(anim, at, float(durations_ms[i]))


static func character(form: int) -> SpriteFrames:
	var d := Forms.get_data(form)
	var key := "char_%d_%s" % [form, d.id]
	if _cache.has(key):
		return _cache[key]
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	if d.get("species", false):
		_species_frames(frames, d)
		_add_celebrate(frames, d.id, d.frame)
		_cache[key] = frames
		return frames
	for anim in CHAR_ANIMS:
		var sheet_tex: Texture2D = tex("res://assets/characters/%s/%s.png" % [d.id, anim])
		_sheet_frames(frames, anim, sheet_tex, d.frame, CHAR_ANIMS[anim], anim != "jump" and anim != "slide")
	var extra: Dictionary = d.get("extra_anims", {})
	for anim in extra:
		var sheet_tex: Texture2D = tex("res://assets/characters/%s/%s.png" % [d.id, anim])
		_sheet_frames(frames, anim, sheet_tex, d.frame, extra[anim], anim == "fly" or anim == "glide")
	_add_celebrate(frames, d.id, d.frame)
	_cache[key] = frames
	return frames


static var _celebrate_meta := {}
static var _running_meta := {}
static var _fx_meta := {}


## The shapeshift burst's meta (tools/prepare_transform_fx.py): cell, pivot,
## fps, swap and cover frames, `cover` (the solid cloud's size at 1x).
static func transform_meta() -> Dictionary:
	if _fx_meta.is_empty() and FileAccess.file_exists("res://assets/fx/transform_burst.json"):
		_fx_meta = JSON.parse_string(FileAccess.get_file_as_string("res://assets/fx/transform_burst.json"))
	return _fx_meta


## The shapeshift burst as frames ("a", plays once), or null without the art.
static func transform_fx() -> SpriteFrames:
	if _cache.has("transform_fx"):
		return _cache["transform_fx"]
	var m := transform_meta()
	if m.is_empty():
		return null
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	var ms := []
	for i in int(m.frames):
		ms.append(1000.0 / float(m.fps))
	_sheet_frames(frames, "a", tex("res://assets/fx/transform_burst.png"), Vector2(m.cell[0], m.cell[1]), ms, false)
	_cache["transform_fx"] = frames
	return frames


## The user's seamless running attacks (tools/prepare_running_attacks.py):
## per hero, the weapons that have one: {weapon: {frame, pivot, hit, phases,
## carry_frame}}. Empty if none.
static func running_meta(hero: String) -> Dictionary:
	if _running_meta.is_empty() and FileAccess.file_exists("res://assets/attacks/running.json"):
		_running_meta = JSON.parse_string(FileAccess.get_file_as_string("res://assets/attacks/running.json"))
	return _running_meta.get(hero, {})


## A hero's character frames with "run" swapped for the run carrying `weapon`
## (the weapon drawn in; GearLayer hides its own copy during the run).
## The plain frames if there's no such sheet.
static func carry_frames(form: int, weapon: String) -> SpriteFrames:
	var d := Forms.get_data(form)
	if weapon == "" or not running_meta(String(d.id)).has(weapon):
		return character(form)
	var key := "carry_%d_%s_%s" % [form, d.id, weapon]
	if _cache.has(key):
		return _cache[key]
	var frames: SpriteFrames = character(form).duplicate()
	frames.remove_animation("run")
	_sheet_frames(frames, "run", tex("res://assets/attacks/%s/run_%s.png" % [d.id, weapon]), d.frame, CHAR_ANIMS["run"], true)
	_cache[key] = frames
	return frames


## The running attack for a hero's weapon: animations "p0".."p7" (the swing
## started at run phase p), 8 frames each, on the attack canvas
## (running_meta pivot). Its frames are stepped by Player with the run's
## clock, not played. null if there's none.
static func running_attack(hero: String, weapon: String) -> SpriteFrames:
	var m: Dictionary = running_meta(hero).get(weapon, {})
	if m.is_empty():
		return null
	var key := "runatk_%s_%s" % [hero, weapon]
	if _cache.has(key):
		return _cache[key]
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	for p in int(m.phases):
		_sheet_frames(frames, "p%d" % p, tex("res://assets/attacks/%s/run_attack_%s_%d.png" % [hero, weapon, p]),
				Vector2(m.frame[0], m.frame[1]), CHAR_ANIMS["run"], false)
	_cache[key] = frames
	return frames


## The new-best celebration jump (Rok, Nira, Boro; the user's art, imported by
## tools/prepare_animation_pack.gd onto each hero's own canvas): {times,
## launch, land} or {} if this character has none.
static func celebrate_meta(id: String) -> Dictionary:
	if _celebrate_meta.is_empty() and FileAccess.file_exists("res://assets/characters/celebrate.json"):
		_celebrate_meta = JSON.parse_string(FileAccess.get_file_as_string("res://assets/characters/celebrate.json"))
	if not ResourceLoader.exists("res://assets/characters/%s/celebrate.png" % id):
		return {}
	return _celebrate_meta.get(id, {})


static func _add_celebrate(frames: SpriteFrames, id: String, frame_size: Vector2) -> void:
	var m := celebrate_meta(id)
	if not m.is_empty():
		_sheet_frames(frames, "celebrate", tex("res://assets/characters/%s/celebrate.png" % id), frame_size, m.times, false)


## An expansion species: its own sheets and frame times (tools/prepare_dinos.gd).
## Pterosaurs have no walk/run: their fly loop stands in on the ground.
static func _species_frames(frames: SpriteFrames, d: Dictionary) -> void:
	var t: Dictionary = d.times
	var file := func(anim: String) -> String:
		if not t.has(anim):
			return "fly"   # walk/run for pterosaurs
		return anim
	for anim in ["idle", "walk", "run", "jump", "duck", "slide"]:
		var f: String = file.call(anim)
		var sheet_tex: Texture2D = tex("res://assets/characters/%s/%s.png" % [d.id, f])
		_sheet_frames(frames, anim, sheet_tex, d.frame, t[f], anim != "jump" and anim != "slide")
	var extra: Dictionary = d.get("extra_files", {})
	for anim in extra:
		var f: String = extra[anim]
		var sheet_tex: Texture2D = tex("res://assets/characters/%s/%s.png" % [d.id, f])
		_sheet_frames(frames, anim, sheet_tex, d.frame, t[f], anim == "fly" or anim == "glide" or anim == "swim")


static var _attack_meta := {}


## The attack clips (tools/prepare_attacks.py): {id: {clip: {frame, pivot,
## times, active, release, direction}}}. A hero's clips are "attack_<weapon
## id>", a dinosaur's is "attack".
static func attack_meta(id: String) -> Dictionary:
	if _attack_meta.is_empty() and FileAccess.file_exists("res://assets/attacks/attacks.json"):
		_attack_meta = JSON.parse_string(FileAccess.get_file_as_string("res://assets/attacks/attacks.json"))
	return _attack_meta.get(id, {})


## One-shot attack clips for a character id, or null if it has none. Each
## clip has its own canvas and pivot (attack_meta).
static func attacks(id: String) -> SpriteFrames:
	var key := "attack_" + id
	if _cache.has(key):
		return _cache[key]
	var m := attack_meta(id)
	if m.is_empty():
		return null
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	for clip in m:
		var c: Dictionary = m[clip]
		_sheet_frames(frames, clip, tex("res://assets/attacks/%s/%s.png" % [id, clip]),
				Vector2(c.frame[0], c.frame[1]), c.times, false)
	_cache[key] = frames
	return frames


static var _react_meta := {}


## Hit reactions for a character id (Rok, a dinosaur form or an expansion
## species): trip, dizzy_enter/dizzy/dizzy_exit, snag_enter/snag/snag_exit.
## null if it has none. Their own canvas and pivot: see reaction_pivot().
static func reactions(id: String) -> SpriteFrames:
	var key := "react_" + id
	if _cache.has(key):
		return _cache[key]
	if _react_meta.is_empty() and FileAccess.file_exists("res://assets/reactions/reactions.json"):
		_react_meta = JSON.parse_string(FileAccess.get_file_as_string("res://assets/reactions/reactions.json"))
	if not _react_meta.has(id):
		return null
	var m: Dictionary = _react_meta[id]
	var fs := Vector2(m.frame[0], m.frame[1])
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	for clip in m.clips:
		var c: Dictionary = m.clips[clip]
		var sheet_tex: Texture2D = tex("res://assets/reactions/%s/%s.png" % [id, c.sheet])
		frames.add_animation(clip)
		frames.set_animation_speed(clip, 1000.0)
		frames.set_animation_loop(clip, c.loop)
		for k in (c.frames as Array).size():
			var i: int = c.frames[k]
			var at := AtlasTexture.new()
			at.atlas = sheet_tex
			at.region = Rect2(Vector2(i % 4, i / 4) * fs, fs)
			frames.add_frame(clip, at, float(c.times[k]))
	_cache[key] = frames
	return frames


static func reaction_pivot(id: String) -> Vector2:
	reactions(id)
	var p: Array = _react_meta[id].pivot
	return Vector2(p[0], p[1])


static func trex() -> SpriteFrames:
	if _cache.has("trex"):
		return _cache["trex"]
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	var anims := {
		"idle": [300, 200, 200, 200, 200, 80, 180, 300],
		"run": [100, 100, 100, 100, 100, 100, 100, 100],
		"roar": [160, 120, 120, 220, 220, 120, 120, 220],
		"bite": [140, 100, 80, 100, 60, 100, 140, 220],
	}
	for anim in anims:
		var sheet_tex: Texture2D = load("res://assets/characters/trex/%s.png" % anim)
		_sheet_frames(frames, anim, sheet_tex, Vector2(672, 448), anims[anim], anim == "idle" or anim == "run")
	_cache["trex"] = frames
	return frames


static var _die_meta := {}


## Mario-style death hop for a form: "die" = hit + surprised (frames 0-1),
## "hop" = the dazed hop pose (frames 2-7, looping) while it falls away.
static func death(form: int) -> SpriteFrames:
	var sd := Forms.get_data(form)
	var key := "die_%d_%s" % [form, sd.id]
	if _cache.has(key):
		return _cache[key]
	if sd.get("species", false):
		# the species' own die clip: hit (0-1), then the dazed hop (2-7)
		var stex: Texture2D = tex("res://assets/characters/%s/die.png" % sd.id)
		var sf := SpriteFrames.new()
		sf.remove_animation("default")
		for anim in ["die", "hop"]:
			sf.add_animation(anim)
			sf.set_animation_speed(anim, 1000.0)
			sf.set_animation_loop(anim, anim == "hop")
			var sidx := [0, 1] if anim == "die" else [2, 3, 4, 5, 6, 7]
			for i in sidx:
				var at := AtlasTexture.new()
				at.atlas = stex
				at.region = Rect2(Vector2(i % 4, i / 4) * sd.frame, sd.frame)
				sf.add_frame(anim, at, float(sd.times.die[i]))
		_cache[key] = sf
		return sf
	if _die_meta.is_empty():
		_die_meta = JSON.parse_string(FileAccess.open("res://assets/characters/die.json", FileAccess.READ).get_as_text())
	var id: String = Forms.get_data(form).id
	var m: Dictionary = _die_meta[id]
	var fs := Vector2(m.frame[0], m.frame[1])
	var sheet_tex: Texture2D = tex("res://assets/characters/%s/die.png" % id)
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	for anim in ["die", "hop"]:
		frames.add_animation(anim)
		frames.set_animation_speed(anim, 1000.0)
		frames.set_animation_loop(anim, anim == "hop")
		var idx := [0, 1] if anim == "die" else [2, 3, 4, 5, 6, 7]
		var dur := [260, 220] if anim == "die" else [90, 90, 90, 90, 90, 90]
		for k in idx.size():
			var at := AtlasTexture.new()
			at.atlas = sheet_tex
			at.region = Rect2(Vector2(idx[k] % 4, idx[k] / 4) * fs, fs)
			frames.add_frame(anim, at, float(dur[k]))
	_cache[key] = frames
	return frames


static func death_pivot(form: int) -> Vector2:
	if Forms.get_data(form).get("species", false):
		return Forms.get_data(form).pivot
	death(form)
	var m: Dictionary = _die_meta[Forms.get_data(form).id]
	return Vector2(m.pivot[0], m.pivot[1])


static var _trap_meta := {}


static func trap_meta() -> Dictionary:
	if _trap_meta.is_empty():
		var f := FileAccess.open("res://assets/traps/traps.json", FileAccess.READ)
		_trap_meta = JSON.parse_string(f.get_as_text())
	return _trap_meta


## Frames for a trap / break animation from assets/traps (one animation
## "a"). part is "" or, for liquids, "left" / "mid" / "right".
static func trap(name: String, part := "") -> SpriteFrames:
	var key := "trap_%s_%s" % [name, part]
	if _cache.has(key):
		return _cache[key]
	var m: Dictionary = trap_meta()[name]
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	var file := name if part == "" else "%s_%s" % [name, part]
	var sheet_tex: Texture2D = load("res://assets/traps/%s.png" % file)
	var fs: Array = m.frame if part == "" else m[part]
	_sheet_frames(frames, "a", sheet_tex, Vector2(fs[0], fs[1]), m.duration_ms, m.loop)
	_cache[key] = frames
	return frames


## An AnimatedSprite2D for a trap animation, its anchor at the node origin.
static func trap_sprite(name: String, playing := true) -> AnimatedSprite2D:
	var m: Dictionary = trap_meta()[name]
	var a := AnimatedSprite2D.new()
	a.sprite_frames = trap(name)
	a.centered = false
	a.offset = -Vector2(m.anchor[0], m.anchor[1])
	a.play("a")
	if not playing:
		a.pause()
		a.frame = 0
	return a


static func wind_meta() -> Dictionary:
	if _wind_meta.is_empty():
		var f := FileAccess.open("res://assets/wind/wind.json", FileAccess.READ)
		_wind_meta = JSON.parse_string(f.get_as_text())
	return _wind_meta


static func wind(name: String) -> SpriteFrames:
	var key := "wind_" + name
	if _cache.has(key):
		return _cache[key]
	var m: Dictionary = wind_meta()[name]
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	var sheet_tex: Texture2D = load("res://assets/wind/%s.png" % name)
	var durations := []
	durations.resize(8)
	durations.fill(m.frame_ms)
	_sheet_frames(frames, "wind", sheet_tex, Vector2(m.frame[0], m.frame[1]), durations, true)
	_cache[key] = frames
	return frames


static func wind_pivot(name: String) -> Vector2:
	var m: Dictionary = wind_meta()[name]
	return Vector2(m.pivot[0], m.pivot[1])


static func wind_frame(name: String) -> Vector2:
	var m: Dictionary = wind_meta()[name]
	return Vector2(m.frame[0], m.frame[1])
