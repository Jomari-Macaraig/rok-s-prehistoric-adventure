class_name Trex
extends Node2D
## The T-rex pursuer (not a playable form). Main keeps a chase gap: the
## distance in px between the T-rex's snout and Rok. The T-rex is drawn so its
## snout sits exactly that far behind him, with its body and tail running off
## the left edge of the screen.

signal stomped(closeness: float)   # 0 far .. 1 about to bite

const SNOUT := 272.0     # snout x relative to the feet pivot (scaled art)
const PIVOT := Vector2(336, 427)

var sprite: AnimatedSprite2D
var hunter := "trex"          # which predator this is (Hunters), main swaps it per zone
var snout := SNOUT            # its snout x relative to the feet
var _ground_y := Tuning.GROUND_Y
var _closeness := 0.0


func _ready() -> void:
	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = SpriteLib.trex()
	sprite.centered = false
	sprite.offset = -PIVOT
	add_child(sprite)
	sprite.play("idle")
	sprite.frame_changed.connect(func():
		if sprite.animation == "run" and (sprite.frame == 0 or sprite.frame == 4):
			stomped.emit(_closeness))


## Place the T-rex so its snout is `gap` px behind snout_target_x, standing on
## the terrain (it bounds over pits rather than falling in).
func follow(target_x: float, gap: float, terrain: Terrain, delta: float, speed_scale := 1.0) -> void:
	position.x = target_x - gap - snout
	var h := terrain.height_at(position.x + 60.0)
	if h < Terrain.PIT:
		_ground_y = h
	position.y = lerpf(position.y, _ground_y, minf(delta * 10.0, 1.0))
	_closeness = clampf(1.0 - gap / Tuning.CHASE_GAP_MAX, 0.0, 1.0)
	if sprite.animation == "run":
		sprite.speed_scale = speed_scale


func run() -> void:
	_eating_ok = true
	sprite.play("run")


func roar() -> void:
	sprite.play("roar")
	sprite.speed_scale = 1.0
	if not sprite.animation_finished.is_connected(_back_to_run):
		sprite.animation_finished.connect(_back_to_run)


## Become another predator (Hunters): its art (or the T-rex's, tinted, until
## its own exists), keeping the current animation.
func set_hunter(id: String) -> void:
	hunter = id
	var anim := sprite.animation
	sprite.sprite_frames = Hunters.frames(id)
	sprite.offset = -Hunters.pivot(id)
	sprite.self_modulate = Hunters.tint(id)
	snout = Hunters.snout(id)
	sprite.play(anim if sprite.sprite_frames.has_animation(anim) else "run")


## Snap up a wild dinosaur (Critters) on the way: a bite, then back to running.
func eat() -> void:
	sprite.play("bite")
	sprite.speed_scale = 1.6
	if not sprite.animation_finished.is_connected(_back_to_run):
		sprite.animation_finished.connect(_back_to_run)


func _back_to_run() -> void:
	if (sprite.animation == "bite" or sprite.animation == "roar") and _eating_ok:
		run()


## main turns this off when the bite is the real one (Rok caught).
var _eating_ok := true


func bite() -> void:
	_eating_ok = false
	sprite.play("bite")
	sprite.speed_scale = 1.0


func idle() -> void:
	sprite.play("idle")
	sprite.speed_scale = 1.0
