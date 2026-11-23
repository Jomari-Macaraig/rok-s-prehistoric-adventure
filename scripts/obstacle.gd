class_name Obstacle
extends Node2D
## A ground obstacle. kind decides which forms can smash it:
## "small" (stones, mushrooms), "wood" (logs), "rock" (boulders, walls), "fence",
## "overhead" (a low floating ledge you slide under; nothing smashes it) and
## "thorns" (bushes / bramble; Spinosaurus tramples them).
## gate_form != -1 marks a dino gate: only that form gets through, and a
## Spinosaurus shield does not help.

var kind := "small"
var size := Vector2.ZERO        # visual size; origin at bottom-centre
var shrink := Vector2(0.8, 0.85)
var passed := false
var gate_form := -1
var vine := false               # Forest low branch: snags Rok instead of ending the run
var mushroom := false
## Wild dinosaurs (Critters): their species id, and the hitbox measured from
## the art relative to the node (custom_box) instead of size * shrink.
var critter := ""
var custom_box := Rect2()
var bumped := false             # already ran into Rok: no more collisions
## Diving flyers (make_diver): start high, dive to their normal height as
## they reach Rok. dive_started turns true when the dive begins.
var dive := false
var dive_started := false
var _dive_high_y := 0.0
var _bob := 0.0
var _bob_t := 0.0
var _base_y := 0.0           # squashed for a dizzy debuff instead of ending the run
var roll_speed := 0.0            # rolling boulders move toward Rok on their own
var shattered := false
## Per visual part: {"node", "bottom": local y of its base, "scale", "break": anim or ""}
var parts_info: Array = []
var anim: AnimatedSprite2D       # steam vents: the vent animation (its frame decides if it's active)

## Which break animation fits each prop texture.
const BREAKS := {
	"Logs_01": "existing_log_break", "Logs_02": "existing_log_break",
	"Logs_03": "existing_log_break", "Logs_04": "existing_log_break",
	"Stones_04": "existing_boulder_break", "Stones_05": "existing_boulder_break",
	"Other_02": "existing_boulder_break", "Other_05": "existing_boulder_break",
	"Fences_01": "existing_fence_break", "Fences_02": "existing_fence_break", "Fences_03": "existing_fence_break",
	"Tile-3_07": "existing_stone_break", "Tile-3_08": "existing_stone_break",
	"Tile-3_09": "existing_stone_break", "Tile-3_10": "existing_stone_break",
	# small rocks (and meteors) crumble like a little boulder
	"Stones_01": "existing_boulder_break", "Stones_02": "existing_boulder_break", "Stones_03": "existing_boulder_break",
}
## A break animation drawn at the prop's scale x this (the boulder break is
## boulder-sized; the small rocks crumble at their own size).
const BREAK_SCALE := {"Stones_01": 0.45, "Stones_02": 0.42, "Stones_03": 0.55}


func setup(k: String, parts: Array, scale_factor: float) -> Obstacle:
	## parts: Array of texture paths stacked bottom-up.
	kind = k
	var y := 0.0
	var w := 0.0
	for p in parts:
		var tex: Texture2D = SpriteLib.tex(p)   # the @2x twin when there is one (sharp on high-DPI)
		var s := Sprite2D.new()
		s.texture = tex
		s.centered = false
		s.scale = Vector2.ONE * scale_factor
		var sz := tex.get_size() * scale_factor
		s.position = Vector2(-sz.x * 0.5, -y - sz.y + 4.0)
		var base: String = p.get_file().get_basename()
		parts_info.append({"node": s, "bottom": -y + 4.0, "scale": scale_factor * float(BREAK_SCALE.get(base, 1.0)),
				"break": BREAKS.get(base, "")})
		y += sz.y - 10.0 * scale_factor
		w = maxf(w, sz.x)
		add_child(s)
	size = Vector2(w, y + 10.0 * scale_factor)
	return self


## A stack of a trap's intact frame (frame 0 of its break animation), used for
## the zone barricades the Triceratops charges through.
func setup_anim_stack(anim: String, scale_factor: float, min_height: float) -> Obstacle:
	kind = "rock"
	var m: Dictionary = SpriteLib.trap_meta()[anim]
	var b: Array = m.bounds0
	var piece_h: float = (b[3] - b[1]) * scale_factor
	var piece_w: float = (b[2] - b[0]) * scale_factor
	var y := 0.0
	var i := 0
	while y < min_height:
		var a := SpriteLib.trap_sprite(anim, false)
		a.scale = Vector2(scale_factor * (-1.0 if i % 2 == 1 else 1.0), scale_factor)
		a.position = Vector2(0, -y)
		add_child(a)
		parts_info.append({"node": a, "bottom": -y, "scale": scale_factor, "break": anim, "self": true})
		y += piece_h * 0.82
		i += 1
	size = Vector2(piece_w, y + piece_h * 0.18)
	shrink = Vector2(0.86, 1.0)
	return self


