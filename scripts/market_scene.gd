class_name MarketScene
extends Control
## The Market as a place (the user wanted to feel they're at the market):
## a trader's cave on the right, a log counter in its mouth, a sign, torches,
## and the hero (Market adds the sprite) standing outside on the grass to buy.
## The merchant is a shadowy figure in the cave with glinting eyes until the
## user supplies merchant art (assets/market/merchant.png, drawn instead).
## The cave, torches and merchant are drawn in code until assets/market/
## cave.png exists; ground, logs and sign use the game's own props.
## Market reads where things are: `ground_y`, `hero_spot()`, `mouth()`,
## `counter_top()`; `happy()` makes the merchant beam after a sale.

const CAVE_ART := "res://assets/market/cave.png"
## The user's cave marketplace (tools/prepare_market.py): the whole cave room,
## Rok and the merchant inside it, laid out from assets/market/market.json.
const ROOM_ART := "res://assets/market/cave_marketplace.png"
const ROOM_META := "res://assets/market/market.json"
const MERCHANT_ART := "res://assets/market/merchant.png"

var _t := 0.0
var _happy := 0.0
var _blink := 2.0
var _tile: Texture2D
var _dirt: Texture2D
var _log: Texture2D
var _sign: Texture2D
var _cave: Texture2D
var _merchant: Texture2D
var _font: Font
var _room: Texture2D        # the user's cave room (market kind), or null
var room_meta := {}         # its layout (hero / merchant feet, counter) on the cave canvas
## Set by the Market to frame the cave its own way (the shop panel takes the
## right side): a ground line, a scale and a top-left for the cave room.
var ground_override := -1.0
var room_s := 0.0
var room_o := Vector2.ZERO
## How a screen's shelf of tiles is shown below the grass: "stall" a wooden
## stall front with an awning and a shelf plank (the Camp), "niches" a stone
## wall whose blocks are the tiles' niches (the Field Guide). The screen sets
## `style`, `band` (the strip below the grass the shelf occupies), `tiles_top`
## and `shelf_y` (where the tiles start and end). (The Market's trial looks,
## Rug and Line, were removed once its shop panel replaced the shelf.)
var style := "stall"
## Which place this is (the Market, the Encyclopedia and the Dinosaurs/Camp
## screens all use this scene): "market" the trader's cave, counter and
## merchant; "elder" the Elder's painted cave, the Elder sitting by a fire;
## "camp" a hide hut and a campfire (the chosen dinosaur stands there, added
## by the Camp). `sign_text` is painted on the roadside sign.
var kind := "market"
var sign_text := "MARKET"
var band := Rect2()
var tiles_top := 0.0
var shelf_y := 0.0


func _init() -> void:
	name = "MarketScene"
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tile = SpriteLib.tex("res://assets/terrain/mid_a.png")
	_dirt = SpriteLib.tex("res://assets/terrain/dirt.png")
	_log = SpriteLib.tex("res://assets/props/Logs_03.png")
	_sign = SpriteLib.tex("res://assets/props/Signs_01.png")
	_cave = load(CAVE_ART) if ResourceLoader.exists(CAVE_ART) else null
	_merchant = load(MERCHANT_ART) if ResourceLoader.exists(MERCHANT_ART) else null
	_font = ThemeDB.fallback_font
	if ResourceLoader.exists(ROOM_ART) and FileAccess.file_exists(ROOM_META):
		_room = load(ROOM_ART)
		room_meta = JSON.parse_string(FileAccess.get_file_as_string(ROOM_META))


## True when the Market shows the user's cave room (hero and merchant inside it).
func room() -> bool:
	return kind == "market" and _room != null


## The cave room's scale and top-left on screen: the floor (the example feet
## line) sits on ground_y and the cave hugs the left, leaving room on the
## right for the merchant's speech bubble.
func room_scale() -> float:
	if room_s > 0.0:
		return room_s
	return clampf(ground_y / 760.0, 0.5, 0.75)


func room_origin() -> Vector2:
	if room_s > 0.0:
		return room_o
	var s := room_scale()
	return Vector2(clampf(size.x * 0.03, 20.0, 80.0), ground_y - float(room_meta.hero_feet[1]) * s)


