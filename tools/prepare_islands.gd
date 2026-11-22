extends SceneTree
## Imports the user's zone floating islands without Pillow:
##   godot --headless --path . -s tools/prepare_islands.gd
## then `godot --headless --path . --import`.
##
## Sources (in ../Assets): "Desert sandstone floating island-2.png" and
## "Ash-dusted basalt floating island-1.png" (1542 x 1020 canvases). Each is
## trimmed to its art (alpha > ALPHA_MIN, so a faint halo doesn't count) and
## scaled with Lanczos to the forest island's in-game size (the width of
## assets/props/Terrain-variation_03.png, 131 px, keeping its own aspect), so
## FloatingPlatform's width and TOP_INSET still fit. Output:
## assets/props/Terrain-variation_03_desert.png and _volcanic.png, which
## FloatingPlatform.island_texture(zone) picks up for the Desert and Volcanic
## platforms and the Volcanic low ledge.

const SRC := "res://../Assets/"
const ISLANDS := {
	"desert": "Desert sandstone floating island-2.png",
	"volcanic": "Ash-dusted basalt floating island-1.png",
}
const FOREST := "res://assets/props/Terrain-variation_03.png"
const ALPHA_MIN := 0.08


func _initialize() -> void:
	var forest := Image.load_from_file(ProjectSettings.globalize_path(FOREST))
	var target_w := forest.get_width()
	print("forest island %dx%d" % [forest.get_width(), forest.get_height()])
	for zone in ISLANDS:
		var path := ProjectSettings.globalize_path(SRC + ISLANDS[zone])
		var img := Image.load_from_file(path)
		if img == null or img.is_empty():
			push_error("prepare_islands: can't read " + path)
			continue
		img.convert(Image.FORMAT_RGBA8)
		var r := _art_rect(img)
		var art := img.get_region(r)
		var h := roundi(target_w * float(r.size.y) / float(r.size.x))
		art.resize(target_w, h, Image.INTERPOLATE_LANCZOS)
		var out := ProjectSettings.globalize_path("res://assets/props/Terrain-variation_03_%s.png" % zone)
		art.save_png(out)
		print("%-8s art %dx%d at %s -> %dx%d" % [zone, r.size.x, r.size.y, r.position, target_w, h])
	quit()


## The bounds of the pixels with alpha above ALPHA_MIN.
func _art_rect(img: Image) -> Rect2i:
	var x0 := img.get_width()
	var y0 := img.get_height()
	var x1 := -1
	var y1 := -1
	for y in img.get_height():
		for x in img.get_width():
			if img.get_pixel(x, y).a > ALPHA_MIN:
				x0 = mini(x0, x)
				y0 = mini(y0, y)
				x1 = maxi(x1, x)
				y1 = maxi(y1, y)
	return Rect2i(x0, y0, x1 - x0 + 1, y1 - y0 + 1)
