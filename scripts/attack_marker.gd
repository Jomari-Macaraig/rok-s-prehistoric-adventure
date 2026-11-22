class_name AttackMarker
extends Node2D
## Shows what ATTACK would hit right now (main._attack_marker_step sets it
## every frame from main.attack_target): corner brackets around the target and
## a small arrow above it. Green = the attack would break it, red = it would
## just clang off (not enough Power, or a dino gate); faded while the attack
## cools down. Works for any reach, so a long-range weapon later just shows
## its marker further out.

var box := Rect2()          # the target's hitbox, in world coordinates
var breaks := true
var ready_now := true
var _t := 0.0


func _process(delta: float) -> void:
	_t += delta
	if visible:
		queue_redraw()


func _draw() -> void:
	var col := Color(0.45, 1.0, 0.45) if breaks else Color(1.0, 0.35, 0.3)
	col.a = 0.95 if ready_now else 0.4
	var r := box.grow(10.0 + 3.0 * sin(_t * 8.0))
	var l := clampf(minf(r.size.x, r.size.y) * 0.3, 10.0, 26.0)
	var dark := Color(0.1, 0.05, 0.02, col.a * 0.8)
	for pass_i in 2:
		var c := dark if pass_i == 0 else col
		var w := 7.0 if pass_i == 0 else 4.0
		for corner in [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]:
			var sx := 1.0 if corner.x == r.position.x else -1.0
			var sy := 1.0 if corner.y == r.position.y else -1.0
			draw_line(corner, corner + Vector2(sx * l, 0), c, w)
			draw_line(corner, corner + Vector2(0, sy * l), c, w)
	# the arrow above, bobbing
	var tip := Vector2(r.get_center().x, r.position.y - 8.0 - 4.0 * absf(sin(_t * 5.0)))
	var pts := PackedVector2Array([tip, tip + Vector2(-12, -16), tip + Vector2(12, -16)])
	draw_colored_polygon(PackedVector2Array([tip + Vector2(0, 3), tip + Vector2(-15, -18), tip + Vector2(15, -18)]), dark)
	draw_colored_polygon(pts, col)
