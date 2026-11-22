extends SceneTree
## Imports the hit reactions (trip, dizzy, snag) for Rok and all 32 dinosaurs
## from ../Assets/Rok_Dinosaur_Expansion/Rok_Hit_Reactions (Rok and the first
## 20) and ../Assets/Rok_Balanced_32_Form_Pack (the 12 species it adds; each
## of their three sheets has its own canvas and pivot, so `_balanced` re-centres
## them on one shared canvas per species), without Pillow:
##   godot --headless --path . -s tools/prepare_reactions.gd
## then `godot --headless --path . --import`. Run tools/prepare_dinos.gd first
## (the expansion species' scales come from assets/dinos/dinos.json).
##
## Each character's three sheets (4x2: dizzy and snag are enter 0-1, hold
## 2-5, recover 6-7; trip is all eight) are scaled to that character's in-game
## art size: 7/16 for the original five (like their other sheets, the form's
## own sprite scale is applied on top), and the species' import scale for the
## expansion dinosaurs. They keep their own canvas and pivot, so they play on
## a separate sprite (Player.react). Output: assets/reactions/<id>/<sheet>.png
## and assets/reactions/reactions.json (frame, pivot, clips with frame
## indices, times and loop flags).

const SRC := "res://../Assets/Rok_Dinosaur_Expansion/Rok_Hit_Reactions"
const OUT := "res://assets/reactions"
const SRC_BALANCED := "res://../Assets/Rok_Balanced_32_Form_Pack"
const ORIGINALS := ["rok", "raptor", "triceratops", "spinosaurus", "pteranodon"]


func _initialize() -> void:
	var src := ProjectSettings.globalize_path(SRC)
	var out := ProjectSettings.globalize_path(OUT)
	var meta: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(src + "/hit_reactions.json"))
	var dinos: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ProjectSettings.globalize_path("res://assets/dinos/dinos.json")))
	var manifest := {}
	for id in meta.character_order:
		var c: Dictionary = meta.characters[id]
		var s := 7.0 / 16.0
		if not ORIGINALS.has(id):
			if not dinos.creatures.has(id) or not dinos.creatures[id].has("play"):
				push_warning("%s: no playable import yet, skipped" % id)
				continue
			s = float(dinos.creatures[id].play.scale)
		var fs := Vector2i(c.frame_size[0], c.frame_size[1])
		var W := maxi(1, roundi(fs.x * s))
		var H := maxi(1, roundi(fs.y * s))
		DirAccess.make_dir_recursive_absolute(out + "/" + id)
		var clips := {}
		var done := {}
		for clip in c.animations:
			var a: Dictionary = c.animations[clip]
			var sheet: String = String(a.sheet).get_file().get_basename()   # dizzy / snag / trip
			if not done.has(sheet):
				var img := Image.load_from_file(src + "/" + a.sheet)
				img.convert(Image.FORMAT_RGBA8)
				img.resize(W * 4, H * 2, Image.INTERPOLATE_LANCZOS)
				img.save_png(out + "/%s/%s.png" % [id, sheet])
				done[sheet] = true
			# frame indices in the 8-frame sheet: enter 0-1, hold 2-5, exit 6-7
			var idx: Array = range(8)
			if clip.ends_with("_enter"):
				idx = [0, 1]
			elif clip.ends_with("_exit"):
				idx = [6, 7]
			elif clip != "trip":
				idx = [2, 3, 4, 5]
			clips[clip] = {"sheet": sheet, "frames": idx, "times": a.duration_ms, "loop": a.loop}
		manifest[id] = {"frame": [W, H], "pivot": [c.ground_pivot_px[0] * s, c.ground_pivot_px[1] * s], "clips": clips}
		print("%-20s %dx%d" % [id, W, H])
	var bsrc := ProjectSettings.globalize_path(SRC_BALANCED)
	if FileAccess.file_exists(bsrc + "/animations.json"):
		var bmeta: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(bsrc + "/animations.json"))
		for id in bmeta.new_character_ids:
			if not dinos.creatures.has(id) or not dinos.creatures[id].has("play"):
				push_warning("%s: no playable import yet, skipped" % id)
				continue
			manifest[id] = _balanced(bsrc, id, bmeta.characters[id], float(dinos.creatures[id].play.scale), out)
	var f := FileAccess.open(out + "/reactions.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(manifest, "\t"))
	f.close()
	quit()


## A balanced-pack species: its dizzy, trip and snag sheets each have their own
## frame size and pivot, so every frame is placed on one canvas (the union of
## the three around their pivots), then scaled by the species' import scale.
func _balanced(bsrc: String, id: String, c: Dictionary, s: float, out: String) -> Dictionary:
	var A: Dictionary = c.animations
	var sheets := ["dizzy", "trip", "snag"]
	var left := 0
	var up := 0
	var right := 0
	var down := 0
	for k in sheets:
		var fs: Array = A[k].frame_size
		var pv: Array = A[k].pivot_px
		left = maxi(left, int(pv[0]))
		up = maxi(up, int(pv[1]))
		right = maxi(right, int(fs[0]) - int(pv[0]))
		down = maxi(down, int(fs[1]) - int(pv[1]))
	var W := maxi(1, ceili((left + right) * s))
	var H := maxi(1, ceili((up + down) * s))
	DirAccess.make_dir_recursive_absolute(out + "/" + id)
	for k in sheets:
		var a: Dictionary = A[k]
		var fs := Vector2i(int(a.frame_size[0]), int(a.frame_size[1]))
		var pv := Vector2i(int(a.pivot_px[0]), int(a.pivot_px[1]))
		var img := Image.load_from_file(bsrc + "/" + String(a.sheet))
		img.convert(Image.FORMAT_RGBA8)
		var sheet := Image.create(W * 4, H * 2, false, Image.FORMAT_RGBA8)
		for i in 8:
			var fr := img.get_region(Rect2i(i % 4 * fs.x, i / 4 * fs.y, fs.x, fs.y))
			var canvas := Image.create(left + right, up + down, false, Image.FORMAT_RGBA8)
			canvas.blit_rect(fr, Rect2i(Vector2i.ZERO, fs), Vector2i(left - pv.x, up - pv.y))
			canvas.resize(W, H, Image.INTERPOLATE_LANCZOS)
			sheet.blit_rect(canvas, Rect2i(0, 0, W, H), Vector2i(i % 4 * W, i / 4 * H))
		sheet.save_png(out + "/%s/%s.png" % [id, k])
	var clips := {}
	for clip in ["dizzy_enter", "dizzy", "dizzy_exit", "trip", "snag_enter", "snag", "snag_exit"]:
		var a: Dictionary = A[clip]
		var sheet: String = clip.split("_")[0]
		var idx: Array = range(8)
		if clip.ends_with("_enter"):
			idx = [0, 1]
		elif clip.ends_with("_exit"):
			idx = [6, 7]
		elif clip != "trip":
			idx = [2, 3, 4, 5]
		clips[clip] = {"sheet": sheet, "frames": idx, "times": a.duration_ms, "loop": a.loop}
	print("%-20s %dx%d (balanced pack)" % [id, W, H])
	return {"frame": [W, H], "pivot": [left * s, up * s], "clips": clips}
