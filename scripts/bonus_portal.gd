class_name BonusPortal
extends Node2D
## The entrance to a bonus zone (main._bonus_step): a stone arch with a
## swirling golden light, standing on the ground (origin = the middle of its
## foot). Rok runs through it, whatever his height. Uses the user's art
## (`assets/items/bonus_portal.png`, bottom-centre at the origin) once it
## exists; until then it's drawn in code.

const ART := "res://assets/items/bonus_portal.png"
const W := 150.0
const H := 230.0

var _t := 0.0
var entered := false


func _ready() -> void:
	if ResourceLoader.exists(ART):
		var s := Sprite2D.new()
		s.texture = load(ART)
		s.centered = false
		s.offset = Vector2(-s.texture.get_width() * 0.5, -s.texture.get_height())
		add_child(s)


func _process(delta: float) -> void:
	_t += delta
	if get_child_count() == 0:
		queue_redraw()


func _draw() -> void:
	if get_child_count() > 0:
		return
	# glow
	for i in 5:
		var c := Color(1.0, 0.8, 0.35, 0.10 + 0.03 * sin(_t * 3.0 + i))
		draw_circle(Vector2(0, -H * 0.5), H * (0.62 - i * 0.08), c)
	# swirling light inside the arch
	var inner := PackedVector2Array()
	for i in 24:
		var a := PI + PI * i / 23.0
		inner.append(Vector2(cos(a) * (W * 0.36), -H * 0.62 + sin(a) * (H * 0.3)))
	inner.append(Vector2(W * 0.36, 0))
	inner.append(Vector2(-W * 0.36, 0))
	draw_colored_polygon(inner, Color(0.55, 0.3, 0.85, 0.85))
	for k in 3:
		var pts := PackedVector2Array()
		for i in 40:
			var a := _t * (2.0 + k) + i * 0.3
			var r := 4.0 + i * 1.3
			pts.append(Vector2(cos(a) * r, -H * 0.45 + sin(a) * r * 1.3))
		draw_polyline(pts, Color(1.0, 0.85, 0.4, 0.7 - k * 0.2), 3.0)
	# stone arch
	var stone := Color(0.5, 0.45, 0.4)
	var dark := Color(0.25, 0.2, 0.17)
	for side in [-1.0, 1.0]:
		draw_rect(Rect2(side * W * 0.5 - (22.0 if side > 0 else 0.0), -H * 0.62, 22, H * 0.62), dark)
		draw_rect(Rect2(side * W * 0.5 - (19.0 if side > 0 else -3.0), -H * 0.6, 16, H * 0.6), stone)
	var arch := PackedVector2Array()
	for i in 21:
		var a := PI + PI * i / 20.0
		arch.append(Vector2(cos(a) * W * 0.5, -H * 0.62 + sin(a) * H * 0.36))
	draw_polyline(arch, dark, 24.0)
	draw_polyline(arch, stone, 18.0)
	draw_circle(Vector2(0, -H * 0.98), 12.0, Color(1.0, 0.8, 0.3))