## Smashed: collision is gone (Course drops it from `obstacles`); each part
## plays its break animation and the rubble keeps scrolling with the world.
## Parts without one just vanish (main adds debris particles).
func shatter() -> void:
	shattered = true
	for info in parts_info:
		var n: Node2D = info.node
		if info.break == "":
			n.visible = false
			continue
		if info.get("self", false):
			(n as AnimatedSprite2D).frame = 2   # impact frame
			(n as AnimatedSprite2D).play("a")
			continue
		var a := SpriteLib.trap_sprite(info.break)
		a.scale = Vector2.ONE * info.scale
		a.position = Vector2(0, info.bottom)
		a.frame = 2
		add_child(a)
		n.visible = false
	for c in get_children():
		if c is AnimatedSprite2D and c.sprite_frames.has_animation("wind"):
			c.visible = false   # thorn bushes: trampled flat


## A low floating ledge built from overlapping floating-island pieces
## (Terrain-variation_03), the same art as the floating islands, so the two
## never clash. Origin is the bottom-centre: position.y is the lowest point of
## the underside you slide beneath.
func setup_ledge(pieces: int, scale_factor: float, zone_id := "forest") -> Obstacle:
	kind = "overhead"
	var tex: Texture2D = FloatingPlatform.island_texture(zone_id)
	var sz := tex.get_size() * scale_factor
	var step := sz.x * 0.62
	var total := sz.x + step * (pieces - 1)
	for i in pieces:
		var s := Sprite2D.new()
		s.texture = tex
		s.centered = false
		s.scale = Vector2.ONE * scale_factor
		s.flip_h = i % 2 == 1
		s.position = Vector2(-total * 0.5 + i * step, -sz.y)
		add_child(s)
	size = Vector2(total, sz.y)
	shrink = Vector2(0.9, 0.72)   # top strip (grass) excluded so you can land on it
	return self


## A single overhead prop (forest branch with vines, desert fossil arch).
## Origin is the bottom-centre: position.y is the lowest hanging tip.
func setup_overhead_static(name: String, scale_factor: float) -> Obstacle:
	kind = "overhead"
	var s := Sprite2D.new()
	s.texture = SpriteLib.tex("res://assets/traps/%s.png" % name)
	s.centered = false
	s.scale = Vector2.ONE * scale_factor
	var sz := s.texture.get_size() * scale_factor
	s.position = Vector2(-sz.x * 0.5, -sz.y)
	add_child(s)
	size = sz
	shrink = Vector2(0.9, 0.8)
	return self


## Thorny bushes (wind-animated) stacked `layers` high; one layer is a
## jumpable thorn bush, a full stack is the Spinosaurus bramble gate.
func setup_thorns(layers: int, scale_factor: float) -> Obstacle:
	kind = "thorns"
	var y := 0.0
	var w := 0.0
	for i in layers:
		var name: String = ["Grasses_16", "Grasses_15"][i % 2]
		var a := Background.make_wind(name, scale_factor * (1.0 if i % 2 == 0 else 1.2))
		a.position = Vector2(randf_range(-10, 10) if layers > 1 else 0.0, -y)
		a.modulate = Color(0.62, 0.7, 0.48)
		add_child(a)
		var fr := SpriteLib.wind_frame(name) * a.scale.x
		w = maxf(w, fr.x * 0.8)
		y += fr.y * 0.62
		# a few dark thorns poking out
		for k in 5:
			var t := Polygon2D.new()
			var base := Vector2(randf_range(-fr.x * 0.35, fr.x * 0.35), -y + randf_range(4.0, fr.y * 0.5))
			var dir := Vector2.from_angle(randf_range(-PI, 0.0))
			var side := dir.orthogonal() * 4.0
			t.polygon = PackedVector2Array([base - side, base + dir * 13.0, base + side])
			t.color = Color(0.3, 0.16, 0.08)
			add_child(t)
	size = Vector2(w, y + 10.0)
	shrink = Vector2(0.8, 0.85)
	return self


## A volcanic steam vent: harmless cone, with a scalding column on its
## active frames (3-5; 1-2 are the warning puffs).
func setup_steam(scale_factor: float) -> Obstacle:
	kind = "steam"
	anim = SpriteLib.trap_sprite("volcanic_steam")
	anim.scale = Vector2.ONE * scale_factor
	anim.frame = randi() % 8
	anim.speed_scale = randf_range(0.85, 1.1)
	add_child(anim)
	var b: Array = SpriteLib.trap_meta().volcanic_steam.bounds0
	size = Vector2((b[2] - b[0]) * scale_factor, (b[3] - b[1]) * scale_factor)
	return self


