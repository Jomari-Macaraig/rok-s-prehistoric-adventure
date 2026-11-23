class_name Background
extends Node2D
## The sky (gradient that follows zones and the day/night cycle, with stars
## and a moon at night), one group of tiling parallax layers per zone that
## cross-fade by distance, and ambient particles (fireflies, dust, embers).
##
## Forest group: bg-2 mountains, a darker far copy of bg-1, a forest-floor
## shade band, bg-1 jungle and wind-animated trees. Desert group: mesa
## backdrop and rolling dunes. Canyon group: the canyon pack's far mesas (painted sky keyed out), mid mesas and near hoodoos, mirrored repeat. Volcanic group: the volcanic biome's own far
## backdrop and mid layer (Rok_Trap_Expansion), ash sky keyed out. The bg-3 fern foreground (forest only) lives on its own node
## so main can draw it in front of the player. The ground is drawn by Terrain.

class Layer:
	extends Node2D
	var factor := 1.0
	var tile_w := 1280.0
	var offset := 0.0
	var copies: Array[Sprite2D] = []
	var overlap := 1.0
	var mirror := false   # every other copy flipped (art made for mirrored repeat: the Canyon's)

	func _init(tex: Texture2D, f: float, y: float, n := 4, ov := 1.0, mirrored := false) -> void:
		factor = f
		overlap = ov
		mirror = mirrored
		tile_w = tex.get_width() - ov
		position.y = y
		for i in n:
			var s := Sprite2D.new()
			s.texture = tex
			s.centered = false
			s.flip_h = mirror and i % 2 == 1
			add_child(s)
			copies.append(s)
		scroll(0.0)

	func scroll(dx: float) -> void:
		offset = fposmod(offset + dx * factor, tile_w * (2.0 if mirror else 1.0))
		for i in copies.size():
			# copies overlap slightly so no seam or gap shows
			copies[i].position.x = -offset + i * tile_w


var layers: Array[Layer] = []
var groups: Array[Node2D] = []     # one per zone, in Zones.ZONES order
var foreground: Layer
var back_decor: Node2D
var sky_grad: GradientTexture2D
var stars: TextureRect
var moon: Sprite2D
var ambient := {}                  # name -> CPUParticles2D
var _decor_timer := 0.0

const BACK_PLANTS := ["Trees_01", "Trees_02", "Trees_03", "Grasses_07", "Grasses_08",
		"Grasses_09", "Grasses_15", "Grasses_16", "Grasses_11"]