## A point on the cave canvas (1536 x 1024) on screen.
func room_point(p: Array) -> Vector2:
	return room_origin() + Vector2(p[0], p[1]) * room_scale()


## Where the merchant's feet are (room mode).
func merchant_spot() -> Vector2:
	return Vector2(room_point(room_meta.merchant_feet).x, ground_y)


## The counter's rectangle on screen (room mode).
func counter_rect() -> Rect2:
	var w := float(room_meta.counter_width) * room_scale()
	var h := w * 887.0 / 1774.0
	var bc := room_point(room_meta.counter_bottom_center)
	return Rect2(bc.x - w * 0.5, bc.y - h, w, h)


## The grass line (the hero's feet).
var ground_y: float:
	get:
		if ground_override >= 0.0:
			return ground_override
		return clampf(size.y * 0.6, 380.0, size.y - 260.0)


## Centre of the cave mouth, on the ground.
func cave_x() -> float:
	return size.x - clampf(size.x * 0.22, 250.0, 330.0)


func hero_spot() -> Vector2:
	if room():
		return Vector2(room_point(room_meta.hero_feet).x, ground_y)
	return Vector2(clampf(size.x * 0.17, 200.0, 280.0), ground_y)


## Where the merchant's face is (speech comes from here).
func mouth() -> Vector2:
	if room():
		return merchant_spot() + Vector2(0.0, -float(room_meta.character_height) * room_scale() * 0.82)
	return Vector2(cave_x(), ground_y - 150.0)


## The middle of the counter top, where the chosen item sits.
func counter_top() -> Vector2:
	if room():
		var r := counter_rect()   # just over the merchant's outstretched hand: he's offering it to Rok
		return Vector2(r.position.x + r.size.x * 0.16, r.position.y + r.size.y * 0.02)
	return Vector2(cave_x() - 20.0, ground_y - 66.0)


## The merchant beams for a moment (after a sale).
func happy() -> void:
	_happy = 2.2


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	_t += delta
	_happy = maxf(_happy - delta, 0.0)
	_blink -= delta
	if _blink < -0.14:
		_blink = randf_range(2.0, 4.5)
	queue_redraw()


func _draw() -> void:
	var gy := ground_y
	var cx := cave_x()
	if room():
		# the user's cave room (the merchant, counter and Rok are nodes on top),
		# then the shelf band in front of its floor
		var rs := Vector2(room_meta.cave_size[0], room_meta.cave_size[1]) * room_scale()
		draw_texture_rect(_room, Rect2(room_origin(), rs), false)
		if band.size != Vector2.ZERO:
			_draw_band()
		return
	# --- ground: the game's grass tiles and dirt
	var tw := _tile.get_width()
	var x := -float(tw) * 0.5
	while x < size.x:
		draw_texture(_tile, Vector2(x, gy - 18.0))
		x += tw - 2
	draw_texture_rect(_dirt, Rect2(0, gy + _tile.get_height() - 24.0, size.x, size.y), true)
	if band.size != Vector2.ZERO:
		_draw_band()
	if kind == "elder":
		_draw_elder_cave(cx, gy)
	elif kind == "camp":
		_draw_camp(cx, gy)
	else:
		_draw_market(cx, gy)
	_draw_sign(gy)


func _draw_market(cx: float, gy: float) -> void:
	# --- the cave
	if _cave:
		var cs := _cave.get_size()
		var s := 460.0 / cs.y
		draw_texture_rect(_cave, Rect2(Vector2(cx - cs.x * s * 0.5, gy - cs.y * s + 6.0), cs * s), false)
	else:
		_draw_cave(cx, gy)
	# --- the merchant in the cave mouth (art, or a shadow with glinting eyes)
	if _merchant:
		var ms := _merchant.get_size()
		var k := 200.0 / ms.y
		draw_texture_rect(_merchant, Rect2(Vector2(cx - ms.x * k * 0.5, gy - 40.0 - ms.y * k), ms * k), false)
	else:
		_draw_merchant(cx, gy)
	# --- the counter: two logs and a plank, in the cave mouth
	var ls := _log.get_size() * 0.95
	draw_texture_rect(_log, Rect2(Vector2(cx - ls.x - 6.0, gy - ls.y + 6.0), ls), false)
	draw_texture_rect(_log, Rect2(Vector2(cx - 34.0, gy - ls.y + 6.0), ls), false)
	var plank := Rect2(cx - ls.x - 20.0, gy - ls.y - 6.0, ls.x * 2.0 + 10.0, 16.0)
	draw_rect(plank.grow(3.0), Color(0.3, 0.16, 0.06))
	draw_rect(plank, Color(0.72, 0.5, 0.26))


