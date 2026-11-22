class_name Fx
extends Node2D
## One-shot particle bursts, floating text and camera shake.

var shake := 0.0
var shake_target: Node2D
var _dot: GradientTexture2D


func _ready() -> void:
	# soft round particle instead of the default square
	_dot = GradientTexture2D.new()
	_dot.width = 16
	_dot.height = 16
	_dot.fill = GradientTexture2D.FILL_RADIAL
	_dot.fill_from = Vector2(0.5, 0.5)
	_dot.fill_to = Vector2(1.0, 0.5)
	var g := Gradient.new()
	g.set_color(0, Color.WHITE)
	g.add_point(0.6, Color(1, 1, 1, 0.9))
	g.set_color(g.get_point_count() - 1, Color(1, 1, 1, 0))
	_dot.gradient = g


func _burst(pos: Vector2, color: Color, amount: int, speed: float, size: float,
		life: float, spread := 180.0, dir := Vector2.UP, gravity := 900.0) -> void:
	var p := CPUParticles2D.new()
	p.position = pos
	p.one_shot = true
	p.emitting = false
	p.amount = amount
	p.lifetime = life
	p.explosiveness = 0.95
	p.direction = dir
	p.spread = spread
	p.initial_velocity_min = speed * 0.4
	p.initial_velocity_max = speed
	p.gravity = Vector2(0, gravity)
	p.scale_amount_min = size * 0.5 / 10.0
	p.scale_amount_max = size / 10.0
	var curve := Curve.new()
	curve.add_point(Vector2(0, 1))
	curve.add_point(Vector2(1, 0))
	p.scale_amount_curve = curve
	p.color = color
	p.texture = _dot
	var ramp := Gradient.new()
	ramp.set_color(0, color)
	ramp.set_color(1, Color(color, 0.0))
	p.color_ramp = ramp
	add_child(p)
	p.emitting = true
	p.finished.connect(p.queue_free)


func dust(pos: Vector2, strong := false) -> void:
	_burst(pos, Color(0.78, 0.62, 0.42, 0.8), 14 if strong else 6, 220.0 if strong else 120.0,
			10.0 if strong else 7.0, 0.45, 60.0, Vector2(-1, -0.6), 300.0)


func transform_puff(pos: Vector2, color: Color) -> void:
	_burst(pos, Color(1, 1, 1, 0.9), 26, 420.0, 18.0, 0.55, 180.0, Vector2.UP, -100.0)
	_burst(pos, color, 30, 520.0, 12.0, 0.7, 180.0, Vector2.UP, 200.0)
	add_shake(5.0)


func smash(pos: Vector2, color: Color) -> void:
	_burst(pos, color, 28, 650.0, 12.0, 0.8, 70.0, Vector2(1, -1), 1500.0)
	_burst(pos, Color(0.85, 0.75, 0.6, 0.7), 12, 260.0, 16.0, 0.5, 180.0, Vector2.UP, 0.0)
	add_shake(9.0)


func sparkle(pos: Vector2, color: Color) -> void:
	_burst(pos, color, 16, 300.0, 8.0, 0.5, 180.0, Vector2.UP, 200.0)


## Popup text. Bright fill, thick dark outline in the accent colour and a
## drop shadow so it reads over the busy jungle; drawn above everything.
## A short horizontal streak behind a speeding Rok.
func speed_line(pos: Vector2) -> void:
	var l := Line2D.new()
	l.width = 4.0
	l.default_color = Color(1.0, 0.95, 0.75, 0.8)
	l.points = PackedVector2Array([Vector2.ZERO, Vector2(-randf_range(60.0, 120.0), 0)])
	l.position = pos
	l.z_index = 30
	add_child(l)
	var t := create_tween().set_parallel()
	t.tween_property(l, "position:x", pos.x - 160.0, 0.3)
	t.tween_property(l, "modulate:a", 0.0, 0.3)
	t.chain().tween_callback(l.queue_free)


func splash(pos: Vector2, color: Color) -> void:
	_burst(pos, color, 30, 520.0, 13.0, 0.8, 60.0, Vector2.UP, 1400.0)
	_burst(pos, Color(1, 1, 1, 0.8), 12, 300.0, 9.0, 0.5, 80.0, Vector2.UP, 900.0)
	add_shake(6.0)


func float_text(pos: Vector2, text: String, color := Color(1, 0.88, 0.35), size := 34) -> void:
	var l := Label.new()
	l.text = text
	l.z_index = 100
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color.lerp(Color.WHITE, 0.35))
	l.add_theme_color_override("font_outline_color", color.darkened(0.75))
	l.add_theme_constant_override("outline_size", 11)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.55))
	l.add_theme_constant_override("shadow_offset_y", 3)
	l.add_theme_constant_override("shadow_offset_x", 0)
	l.position = pos - Vector2(40, 20)
	l.pivot_offset = Vector2(40, 20)
	l.scale = Vector2.ONE * 0.6
	add_child(l)
	var t := create_tween().set_parallel()
	t.tween_property(l, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(l, "position:y", l.position.y - 70.0, 0.9).set_ease(Tween.EASE_OUT)
	t.tween_property(l, "modulate:a", 0.0, 0.3).set_delay(0.6)
	t.chain().tween_callback(l.queue_free)


func add_shake(amount: float) -> void:
	shake = maxf(shake, amount)


func _process(delta: float) -> void:
	if shake_target == null:
		return
	if shake > 0.05:
		shake_target.position = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * shake
		shake = lerpf(shake, 0.0, minf(delta * 10.0, 1.0))
	else:
		shake_target.position = Vector2.ZERO