func _ready() -> void:
	var sky := TextureRect.new()
	sky_grad = GradientTexture2D.new()
	sky_grad.gradient = Gradient.new()
	sky_grad.gradient.set_color(0, Color(0.5, 0.74, 0.9))
	sky_grad.gradient.add_point(0.55, Color(0.93, 0.88, 0.74))
	sky_grad.gradient.set_color(sky_grad.gradient.get_point_count() - 1, Color(0.62, 0.7, 0.5))
	sky_grad.fill_from = Vector2(0, 0)
	sky_grad.fill_to = Vector2(0, 1)
	sky_grad.width = 4
	sky_grad.height = 256
	sky.texture = sky_grad
	sky.size = Vector2(4000, Tuning.VIEW_H)
	sky.position.x = -400
	sky.stretch_mode = TextureRect.STRETCH_SCALE
	add_child(sky)
	_make_stars_and_moon()

	# ---- forest
	var forest := _group()
	var mountains := Layer.new(load("res://assets/bg/bg_2.png"), Tuning.PARALLAX_MOUNTAINS, 0.0, 4, 50.0)
	_add(forest, mountains)
	# Far jungle: a smaller, darker copy of bg-1 fills the gaps behind the
	# main jungle so its baked-in fog reads as depth instead of empty space.
	var far := Layer.new(load("res://assets/bg/bg_1.png"), Tuning.PARALLAX_FAR_TREES / 0.78, 0.0, 4)
	far.scale = Vector2(0.78, 0.78)
	far.position.y = Tuning.GROUND_Y + 18.0 - Tuning.VIEW_H * 0.78 * 0.84
	far.modulate = Color(0.55, 0.68, 0.58)
	_add(forest, far)
	# forest-floor shade: dark band rising toward the ground line
	var floor_shade := TextureRect.new()
	var fg := GradientTexture2D.new()
	fg.gradient = Gradient.new()
	fg.gradient.set_color(0, Color(0.36, 0.45, 0.25, 0.0))
	fg.gradient.add_point(0.55, Color(0.36, 0.45, 0.25, 0.75))
	fg.gradient.set_color(fg.gradient.get_point_count() - 1, Color(0.24, 0.3, 0.16, 1.0))
	fg.fill_to = Vector2(0, 1)
	fg.width = 4
	fg.height = 128
	floor_shade.texture = fg
	floor_shade.stretch_mode = TextureRect.STRETCH_SCALE
	floor_shade.position = Vector2(-400, Tuning.GROUND_Y - 164.0)
	floor_shade.size = Vector2(4000, Tuning.VIEW_H - Tuning.GROUND_Y + 164.0)
	forest.add_child(floor_shade)
	_add(forest, Layer.new(load("res://assets/bg/bg_1.png"), Tuning.PARALLAX_TREES, Tuning.GROUND_Y - 586.0))
	back_decor = Node2D.new()
	back_decor.modulate = Color(0.7, 0.8, 0.72, 0.92)
	forest.add_child(back_decor)

	# ---- desert, canyon and volcanic badlands (in Zones.ZONES order after the forest)
	for zid in ["desert", "canyon", "volcanic"]:
		var g := _group()
		if zid == "canyon":
			# the canyon pack: far mesas (its sky keyed out), mid mesas, near hoodoos; mirrored repeat
			_add(g, Layer.new(load("res://assets/bg/canyon_far.png"), Tuning.PARALLAX_MOUNTAINS * 1.5, Tuning.GROUND_Y + 40.0 - 720.0, 4, 1.0, true))
			_add(g, Layer.new(load("res://assets/bg/canyon_mid.png"), Tuning.PARALLAX_FAR_TREES, Tuning.GROUND_Y + 50.0 - 720.0, 4, 1.0, true))
			_add(g, Layer.new(load("res://assets/bg/canyon_near.png"), Tuning.PARALLAX_TREES, Tuning.GROUND_Y + 60.0 - 720.0, 4, 1.0, true))
		else:
			_add(g, Layer.new(load("res://assets/bg/%s_far.png" % zid), Tuning.PARALLAX_MOUNTAINS * 1.5, Tuning.GROUND_Y - 600.0))
			_add(g, Layer.new(load("res://assets/bg/%s_dunes.png" % zid), Tuning.PARALLAX_TREES, Tuning.GROUND_Y - 560.0))
		g.visible = false

	foreground = Layer.new(load("res://assets/bg/bg_3.png"), Tuning.PARALLAX_FOREGROUND, 150.0)
	foreground.modulate = Color(0.8, 0.86, 0.75, 0.85)
	_make_ambient()

	# pre-populate decor so the first screen isn't empty
	for x in range(80, 1500, 380):
		_spawn_back_plant(x + randf() * 120.0)
	apply_environment(0.0)


func _group() -> Node2D:
	var g := Node2D.new()
	add_child(g)
	groups.append(g)
	return g


func _add(g: Node2D, l: Layer) -> void:
	g.add_child(l)
	layers.append(l)


func view_width() -> float:
	return maxf(get_viewport_rect().size.x, Tuning.VIEW_W)


func scroll(speed: float, delta: float) -> void:
	var dx := speed * delta
	for l in layers:
		l.scroll(dx)
	foreground.scroll(dx)
	for c in back_decor.get_children():
		c.position.x -= dx * Tuning.PARALLAX_BACK_DECOR
		if c.position.x < -400.0:
			c.queue_free()
	_decor_timer -= dx * Tuning.PARALLAX_BACK_DECOR
	if _decor_timer <= 0.0:
		_spawn_back_plant(view_width() + 300.0)
		_decor_timer = randf_range(260.0, 600.0)


## Zone layer cross-fade, sky colours, stars/moon and ambient particles for
## this distance.
func apply_environment(metres: float) -> void:
	var w: Array = Zones.weights(metres)
	for i in groups.size():
		groups[i].visible = w[i] > 0.001
		groups[i].modulate.a = w[i]
	foreground.modulate.a = 0.85 * w[0]
	foreground.visible = w[0] > 0.001
	var sky: Array = Zones.sky(metres)
	sky_grad.gradient.set_color(0, sky[0])
	sky_grad.gradient.set_color(1, sky[1])
	sky_grad.gradient.set_color(2, sky[2])
	var night := 1.0 - Zones.daylight(metres)
	stars.modulate.a = night
	moon.modulate.a = night
	moon.visible = night > 0.01
	var amb: Dictionary = Zones.ambient(metres)
	for k in ambient:
		var p: CPUParticles2D = ambient[k]
		p.emitting = amb[k] > 0.05
		p.modulate.a = clampf(amb[k], 0.0, 1.0)


