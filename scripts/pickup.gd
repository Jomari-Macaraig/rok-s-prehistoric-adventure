class_name Pickup
extends Node2D
## Amber crystal (energy), meat (Market currency), a heart (heals one, rare;
## Hearts) or a booster (see Boosters, e.g. the dino egg). Bobs gently.
## Escalating pickups (later in a run, Course._pickup): big meat (the meat
## art at BIG_MEAT_SCALE, worth BIG_MEAT_VALUE) and rare fossils (FOSSIL_MEAT
## meat + FOSSIL_SCORE). A milestone chest ("chest") sits still on the ground
## and opens when Rok runs into it (`open()`). Fossils and chests use the
## user's art (`assets/items/fossil.png`; one chest per rarity,
## `chest_<tier>_anim.png`) once it exists; until then they're drawn in code.

var kind := "amber"
var radius := 34.0
var _t := 0.0
var _base_y := 0.0
var sprite: Node2D
var opened := false   # a chest, once opened
var rarity := ""      # a chest's rarity (Chest.RARITY), rolled when it's placed (set_rarity)


const ART := {"fossil": "res://assets/items/fossil.png",
		"chest": "res://assets/items/chest_common_closed.png"}
const CHEST_META := "res://assets/items/chest.json"   # the animated chests, one per tier (tools/prepare_chest.py)
static var _chest_sf := {}   # tier -> SpriteFrames


static func chest_art(tier: String, part: String) -> String:
	return "res://assets/items/chest_%s_%s.png" % [tier, part]


## Build the chest's and meat's frames ahead of time (the loading screen:
## the chest decodes its @2x sheet, a stutter the first time one appears).
static func warm() -> void:
	if FileAccess.file_exists(CHEST_META):
		var meta: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CHEST_META))
		for t in Chest.RARITY:
			_chest_frames(meta, t)
	if ResourceLoader.exists(MEAT_IDLE):
		_meat_frames()


## A tier's clips from chest_<tier>_anim.png (4 across): closed, open (once), sparkle (loop).
static func _chest_frames(meta: Dictionary, tier := "common") -> SpriteFrames:
	if _chest_sf.has(tier):
		return _chest_sf[tier]
	var path := chest_art(tier, "anim")
	if not ResourceLoader.exists(path):
		path = chest_art("common", "anim")
	var tex := SpriteLib.tex(path)
	var fs := Vector2(meta.frame[0], meta.frame[1])
	var sf := SpriteFrames.new()
	_chest_sf[tier] = sf
	sf.remove_animation("default")
	for clip in [["closed", [0], [1000], true], ["open", meta.open, meta.open_ms, false], ["sparkle", meta.sparkle, meta.sparkle_ms, true]]:
		sf.add_animation(clip[0])
		sf.set_animation_speed(clip[0], 1000.0)
		sf.set_animation_loop(clip[0], clip[3])
		for j in (clip[1] as Array).size():
			var i: int = clip[1][j]
			var at := AtlasTexture.new()
			at.atlas = tex
			at.region = Rect2(Vector2(i % 4, i / 4) * fs, fs)
			sf.add_frame(clip[0], at, float(clip[2][j]))
	return sf


## True when the chest or fossil is drawn from the user's art (not in code).
func _has_art() -> bool:
	return sprite is Sprite2D or (kind == "chest" and sprite is AnimatedSprite2D)


