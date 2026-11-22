class_name ComboMeter
extends Control
## HUD readout for the combo streak and Primal Frenzy (combo.gd), under the
## meat pill at the top right. Drawn in code: the multiplier ("x2") in its
## tier colour, the streak count, a bar for the time left before the streak
## lapses, and the frenzy meter (gold, pulsing when nearly full; during a
## frenzy it drains, flashing). Hidden while there's nothing to show and
## outside a run (`shown`).

const TIER_COLORS := [Color(0.9, 0.9, 0.85), Color(0.55, 0.9, 1.0), Color(0.5, 1.0, 0.5),
		Color(1.0, 0.85, 0.3), Color(1.0, 0.55, 0.25), Color(1.0, 0.35, 0.6)]
const W := 250.0
const H := 78.0

var combo: Combo
var shown := true   # main: only during a run (it covered the Marketplace button on the summary)
var _t := 0.0
var _pop := 0.0
var _font: Font


func _init() -> void:
	custom_minimum_size = Vector2(W, H)
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_font = ThemeDB.fallback_font


## A tier was reached: the readout pops.
func pop() -> void:
	_pop = 1.0


func tier_color(t: int) -> Color:
	return TIER_COLORS[clampi(t, 0, TIER_COLORS.size() - 1)]


func _process(delta: float) -> void:
	_t += delta
	_pop = maxf(_pop - delta * 3.0, 0.0)
	visible = shown and combo != null and (combo.count > 0 or combo.meter > 0.0)
	if visible:
		queue_redraw()


func _text(pos: Vector2, s: String, fs: int, col: Color, align := HORIZONTAL_ALIGNMENT_RIGHT) -> void:
	var outline := Color(0.25, 0.1, 0.03)
	draw_string_outline(_font, pos, s, align, W - 16.0, fs, 8, outline)
	draw_string(_font, pos, s, align, W - 16.0, fs, col)


func _draw() -> void:
	if combo == null:
		return
	draw_style_box(_panel(), Rect2(Vector2.ZERO, size))
	var frenzy := combo.in_frenzy()
	var col := Color(1.0, 0.8, 0.25) if frenzy else tier_color(combo.tier)
	if frenzy:
		var flash := 0.5 + 0.5 * sin(_t * 14.0)
		col = col.lerp(Color(1, 1, 1), flash * 0.4)
		_text(Vector2(8, 34), "PRIMAL FRENZY!", 26 + int(_pop * 8.0), col)
	elif combo.count > 0:
		var big := 30 + int(_pop * 12.0)
		_text(Vector2(8, 34), "x%s" % _mult_text(combo.mult()), big, col)
		_text(Vector2(8, 34), "%d COMBO" % combo.count, 18, Color(1, 0.95, 0.85), HORIZONTAL_ALIGNMENT_LEFT)
		# time left before the streak lapses
		var f := clampf(combo.window / Tuning.COMBO_WINDOW, 0.0, 1.0)
		draw_rect(Rect2(12, 44, W - 24, 6), Color(0, 0, 0, 0.35))
		draw_rect(Rect2(12, 44, (W - 24) * f, 6), col)
	# frenzy meter
	var y := 58.0
	draw_rect(Rect2(12, y, W - 24, 10), Color(0.1, 0.05, 0.02, 0.6))
	var gold := Color(1.0, 0.75, 0.2)
	if combo.meter > 0.85 and not frenzy:
		gold = gold.lerp(Color(1, 1, 0.8), 0.5 + 0.5 * sin(_t * 10.0))
	draw_rect(Rect2(12, y, (W - 24) * combo.meter, 10), gold)
	draw_rect(Rect2(12, y, W - 24, 10), Color(0.35, 0.18, 0.06), false, 2.0)


func _mult_text(m: float) -> String:
	return str(int(m)) if is_equal_approx(m, roundf(m)) else "%.1f" % m


var _sb: StyleBoxFlat


func _panel() -> StyleBoxFlat:
	if _sb == null:
		_sb = StyleBoxFlat.new()
		_sb.bg_color = Color(0.25, 0.13, 0.06, 0.55)
		_sb.set_corner_radius_all(14)
	return _sb