func _make_stars_and_moon() -> void:
	var img := Image.create(512, 256, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 260:
		var p := Vector2i(rng.randi_range(0, 511), rng.randi_range(0, 255))
		var b := rng.randf_range(0.4, 1.0)
		img.set_pixelv(p, Color(1, 1, 0.95, b))
		if rng.randf() < 0.15 and p.x < 511 and p.y < 255:
			img.set_pixelv(p + Vector2i(1, 0), Color(1, 1, 0.95, b * 0.6))
			img.set_pixelv(p + Vector2i(0, 1), Color(1, 1, 0.95, b * 0.6))
	stars = TextureRect.new()
	stars.texture = ImageTexture.create_from_image(img)
	stars.stretch_mode = TextureRect.STRETCH_TILE
	stars.position = Vector2(-400, 0)
	stars.size = Vector2(4000, 420)
	stars.modulate.a = 0.0
	add_child(stars)
	var mi := Image.create(96, 96, false, Image.FORMAT_RGBA8)
	mi.fill(Color(0, 0, 0, 0))
	for y in 96:
		for x in 96:
			var d := Vector2(x - 48, y - 48).length()
			if d < 34.0:
				var shade := 0.9 - 0.15 * (Vector2(x - 40, y - 40).length() / 40.0)
				mi.set_pixel(x, y, Color(shade, shade, shade * 0.92))
			elif d < 46.0:
				mi.set_pixel(x, y, Color(1, 1, 0.9, 0.18 * (46.0 - d) / 12.0))
	for c in [[38, 40, 6], [56, 52, 4], [45, 60, 5]]:
		for y in range(-c[2], c[2] + 1):
			for x in range(-c[2], c[2] + 1):
				if x * x + y * y <= c[2] * c[2]:
					mi.set_pixel(c[0] + x, c[1] + y, Color(0.72, 0.72, 0.7))
	moon = Sprite2D.new()
	moon.texture = ImageTexture.create_from_image(mi)
	moon.position = Vector2(980, 150)
	moon.modulate.a = 0.0
	add_child(moon)


func _make_ambient() -> void:
	var dot := GradientTexture2D.new()
	dot.width = 16
	dot.height = 16
	dot.fill = GradientTexture2D.FILL_RADIAL
	dot.fill_from = Vector2(0.5, 0.5)
	dot.fill_to = Vector2(1.0, 0.5)
	var g := Gradient.new()
	g.set_color(0, Color.WHITE)
	g.set_color(1, Color(1, 1, 1, 0))
	dot.gradient = g
	var specs := {
		"fireflies": {"color": Color(0.85, 1.0, 0.45), "amount": 28, "life": 5.0, "vel": Vector2(-10, -12), "spread": 180.0, "size": 0.55, "box": Vector2(900, 200), "y": 420.0, "speed": 20.0},
		"dust": {"color": Color(1.0, 0.9, 0.7, 0.6), "amount": 40, "life": 4.0, "vel": Vector2(-1, 0), "spread": 15.0, "size": 0.5, "box": Vector2(900, 260), "y": 380.0, "speed": 160.0},
		"embers": {"color": Color(1.0, 0.55, 0.15), "amount": 46, "life": 4.5, "vel": Vector2(-0.3, -1), "spread": 30.0, "size": 0.45, "box": Vector2(900, 60), "y": 650.0, "speed": 90.0},
	}
	for k in specs:
		var sp: Dictionary = specs[k]
		var p := CPUParticles2D.new()
		p.texture = dot
		p.amount = sp.amount
		p.lifetime = sp.life
		p.preprocess = sp.life
		p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		p.emission_rect_extents = sp.box
		p.position = Vector2(700, sp.y)
		p.direction = sp.vel.normalized()
		p.spread = sp.spread
		p.initial_velocity_min = sp.speed * 0.5
		p.initial_velocity_max = sp.speed
		p.gravity = Vector2.ZERO
		p.scale_amount_min = sp.size * 0.6
		p.scale_amount_max = sp.size
		var ramp := Gradient.new()
		ramp.set_color(0, Color(sp.color, 0.0))
		ramp.add_point(0.2, sp.color)
		ramp.add_point(0.8, sp.color)
		ramp.set_color(ramp.get_point_count() - 1, Color(sp.color, 0.0))
		p.color_ramp = ramp
		p.emitting = false
		p.z_index = 40
		add_child(p)
		ambient[k] = p


static func make_wind(name: String, scale_f: float) -> AnimatedSprite2D:
	var a := AnimatedSprite2D.new()
	a.sprite_frames = SpriteLib.wind(name)
	a.centered = false
	a.offset = -SpriteLib.wind_pivot(name)
	a.scale = Vector2.ONE * scale_f
	a.play("wind")
	a.frame = randi() % 8
	a.speed_scale = randf_range(0.85, 1.15)
	if randf() < 0.5:
		a.flip_h = true
		a.offset.x = -(SpriteLib.wind_frame(name).x - SpriteLib.wind_pivot(name).x)
	return a


func _spawn_back_plant(x: float) -> void:
	var name: String = BACK_PLANTS.pick_random()
	var is_tree := name.begins_with("Trees")
	var a := make_wind(name, randf_range(0.55, 0.72) if is_tree else randf_range(0.4, 0.55))
	a.position = Vector2(x, Tuning.GROUND_STRIP_TOP + 10.0)
	back_decor.add_child(a)
