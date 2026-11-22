extends SceneTree
## Imports the extra heroes (Nira, Boro) from ../Assets/Rok_New_Heroes_Nira_Boro
## without Pillow:
##   godot --headless --path . -s tools/prepare_heroes.gd
## then `godot --headless --path . --import`.
##
## Their 576x512 frames (ground pivot 288,488) are scaled by 7/16 like Rok's
## sheets, so they stand as tall as him: 252x224 frames, pivot (126, 213.5).
## Per hero it writes:
## - assets/characters/<id>/{idle,walk,run,jump,duck,slide,die}.png (the
##   slide remapped to the game's enter 0-1 / glide 2-4 / recover 5-7)
## - assets/reactions/<id>/{dizzy,trip,snag}.png + its reactions.json entry
## - assets/portraits/<id>.png (first idle frame, trimmed)
## - assets/heroes/heroes.json: name, role, frame, pivot, frame times and the
##   measured standing/sliding bounds (Dinos.form_data turns them into hitboxes)

const SRC := "res://../Assets/Rok_New_Heroes_Nira_Boro"
const IDS := ["nira", "boro"]
const S := 7.0 / 16.0
const PORTRAIT := Vector2(150, 110)


func _initialize() -> void:
	var src := ProjectSettings.globalize_path(SRC)
	var manifest := {}
	var rpath := ProjectSettings.globalize_path("res://assets/reactions/reactions.json")
	var reactions: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(rpath))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://assets/heroes"))
	for id in IDS:
		var meta: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("%s/%s/animations.json" % [src, id]))
		var A: Dictionary = meta.animations
		var fs := Vector2i(meta.frame_size[0], meta.frame_size[1])
		var W := roundi(fs.x * S)
		var H := roundi(fs.y * S)
		var dir := ProjectSettings.globalize_path("res://assets/characters/%s" % id)
		DirAccess.make_dir_recursive_absolute(dir)
		var load_sheet := func(name: String) -> Image:
			var img := Image.load_from_file("%s/%s/spritesheets/%s.png" % [src, id, name])
			img.convert(Image.FORMAT_RGBA8)
			return img
		var write := func(out_path: String, sheet: Image, order: Array) -> void:
			var out := Image.create(W * 4, H * 2, false, Image.FORMAT_RGBA8)
			for j in order.size():
				var i: int = order[j]
				var fr := sheet.get_region(Rect2i(i % 4 * fs.x, i / 4 * fs.y, fs.x, fs.y))
				fr.resize(W, H, Image.INTERPOLATE_LANCZOS)
				out.blit_rect(fr, Rect2i(0, 0, W, H), Vector2i(j % 4 * W, j / 4 * H))
			out.save_png(out_path)
		var times := {}
		for anim in ["idle", "walk", "run", "jump", "duck", "die"]:
			write.call("%s/%s.png" % [dir, anim], load_sheet.call(anim), range(8))
			times[anim] = A[anim].duration_ms
		# slide: the pack's enter 0-1 / hold 2-5 / exit 6-7 -> the game's layout
		write.call("%s/slide.png" % dir, load_sheet.call("slide"), [0, 1, 2, 3, 4, 6, 7, 7])
		times["slide"] = [80, 80, 100, 180, 180, 100, 100, 180]
		# hit reactions on the same canvas
		var rdir := ProjectSettings.globalize_path("res://assets/reactions/%s" % id)
		DirAccess.make_dir_recursive_absolute(rdir)
		for sh in ["dizzy", "trip", "snag"]:
			write.call("%s/%s.png" % [rdir, sh], load_sheet.call(sh), range(8))
		var clips := {}
		for clip in ["dizzy_enter", "dizzy", "dizzy_exit", "trip", "snag_enter", "snag", "snag_exit"]:
			clips[clip] = {"sheet": clip.split("_")[0], "frames": A[clip].source_frame_indices,
					"times": A[clip].duration_ms, "loop": A[clip].loop}
		reactions[id] = {"frame": [W, H], "pivot": [meta.ground_pivot_px[0] * S, meta.ground_pivot_px[1] * S], "clips": clips}
		# measured bounds (game px, relative to the feet)
		var idle: Image = load_sheet.call("idle")
		var first := idle.get_region(Rect2i(0, 0, fs.x, fs.y))
		var u := first.get_used_rect()
		var pv := Vector2(meta.ground_pivot_px[0], meta.ground_pivot_px[1])
		var slide: Image = load_sheet.call("slide")
		var su := slide.get_region(Rect2i(3 * fs.x, 0, fs.x, fs.y)).get_used_rect()
		manifest[id] = {
			"name": meta.display_name, "role": meta.role,
			"frame": [W, H], "pivot": [pv.x * S, pv.y * S], "scale": S, "times": times,
			"stand": [u.size.x * S, (pv.y - u.position.y) * S, (u.get_center().x - pv.x) * S],
			"slide": [su.size.x * S, (pv.y - su.position.y) * S],
		}
		# portrait
		var p := first.get_region(u)
		var ps: float = minf(PORTRAIT.x / p.get_width(), PORTRAIT.y / p.get_height())
		p.resize(maxi(1, roundi(p.get_width() * ps)), maxi(1, roundi(p.get_height() * ps)), Image.INTERPOLATE_LANCZOS)
		p.save_png(ProjectSettings.globalize_path("res://assets/portraits/%s.png" % id))
		print("%-6s frame %dx%d  stands %dx%d  slides %dx%d" % [id, W, H, roundi(manifest[id].stand[0]), roundi(manifest[id].stand[1]), roundi(manifest[id].slide[0]), roundi(manifest[id].slide[1])])
	var f := FileAccess.open(ProjectSettings.globalize_path("res://assets/heroes/heroes.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(manifest, "\t"))
	f.close()
	var rf := FileAccess.open(rpath, FileAccess.WRITE)
	rf.store_string(JSON.stringify(reactions, "\t"))
	rf.close()
	quit()