## A roadside sign at the left, pointing the way to the place (sign_text).
func _draw_sign(gy: float) -> void:
	var ss := _sign.get_size() * 1.25
	var sp := Vector2(18.0, gy - ss.y + 8.0)
	draw_set_transform(Vector2(sp.x + ss.x, 0.0), 0.0, Vector2(-1.0, 1.0))   # flipped: the arrow points right
	draw_texture_rect(_sign, Rect2(Vector2(0.0, sp.y), ss), false)
	draw_set_transform(Vector2.ZERO)
	var label := sign_text
	var fs := 19
	var w := _font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var tp := sp + Vector2(ss.x * 0.48 - w * 0.5, ss.y * 0.36)
	draw_string_outline(_font, tp, label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 5, Color(0.3, 0.15, 0.05))
	draw_string(_font, tp, label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1, 0.93, 0.75))


## The strip under the grass where the goods are, in the chosen look.
func _draw_band() -> void:
	var b := band
	var dark := Color(0.28, 0.15, 0.06)
	match style:
		"stall":
			# back boards
			var bt := b.position.y + 22.0
			draw_rect(Rect2(b.position.x, bt, b.size.x, b.end.y - bt), Color(0.55, 0.35, 0.18))
			var x := b.position.x
			var i := 0
			while x < b.end.x:
				draw_rect(Rect2(x, bt, 44.0, b.end.y - bt), Color(0.6, 0.39, 0.2) if i % 2 == 0 else Color(0.52, 0.33, 0.16))
				draw_line(Vector2(x, bt), Vector2(x, b.end.y), dark, 2.0)
				x += 44.0
				i += 1
			# the shelf plank the goods stand on, with brackets
			var sy := shelf_y
			draw_rect(Rect2(b.position.x, sy, b.size.x, 18.0), Color(0.78, 0.55, 0.3))
			draw_rect(Rect2(b.position.x, sy + 18.0, b.size.x, 6.0), dark)
			for bx in range(int(b.position.x) + 80, int(b.end.x), 260):
				draw_colored_polygon(PackedVector2Array([Vector2(bx, sy + 24), Vector2(bx + 26, sy + 24), Vector2(bx, sy + 50)]), Color(0.45, 0.27, 0.12))
			# log posts at both ends
			for px in [b.position.x - 6.0, b.end.x - 22.0]:
				draw_rect(Rect2(px, b.position.y, 28.0, b.size.y), dark)
				draw_rect(Rect2(px + 3.0, b.position.y, 22.0, b.size.y), Color(0.62, 0.4, 0.2))
			# a striped hide awning along the top
			var ax := b.position.x - 10.0
			var k := 0
			while ax < b.end.x + 10.0:
				var col := Color(0.85, 0.7, 0.45) if k % 2 == 0 else Color(0.7, 0.32, 0.18)
				draw_rect(Rect2(ax, b.position.y, 40.0, 16.0), col)
				draw_circle(Vector2(ax + 20.0, b.position.y + 16.0), 20.0, col)
				ax += 40.0
				k += 1
			draw_line(Vector2(b.position.x - 10.0, b.position.y), Vector2(b.end.x + 10.0, b.position.y), dark, 4.0)
		"niches":
			# a stone wall: blocks in rows (the tiles are the niches)
			draw_rect(b, Color(0.48, 0.45, 0.42))
			var row := 0
			var y := b.position.y
			while y < b.end.y:
				var off := 0.0 if row % 2 == 0 else 45.0
				draw_line(Vector2(b.position.x, y), Vector2(b.end.x, y), Color(0.3, 0.27, 0.25), 3.0)
				var x2 := b.position.x - off
				while x2 < b.end.x:
					draw_line(Vector2(x2, y), Vector2(x2, y + 40.0), Color(0.3, 0.27, 0.25), 3.0)
					x2 += 90.0
				y += 40.0
				row += 1
			draw_rect(Rect2(b.position.x, b.position.y, b.size.x, 10.0), Color(0.3, 0.27, 0.25))


