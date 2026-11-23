class_name TouchButton
extends Control
## A round on-screen button drawn in code. It never takes GUI input itself:
## main.gd hit-tests touches against it (see Hud.action_at) so several
## buttons can be held at once (multitouch).

var action := ""
var icon: Texture2D
var caption := ""
var pill_text := ""   # a text pill instead of a round button (the training run's "Skip »"): tapped anywhere on it
var caption_below := false   # draw the caption under the button (like the square menu buttons) instead of inside it
var key_hint := ""
var ring := Color(0.4, 0.22, 0.1)
var fill := Color(0.98, 0.9, 0.72, 0.9)
var active := false
var enabled := true
var held := false
var locked := false
var glow := 0               # 0 none, 1 soft hint, 2 strong (gate ahead)
var glow_color := Color(1, 0.85, 0.3)
var _t := 0.0
var badge := false          # small red dot: something new inside
var lock_text := ""
var arrow := false
var arrow_down := false
var frame: Texture2D        # the user's sandstone slot ring (hero / dino / power-up), drawn over the button
var frame_geo := {}         # its ring: centre, outer and inner radius as fractions of the image (slot_frames.json)
const FRAME_OUT := 1.12     # the ring's outside sits this far out from the button's edge
var cooldown := 0.0:        # share of a cooldown still to go (1 = just used, 0 = ready): a dark wedge unwinds clockwise
	set(v):
		if not is_equal_approx(v, cooldown):
			cooldown = v
			queue_redraw()
var cooldown_left := 0.0    # seconds still to wait, shown as a timer in the middle (e.g. "0.6")
var art: Texture2D          # a round picture button (the user's jump/slide/attack art, icon baked in): drawn filling the circle
var banner: Texture2D       # a picture button (the user's square menu buttons): drawn as-is, tapped anywhere on it, caption below
var _pop := 0.0


func _init(act: String, diameter: float) -> void:
	action = act
	custom_minimum_size = Vector2(diameter, diameter)
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	pivot_offset = size * 0.5


func set_diameter(d: float) -> void:
	custom_minimum_size = Vector2(d, d)
	size = custom_minimum_size
	pivot_offset = size * 0.5
	queue_redraw()


func radius() -> float:
	return size.x * 0.5


func hit(p: Vector2) -> bool:
	if banner or pill_text != "":
		return visible and Rect2(global_position, size).has_point(p)
	return visible and (p - (global_position + size * 0.5)).length() <= radius() * 1.12


## Turn this into a picture button `w` px wide (height from the picture).
func set_banner(tex: Texture2D, w: float) -> void:
	banner = tex
	custom_minimum_size = Vector2(w, w * tex.get_height() / tex.get_width())
	size = custom_minimum_size
	pivot_offset = size * 0.5
	queue_redraw()


func set_held(h: bool) -> void:
	if h and not held:
		_pop = 1.0
	held = h
	queue_redraw()


func _process(delta: float) -> void:
	_t += delta
	if glow > 0:
		queue_redraw()
	if _pop > 0.0:
		_pop = maxf(_pop - delta * 6.0, 0.0)
		queue_redraw()
	scale = Vector2.ONE * (0.92 if held else 1.0 + _pop * 0.06)


