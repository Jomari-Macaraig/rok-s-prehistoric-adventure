class_name CardView
extends Control
## A dinosaur card as the user drew it (assets/cards/<id>, tools/prepare_cards.py)
## with its bonus written on the blank parchment (cards.json `text_box`), or,
## for a dinosaur without card art yet, its portrait on the scene kit's card
## with the name and bonus underneath. Fits its rect, keeping the card's shape.
## The Encyclopedia's Cards tab (Codex) shows it on the book's left page.

var dino := ""
var text := ""            # the bonus, e.g. "+2 Speed"
var locked := false       # not found yet: a dark silhouette, no text
static var _meta := {}


func _init(id := "", bonus := "", is_locked := false) -> void:
	dino = id
	text = bonus
	locked = is_locked
	mouse_filter = Control.MOUSE_FILTER_IGNORE


static func meta() -> Dictionary:
	if _meta.is_empty() and FileAccess.file_exists("res://assets/cards/cards.json"):
		_meta = JSON.parse_string(FileAccess.get_file_as_string("res://assets/cards/cards.json"))
	return _meta


## The card art for a dinosaur, or null if it has none yet.
static func art(id: String) -> Texture2D:
	var p := "res://assets/cards/%s.png" % id
	return SpriteLib.tex(p) if ResourceLoader.exists(p) else null


## The picture to show for a card on a shelf tile: its art, else its portrait.
static func icon(id: String) -> Texture2D:
	var a := art(id)
	return a if a else Gear.icon(Gear.CARD_PREFIX + id)


func _draw() -> void:
	var tex := art(dino)
	var tint := Color(0.12, 0.07, 0.03, 0.85) if locked else Color.WHITE
	var font := SpriteLib.ui_font("heading")
	if tex:
		var r := _fit(tex.get_size())
		draw_texture_rect(tex, r, false, tint)
		if locked or text == "":
			return
		var tb: Array = meta().get(dino, {}).get("text_box", [0.1, 0.77, 0.9, 0.95])
		var box := Rect2(r.position + Vector2(tb[0], tb[1]) * r.size, Vector2(tb[2] - tb[0], tb[3] - tb[1]) * r.size)
		box = box.grow_individual(-box.size.x * 0.1, -box.size.y * 0.12, -box.size.x * 0.1, -box.size.y * 0.12)
		_text_in(box, font)
		return
	# no art yet: the portrait on the kit's parchment card, name and bonus below
	var base := SceneKit.card_box(false, locked)
	var r2 := _fit(Vector2(256, 320))
	if base:
		draw_style_box(base, r2)
	var pic := Gear.icon(Gear.CARD_PREFIX + dino)
	if pic:
		var pr := Rect2(r2.position + Vector2(r2.size.x * 0.1, r2.size.y * 0.08), Vector2(r2.size.x * 0.8, r2.size.y * 0.58))
		var s := minf(pr.size.x / pic.get_width(), pr.size.y / pic.get_height())
		var ps := pic.get_size() * s
		draw_texture_rect(pic, Rect2(pr.get_center() - ps * 0.5, ps), false, tint)
	if not locked:
		_text_in(Rect2(r2.position + Vector2(r2.size.x * 0.08, r2.size.y * 0.7), Vector2(r2.size.x * 0.84, r2.size.y * 0.22)), font)


## The card's rect inside ours, keeping its aspect.
func _fit(src: Vector2) -> Rect2:
	var s := minf(size.x / src.x, size.y / src.y)
	var sz := src * s
	return Rect2((size - sz) * 0.5, sz)


## The bonus centred in `box`, as large as fits (one or two lines).
func _text_in(box: Rect2, font: Font) -> void:
	var fs := int(clampf(box.size.y * 0.42, 12.0, 30.0))
	var lines := text.split("\n")
	while fs > 10:
		var w := 0.0
		for l in lines:
			w = maxf(w, font.get_string_size(l, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x)
		if w <= box.size.x and fs * 1.15 * lines.size() <= box.size.y:
			break
		fs -= 1
	var lh := fs * 1.15
	var y := box.get_center().y - lh * lines.size() * 0.5 + fs * 0.85
	for l in lines:
		var lw := font.get_string_size(l, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		draw_string(font, Vector2(box.get_center().x - lw * 0.5, y), l, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0.3, 0.16, 0.05))
		y += lh
