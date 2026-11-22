extends SceneTree
## Imports the Dinosaur Expansion art without Pillow:
##   godot --headless --path . -s tools/prepare_dinos.gd
## then `godot --headless --path . --import`.
##
## Sources: ../Assets/Rok_Dinosaur_Expansion/Rok_Dinosaur_Expansion (2) (the
## first 16, full set with jump, slide and die; falls back to the idle-only
## pack), then ../Assets/Rok_Balanced_32_Form_Pack for the 12 species it adds
## (its `new_character_ids`: 4 Runners, 3 Smashers, 5 Flyers). Its metadata is
## normalised to the expansion's shape (`_balanced`); those species also bring
## a real duck loop instead of one built from the slide.
##
## For each of the 28 creatures it writes:
## - assets/dinos/<id>_idle.png: the idle loop cropped to its frames' shared
##   bounds and fitted in CARD_SIDE px, for Market cards.
## - assets/characters/<id>/<anim>.png: playable sheets, 4x2 like the other
##   forms. Every clip is re-centred on ONE canvas per species (some clips have
##   extra padding with their own pivot; the game uses one pivot per form),
##   then scaled so the creature stands as tall as its category's playable
##   form (CATEGORY_HEIGHT), but no wider than MAX_WIDTH. The slide sheet is
##   remapped to the game's layout (enter 0-1, glide 2-4, recover 5-7), and a
##   duck sheet is made from the slide's held poses. Pterosaurs have no
##   walk/run: their fly loop stands in on the ground.
## - assets/portraits/<id>.png: the first idle frame, trimmed, for buttons.
## - assets/dinos/dinos.json: catalogue text, card frames, and per species the
##   playable frame size, pivot, frame times and measured bounds (standing,
##   sliding, flying) used for hitboxes (Dinos.form_data).

const SRC_FULL := "res://../Assets/Rok_Dinosaur_Expansion/Rok_Dinosaur_Expansion (2)"
const SRC_IDLE := "res://../Assets/Rok_Dinosaur_Expansion"
const SRC_BALANCED := "res://../Assets/Rok_Balanced_32_Form_Pack"
const OUT := "res://assets/dinos"
const CARD_SIDE := 160.0
## In-game standing height per category: that of its playable form.
const CATEGORY_HEIGHT := {"runner": 112.0, "smasher": 136.0, "tank": 152.0, "flyer": 124.0}
const MAX_WIDTH := 240.0
const PORTRAIT := Vector2(150, 110)

var src := ""


func _initialize() -> void:
	src = ProjectSettings.globalize_path(SRC_FULL)
	if not FileAccess.file_exists(src + "/animations.json"):
		src = ProjectSettings.globalize_path(SRC_IDLE)
	var out := ProjectSettings.globalize_path(OUT)
	DirAccess.make_dir_recursive_absolute(out)
	var meta: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(src + "/animations.json"))
	var manifest := {}
	for id in meta.creature_order:
		var c: Dictionary = meta.creatures[id]
		var entry := _card(id, c, out)
		if c.animations.has("die"):
			entry["play"] = _playable(id, c)
		manifest[id] = entry
	var order: Array = meta.creature_order.duplicate()
	# the balanced roster's new species
	var bsrc := ProjectSettings.globalize_path(SRC_BALANCED)
	if FileAccess.file_exists(bsrc + "/animations.json"):
		src = bsrc
		var bmeta: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(bsrc + "/animations.json"))
		for id in bmeta.new_character_ids:
			var c := _balanced(bmeta.characters[id])
			var entry := _card(id, c, out)
			entry["play"] = _playable(id, c)
			manifest[id] = entry
			order.append(id)
	else:
		push_warning("prepare_dinos: %s missing, only the first 16 imported" % SRC_BALANCED)
	var f := FileAccess.open(out + "/dinos.json", FileAccess.WRITE)
	f.store_string(JSON.stringify({"order": order, "creatures": manifest}, "\t"))
	f.close()
	quit()


## A balanced-pack character in the expansion's metadata shape: `role` becomes
## `group` (Flyers are pterosaurs) and the reference height is the first idle
## frame's visual height, as in the expansion pack.
func _balanced(c: Dictionary) -> Dictionary:
	var d := c.duplicate()
	d["group"] = "pterosaurs" if c.role == "Flyer" else "dinosaurs"
	var b: Array = c.animations.idle.visual_bounds_px[0]
	d["reference_visual_height_px"] = b[3] - b[1]
	d["own_duck"] = c.animations.has("duck") and not c.animations.duck.has("derived_from")
	return d


