extends SceneTree
## Imports ../Assets/Rok_Hunters_Crouches_Best_Distance without Pillow:
##   godot --headless --path . -s tools/prepare_animation_pack.gd
## then `godot --headless --path . --import`. Run it AFTER prepare_dinos.gd
## (it rewrites the 16 expansion species' duck.png and their dinos.json entry).
##
## Every source sheet is 4x2 with one frame size and ground pivot per clip
## (the pack's animations.json). It writes:
## - assets/hunters/<id>/{idle,run,roar,bite}.png + assets/hunters/hunters.json:
##   the Carnotaurus and Allosaurus, scaled x0.875 like the T-rex (768x512 ->
##   672x448, pivot 336,427). `snout` is measured like Trex.SNOUT: the run
##   clip's furthest visual x past the feet, scaled.
## - assets/characters/<id>/duck.png for the 16 older expansion species: their
##   real crouch, scaled by the species' import scale (dinos.json play.scale)
##   and placed on its existing playable canvas so the crouch's pivot lands on
##   the species' pivot. dinos.json gets play.times.duck and play.own_duck.
## - assets/best_flag/{waving,passed}.png + best_flag.json: the best-distance
##   flag at Rok's scale (7/16; 640x512 -> 280x224, pivot 63,213.5).
## - assets/characters/<id>/celebrate.png + assets/characters/celebrate.json:
##   the new-best celebration jump for Rok, Nira and Boro at 7/16. Rok's
##   frames are cropped to his 384 px source canvas (168 px in game) around
##   the pivot so they share his other clips' canvas.

const SRC := "res://../Assets/Rok_Hunters_Crouches_Best_Distance"
const HUNTER_SCALE := 0.875
const ROK_SCALE := 0.4375

var src := ""
var meta := {}


func _initialize() -> void:
	src = ProjectSettings.globalize_path(SRC)
	if not FileAccess.file_exists(src + "/animations.json"):
		push_error("prepare_animation_pack: %s/animations.json not found" % src)
		quit(1)
		return
	meta = JSON.parse_string(FileAccess.get_file_as_string(src + "/animations.json")).assets
	_hunters()
	_crouches()
	_flag()
	_celebrations()
	quit()


func _img(rel: String) -> Image:
	return Image.load_from_file(src + "/" + rel)


## Frame i of a clip, cut out of its 4x2 sheet.
func _frame(sheet: Image, fs: Vector2i, i: int) -> Image:
	return sheet.get_region(Rect2i(i % 4 * fs.x, i / 4 * fs.y, fs.x, fs.y))


## A clip re-drawn into a 4x2 sheet of out_size frames: each source frame is
## scaled by s and placed so its pivot lands on out_pivot.
func _resheet(a: Dictionary, fs: Vector2i, pv: Vector2, s: float, out_size: Vector2i, out_pivot: Vector2, path: String) -> void:
	var sheet := _img(a.sheet)
	var out := Image.create(out_size.x * 4, out_size.y * 2, false, Image.FORMAT_RGBA8)
	var scaled := Vector2i(roundi(fs.x * s), roundi(fs.y * s))
	var at := Vector2i((out_pivot - pv * s).round())
	var clipped := false
	for i in 8:
		var fr := _frame(sheet, fs, i)
		fr.resize(scaled.x, scaled.y, Image.INTERPOLATE_LANCZOS)
		var used := fr.get_used_rect()
		var r := Rect2i(at + used.position, used.size)
		if not Rect2i(Vector2i.ZERO, out_size).encloses(r):
			clipped = true
		var cell := Image.create(out_size.x, out_size.y, false, Image.FORMAT_RGBA8)
		cell.blit_rect(fr, Rect2i(Vector2i.ZERO, scaled), at)
		out.blit_rect(cell, Rect2i(Vector2i.ZERO, out_size), Vector2i(i % 4 * out_size.x, i / 4 * out_size.y))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path).get_base_dir())
	out.save_png(ProjectSettings.globalize_path(path))
	if clipped:
		print("  note: %s is cropped at the canvas edge" % path)


func _v(a: Array) -> Vector2:
	return Vector2(a[0], a[1])


