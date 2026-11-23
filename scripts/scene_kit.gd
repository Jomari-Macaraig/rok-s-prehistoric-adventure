class_name SceneKit
## The user's Encyclopedia and Dinosaurs (Camp) scene kit
## (tools/prepare_scene_kit.py, assets/scenes/), shared by Codex and Herd:
## textures, 9-slice styles, the painted backdrop, the title plaques, the
## stone Back button, the counter plate and the roster's tabs and cards.
## Every helper returns null / does nothing without the kit, so the screens
## fall back to their drawn look.

const DIR := "res://assets/scenes/%s.png"
const LIGHT := Color(1.0, 0.96, 0.86)
const DARK := Color(0.25, 0.13, 0.05)
static var _meta := {}


static func has() -> bool:
	return ResourceLoader.exists(DIR % "open_book")


static func tex(name: String) -> Texture2D:
	var p := DIR % name
	return SpriteLib.tex(p) if ResourceLoader.exists(p) else null


static func meta() -> Dictionary:
	if _meta.is_empty() and FileAccess.file_exists("res://assets/scenes/scene_kit.json"):
		_meta = JSON.parse_string(FileAccess.get_file_as_string("res://assets/scenes/scene_kit.json"))
	return _meta


## A piece as a 9-slice style (the kit's margins, 1x), or null.
static func box(name: String, content_scale := 1.0) -> StyleBoxTexture:
	var t := tex(name)
	if t == null:
		return null
	var sb := StyleBoxTexture.new()
	sb.texture = t
	var m: Dictionary = meta().get("boxes", {}).get(name, {})
	var tm: Array = m.get("texture", [0, 0, 0, 0])
	var cm: Array = m.get("content", [0, 0, 0, 0])
	sb.texture_margin_left = tm[0]
	sb.texture_margin_top = tm[1]
	sb.texture_margin_right = tm[2]
	sb.texture_margin_bottom = tm[3]
	sb.content_margin_left = cm[0] * content_scale
	sb.content_margin_top = cm[1] * content_scale
	sb.content_margin_right = cm[2] * content_scale
	sb.content_margin_bottom = cm[3] * content_scale
	return sb


## The painted background, covering the screen (named Backdrop like
## Market.backdrop), or null.
static func backdrop(name: String) -> Control:
	var t := tex(name)
	if t == null:
		return null
	var c := Control.new()
	c.name = "Backdrop"
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var pic := TextureRect.new()
	pic.texture = t
	pic.set_anchors_preset(Control.PRESET_FULL_RECT)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.add_child(pic)
	return c


## A picture (a character, the title plaque) at height `h`, keeping its aspect.
static func picture(name: String, h: float, node_name := "") -> TextureRect:
	var t := tex(name)
	if t == null:
		return null
	var r := TextureRect.new()
	if node_name != "":
		r.name = node_name
	r.texture = t
	r.set_meta("art", DIR % name)
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.custom_minimum_size = Vector2(h * t.get_width() / t.get_height(), h)
	r.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


## Dress a Button in a kit piece for every state (pressed = `pressed_name`).
static func style_button(b: Button, name: String, pressed_name := "", font_size := 22, color := LIGHT) -> void:
	var n := box(name)
	if n == null:
		return
	var p := box(pressed_name if pressed_name != "" else name)
	for st in ["normal", "hover", "focus", "disabled"]:
		b.add_theme_stylebox_override(st, n)
	for st in ["pressed", "hover_pressed"]:
		b.add_theme_stylebox_override(st, p)
	b.add_theme_font_override("font", SpriteLib.ui_font("heading"))
	b.add_theme_font_size_override("font_size", font_size)
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(c, color)
	b.add_theme_color_override("font_outline_color", DARK)
	b.add_theme_constant_override("outline_size", 6)


## The stone Back button (icon only; the node keeps its name and its place).
static func style_back(b: Button) -> void:
	var t := tex("stone_back")
	if t == null:
		return
	b.text = ""
	b.icon = t
	b.expand_icon = true
	b.custom_minimum_size = Vector2(64, 64)
	var empty := StyleBoxEmpty.new()
	for st in ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]:
		b.add_theme_stylebox_override(st, empty)


## A roster card's base: selected, locked or normal.
static func card_box(chosen: bool, locked: bool) -> StyleBox:
	return box("card_selected" if chosen else ("card_locked" if locked else "card_normal"))


## A small label on a kit pill ("NEW" on the orange badge, a status on the
## green pill), or null without the kit.
static func badge(text: String, piece: String, size := 13) -> Label:
	var sb := box(piece) if piece == "status_pill_blank" else null
	var t := tex(piece)
	if t == null:
		return null
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", SpriteLib.ui_font("heading"))
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", LIGHT)
	l.add_theme_color_override("font_outline_color", DARK)
	l.add_theme_constant_override("outline_size", 4)
	if sb == null:
		sb = StyleBoxTexture.new()
		sb.texture = t
		sb.texture_margin_left = 18
		sb.texture_margin_right = 18
		sb.texture_margin_top = 8
		sb.texture_margin_bottom = 8
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 1
	sb.content_margin_bottom = 3
	l.add_theme_stylebox_override("normal", sb)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l
