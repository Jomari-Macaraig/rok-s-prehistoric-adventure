class_name CoachMarker
extends Control
## The coach hint drawn on the HUD (Tutorial, Hud.coach): a pulsing golden
## ring around the button to press and a small bubble with a few words above
## it (below it if there's no room), with a little arrow pointing at the
## button. A wide target (a HUD bar, a Back button) gets a rounded box
## instead of a ring. It ignores input and fades in and out.

const RING := Color(1.0, 0.85, 0.3)
const PAPER := Color(0.99, 0.95, 0.84)
const INK := Color(0.3, 0.17, 0.06)
const FS := 22

var target: Control
var text := ""        # may hold "\n" for two short lines
var below := false    # put the bubble under the button (the menu's side buttons)
var _t := 0.0
var _font: Font


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_font = ThemeDB.fallback_font
	modulate.a = 0.0
	visible = false


func show_on(b: Control, t: String, under := false) -> void:
	target = b
	text = t
	below = under
	_t = 0.0
	visible = true
	create_tween().tween_property(self, "modulate:a", 1.0, 0.15)
	queue_redraw()


func hide_now() -> void:
	if not visible:
		return
	target = null
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.15)
	tw.tween_callback(func(): if target == null: visible = false)


func _process(delta: float) -> void:
	if visible:
		_t += delta
		queue_redraw()


## Where the bubble goes: above the button, centred, kept on screen.
func bubble_rect() -> Rect2:
	if target == null:
		return Rect2()
	var r := target.get_global_rect()
	var w := 0.0
	for line in text.split("\n"):
		w = maxf(w, _font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, FS).x)
	w += 32.0
	var h := 16.0 + 28.0 * text.split("\n").size()
	var x := clampf(r.get_center().x - w * 0.5, 12.0, size.x - w - 12.0)
	var y := r.position.y - h - 22.0
	if below or y < 90.0:
		y = r.end.y + (40.0 if below else 26.0)   # under it (asked for, or no room above), clear of a side button's caption
	return Rect2(x, y, w, h)


func _draw() -> void:
	if target == null or not target.visible:
		return
	var r := target.get_global_rect()
	var c := r.get_center()
	var rad := maxf(r.size.x, r.size.y) * 0.5 + 10.0
	var pulse := 0.5 + 0.5 * sin(_t * 7.0)
	if r.size.x > r.size.y * 1.5:
		for k in 2:   # a rounded box around a wide target
			var hb := StyleBoxFlat.new()
			hb.draw_center = false
			hb.set_corner_radius_all(12)
			hb.set_border_width_all(6 if k == 0 else 4)
			hb.border_color = Color(RING, 0.35 + 0.35 * (1.0 - pulse)) if k == 0 else RING
			draw_style_box(hb, r.grow(8.0 + (pulse * 7.0 if k == 0 else 0.0)))
	else:
		draw_arc(c, rad + pulse * 8.0, 0.0, TAU, 48, Color(RING, 0.35 + 0.35 * (1.0 - pulse)), 6.0, true)
		draw_arc(c, rad, 0.0, TAU, 48, RING, 4.0, true)
	var b := bubble_rect()
	var sb := StyleBoxFlat.new()
	sb.bg_color = PAPER
	sb.border_color = Color(0.55, 0.32, 0.12)
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(14)
	sb.shadow_color = Color(0, 0, 0, 0.3)
	sb.shadow_size = 4
	# the arrow from the bubble to the ring
	var above := b.end.y < c.y
	var tip := Vector2(clampf(c.x, b.position.x + 20.0, b.end.x - 20.0), b.end.y + 14.0 if above else b.position.y - 14.0)
	var base_y := b.end.y - 2.0 if above else b.position.y + 2.0
	var bob := Vector2(0, (1.0 if above else -1.0) * pulse * 4.0)
	draw_colored_polygon(PackedVector2Array([Vector2(tip.x - 12.0, base_y), Vector2(tip.x + 12.0, base_y), tip + bob]), Color(0.55, 0.32, 0.12))
	draw_style_box(sb, b)
	var lines := text.split("\n")
	for i in lines.size():
		var lw := _font.get_string_size(lines[i], HORIZONTAL_ALIGNMENT_LEFT, -1, FS).x
		draw_string(_font, Vector2(b.get_center().x - lw * 0.5, b.position.y + 30.0 + 28.0 * i), lines[i], HORIZONTAL_ALIGNMENT_LEFT, -1, FS, INK)
