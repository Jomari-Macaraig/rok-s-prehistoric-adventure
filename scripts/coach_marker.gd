class_name CoachMarker
extends Control
## The coach hint drawn on the HUD (Tutorial, Hud.coach). Two looks:
## - a bubble: a pulsing golden ring around the target (a button, or a
##   rounded box round a wide target such as a HUD bar or a Back button) and
##   a small bubble with a few words above or below it, with an arrow;
## - a card (the training run, after the user's mockups): a big card at the
##   top with a bold title and a short line, the target glowing with little
##   rays and a tapping hand (assets/ui/tap_hand.png, when it exists), and
##   optionally a dashed arc showing the move (the jump over a rock).
##   A card with no target is a free-standing note (a step's intro).
## With the user's tutorial UI kit (tools/prepare_tutorial_ui.py) the card
## is its ivory panel, the ring its focus ring, the sparks its attention
## marks, the hand its tap pointer, the chips its pill, and the text Baloo 2
## (titles) / Nunito Sans; without it they're drawn in code.
## In any text, [WORD] is drawn in the accent colour ("Tap [JUMP] ...").
## Notes can have Back / Next chips (chip_at). It ignores input otherwise
## and fades in and out.

const RING := Color(1.0, 0.85, 0.3)
const PAPER := Color(0.99, 0.95, 0.84)
const INK := Color(0.3, 0.17, 0.06)
const ACCENT := Color(0.86, 0.38, 0.08)   # [highlighted] words, the card title's shadow
const FS := 22
const CARD_TITLE_FS := 44
const CARD_FS := 26
const CARD_TOP := 150.0      # y of a card (under the top HUD and the tutorial plaque)

var target: Control   # what to point at; null = a free-standing card
var text := ""        # may hold "\n" for two short lines
var title := ""       # an optional heading drawn bigger above the text
var below := false    # put the bubble under the button (the menu's side buttons)
var card := false     # the training run's big top card
var arc := PackedVector2Array()   # a dashed path (screen points) with an arrowhead at the end
## Chips in the bottom row (the training run's notes): any of "back",
## "next". chip_at() hit-tests them (Hud.action_at).
var chips: Array = []
const CHIP_H := 36.0
const CHIP_LABEL := {"back": "‹ Back", "next": "Next ›"}
var _t := 0.0
var _font: Font        # body text (the kit's Nunito Sans, or the default)
var _head: Font        # card titles (the kit's Baloo 2, or the default)
var _hand: Texture2D
var _ring: Texture2D
var _marks: Texture2D
var _card_box: StyleBoxTexture
var _pill_box: StyleBoxTexture


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_font = SpriteLib.ui_font("body")
	_head = SpriteLib.ui_font("heading")
	_hand = SpriteLib.tutorial_ui("hand")
	_ring = SpriteLib.tutorial_ui("ring")
	_marks = SpriteLib.tutorial_ui("marks")
	_card_box = SpriteLib.tutorial_box("card")
	_pill_box = SpriteLib.tutorial_box("pill")
	modulate.a = 0.0
	visible = false


func show_on(b: Control, t: String, under := false, p_chips: Array = [], p_title := "", p_card := false, p_arc := PackedVector2Array()) -> void:
	target = b
	text = t
	below = under
	chips = p_chips
	title = p_title
	card = p_card or b == null
	arc = p_arc
	_t = 0.0
	visible = true
	create_tween().tween_property(self, "modulate:a", 1.0, 0.15)
	queue_redraw()


func hide_now() -> void:
	if not visible:
		return
	target = null
	text = ""
	chips = []
	arc = PackedVector2Array()
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.15)
	tw.tween_callback(func(): if text == "": visible = false)   # (unless a new note came meanwhile)


func _process(delta: float) -> void:
	if visible:
		_t += delta
		queue_redraw()


func _has_note() -> bool:
	return text != "" and (target == null or target.visible)


func _fs() -> int:
	return CARD_FS if card else FS


func _title_fs() -> int:
	return CARD_TITLE_FS if card else FS + 8


func _title_h() -> float:
	if title == "":
		return 0.0
	return 50.0 if card else 34.0