func _img(rel: String) -> Image:
	var img := Image.load_from_file(src + "/" + rel)
	img.convert(Image.FORMAT_RGBA8)
	return img


## Market card loop: idle frames cropped to their shared bounds.
func _card(id: String, c: Dictionary, out: String) -> Dictionary:
	var anim: Dictionary = c.animations.idle
	var frames: Array[Image] = []
	var used := Rect2i()
	for rel in anim.frames:
		var img := _img(rel)
		frames.append(img)
		var r := img.get_used_rect()
		used = r if used.size == Vector2i.ZERO else used.merge(r)
	var s: float = CARD_SIDE / maxf(used.size.x, used.size.y)
	var fw := maxi(1, roundi(used.size.x * s))
	var fh := maxi(1, roundi(used.size.y * s))
	var sheet := Image.create(fw * 4, fh * 2, false, Image.FORMAT_RGBA8)
	for i in frames.size():
		var fr := frames[i].get_region(used)
		fr.resize(fw, fh, Image.INTERPOLATE_LANCZOS)
		sheet.blit_rect(fr, Rect2i(Vector2i.ZERO, fr.get_size()), Vector2i(i % 4 * fw, i / 4 * fh))
	sheet.save_png(out + "/%s_idle.png" % id)
	# portrait: first idle frame, trimmed, fitted in PORTRAIT
	var p := frames[0].get_region(frames[0].get_used_rect())
	var ps: float = minf(PORTRAIT.x / p.get_width(), PORTRAIT.y / p.get_height())
	p.resize(maxi(1, roundi(p.get_width() * ps)), maxi(1, roundi(p.get_height() * ps)), Image.INTERPOLATE_LANCZOS)
	p.save_png(ProjectSettings.globalize_path("res://assets/portraits/%s.png" % id))
	return {
		"name": c.display_name, "group": c.group, "feature": c.distinctive_feature,
		"frame": [fw, fh], "duration_ms": anim.duration_ms,
	}


func _fs(c: Dictionary, a: Dictionary) -> Vector2i:
	var v: Array = a.get("frame_size", c.frame_size)
	return Vector2i(v[0], v[1])


func _pv(c: Dictionary, a: Dictionary) -> Vector2i:
	var v: Array = a.get("pivot_px", c.ground_pivot_px)
	return Vector2i(v[0], v[1])


## Union of visual bounds (x0, y0, x1, y1 in the clip's canvas) of the given
## frames, relative to the pivot.
func _bounds(c: Dictionary, a: Dictionary, idx: Array) -> Rect2:
	var pv := Vector2(_pv(c, a))
	var r := Rect2()
	for i in idx:
		var b: Array = a.visual_bounds_px[i]
		var fr := Rect2(Vector2(b[0], b[1]) - pv, Vector2(b[2] - b[0], b[3] - b[1]))
		r = fr if r.size == Vector2.ZERO else r.merge(fr)
	return r


var _ptera_top := -1.0


## How far above its feet the Pteranodon's flight art reaches (game px).
func _pteranodon_fly_top() -> float:
	if _ptera_top < 0.0:
		var img := Image.load_from_file(ProjectSettings.globalize_path("res://assets/characters/pteranodon/fly.png"))
		var top := 1e9
		for i in 8:
			var r := img.get_region(Rect2i(i % 4 * 224, i / 4 * 224, 224, 224)).get_used_rect()
			top = minf(top, r.position.y)
		_ptera_top = 213.5 - top   # Pteranodon pivot y, scale 1
	return _ptera_top