func _hunters() -> void:
	var out := {}
	for id in ["carnotaurus", "allosaurus"]:
		var e: Dictionary = meta["hunters/" + id]
		var fs := Vector2i(_v(e.frame_size))
		var pv := _v(e.ground_pivot_px)
		var size := Vector2i((Vector2(fs) * HUNTER_SCALE).round())
		var times := {}
		for anim in ["idle", "run", "roar", "bite"]:
			var a: Dictionary = e.animations[anim]
			_resheet(a, fs, pv, HUNTER_SCALE, size, pv * HUNTER_SCALE, "res://assets/hunters/%s/%s.png" % [id, anim])
			times[anim] = a.duration_ms
		var reach := 0.0
		for b in e.animations.run.visual_bounds_px:
			reach = maxf(reach, float(b[2]))
		out[id] = {"frame": [size.x, size.y], "pivot": [pv.x * HUNTER_SCALE, pv.y * HUNTER_SCALE],
				"snout": snappedf((reach - pv.x) * HUNTER_SCALE, 0.5), "times": times,
				"bite_impact_frame": e.animations.bite.get("events", {}).get("bite_impact_frame", 4)}
		print("hunter %-12s frame %dx%d snout %.1f" % [id, size.x, size.y, out[id].snout])
	_save_json("res://assets/hunters/hunters.json", out)


func _crouches() -> void:
	var path := "res://assets/dinos/dinos.json"
	var dinos: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	var n := 0
	for key in meta:
		if not String(key).begins_with("crouches/"):
			continue
		var id: String = String(key).get_slice("/", 1)
		var play: Dictionary = dinos.creatures.get(id, {}).get("play", {})
		if play.is_empty():
			print("  skip crouch %s: not a playable species in dinos.json" % id)
			continue
		var a: Dictionary = meta[key].animations.duck
		var fs := Vector2i(_v(a.get("frame_size", meta[key].get("frame_size"))))
		var pv := _v(a.get("ground_pivot_px", meta[key].get("ground_pivot_px")))
		_resheet(a, fs, pv, float(play.scale), Vector2i(_v(play.frame)), _v(play.pivot),
				"res://assets/characters/%s/duck.png" % id)
		play.times["duck"] = a.duration_ms
		play["own_duck"] = true
		n += 1
	_save_json(path, dinos)
	print("%d real crouches" % n)


func _flag() -> void:
	var e: Dictionary = meta["best_distance/best_distance_flag"]
	var fs := Vector2i(_v(e.frame_size))
	var pv := _v(e.ground_pivot_px)
	var size := Vector2i((Vector2(fs) * ROK_SCALE).round())
	var times := {}
	for anim in ["waving", "passed"]:
		_resheet(e.animations[anim], fs, pv, ROK_SCALE, size, pv * ROK_SCALE, "res://assets/best_flag/%s.png" % anim)
		times[anim] = e.animations[anim].duration_ms
	var top := 1e9
	for b in e.animations.waving.visual_bounds_px:
		top = minf(top, float(b[1]))
	_save_json("res://assets/best_flag/best_flag.json", {"frame": [size.x, size.y],
			"pivot": [pv.x * ROK_SCALE, pv.y * ROK_SCALE], "top": snappedf((pv.y - top) * ROK_SCALE, 0.5), "times": times})
	print("flag frame %dx%d" % [size.x, size.y])


func _celebrations() -> void:
	var out := {}
	for id in ["rok", "nira", "boro"]:
		var e: Dictionary = meta["celebrations/" + id]
		var a: Dictionary = e.animations.celebrate_jump
		var fs := Vector2i(_v(e.frame_size))
		var pv := _v(e.ground_pivot_px)
		# Rok's clips use a 384 px source canvas (168 x 224 in game, pivot 84, 213.5)
		var out_size := Vector2i(168, 224) if id == "rok" else Vector2i((Vector2(fs) * ROK_SCALE).round())
		var out_pivot := Vector2(84, 213.5) if id == "rok" else pv * ROK_SCALE
		_resheet(a, fs, pv, ROK_SCALE, out_size, out_pivot, "res://assets/characters/%s/celebrate.png" % id)
		var ev: Dictionary = a.get("events", {})
		out[id] = {"times": a.duration_ms, "launch": ev.get("launch_frame", 2), "land": ev.get("land_frame", 6)}
	_save_json("res://assets/characters/celebrate.json", out)
	print("3 celebration jumps")


func _save_json(path: String, data: Variant) -> void:
	var f := FileAccess.open(ProjectSettings.globalize_path(path), FileAccess.WRITE)
	f.store_string(JSON.stringify(data, "\t"))
	f.close()