func steam_active() -> bool:
	return anim != null and anim.frame >= 3 and anim.frame <= 5


## A boulder rolling toward Rok (faster than the ground scrolls).
## A wild dinosaur (see Critters): its running or flying loop, mirrored to
## face Rok, closing in on its own. Swoopers fly with their underside
## `height` px above the ground and bob. Call place_critter() once positioned.
func setup_critter(id: String) -> Obstacle:
	var d: Dictionary = Critters.DATA[id]
	critter = id
	kind = d.kind
	roll_speed = d.speed
	var a := AnimatedSprite2D.new()
	a.sprite_frames = Critters.frames(id)
	a.centered = false
	a.offset = -Critters.pivot(id)
	a.scale = Vector2(-d.scale, d.scale)   # mirrored: runs at Rok
	a.play("a")
	a.frame = randi() % 8
	add_child(a)
	anim = a
	var b := Critters.art_bounds(id)
	var s: float = d.scale
	# mirrored bounds, a little inside the art
	var w := b.size.x * s * 0.62
	var h := b.size.y * s * 0.7
	var cx := -(b.position.x + b.size.x * 0.5) * s
	var bottom := (b.position.y + b.size.y) * s
	custom_box = Rect2(cx - w * 0.5, bottom - h - b.size.y * s * 0.08, w, h)
	size = b.size * s
	shrink = Vector2.ONE
	_bob = d.get("bob", 0.0)
	_bob_t = randf() * TAU
	return self


## Swoopers: lift the node so the art's underside flies `height` px up.
func place_critter(ground_y: float) -> void:
	var d: Dictionary = Critters.DATA[critter]
	if kind == "swooper":
		var b := Critters.art_bounds(critter)
		position.y = ground_y - d.height - (b.position.y + b.size.y) * d.scale
	else:
		position.y = ground_y + 6.0
	_base_y = position.y


## A swooper that comes in high (Tuning.DIVE_START_H) and dives toward Rok,
## bottoming out DIVE_DIP px below its normal height DIVE_TO_X px ahead of
## him. Call after place_critter().
func make_diver() -> void:
	dive = true
	_bob = 0.0
	roll_speed *= Tuning.DIVE_SPEED_MULT
	var d: Dictionary = Critters.DATA[critter]
	_dive_high_y = _base_y - (Tuning.DIVE_START_H - d.height)
	_base_y += Tuning.DIVE_DIP
	update_dive()


## 0 while it's still far ahead, 1 once it has dived (from its distance to Rok).
func dive_progress() -> float:
	return clampf((Tuning.DIVE_FROM_X - (position.x - Tuning.PLAYER_X)) / (Tuning.DIVE_FROM_X - Tuning.DIVE_TO_X), 0.0, 1.0)


func update_dive() -> void:
	var t := dive_progress()
	dive_started = dive_started or t > 0.0
	position.y = lerpf(_dive_high_y, _base_y, t * t * (3.0 - 2.0 * t))
	if anim:
		anim.rotation = -sin(t * PI) * Tuning.DIVE_TILT   # facing left: nose down


func _process(delta: float) -> void:
	if dive:
		update_dive()
	if _bob > 0.0:
		_bob_t += delta * 3.0
		position.y = _base_y + sin(_bob_t) * _bob


func setup_rolling(scale_factor: float) -> Obstacle:
	kind = "rock"
	roll_speed = Tuning.ROLL_SPEED
	var a := SpriteLib.trap_sprite("volcanic_boulder")
	a.scale = Vector2.ONE * scale_factor
	add_child(a)
	parts_info.append({"node": a, "bottom": 0.0, "scale": scale_factor, "break": ""})
	var b: Array = SpriteLib.trap_meta().volcanic_boulder.bounds0
	size = Vector2((b[2] - b[0]) * scale_factor, (b[3] - b[1]) * scale_factor)
	shrink = Vector2(0.72, 0.8)
	return self


func hitbox() -> Rect2:
	if custom_box.size != Vector2.ZERO:
		return Rect2(position + custom_box.position, custom_box.size)
	if kind == "steam":
		if not steam_active():
			return Rect2()
		return Rect2(position.x - 34.0, position.y - 330.0, 68.0, 330.0)
	var hs := size * shrink
	return Rect2(position.x - hs.x * 0.5, position.y - hs.y, hs.x, hs.y)


func right_edge() -> float:
	return position.x + size.x * 0.5
