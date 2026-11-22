extends SceneTree
## Imports the meat currency art (../Assets/Rok_Meat_Currency), no Pillow needed:
##   godot --headless --path . -s tools/prepare_meat.gd
## then `godot --headless --path . --import`.
##
## assets/items/meat.png: the static 128 px icon scaled to 96 px (HUD counter,
## Market, Field Guide). assets/items/meat_idle.png: the 128 px 4x2 idle loop
## (gentle bob, tilt and shine, 100 ms per frame), used by meat pickups.

const SRC := "res://../Assets/Rok_Meat_Currency"
const OUT := "res://assets/items"


func _initialize() -> void:
	var src := ProjectSettings.globalize_path(SRC)
	var out := ProjectSettings.globalize_path(OUT)
	DirAccess.make_dir_recursive_absolute(out)
	var icon := Image.load_from_file(src + "/meat_128.png")
	icon.convert(Image.FORMAT_RGBA8)
	icon.resize(96, 96, Image.INTERPOLATE_LANCZOS)
	icon.save_png(out + "/meat.png")
	var sheet := Image.load_from_file(src + "/animations/128/spritesheets/meat_idle.png")
	sheet.save_png(out + "/meat_idle.png")
	print("meat icon 96 px, idle sheet %s" % sheet.get_size())
	quit()