func setup(k: String) -> Pickup:
	kind = k
	if ART.has(k):
		# escalating pickups and chests: the user's art, or drawn in code (_draw)
		sprite = Node2D.new()
		if ResourceLoader.exists(ART[k]) and not (k == "chest" and FileAccess.file_exists(CHEST_META)):
			var st := Sprite2D.new()
			st.texture = load(ART[k])
			st.scale = Vector2.ONE * (88.0 / maxf(st.texture.get_width(), st.texture.get_height())) if k != "chest" else Vector2.ONE
			if k == "chest":
				st.centered = false
				st.offset = Vector2(-st.texture.get_width() * 0.5, -st.texture.get_height())
			sprite = st
		if k == "chest" and FileAccess.file_exists(CHEST_META):
			# the user's animated chest: closed, the lid opening, then a sparkle loop
			var meta: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CHEST_META))
			var fs := Vector2(meta.frame[0], meta.frame[1])
			var a := AnimatedSprite2D.new()
			a.sprite_frames = _chest_frames(meta, "common")
			a.centered = false
			a.offset = Vector2(-fs.x * 0.5, -fs.y)
			a.play("closed")
			a.animation_finished.connect(func():
				if a.animation == "open":
					a.play("sparkle"))
			sprite = a
		if k == "chest":
			radius = 56.0
		elif k == "fossil":
			radius = 40.0
	elif (k == "meat" or k == "big_meat") and ResourceLoader.exists(MEAT_IDLE):
		# animated meat (bob, tilt and shine are in the frames)
		var m := AnimatedSprite2D.new()
		m.sprite_frames = _meat_frames()
		m.play("idle")
		m.frame = randi() % 8
		m.scale = Vector2.ONE * (Tuning.BIG_MEAT_SCALE if k == "big_meat" else 0.47)   # 128 px frames -> about the old 60 px
		if k == "big_meat":
			radius = 46.0
		sprite = m
	elif Boosters.is_booster(k):
		# animated power-up (its gentle bob is part of the frames)
		var a := AnimatedSprite2D.new()
		a.sprite_frames = Boosters.frames(k)
		a.play("idle")
		a.frame = randi() % 8
		a.scale = Vector2.ONE * 0.62
		sprite = a
	else:
		var st := Sprite2D.new()
		if k == "meat" or k == "big_meat":
			st.texture = load(Hud.MEAT_ICON)
			st.scale = Vector2.ONE * (1.05 if k == "big_meat" else 0.62)
		elif k == "heart":
			st.texture = Hearts.icon(Hearts.QUARTERS)
			st.scale = Vector2.ONE * 0.85
		elif k.begins_with(Crafting.PICKUP_PREFIX):   # a crafting material
			st.texture = Crafting.icon(k.substr(Crafting.PICKUP_PREFIX.length()))
			st.scale = Vector2.ONE * (56.0 / maxf(st.texture.get_width(), st.texture.get_height()))
		else:
			st.texture = SpriteLib.tex("res://assets/props/Other_07.png")
			st.scale = Vector2.ONE * 0.55
		sprite = st
	add_child(sprite)
	_t = randf() * TAU
	return self


const MEAT_IDLE := "res://assets/items/meat_idle.png"
static var _meat_sf: SpriteFrames


## The meat pickup loop: a 4x2 sheet of 128 px frames, 100 ms each.
static func _meat_frames() -> SpriteFrames:
	if _meat_sf:
		return _meat_sf
	_meat_sf = SpriteFrames.new()
	_meat_sf.remove_animation("default")
	_meat_sf.add_animation("idle")
	_meat_sf.set_animation_loop("idle", true)
	_meat_sf.set_animation_speed("idle", 10.0)
	var tex: Texture2D = load(MEAT_IDLE)
	for i in 8:
		var at := AtlasTexture.new()
		at.atlas = tex
		at.region = Rect2(Vector2(i % 4, i / 4) * 128.0, Vector2(128, 128))
		_meat_sf.add_frame("idle", at)
	return _meat_sf


func place(p: Vector2) -> void:
	position = p
	_base_y = p.y


## Fossil Magnet: drift toward a point (keeps the bob around the new spot).
func pull_toward(target: Vector2, step: float) -> void:
	var p := Vector2(position.x, _base_y).move_toward(target, step)
	position.x = p.x
	_base_y = p.y


## A chest's rarity, rolled when it's placed: it wears that tier's art.
func set_rarity(r: String) -> void:
	rarity = r
	if sprite is AnimatedSprite2D and FileAccess.file_exists(CHEST_META):
		var a := sprite as AnimatedSprite2D
		a.sprite_frames = _chest_frames(JSON.parse_string(FileAccess.get_file_as_string(CHEST_META)), r)
		a.play("closed")
	elif sprite is Sprite2D and ResourceLoader.exists(chest_art(r, "closed")):
		(sprite as Sprite2D).texture = load(chest_art(r, "closed"))
	queue_redraw()