## The Elder's cave: the same rocky hill, but its mouth opens onto a wall of
## cave paintings, and the Elder sits by a fire in front (drawn in code until
## assets/encyclopedia/elder.png exists).
func _draw_elder_cave(cx: float, gy: float) -> void:
	_draw_cave(cx, gy, false)
	# paintings on the back wall: a dinosaur, hand prints, a hunt
	var ochre := Color(0.85, 0.45, 0.2, 0.85)
	var w := cx - 20.0
	draw_colored_polygon(PackedVector2Array([Vector2(w - 70, gy - 210), Vector2(w - 20, gy - 240), Vector2(w + 30, gy - 236),
			Vector2(w + 60, gy - 214), Vector2(w + 20, gy - 206), Vector2(w - 10, gy - 190), Vector2(w - 40, gy - 196)]), ochre)
	draw_circle(Vector2(w + 64, gy - 222), 12.0, ochre)
	for k in 3:
		var h := Vector2(cx + 60.0 + k * 26.0, gy - 250.0 + k * 14.0)
		draw_circle(h, 8.0, Color(0.95, 0.85, 0.7, 0.8))
		for f in 4:
			draw_line(h, h + Vector2.from_angle(-PI * 0.75 + f * 0.35) * 14.0, Color(0.95, 0.85, 0.7, 0.8), 3.0)
	for k in 3:
		var p := Vector2(cx - 90.0 + k * 22.0, gy - 160.0)
		draw_line(p, p + Vector2(0, 22), ochre, 3.0)
		draw_circle(p - Vector2(0, 5), 4.0, ochre)
		draw_line(p + Vector2(0, 6), p + Vector2(14, -4), ochre, 2.0)
	# the fire in front of the mouth
	_draw_fire(Vector2(cx - 40.0, gy - 6.0), 1.0)
	# the Elder: art, or a cloaked figure with a feather and a staff, by the fire
	var art := "res://assets/encyclopedia/elder.png"
	if ResourceLoader.exists(art):
		var t: Texture2D = load(art)
		var k2 := 210.0 / t.get_height()
		draw_texture_rect(t, Rect2(Vector2(cx + 70.0 - t.get_width() * k2 * 0.5, gy - t.get_height() * k2), t.get_size() * k2), false)
		return
	var e := Vector2(cx + 80.0, gy)
	var cloak := Color(0.42, 0.25, 0.14)
	draw_colored_polygon(PackedVector2Array([e + Vector2(-50, 0), e + Vector2(-38, -90), e + Vector2(-20, -128),
			e + Vector2(20, -128), e + Vector2(38, -90), e + Vector2(50, 0)]), cloak)
	draw_circle(e + Vector2(0, -140), 26.0, Color(0.78, 0.55, 0.38))
	draw_arc(e + Vector2(0, -140), 26.0, PI * 1.05, PI * 1.95, 14, Color(0.9, 0.9, 0.88), 9.0, true)   # white hair
	draw_colored_polygon(PackedVector2Array([e + Vector2(-12, -126), e + Vector2(0, -98), e + Vector2(12, -126)]), Color(0.92, 0.92, 0.9))   # beard
	draw_line(e + Vector2(14, -170), e + Vector2(30, -200), Color(0.85, 0.3, 0.2), 6.0)   # feather
	for side in [-1.0, 1.0]:
		var ey: Vector2 = e + Vector2(side * 9.0 - 2.0, -144.0)
		if _happy > 0.0 or _blink <= 0.0:
			draw_arc(ey + Vector2(0, 2), 4.0, PI * 1.1, PI * 1.9, 6, Color(0.2, 0.1, 0.05), 2.0, true)
		else:
			draw_circle(ey, 3.5, Color(0.2, 0.1, 0.05))
	draw_line(e + Vector2(-60, -170), e + Vector2(-54, 0), Color(0.45, 0.28, 0.12), 7.0)   # staff
	draw_circle(e + Vector2(-60, -176), 10.0, Color(0.95, 0.8, 0.4))


