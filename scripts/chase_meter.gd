class_name ChaseMeter
extends Control
## HUD track showing how far behind the T-rex is: Rok's icon sits at the
## right end, the T-rex's icon behind him at a distance proportional to the
## chase gap (it slides toward Rok and the track turns red as it closes in).

var gap := Tuning.CHASE_GAP_MAX
var _shown := Tuning.CHASE_GAP_MAX
var rok_tex: Texture2D
var trex_tex: Texture2D
var _t := 0.0


func _init() -> void:
	custom_minimum_size = Vector2(330, 54)
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	rok_tex = SpriteLib.tex("res://assets/portraits/rok.png")
	trex_tex = SpriteLib.tex("res://assets/portraits/trex.png")


## 0 = caught, 1 = as far as it gets (CHASE_GAP_FAR).
func fraction() -> float:
	return clampf(_shown / Tuning.CHASE_GAP_FAR, 0.0, 1.0)


func _process(delta: float) -> void:
	_t += delta
	_shown = lerpf(_shown, gap, minf(delta * 8.0, 1.0))
	queue_redraw()


func _icon(tex: Texture2D, center: Vector2, h: float, flip := false) -> void:
	var sz := tex.get_size()
	var s := h / sz.y
	var w := sz.x * s
	var r := Rect2(center - Vector2(w, h) * 0.5, Vector2(w, h))
	if flip:
		r.position.x += w
		r.size.x = -w
	draw_texture_rect(tex, r, false)


func _draw() -> void:
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.25, 0.13, 0.06, 0.55)
	bg.set_corner_radius_all(14)
	draw_style_box(bg, Rect2(Vector2.ZERO, size))
	var left := 26.0
	var right := size.x - 30.0
	var y := size.y * 0.5 + 4.0
	var f := fraction()
	var danger := clampf(1.0 - _shown / Tuning.CHASE_DANGER, 0.0, 1.0)
	var col := Color(0.95, 0.25, 0.15).lerp(Color(0.55, 0.85, 0.35), clampf((f - 0.15) / 0.5, 0.0, 1.0))
	draw_line(Vector2(left, y), Vector2(right, y), Color(0.15, 0.08, 0.04, 0.8), 8.0, true)
	var tx := lerpf(right - 26.0, left, f)
	draw_line(Vector2(tx, y), Vector2(right, y), col, 8.0, true)
	if danger > 0.0:
		var pulse := 0.5 + 0.5 * sin(_t * 14.0)
		draw_circle(Vector2(tx, y - 6), 22.0 + 4.0 * pulse, Color(1, 0.15, 0.05, 0.35 * danger))
	_icon(trex_tex, Vector2(tx, y - 6), 38.0)
	_icon(rok_tex, Vector2(right, y - 6), 40.0)
