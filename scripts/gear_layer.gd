class_name GearLayer
extends Node2D
## A hero's equipped gear drawn on their body as separate layers (the user's
## plan: swap weapons without new hero art). Add it as a child of the hero's
## AnimatedSprite2D (centered off, offset = -pivot) and set `hero`:
## - the weapon sits in the front hand: its grip (gear_art.json) on the hand
##   socket of the frame showing (sockets.json, measured from the art by
##   tools/prepare_gear.py), tilted by the clip (CLIP_ANGLE) plus the
##   weapon's own angle; a sling hangs from the hand instead;
## - the Shell Plate rides on the back socket.
## Both draw behind the body, so the fist and torso cover the handle and the
## shell. Hidden for anything that isn't a hero clip (dinosaur forms, the
## death hop) and for gear without art (old saves' cards in the weapon slot;
## the vest, scale mail and bone guards need fitted overlay sheets).

## Tilt of a held weapon per clip, degrees clockwise from upright.
const CLIP_ANGLE := {"idle": 20.0, "walk": 25.0, "run": 45.0, "jump": 15.0, "duck": 60.0, "slide": 75.0, "celebrate": -15.0}
const ROK_HEIGHT := 168.0   # gear_art lengths are for Rok's standing height

var hero := "":   # "rok", "nira", "boro" or "" (not a hero: nothing shown)
	set(v):
		hero = v
		refresh()

var _weapon := Sprite2D.new()
var _back := Sprite2D.new()
var _weapon_id := ""
var _weapon_broken := false
var _back_id := ""
var _sock: Dictionary = {}

static var _art := {}
static var _sockets := {}


var baked_run := false   # the hero's run sheet carries the weapon (Player.set_carry): hide ours during "run"
## A style clip's layer (Player.atk_gear): the weapon draws IN FRONT of the
## body with the fist redrawn over its handle (`_fist`), the shell behind.
var front := false
## The guide of the style clip showing (Player sets it: a standing clip's
## attack_meta entry, or one phase of a running style); {} = none.
var clip_meta := {}
var _fist := Sprite2D.new()
const FIST_R := 10.0   # 1x px: the fist patch's half size around the grip

func _ready() -> void:
	show_behind_parent = not front
	if front:
		var behind := Node2D.new()   # the shell still goes behind the body
		behind.show_behind_parent = true
		behind.add_child(_back)
		get_parent().add_child.call_deferred(behind)
		_fist.centered = false
		_fist.region_enabled = true
	else:
		add_child(_back)
	add_child(_weapon)
	if front:
		add_child(_fist)
	_weapon.centered = false
	_back.centered = false
	if _art.is_empty() and FileAccess.file_exists("res://assets/gear/gear_art.json"):
		_art = JSON.parse_string(FileAccess.get_file_as_string("res://assets/gear/gear_art.json"))
		_sockets = JSON.parse_string(FileAccess.get_file_as_string("res://assets/gear/sockets.json"))
	refresh()


## Re-read what the hero has equipped (call after equipping).
func refresh() -> void:
	if not is_inside_tree():
		return
	_weapon_id = Gear.slot_item(hero, "weapon") if hero != "" else ""
	_weapon_broken = false   # (gear no longer breaks from wear: Worn Out pieces are still drawn)
	_back_id = Gear.slot_item(hero, "armor") if hero != "" else ""
	_setup(_weapon, "" if _weapon_broken else Gear.base(_weapon_id))
	_setup(_back, Gear.base(_back_id))
	_sock = _sockets.get(hero, {})
	_place()


func _setup(s: Sprite2D, id: String) -> void:
	if s == _weapon:
		_anim_frames = []
	if not _art.has(id):
		s.texture = null
		return
	var a: Dictionary = _art[id]
	s.texture = Gear.icon(id)
	var k := float(a.length) / float(a.size[1])
	s.scale = Vector2(k, k)
	s.offset = -Vector2(a.point[0], a.point[1])
	if s == _weapon and a.has("anim"):   # the Torch's burning loop, registered to its icon
		_anim_frames = _frames_of("gear/%s_anim" % id, a.anim)
		s.texture = _anim_frames[0]
		s.offset = -(Vector2(a.point[0], a.point[1]) + Vector2(a.anim.origin[0], a.anim.origin[1]))
		_anim_ms = float(a.anim.ms)


var _anim_frames: Array = []
var _anim_ms := 83.0
var _anim_t := 0.0


## 8 AtlasTexture frames from a 4x2 gear sheet (assets/<path>.png).
static func _frames_of(path: String, m: Dictionary) -> Array:
	var tex := SpriteLib.tex("res://assets/%s.png" % path)
	var fs := Vector2(m.frame[0], m.frame[1])
	var out := []
	for i in 8:
		var at := AtlasTexture.new()
		at.atlas = tex
		at.region = Rect2(Vector2(i % 4, i / 4) * fs, fs)
		out.append(at)
	return out