## The camp: a hide hut on the right, a campfire, logs to sit on. The chosen
## dinosaur and the hero stand in front (added by the Camp).
func _draw_camp(cx: float, gy: float) -> void:
	var art := "res://assets/camp/hut.png"
	if ResourceLoader.exists(art):
		var t: Texture2D = load(art)
		var k := 300.0 / t.get_height()
		draw_texture_rect(t, Rect2(Vector2(cx + 60.0 - t.get_width() * k * 0.5, gy - t.get_height() * k + 6.0), t.get_size() * k), false)
	else:
		var hx := cx + 70.0
		var hide := Color(0.78, 0.6, 0.4)
		var dark := Color(0.3, 0.17, 0.08)
		var pts := PackedVector2Array([Vector2(hx - 150, gy + 4), Vector2(hx, gy - 290), Vector2(hx + 150, gy + 4)])
		draw_colored_polygon(pts, hide)
		pts.append(pts[0])
		draw_polyline(pts, dark, 6.0, true)
		for k in 4:   # stitched hide panels
			draw_line(Vector2(hx, gy - 290), Vector2(hx - 120 + k * 80, gy + 4), Color(0.6, 0.42, 0.25), 3.0)
		draw_colored_polygon(PackedVector2Array([Vector2(hx - 45, gy + 4), Vector2(hx, gy - 120), Vector2(hx + 45, gy + 4)]), Color(0.18, 0.1, 0.05))   # doorway
		for side in [-1.0, 1.0]:   # poles poking out of the top
			draw_line(Vector2(hx, gy - 290), Vector2(hx + side * 28.0, gy - 336), dark, 6.0)
		for k in 6:   # spots on the hide
			draw_circle(Vector2(hx - 70 + k * 28, gy - 60 - (k % 3) * 50), 8.0, Color(0.65, 0.45, 0.28, 0.7))
	_draw_fire(Vector2(cx - 150.0, gy - 6.0), 1.15)
	var ls := _log.get_size() * 0.6
	draw_texture_rect(_log, Rect2(Vector2(cx - 270.0, gy - ls.y + 8.0), ls), false)


## A small campfire: stones, crossed sticks, flickering flames.
func _draw_fire(base: Vector2, s: float) -> void:
	for k in 5:
		draw_circle(base + Vector2((-28 + k * 14) * s, 4), 8.0 * s, Color(0.45, 0.42, 0.4))
	draw_line(base + Vector2(-24, 2) * s, base + Vector2(20, -14) * s, Color(0.4, 0.22, 0.1), 7.0 * s)
	draw_line(base + Vector2(24, 2) * s, base + Vector2(-20, -14) * s, Color(0.4, 0.22, 0.1), 7.0 * s)
	var f := 1.0 + 0.18 * sin(_t * 11.0) + 0.1 * sin(_t * 17.0)
	draw_circle(base + Vector2(0, -20) * s, 48.0 * s * f, Color(1.0, 0.6, 0.2, 0.15))
	draw_colored_polygon(PackedVector2Array([base + Vector2(-20, -6) * s, base + Vector2(0, -62.0 * f) * s, base + Vector2(20, -6) * s]), Color(1.0, 0.5, 0.15))
	draw_colored_polygon(PackedVector2Array([base + Vector2(-11, -8) * s, base + Vector2(2, -40.0 * f) * s, base + Vector2(11, -8) * s]), Color(1.0, 0.85, 0.4))