func _line_h() -> float:
	return 32.0 if card else 28.0


## A line without its [brackets] (for measuring).
static func plain(s: String) -> String:
	return s.replace("[", "").replace("]", "")


func _text_w(s: String, fs: int, f: Font = null) -> float:
	return (f if f else _font).get_string_size(plain(s), HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x


func _title_font() -> Font:
	return _head if card else _font


## Where the bubble goes: a card centred at the top; a bubble above the
## button, centred, kept on screen (below it when there's no room).
func bubble_rect() -> Rect2:
	if text == "":
		return Rect2()
	var w := 0.0
	for line in text.split("\n"):
		w = maxf(w, _text_w(line, _fs()))
	if title != "":
		w = maxf(w, _text_w(title, _title_fs(), _title_font()))
	w = maxf(w, chips.size() * 130.0)
	w += (110.0 if _card_box else 48.0) if card else 32.0   # (the kit's card: text in its middle 75%)
	var h := ((40.0 if _card_box else 22.0) if card else 16.0) + _title_h() + _line_h() * text.split("\n").size() + ((CHIP_H + (22.0 if card and _card_box else 12.0)) if not chips.is_empty() else 0.0)
	if card:
		return Rect2((size.x - w) * 0.5, CARD_TOP, w, h)
	var r := target.get_global_rect()
	var x := clampf(r.get_center().x - w * 0.5, 12.0, size.x - w - 12.0)
	var y := r.position.y - h - 22.0
	if below or y < 90.0:
		y = r.end.y + (40.0 if below else 26.0)   # under it (asked for, or no room above), clear of a side button's caption
	return Rect2(x, y, w, h)


## The chips' rects (bottom row of the bubble, right-aligned: Back, Next).
func chip_rects() -> Dictionary:
	var out := {}
	if chips.is_empty() or not visible or not _has_note():
		return out
	var b := bubble_rect()
	var kit_card := card and _card_box != null   # inside the kit card's rounded end and bottom rim
	var x := b.end.x - (b.size.y * 0.32 if kit_card else 14.0)
	for k in range(chips.size() - 1, -1, -1):
		var w := 120.0
		x -= w
		out[chips[k]] = Rect2(x, b.end.y - CHIP_H - (24.0 if kit_card else 12.0), w, CHIP_H)
		x -= 10.0
	return out


## Which chip is at screen point p ("" if none).
func chip_at(p: Vector2) -> String:
	var rs := chip_rects()
	for k in rs:
		if (rs[k] as Rect2).grow(6.0).has_point(p):
			return k
	return ""


func _draw() -> void:
	if not _has_note():
		return
	var pulse := 0.5 + 0.5 * sin(_t * 7.0)
	if arc.size() >= 2:
		_draw_arc_path(pulse)
	if target != null:
		var r := target.get_global_rect()
		var c := r.get_center()
		var rad := maxf(r.size.x, r.size.y) * 0.5 + 10.0
		if r.size.x > r.size.y * 1.5:
			for k in 2:   # a rounded box around a wide target
				var hb := StyleBoxFlat.new()
				hb.draw_center = false
				hb.set_corner_radius_all(12)
				hb.set_border_width_all(6 if k == 0 else 4)
				hb.border_color = Color(RING, 0.35 + 0.35 * (1.0 - pulse)) if k == 0 else RING
				draw_style_box(hb, r.grow(8.0 + (pulse * 7.0 if k == 0 else 0.0)))
		elif card and _ring:   # the kit's focus ring, breathing
			var d := (rad + 16.0) * 2.0 * (1.0 + pulse * 0.06)
			draw_texture_rect(_ring, Rect2(c - Vector2(d, d) * 0.5, Vector2(d, d)), false, Color(1, 1, 1, 0.75 + 0.25 * pulse))
		else:
			if card:   # a soft glow behind the ring
				for k in 4:
					draw_circle(c, rad + 18.0 - k * 5.0, Color(1.0, 0.8, 0.25, 0.07 + 0.03 * pulse))
			draw_arc(c, rad + pulse * 8.0, 0.0, TAU, 48, Color(RING, 0.35 + 0.35 * (1.0 - pulse)), 6.0, true)
			draw_arc(c, rad, 0.0, TAU, 48, RING, 4.0, true)
		if card and r.size.x <= r.size.y * 1.5:
			_draw_rays(c, rad, pulse)
			_draw_hand(c, rad, pulse)
		_draw_bubble(bubble_rect(), not card, c, pulse)
	else:
		_draw_bubble(bubble_rect(), false, Vector2.ZERO, pulse)


## Three short strokes over the button's top right, popping in and out
## (the mockups' "tap here" sparks).
func _draw_rays(c: Vector2, rad: float, pulse: float) -> void:
	if _marks:   # the kit's attention marks over the button's top, popping
		var mw := rad * 1.25 * (0.9 + pulse * 0.15)
		var ms := _marks.get_size() * (mw / _marks.get_width())
		draw_texture_rect(_marks, Rect2(Vector2(c.x - ms.x * 0.5, c.y - rad - ms.y - 4.0 - pulse * 4.0), ms), false)
		return
	var grow := 6.0 + pulse * 6.0
	for k in 3:
		var a := deg_to_rad(-120.0 + k * 30.0)   # up-left, up, up-right
		var d := Vector2(cos(a), sin(a))
		draw_line(c + d * (rad + 10.0), c + d * (rad + 10.0 + grow + 10.0), Color(1.0, 0.82, 0.25), 5.0, true)


## The user's tap pointer over the button's lower right, bobbing (only with
## the tutorial kit; it points up-left, the fingertip at the image's top left).
func _draw_hand(c: Vector2, rad: float, pulse: float) -> void:
	if _hand == null:
		return
	var h := rad * 1.25
	var sz := _hand.get_size() * (h / _hand.get_height())
	var at := c + Vector2(rad * 0.15, rad * 0.25 + pulse * 6.0)
	if at.x + sz.x > size.x - 4.0:
		# no room on the right (JUMP sits in the corner): mirror it to point
		# up-right from the button's lower left
		var tip := c + Vector2(-rad * 0.15, rad * 0.25 + pulse * 6.0)
		draw_set_transform(tip, 0.0, Vector2(-1, 1))
		draw_texture_rect(_hand, Rect2(Vector2.ZERO, sz), false)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	else:
		draw_texture_rect(_hand, Rect2(at, sz), false)


## A dashed path along `arc` with an arrowhead at its end.
func _draw_arc_path(pulse: float) -> void:
	var col := Color(1.0, 0.92, 0.55, 0.95)
	var dash := 14.0
	var gap := 10.0
	var offset := fmod(_t * 40.0, dash + gap)   # the dashes crawl forward
	var dist := -offset
	for i in arc.size() - 1:
		var a := arc[i]
		var b := arc[i + 1]
		var seg := a.distance_to(b)
		var dir := (b - a) / maxf(seg, 0.001)
		var s := 0.0
		while s < seg:
			var phase := fmod(dist + s + (dash + gap) * 100.0, dash + gap)
			if phase < dash:
				var e := minf(s + (dash - phase), seg)
				draw_line(a + dir * s, a + dir * e, col, 6.0, true)
				s = e
			else:
				s += (dash + gap) - phase
		dist += seg
	var tip := arc[arc.size() - 1]
	var back := (arc[arc.size() - 2] - tip).normalized()
	var side := Vector2(-back.y, back.x)
	draw_colored_polygon(PackedVector2Array([tip, tip + back * 22.0 + side * 12.0, tip + back * 22.0 - side * 12.0]), col)


## One line, centred on cx at baseline y, with [WORD] in the accent colour.
func _draw_rich(cx: float, y: float, line: String, fs: int, f: Font = null) -> void:
	if f == null:
		f = _font
	var x := cx - _text_w(line, fs, f) * 0.5
	var hot := false
	for part in line.replace("]", "[").split("["):
		if part != "":
			draw_string(f, Vector2(x, y), part, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, ACCENT if hot else INK)
			if hot:   # a touch heavier, like the mockups' coloured button names
				draw_string(f, Vector2(x + 0.7, y), part, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, ACCENT)
			x += f.get_string_size(part, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		hot = not hot


func _draw_bubble(b: Rect2, with_arrow: bool, c: Vector2, pulse: float) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = PAPER
	sb.border_color = Color(0.55, 0.32, 0.12)
	sb.set_border_width_all(4 if card else 3)
	sb.set_corner_radius_all(22 if card else 14)
	sb.shadow_color = Color(0, 0, 0, 0.3)
	sb.shadow_size = 6 if card else 4
	sb.shadow_offset = Vector2(0, 3) if card else Vector2.ZERO
	# the arrow from the bubble to the ring
	if with_arrow:
		var above := b.end.y < c.y
		var tip := Vector2(clampf(c.x, b.position.x + 20.0, b.end.x - 20.0), b.end.y + 14.0 if above else b.position.y - 14.0)
		var base_y := b.end.y - 2.0 if above else b.position.y + 2.0
		var bob := Vector2(0, (1.0 if above else -1.0) * pulse * 4.0)
		draw_colored_polygon(PackedVector2Array([Vector2(tip.x - 12.0, base_y), Vector2(tip.x + 12.0, base_y), tip + bob]), Color(0.55, 0.32, 0.12))
	if card and _card_box:
		draw_style_box(_card_box, b)   # the kit's ivory card
	else:
		draw_style_box(sb, b)
	if card:   # attention marks off the card's top right (the kit's, or two drawn strokes)
		if _marks:
			var ms := _marks.get_size() * 0.8
			draw_set_transform(Vector2(b.end.x - 30.0, b.position.y + 6.0), 0.5, Vector2.ONE)
			draw_texture_rect(_marks, Rect2(-ms * 0.5, ms), false)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		else:
			var o := Vector2(b.end.x - 26.0, b.position.y - 4.0)
			draw_line(o, o + Vector2(10, -24), ACCENT, 6.0, true)
			draw_line(o + Vector2(16, 6), o + Vector2(30, -14), ACCENT, 6.0, true)
	var top := b.position.y + ((16.0 if _card_box else 6.0) if card else 0.0)
	if title != "":
		var tfs := _title_fs()
		var tf := _title_font()
		var tw := _text_w(title, tfs, tf)
		var tp := Vector2(b.get_center().x - tw * 0.5, top + (44.0 if card else 36.0))
		if card:   # a bold, dark title
			if tf == ThemeDB.fallback_font:
				draw_string_outline(tf, tp, title, HORIZONTAL_ALIGNMENT_LEFT, -1, tfs, 3, INK)
			draw_string(tf, tp, title, HORIZONTAL_ALIGNMENT_LEFT, -1, tfs, INK)
		else:
			draw_string(tf, tp, title, HORIZONTAL_ALIGNMENT_LEFT, -1, tfs, Color(0.75, 0.35, 0.08))
		top += _title_h()
	var lines := text.split("\n")
	for i in lines.size():
		_draw_rich(b.get_center().x, top + (32.0 if card else 30.0) + _line_h() * i, lines[i], _fs())
	var rs := chip_rects()
	for k in rs:
		var cr: Rect2 = rs[k]
		var light := false
		if _pill_box:   # the kit's brown pill (Back a little dimmer)
			draw_style_box(_pill_box, cr)
			if k == "back":
				draw_style_box(_pill_box, cr)
			light = true
		else:
			var cs := StyleBoxFlat.new()
			cs.bg_color = Color(0.85, 0.55, 0.2) if k == "next" else Color(0.88, 0.8, 0.66)
			cs.border_color = Color(0.55, 0.32, 0.12)
			cs.set_border_width_all(2)
			cs.set_corner_radius_all(10)
			draw_style_box(cs, cr)
			light = k == "next"
		var label: String = CHIP_LABEL[k]
		var lw := _font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, FS - 2).x
		draw_string(_font, Vector2(cr.get_center().x - lw * 0.5, cr.get_center().y + 7.0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, FS - 2,
				Color(1, 0.97, 0.9) if light else INK)
