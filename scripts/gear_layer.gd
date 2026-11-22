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
## death hop) and for gear without art (dinosaur cards in the weapon slot;
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


func _ready() -> void:
	show_behind_parent = true
	add_child(_back)
	add_child(_weapon)
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
	_weapon_broken = Gear.broken(_weapon_id)   # a broken weapon isn't drawn
	_back_id = Gear.slot_item(hero, "armor") if hero != "" else ""
	_setup(_weapon, "" if _weapon_broken else _weapon_id)
	_setup(_back, _back_id)
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
			or Gear.broken(_weapon_id) != _weapon_broken):
		refresh()   # equipped or changed at the Camp
	_place()


func _place() -> void:
	var spr := get_parent() as AnimatedSprite2D
	if spr == null:
		return
	var frames: Array = _sock.get(String(spr.animation), [])
	var ok := hero != "" and not frames.is_empty() and spr.frame < frames.size()
	_weapon.visible = ok and _weapon.texture != null
	_back.visible = ok and _back.texture != null
	if not ok:
		return
	var f: Array = frames[spr.frame]
	var size_k := spr.sprite_frames.get_frame_texture(spr.animation, spr.frame).get_height() / 224.0   # heroes share a 224 px tall canvas
	if _weapon.visible:
		var a: Dictionary = _art[_weapon_id]
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