func _draw() -> void:
	if pill_text != "":   # a dark rounded pill with light text (lit while armed)
		var kit := SpriteLib.tutorial_box("pill")   # the user's brown pill, and its chevrons
		var chev := SpriteLib.tutorial_ui("chevrons")
		if kit:
			var tint := Color(1.25, 0.75, 0.6) if active else (Color(0.85, 0.85, 0.85) if held else Color.WHITE)
			draw_style_box(kit, Rect2(Vector2.ZERO, size))
			if tint != Color.WHITE:
				draw_rect(Rect2(Vector2(size.y * 0.25, size.y * 0.2), size - Vector2(size.y * 0.5, size.y * 0.4)), Color(tint, 0.18) if active else Color(0, 0, 0, 0.15))
		else:
			var sb := StyleBoxFlat.new()
			sb.bg_color = Color(0.62, 0.22, 0.1, 0.95) if active else Color(0.25, 0.13, 0.06, 0.85 if not held else 0.95)
			sb.border_color = Color(1.0, 0.85, 0.55, 0.9)
			sb.set_border_width_all(2)
			sb.set_corner_radius_all(int(size.y * 0.5))
			draw_style_box(sb, Rect2(Vector2.ZERO, size))
		var pf := SpriteLib.ui_font("body")
		var label := pill_text.trim_suffix(" »") if chev else pill_text
		var pw := pf.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x
		var cw := chev.get_width() + 6.0 if chev else 0.0
		var x0 := size.x * 0.5 - (pw + cw) * 0.5
		draw_string(pf, Vector2(x0, size.y * 0.5 + 8.0), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(1, 0.96, 0.88))
		if chev:
			draw_texture(chev, Vector2(x0 + pw + 6.0, size.y * 0.5 - chev.get_height() * 0.5))
		return
	if banner:
		var tint := Color(0.85, 0.85, 0.85) if held else Color.WHITE
		draw_texture_rect(banner, Rect2(Vector2.ZERO, size), false, tint)
		if badge:
			var bp := Vector2(size.x - 12.0, 12.0)
			draw_circle(bp, 11.0, Color(0.9, 0.2, 0.12))
			draw_arc(bp, 11.0, 0, TAU, 20, Color(1, 0.95, 0.85), 2.5, true)
		if caption != "":   # the name under the picture
			var bf := get_theme_default_font()
			var bw := bf.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x
			var bpos := Vector2(size.x * 0.5 - bw * 0.5, size.y + 18.0)
			draw_string_outline(bf, bpos, caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, 6, Color(0.28, 0.14, 0.05))
			draw_string(bf, bpos, caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(1, 0.97, 0.88))
		return
	var c := size * 0.5
	var r := radius()
	var dim := 1.0 if enabled else 0.55
	if glow > 0:
		var pulse := 0.5 + 0.5 * sin(_t * (9.0 if glow == 2 else 5.0))
		var gr := r + 6.0 + pulse * (10.0 if glow == 2 else 5.0)
		draw_circle(c, gr, Color(glow_color, (0.35 if glow == 2 else 0.2) + 0.25 * pulse))
		draw_arc(c, gr, 0, TAU, 40, Color(glow_color.lightened(0.4), 0.9), 4.0, true)
	draw_circle(c + Vector2(0, 5), r, Color(0.12, 0.06, 0.02, 0.45))
	if art:
		var k := (0.78 if held else 1.0) * dim
		draw_texture_rect(art, Rect2(c - Vector2(r, r), Vector2(r, r) * 2.0), false, Color(k, k, k, fill.a))
		_draw_cooldown(c, r)
		return
	var outer := r
	if frame:   # the portrait and fill sit in the ring's hole
		r = r * FRAME_OUT * float(frame_geo.inner) / float(frame_geo.outer)
	var f := fill.darkened(0.15) if held else fill
	draw_circle(c, r, Color(f.r * dim, f.g * dim, f.b * dim, f.a))
	var rc := ring if not active else ring.lightened(0.15)
	if not frame:
		draw_arc(c, r - 3.0, 0, TAU, 48, rc, 6.0 if active else 4.0, true)
	if active:
		draw_arc(c, outer * (FRAME_OUT + 0.06 if frame else 1.0) + 4.0, 0, TAU, 48, Color(rc.lightened(0.3) if frame else rc, 0.7 if frame else 0.5), 4.0 if frame else 3.0, true)
	if icon:
		var isz := icon.get_size()
		var inside := caption != "" and not caption_below
		var s := (r * (1.05 if inside else 1.45)) / maxf(isz.x, isz.y)
		var dsz := isz * s
		var ic := c - Vector2(0, r * 0.14) if inside else c   # room for the caption below
		draw_texture_rect(icon, Rect2(ic - dsz * 0.5, dsz), false, Color(dim, dim, dim))
	if arrow:
		var a := r * 0.42
		var pts := PackedVector2Array([c + Vector2(0, -a * 1.2), c + Vector2(a, -a * 0.1),
				c + Vector2(a * 0.42, -a * 0.1), c + Vector2(a * 0.42, a * 0.75),
				c + Vector2(-a * 0.42, a * 0.75), c + Vector2(-a * 0.42, -a * 0.1),
				c + Vector2(-a, -a * 0.1)])
		if arrow_down:
			for i in pts.size():
				pts[i] = c + Vector2(pts[i].x - c.x, c.y - pts[i].y - a * 0.1)
		draw_colored_polygon(pts, Color(0.45, 0.24, 0.1))
	var font := get_theme_default_font()
	if frame:   # the ring on top: its outside at FRAME_OUT x the button's radius
		var side := outer * FRAME_OUT / float(frame_geo.outer)
		var cc: Array = frame_geo.center
		var k := 0.8 if held else dim
		draw_texture_rect(frame, Rect2(c - Vector2(float(cc[0]), float(cc[1])) * side, Vector2(side, side)), false, Color(k, k, k))
	_draw_cooldown(c, r)
	if locked:
		draw_circle(c, r - 2.0, Color(0.15, 0.08, 0.03, 0.6))
		# padlock
		var lw := r * 0.5
		var body := Rect2(c + Vector2(-lw * 0.5, -r * 0.12), Vector2(lw, lw * 0.75))
		draw_arc(c + Vector2(0, -r * 0.12), lw * 0.32, PI, TAU, 16, Color(1, 0.92, 0.75), 5.0, true)
		draw_rect(body, Color(1, 0.85, 0.45))
		draw_circle(body.get_center(), 3.5, Color(0.35, 0.18, 0.06))
		var fs := 17
		var w := font.get_string_size(lock_text, HORIZONTAL_ALIGNMENT_CENTER, -1, fs).x
		var lp := c + Vector2(-w * 0.5, r * 0.82)
		draw_string_outline(font, lp, lock_text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 6, Color(0.28, 0.14, 0.05))
		draw_string(font, lp, lock_text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1, 0.95, 0.8))
	if badge:
		draw_circle(c + Vector2(r * 0.7, -r * 0.7), 9.0, Color(0.9, 0.2, 0.12))
		draw_arc(c + Vector2(r * 0.7, -r * 0.7), 9.0, 0, TAU, 20, Color(1, 0.95, 0.85), 2.0, true)
	if caption != "":
		var fs := 18 if caption_below else 20
		var w := font.get_string_size(caption, HORIZONTAL_ALIGNMENT_CENTER, -1, fs).x
		var p := c + Vector2(-w * 0.5, r * 0.72) if not caption_below else Vector2(size.x * 0.5 - w * 0.5, size.y + 18.0)
		draw_string_outline(font, p, caption, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 6, Color(0.28, 0.14, 0.05))
		draw_string(font, p, caption, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1, 0.97, 0.88))
	if key_hint != "":
		var p2 := c + Vector2(-r * 0.78, -r * 0.5)
		draw_string_outline(font, p2, key_hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, 5, Color(0.28, 0.14, 0.05))
		draw_string(font, p2, key_hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(1, 0.97, 0.88))