## A weapon breaking: its 8-frame shatter (the user's weapons pack) plays where
## it was held, then disappears. Call before the weapon is hidden.
func play_break(id: String) -> void:
	if not _art.has(id) or not _art[id].has("break") or not _weapon.visible:
		return
	var a: Dictionary = _art[id]
	var fx := Sprite2D.new()
	fx.centered = false
	fx.position = _weapon.position
	fx.rotation = _weapon.rotation
	fx.scale = _weapon.scale
	fx.offset = -(Vector2(a.point[0], a.point[1]) + Vector2(a["break"].origin[0], a["break"].origin[1]))
	var frames := _frames_of("gear/break_" + id, a["break"])
	fx.texture = frames[0]
	add_child(fx)
	var t := fx.create_tween()
	for i in range(1, frames.size()):
		t.tween_interval(float(a["break"].ms) / 1000.0)
		t.tween_callback(func(): fx.texture = frames[i])
	t.tween_interval(float(a["break"].ms) / 1000.0)
	t.tween_callback(fx.queue_free)


func _process(_d: float) -> void:
	if not _anim_frames.is_empty() and _weapon.visible:
		_anim_t += _d * 1000.0
		_weapon.texture = _anim_frames[int(_anim_t / _anim_ms) % _anim_frames.size()]
	if hero != "" and (Gear.slot_item(hero, "weapon") != _weapon_id or Gear.slot_item(hero, "armor") != _back_id
			):
		refresh()   # equipped or changed at the Camp
	_place()


func _place() -> void:
	var spr := get_parent() as AnimatedSprite2D
	if spr == null:
		return
	if not clip_meta.is_empty():
		_place_style(spr, clip_meta)
		return
	var frames: Array = _sock.get(String(spr.animation), [])
	var ok := hero != "" and not frames.is_empty() and spr.frame < frames.size()
	# the run sheet has the weapon drawn in (Player.set_carry): no second copy
	_weapon.visible = ok and _weapon.texture != null and not (baked_run and spr.animation == "run")
	_back.visible = ok and _back.texture != null
	if not ok:
		return
	var f: Array = frames[spr.frame]
	var size_k := spr.sprite_frames.get_frame_texture(spr.animation, spr.frame).get_height() / 224.0   # heroes share a 224 px tall canvas
	if _weapon.visible:
		var a: Dictionary = _art[Gear.base(_weapon_id)]
		_weapon.position = spr.offset + Vector2(f[0], f[1])
		var tilt: float = 0.0 if a.get("hang", false) else CLIP_ANGLE.get(String(spr.animation), 20.0) + float(a.angle)
		if a.get("upright", false):   # the bow and torch stay nearly upright (the flame points up)
			tilt = clampf(tilt * 0.25, -8.0, 12.0)
		_weapon.rotation_degrees = tilt
		var k := float(a.length) / float(a.size[1]) * size_k
		_weapon.scale = Vector2(k, k)
	if _back.visible:
		_back.position = spr.offset + Vector2(f[2], f[3])
		_back.rotation_degrees = -8.0 if spr.animation == "run" else 0.0


## An empty-handed style clip ("style_swing", tools/prepare_styles.py): the
## weapon's grip goes on the guide's grip point and it points along the
## guide's stick (angle clockwise from up, plus the weapon's own tilt); the
## shell rides on the guide's back point. No stick: no weapon (Fist), except
## after a Throw or Shoot release, where the sling or bow stays in the hand
## at its last angle (only the stone or arrow left).
func _place_style(spr: AnimatedSprite2D, m: Dictionary) -> void:
	var i := spr.frame
	var grips: Array = m.get("grip", [])
	var angles: Array = (m.get("angle", []) as Array).duplicate()
	if m.get("release") != null and i < angles.size() and angles[i] == null:
		for k in range(i, -1, -1):
			if angles[k] != null:
				angles[i] = angles[k]
				break
	var ok := i < grips.size() and grips[i] != null
	_weapon.visible = ok and _weapon.texture != null and i < angles.size() and angles[i] != null
	var backs: Array = m.get("back", [])
	_back.visible = hero != "" and _back.texture != null and i < backs.size() and backs[i] != null
	_fist.visible = _weapon.visible and front
	if _weapon.visible:
		var a: Dictionary = _art[Gear.base(_weapon_id)]
		var g := Vector2(grips[i][0], grips[i][1])
		_weapon.position = spr.offset + g
		_weapon.rotation_degrees = float(angles[i]) + float(a.angle)
		var k := float(a.length) / float(a.size[1]) * Gear.style_scale(_weapon_id)   # every hero is drawn on a 224 px tall canvas
		_weapon.scale = Vector2(k, k)
		if front:   # the fist over the handle: the same frame, just the box around the grip
			_fist.texture = spr.sprite_frames.get_frame_texture(spr.animation, i)
			_fist.region_rect = Rect2(g - Vector2(FIST_R, FIST_R), Vector2(FIST_R, FIST_R) * 2.0)
			_fist.position = spr.offset + g - Vector2(FIST_R, FIST_R)
	if _back.visible:
		_back.position = spr.offset + Vector2(backs[i][0], backs[i][1])
		_back.rotation_degrees = 0.0