## A chest opens (it stays, open, scrolling away).
func open(r: String) -> void:
	if r != rarity:
		set_rarity(r)
	opened = true
	if sprite is AnimatedSprite2D and (sprite as AnimatedSprite2D).sprite_frames.has_animation("open"):
		(sprite as AnimatedSprite2D).play("open")   # then it sparkles
	elif sprite is Sprite2D and ResourceLoader.exists(chest_art(r, "open")):
		(sprite as Sprite2D).texture = load(chest_art(r, "open"))
	var t := create_tween()
	scale = Vector2(1.25, 0.8)
	t.tween_property(self, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	queue_redraw()


func _process(delta: float) -> void:
	if kind == "chest":
		position.y = _base_y   # chests sit still on the ground
		if not _has_art():
			_t += delta
			queue_redraw()
		return
	if ART.has(kind) and not _has_art():
		_t += delta * 3.0
		position.y = _base_y + sin(_t) * 6.0
		queue_redraw()
		return
	if sprite is AnimatedSprite2D:
		position.y = _base_y   # the bob is drawn into the animation
		return
	_t += delta * 3.0
	position.y = _base_y + sin(_t) * 6.0
	sprite.rotation = sin(_t * 0.7) * 0.08


# ------------------------------------------------- placeholders (no art yet)

func _draw() -> void:
	if _has_art() or not ART.has(kind):
		return
	match kind:
		"fossil":
			_draw_glow(Color(0.7, 0.9, 1.0), 40.0)
			# an ammonite: a stone disc with a spiral and ribs
			draw_circle(Vector2.ZERO, 27.0, Color(0.35, 0.25, 0.15))
			draw_circle(Vector2.ZERO, 24.0, Color(0.86, 0.76, 0.58))
			var pts := PackedVector2Array()
			for i in 60:
				var a := i * 0.32
				pts.append(Vector2.from_angle(a) * (2.0 + i * 0.36))
			draw_polyline(pts, Color(0.45, 0.32, 0.18), 3.0)
			for i in 10:
				var a := TAU * i / 10.0
				draw_line(Vector2.from_angle(a) * 14.0, Vector2.from_angle(a) * 23.0, Color(0.6, 0.47, 0.3), 2.0)
		"chest":
			var col: Color = Chest.RARITY_COLOR.get(rarity, Color(0.95, 0.8, 0.5))
			if opened:
				_draw_glow(col, 70.0, 0.35)
			else:
				_draw_glow(Color(1.0, 0.85, 0.4), 62.0, 0.18 + 0.1 * sin(_t * 4.0))
			var wood := Color(0.55, 0.3, 0.12)
			var dark := Color(0.3, 0.15, 0.05)
			var band := Color(0.95, 0.75, 0.3)
			draw_rect(Rect2(-44, -50, 88, 50), dark)
			draw_rect(Rect2(-40, -46, 80, 44), wood)
			draw_rect(Rect2(-44, -30, 88, 7), band)
			if opened:
				# lid tipped back, treasure glinting inside
				draw_colored_polygon(PackedVector2Array([Vector2(-44, -50), Vector2(44, -50), Vector2(36, -86), Vector2(-36, -86)]), dark)
				draw_colored_polygon(PackedVector2Array([Vector2(-40, -52), Vector2(40, -52), Vector2(33, -82), Vector2(-33, -82)]), wood)
				draw_circle(Vector2(0, -52), 16.0, col)
			else:
				draw_colored_polygon(PackedVector2Array([Vector2(-46, -50), Vector2(46, -50), Vector2(40, -74), Vector2(-40, -74)]), dark)
				draw_colored_polygon(PackedVector2Array([Vector2(-42, -52), Vector2(42, -52), Vector2(37, -71), Vector2(-37, -71)]), wood)
				draw_rect(Rect2(-8, -58, 16, 18), band)
				draw_rect(Rect2(-3, -53, 6, 7), dark)


func _draw_glow(col: Color, r: float, alpha := 0.25) -> void:
	for i in 4:
		var c := col
		c.a = alpha * (1.0 - i / 4.0)
		draw_circle(Vector2(0, -r * 0.4 if kind == "chest" else 0.0), r * (1.0 - i * 0.18), c)