## The cooldown wedge: what's left of the wait, as a dark slice from 12
## o'clock going clockwise, shrinking to nothing when the action is ready.
func _draw_cooldown(c: Vector2, r: float) -> void:
	if cooldown <= 0.001:
		return
	queue_redraw()   # the timer text ticks every frame
	var pts := PackedVector2Array([c])
	var steps := maxi(6, int(40 * cooldown))
	for i in steps + 1:
		var a := -PI * 0.5 + TAU * (1.0 - cooldown) + TAU * cooldown * float(i) / float(steps)
		pts.append(c + Vector2(cos(a), sin(a)) * (r - 2.0))
	draw_colored_polygon(pts, Color(0.05, 0.03, 0.02, 0.55))
	draw_arc(c, r - 2.0, -PI * 0.5 + TAU * (1.0 - cooldown), PI * 1.5, steps, Color(1.0, 0.85, 0.5, 0.7), 3.0, true)
	if cooldown_left > 0.0:   # the timer in the middle
		var font := get_theme_default_font()
		var txt := "%.1f" % cooldown_left
		var fs := int(clampf(r * 0.62, 18.0, 34.0))
		var w := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var p := c + Vector2(-w * 0.5, fs * 0.36)
		draw_string_outline(font, p, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 7, Color(0.15, 0.08, 0.03))
		draw_string(font, p, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1.0, 0.95, 0.8))