func _draw_cave(cx: float, gy: float, torches := true) -> void:
	var stone := Color(0.52, 0.47, 0.42)
	var light := Color(0.66, 0.6, 0.53)
	var dark := Color(0.24, 0.18, 0.14)
	# the rock: a lumpy hill around the mouth
	var pts := PackedVector2Array()
	var steps := 28
	for i in steps + 1:
		var a := PI + PI * i / steps
		var r := 1.0 + 0.08 * sin(i * 1.7) + 0.05 * sin(i * 3.1)
		pts.append(Vector2(cx + cos(a) * 300.0 * r, gy + sin(a) * 330.0 * r))
	pts.append(Vector2(cx + 300.0, gy + 4.0))
	pts.append(Vector2(cx - 300.0, gy + 4.0))
	var outline := pts.duplicate()
	draw_colored_polygon(pts, stone)
	outline.append(outline[0])
	draw_polyline(outline, dark, 6.0, true)
	# boulders on the rock for texture
	for b in [[-170.0, -230.0, 44.0], [120.0, -270.0, 52.0], [210.0, -150.0, 38.0], [-230.0, -110.0, 36.0], [20.0, -300.0, 30.0]]:
		var c := Vector2(cx + b[0], gy + b[1])
		draw_circle(c, b[2] + 4.0, dark)
		draw_circle(c, b[2], light)
		draw_circle(c + Vector2(-b[2] * 0.3, -b[2] * 0.3), b[2] * 0.35, light.lightened(0.15))
	# the mouth: a dark arch with a warm glow deep inside
	var mouth := PackedVector2Array()
	for i in 21:
		var a := PI + PI * i / 20.0
		mouth.append(Vector2(cx + cos(a) * 150.0, gy - 170.0 + sin(a) * 120.0))
	mouth.append(Vector2(cx + 150.0, gy))
	mouth.append(Vector2(cx - 150.0, gy))
	draw_colored_polygon(mouth, Color(0.1, 0.06, 0.04))
	var glow := 0.18 + 0.04 * sin(_t * 3.0)
	for i in 4:
		draw_circle(Vector2(cx, gy - 120.0), 120.0 - i * 26.0, Color(1.0, 0.55, 0.2, glow * 0.35))
	var rim := mouth.duplicate()
	rim.resize(21)
	draw_polyline(rim, dark, 10.0, true)
	# torches either side of the mouth
	for side in ([-1.0, 1.0] if torches else []):
		var tx: float = cx + side * 185.0
		draw_rect(Rect2(tx - 5.0, gy - 190.0, 10.0, 120.0), Color(0.38, 0.22, 0.1))
		var f := 1.0 + 0.15 * sin(_t * 13.0 + side) + 0.1 * sin(_t * 7.0)
		var top := Vector2(tx, gy - 196.0)
		draw_circle(top, 34.0 * f, Color(1.0, 0.6, 0.2, 0.18))
		draw_colored_polygon(PackedVector2Array([top + Vector2(-11, 4), top + Vector2(0, -30.0 * f), top + Vector2(11, 4)]), Color(1.0, 0.55, 0.15))
		draw_colored_polygon(PackedVector2Array([top + Vector2(-6, 2), top + Vector2(0, -18.0 * f), top + Vector2(6, 2)]), Color(1.0, 0.9, 0.45))


func _draw_merchant(cx: float, gy: float) -> void:
	var body := Color(0.2, 0.12, 0.08)
	var c := Vector2(cx + 30.0, gy - 120.0)
	# hooded shoulders and head, just lit by the cave glow
	draw_colored_polygon(PackedVector2Array([c + Vector2(-70, 80), c + Vector2(-52, 0), c + Vector2(-30, -40),
			c + Vector2(30, -40), c + Vector2(52, 0), c + Vector2(70, 80)]), body)
	draw_circle(c + Vector2(0, -48), 40.0, body)
	draw_arc(c + Vector2(0, -48), 40.0, PI * 1.1, PI * 1.9, 16, Color(0.55, 0.32, 0.15, 0.6), 4.0, true)
	# eyes: glinting, blinking; squinting with joy after a sale
	var eye := Color(1.0, 0.85, 0.3)
	for side in [-1.0, 1.0]:
		var e: Vector2 = c + Vector2(side * 14.0, -52.0)
		if _happy > 0.0:
			draw_arc(e + Vector2(0, 4), 8.0, PI * 1.1, PI * 1.9, 8, eye, 3.0, true)
		elif _blink > 0.0:
			draw_circle(e, 6.0, eye)
			draw_circle(e + Vector2(1.5, -1.5), 2.0, Color(1, 1, 0.9))
		else:
			draw_line(e + Vector2(-6, 0), e + Vector2(6, 0), eye, 2.0)
	if _happy > 0.0:   # a grin
		draw_arc(c + Vector2(0, -34), 14.0, PI * 0.15, PI * 0.85, 10, eye, 3.0, true)
