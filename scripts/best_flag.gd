class_name BestFlag
extends Node2D
## A flag planted at the player's best distance, scrolling in with the world
## so you can see your record coming and run past it (main._best_flag_step
## places it and celebrates the pass). Origin = the foot of the pole, on the
## ground. The user's art (assets/best_flag/{waving,passed}.png +
## best_flag.json, tools/prepare_animation_pack.gd) loops "waving" and switches
## to "passed" (green and gold, sparkles) once Rok runs past; without it the
## flag is drawn in code.

const META := "res://assets/best_flag/best_flag.json"

var metres := 0
var passed := false:
	set(v):
		passed = v
		if _sprite and v:
			_sprite.play("passed")
var _wave := 0.0
var _label: Label
var _sprite: AnimatedSprite2D
static var _frames: SpriteFrames
static var _meta := {}


static func has_art() -> bool:
	return FileAccess.file_exists(META) and ResourceLoader.exists("res://assets/best_flag/waving.png")


static func _load_frames() -> SpriteFrames:
	if _frames == null:
		_meta = JSON.parse_string(FileAccess.get_file_as_string(META))
		_frames = SpriteFrames.new()
		_frames.remove_animation("default")
		var fs := Vector2(_meta.frame[0], _meta.frame[1])
		for anim in ["waving", "passed"]:
			SpriteLib._sheet_frames(_frames, anim, load("res://assets/best_flag/%s.png" % anim), fs, _meta.times[anim], true)
	return _frames


func setup(m: int) -> BestFlag:
	metres = m
	var top := 182.0
	if has_art():
		_sprite = AnimatedSprite2D.new()
		_sprite.sprite_frames = _load_frames()
		_sprite.centered = false
		_sprite.offset = -Vector2(_meta.pivot[0], _meta.pivot[1])
		_sprite.play("waving")
		add_child(_sprite)
		top = float(_meta.top)
		set_process(false)
	_label = Label.new()
	_label.text = "BEST %d m" % m
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 20)
	_label.add_theme_color_override("font_color", Color(1, 0.97, 0.88))
	_label.add_theme_color_override("font_outline_color", Color(0.35, 0.12, 0.05))
	_label.add_theme_constant_override("outline_size", 6)
	_label.size = Vector2(140, 28)
	_label.position = Vector2(-70, -top - 34) if _sprite else Vector2(6, -168)
	if not _sprite:
		_label.text = "BEST\n%d m" % m
		_label.size = Vector2(90, 50)
	add_child(_label)
	return self


func _process(delta: float) -> void:
	_wave += delta * 6.0
	queue_redraw()


func _draw() -> void:
	if _sprite:
		return
	# pole
	draw_rect(Rect2(-4, -180, 8, 180), Color(0.42, 0.24, 0.1))
	draw_circle(Vector2(0, -182), 7.0, Color(1.0, 0.8, 0.25))
	# waving pennant
	var cloth := Color(0.3, 0.75, 0.35) if passed else Color(0.85, 0.25, 0.18)
	var pts := PackedVector2Array()
	for i in 9:
		var x := 4.0 + i * 12.0
		pts.append(Vector2(x, -176 + sin(_wave + i * 0.6) * 4.0 * i / 8.0))
	for i in range(8, -1, -1):
		var x := 4.0 + i * 12.0
		pts.append(Vector2(x, -118 + sin(_wave + i * 0.6) * 4.0 * i / 8.0 - i * 2.0))
	draw_colored_polygon(pts, cloth)
	draw_polyline(pts + PackedVector2Array([pts[0]]), cloth.darkened(0.4), 2.0)