func _playable(id: String, c: Dictionary) -> Dictionary:
	var A: Dictionary = c.animations
	var flyer: bool = c.group == "pterosaurs"
	var own_duck: bool = c.get("own_duck", false)
	var clips := ["idle", "jump", "slide", "die"] + (["fly", "glide"] if flyer else ["walk", "run"]) + (["duck"] if own_duck else [])
	# one shared canvas: the extents of every clip around its pivot
	var left := 0
	var up := 0
	var right := 0
	var down := 0
	for k in clips:
		var fs := _fs(c, A[k])
		var pv := _pv(c, A[k])
		left = maxi(left, pv.x)
		up = maxi(up, pv.y)
		right = maxi(right, fs.x - pv.x)
		down = maxi(down, fs.y - pv.y)
	# size: as tall as the category's form, no wider than MAX_WIDTH
	var stand := _bounds(c, A.idle if flyer else A.run, range(8))
	var cat: String = Dinos.category_of(id)
	var s: float = minf(CATEGORY_HEIGHT[cat] / float(c.reference_visual_height_px), MAX_WIDTH / stand.size.x)
	# flyers: flight art is registered at the beak tip, floating far above the
	# feet. Shift fly/glide down so the art's top sits as high above the feet
	# as the Pteranodon's, so the flight ceiling and fly hitbox still fit.
	var fly_dy := 0
	if flyer:
		var top_now: float = -_bounds(c, A.fly, range(A.fly.visual_bounds_px.size())).position.y * s
		fly_dy = maxi(0, roundi((top_now - _pteranodon_fly_top()) / s))
		down += fly_dy
	var W := ceili((left + right) * s)
	var H := ceili((up + down) * s)
	var dir := ProjectSettings.globalize_path("res://assets/characters/%s" % id)
	DirAccess.make_dir_recursive_absolute(dir)
	var times := {}
	var write := func(name: String, clip: String, order: Array, dy := 0) -> void:
		var a: Dictionary = A[clip]
		var fs := _fs(c, a)
		var pv := _pv(c, a)
		var sheet_img := _img(a.sheet)
		var outimg := Image.create(W * 4, H * 2, false, Image.FORMAT_RGBA8)
		for j in order.size():
			var i: int = order[j]
			var fr := sheet_img.get_region(Rect2i(i % 4 * fs.x, i / 4 * fs.y, fs.x, fs.y))
			var canvas := Image.create(left + right, up + down, false, Image.FORMAT_RGBA8)
			canvas.blit_rect(fr, Rect2i(Vector2i.ZERO, fs), Vector2i(left - pv.x, up - pv.y + dy))
			canvas.resize(W, H, Image.INTERPOLATE_LANCZOS)
			outimg.blit_rect(canvas, Rect2i(0, 0, W, H), Vector2i(j % 4 * W, j / 4 * H))
		outimg.save_png(dir + "/%s.png" % name)
	write.call("idle", "idle", range(8))
	times["idle"] = A.idle.duration_ms
	write.call("jump", "jump", range(8))
	times["jump"] = A.jump.duration_ms
	# the slide sheet: enter 0-1, loop 2-5, exit 6-7 -> the game's enter 0-1,
	# glide 2-4, recover 5-7
	write.call("slide", "slide", [0, 1, 2, 3, 4, 6, 7, 7])
	times["slide"] = [80, 80, 100, 180, 180, 100, 100, 180]
	if own_duck:
		write.call("duck", "duck", range(8))
		times["duck"] = A.duck.duration_ms
	else:
		write.call("duck", "slide", [2, 3, 4, 5, 2, 3, 4, 5])
		times["duck"] = [200, 200, 200, 200, 200, 200, 200, 200]
	write.call("die", "die", range(8))
	times["die"] = A.die.duration_ms
	if flyer:
		write.call("fly", "fly", range(8), fly_dy)
		write.call("glide", "glide", range(8), fly_dy)
		times["fly"] = A.fly.duration_ms
		times["glide"] = A.glide.duration_ms
	else:
		write.call("walk", "walk", range(8))
		write.call("run", "run", range(8))
		times["walk"] = A.walk.duration_ms
		times["run"] = A.run.duration_ms
	var slide := _bounds(c, A.slide, range(A.slide.visual_bounds_px.size()))   # the held slide poses
	var out := {
		"frame": [W, H], "pivot": [left * s, up * s], "scale": s, "times": times, "flyer": flyer,
		# measured art, in game pixels, relative to the feet (pivot)
		"stand": [stand.size.x * s, -stand.position.y * s, stand.get_center().x * s],
		"slide": [slide.size.x * s, -slide.position.y * s],
	}
	if flyer:
		var fly := _bounds(c, A.fly, range(A.fly.visual_bounds_px.size()))
		fly.position.y += fly_dy   # where it's drawn now
		out["fly"] = [fly.size.x * s, fly.size.y * s, -fly.end.y * s, fly.get_center().x * s]
	print("%-20s %-8s frame %dx%d  stands %dx%d  slides %dx%d" % [id, cat, W, H,
			roundi(out.stand[0]), roundi(out.stand[1]), roundi(out.slide[0]), roundi(out.slide[1])])
	return out
