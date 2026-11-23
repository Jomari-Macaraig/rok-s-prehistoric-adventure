class_name Player
extends Node2D
## Rok. Origin is at his feet. Vertical physics only — the world scrolls.

signal landed(hard: bool)
signal jumped(air: bool)
signal shifted(form: int)
signal slid
signal flapped
signal stepped    # a foot hits the ground while running

## Low states: slide (enter -> glide -> recover) and duck (held after a long slide).
enum Low { NONE, ENTER, GLIDE, DUCK, RECOVER }

var form: int = Forms.ROK
var vy := 0.0
var on_ground := true
var air_jumps_left := 1
var armor := 0
var dead := false
var invuln := 0.0

var _coyote := 0.0
var _buffer := 0.0
var _jump_held := false
var _cut_after := -1.0     # s after takeoff to cut a jump whose tap ended before it started (-1: none)
var _jump_v := 0.0
var jump_mult := 1.0   # main lowers it while Rok is dizzy (mushroom spores)
var sand_grip := 1.0   # main lowers it while quicksand holds his feet (no air jump then)
var celebrate_t := 0.0   # main sets it on a new best: a jump within this many seconds celebrates
var _celebrating := false     # airborne in the celebration jump (frames follow vy)

var low := Low.NONE
var swimming := false
var _death_freeze := 0.0
var headroom_clear: Callable    # main supplies: true when standing up would not hit a ledge
var _low_t := 0.0
var _slide_total := 0.0
var _slide_held := false
var _slide_buffer := 0.0
var slide_cd := 0.0              # seconds until the next slide (Tuning.SLIDE_COOLDOWN x Speed's cut)
var slide_cd_max := 1.0          # the slide cooldown's full length (for the button's sweep)
var jump_cd := 0.0               # seconds until the next ground jump (Tuning.JUMP_COOLDOWN x Jump's cut)
var jump_cd_max := 1.0
var _takeoff_t := 0.0      # Pteranodon takeoff animation time left

var body: Node2D               # squashes vertically while low
var sprite: AnimatedSprite2D
var gear: GearLayer             # equipped hero gear, a layer on the sprite
## Hit reactions (trip, dizzy, snag) play on their own sprite: they have their
## own canvas and pivot. While one plays the main sprite is hidden (it keeps
## animating underneath, so footsteps and the run cycle carry on).
var react: AnimatedSprite2D
var react_kind := ""           # "", "trip", "dizzy" or "snag"
var atk: AnimatedSprite2D       # the attack clip (its own canvas), shown instead of sprite while it plays
var attack_clip := ""          # the clip playing, or ""
## The seamless running attack (SpriteLib.running_attack): the run phase it
## started at (-1 when none) and how many run frames have gone by since. Its
## frame follows the body's run frame by frame (the body keeps running
## hidden underneath), so after 8 frames the run carries on at that phase.
var run_attack_phase := -1
var _run_attack_n := 0
var carry := ""                # the weapon drawn into the run sheet (SpriteLib.carry_frames), or ""
var tfx: AnimatedSprite2D       # the shapeshift burst (play_transform), drawn over the body
var pfx_once: AnimatedSprite2D  # a power-up's pickup / activation / expire effect, over the body
var pfx_aura: AnimatedSprite2D  # the power-up aura while one runs, behind the body
var _react_hold := 0.0         # seconds left in the held loop before recovering
var shadow: Polygon2D


func _ready() -> void:
	shadow = Polygon2D.new()
	var pts := PackedVector2Array()
	for i in 20:
		var a := TAU * i / 20.0
		pts.append(Vector2(cos(a) * 46.0, sin(a) * 9.0))
	shadow.polygon = pts
	shadow.color = Color(0.2, 0.1, 0.05, 0.28)
	add_child(shadow)
	body = Node2D.new()
	add_child(body)
	sprite = AnimatedSprite2D.new()
	sprite.centered = false
	body.add_child(sprite)
	gear = GearLayer.new()   # the hero's weapon (and shell) drawn on him
	sprite.add_child(gear)
	sprite.frame_changed.connect(_run_attack_tick)
	sprite.frame_changed.connect(func():
		if sprite.animation == "fly" and sprite.frame == 3:
			flapped.emit()
		elif sprite.animation == "run" and on_ground and (sprite.frame == 0 or sprite.frame == 4):
			stepped.emit())
	react = AnimatedSprite2D.new()
	react.centered = false
	react.visible = false
	body.add_child(react)
	react.animation_finished.connect(_on_react_finished)
	atk = AnimatedSprite2D.new()
	atk.centered = false
	atk.visible = false
	body.add_child(atk)
	atk.animation_finished.connect(attack_stop)
	tfx = AnimatedSprite2D.new()   # (a child of the player, not the body: a slide's squash mustn't bend it)
	tfx.centered = false
	tfx.visible = false
	add_child(tfx)
	tfx.animation_finished.connect(func(): tfx.visible = false)
	pfx_aura = AnimatedSprite2D.new()
	pfx_aura.centered = false
	pfx_aura.visible = false
	add_child(pfx_aura)
	move_child(pfx_aura, 0)   # behind the body
	pfx_once = AnimatedSprite2D.new()
	pfx_once.centered = false
	pfx_once.visible = false
	add_child(pfx_once)
	pfx_once.animation_finished.connect(func(): pfx_once.visible = false)
	_apply_form(Forms.ROK)
	sprite.play("idle")


## Play a hit reaction: "trip" once, or "dizzy"/"snag" as enter, a held loop
## for `hold` seconds, then recover. from_hold starts in the loop (dizziness
## resuming after a jump). Only on the ground; returns true if it plays.
func react_play(kind: String, hold := 0.0, from_hold := false) -> bool:
	if dead or not on_ground or swimming or low != Low.NONE:
		return false
	var sf := SpriteLib.reactions(data().id)
	if sf == null:
		return false
	react.sprite_frames = sf
	react.offset = -SpriteLib.reaction_pivot(data().id)
	attack_stop()
	react_kind = kind
	_react_hold = hold
	react.play(kind if kind == "trip" or from_hold else kind + "_enter")
	react.visible = true
	sprite.visible = false
	return true


## Play an attack clip (SpriteLib.attacks: "attack" for a dinosaur,
## "attack_<weapon id>" for a hero) once, in place of the body sprite (the
## clip has the weapon drawn in it). Not while sliding, swimming or dead.
## Returns false if this character has no such clip.
func attack_play(clip: String) -> bool:
	if dead or swimming or low != Low.NONE:
		return false
	var sf := SpriteLib.attacks(String(data().id))
	if sf == null or not sf.has_animation(clip):
		return false
	react_stop()
	var p: Array = SpriteLib.attack_meta(String(data().id))[clip].pivot
	atk.sprite_frames = sf
	atk.offset = -Vector2(p[0], p[1])
	atk.speed_scale = 1.0
	attack_clip = clip
	atk.play(clip)
	atk.visible = true
	sprite.visible = false
	return true


## The user's shapeshift burst over the change from form data `from` to the
## current form: scaled so its solid cloud (meta `cover`) hides the bigger of
## the two (TRANSFORM_FX_COVER of its frame), centred on it, following the
## player. It starts on TRANSFORM_FX_START (the swap has already happened,
## under the cloud) and hides itself when done. False without the art.
func play_transform(from: Dictionary) -> bool:
	var sf := SpriteLib.transform_fx()
	if sf == null:
		return false
	var m := SpriteLib.transform_meta()
	var a := _art_size(from)
	var b := _art_size(data())
	var w := maxf(a.x, b.x)
	var h := maxf(a.y, b.y)
	var k := maxf(w / float(m.cover[0]), h / float(m.cover[1]))
	tfx.sprite_frames = sf
	tfx.offset = -Vector2(m.pivot[0], m.pivot[1])
	tfx.scale = Vector2.ONE * k
	tfx.position = Vector2(0, -h * 0.5)
	tfx.play("a")
	tfx.frame = mini(Tuning.TRANSFORM_FX_START, int(m.frames) - 1)
	tfx.visible = true
	return true


## Size and centre a power-up effect on the current form (its ring
## POWERUP_FX_SIZE of the form's bigger side). False without the art.
func _place_pfx(s: AnimatedSprite2D) -> bool:
	var sf := SpriteLib.powerup_fx()
	if sf == null:
		return false
	var m := SpriteLib.powerup_meta()
	var art := Vector2(data().frame) * float(data().scale)
	s.sprite_frames = sf
	s.offset = -Vector2(m.origin[0], m.origin[1])
	s.scale = Vector2.ONE * (maxf(art.x, art.y) * Tuning.POWERUP_FX_SIZE / float(m.ring))
	s.position = Vector2(0, -art.y * 0.42)
	return true


## A power-up effect once: "pickup", "activation" or "expire".
func powerup_fx(anim: String) -> bool:
	if not _place_pfx(pfx_once):
		return false
	pfx_once.play(anim)
	pfx_once.frame = 0
	pfx_once.visible = true
	return true


## The looping aura while a power-up runs; when it stops, the expire effect.
func set_power_aura(on: bool) -> void:
	if on == pfx_aura.visible:
		if on:
			_place_pfx(pfx_aura)   # (follows a shapeshift's size)
		return
	if on:
		if _place_pfx(pfx_aura):
			pfx_aura.play("aura")
			pfx_aura.visible = true
	else:
		pfx_aura.visible = false
		pfx_aura.stop()
		powerup_fx("expire")


## How big a form's art is drawn (its frame at its scale, the part the burst covers).
static func _art_size(d: Dictionary) -> Vector2:
	return Vector2(d.frame) * float(d.scale) * Tuning.TRANSFORM_FX_COVER


## The seamless running attack for the hero's `weapon`, if he's running on
## the ground and it exists: the swing for the current run phase, stepped by
## the run's own frames (_run_attack_tick). Returns false otherwise (the
## standing clip is used instead).
func run_attack_play(weapon: String) -> bool:
	if dead or swimming or low != Low.NONE or not on_ground or sprite.animation != "run" or form != Forms.ROK:
		return false
	var hero := String(data().id)
	var sf := SpriteLib.running_attack(hero, weapon)
	if sf == null:
		return false
	react_stop()
	var m: Dictionary = SpriteLib.running_meta(hero)[weapon]
	atk.stop()
	atk.sprite_frames = sf
	atk.offset = -Vector2(m.pivot[0], m.pivot[1])
	run_attack_phase = sprite.frame
	_run_attack_n = 0
	atk.animation = "p%d" % run_attack_phase
	atk.frame = 0
	attack_clip = "run_attack_" + weapon
	atk.visible = true
	sprite.visible = false
	return true


## Seconds until the running attack's frame `i` (from now), at the run's clock.
func run_attack_wait(i: int) -> float:
	if run_attack_phase < 0:
		return 0.0
	var t := 0.0
	for k in range(_run_attack_n, i):
		t += sprite.sprite_frames.get_frame_duration("run", (run_attack_phase + k) % 8) / 1000.0
	return t / maxf(sprite.speed_scale, 0.01)


func _run_attack_tick() -> void:
	if run_attack_phase < 0:
		return
	if sprite.animation != "run":
		attack_stop()   # jumped, slid, fell...
		return
	_run_attack_n += 1
	if _run_attack_n >= 8:
		attack_stop()   # the run is back at the phase it started from
	else:
		atk.frame = _run_attack_n


## The hero's run carries `weapon` drawn in (SpriteLib.carry_frames), or the
## plain run with "" (GearLayer draws the weapon then). Keeps the animation.
func set_carry(weapon: String) -> void:
	if form != Forms.ROK or not SpriteLib.running_meta(String(data().id)).has(weapon):
		weapon = ""
	if weapon == carry:
		return
	carry = weapon
	var anim := sprite.animation
	var fr := sprite.frame
	var prog := sprite.frame_progress
	sprite.sprite_frames = SpriteLib.carry_frames(form, weapon)
	sprite.play(anim)
	sprite.set_frame_and_progress(fr, prog)
	gear.baked_run = weapon != ""


func attack_stop() -> void:
	if attack_clip == "":
		return
	attack_clip = ""
	run_attack_phase = -1
	atk.stop()
	atk.visible = false
	sprite.visible = true


## Keep the attack clip in step with the body sprite (tints, the shapeshift
## pop); a slide, a dive into water or death cuts it short.
func _attack_step() -> void:
	if attack_clip == "":
		return
	if dead or swimming or low != Low.NONE or (run_attack_phase >= 0 and not on_ground):
		attack_stop()
		return
	atk.scale = sprite.scale
	atk.rotation = sprite.rotation
	atk.modulate = sprite.modulate
	atk.self_modulate = sprite.self_modulate


func react_stop() -> void:
	react_kind = ""
	react.stop()
	react.visible = false
	sprite.visible = true


func _on_react_finished() -> void:
	var a := react.animation
	if a.ends_with("_enter"):
		react.play(react_kind)   # the held loop
	else:
		react_stop()   # trip or recovery done


## Keep the reaction sprite in step with the main one (tints, wobble, the
## shapeshift pop) and end the held loop when its time is up. Jumping,
## sliding or leaving the ground cancels a reaction at once.
func _react_step(delta: float) -> void:
	if react_kind == "":
		return
	if dead or not on_ground or low != Low.NONE or swimming:
		react_stop()
		return
	react.scale = sprite.scale
	react.rotation = sprite.rotation
	react.modulate = sprite.modulate
	react.self_modulate = sprite.self_modulate
	if react.animation == react_kind and react_kind != "trip":
		_react_hold -= delta
		if _react_hold <= 0.0:
			react.play(react_kind + "_exit")


func data() -> Dictionary:
	return Forms.get_data(form)


func flies() -> bool:
	return data().get("flies", false)


func _apply_form(f: int) -> void:
	var was_flying := flies() and not on_ground
	if swimming:
		swimming = false
	form = f
	var d := data()
	sprite.sprite_frames = SpriteLib.character(f)
	carry = ""   # (set_carry puts a carry run back for this form)
	sprite.offset = -d.pivot
	sprite.scale = Vector2.ONE * d.scale
	gear.hero = String(d.id) if f == Forms.ROK else ""   # gear shows in human form only
	air_jumps_left = mini(air_jumps_left, d.air_jumps) if not on_ground else d.air_jumps
	if was_flying:
		air_jumps_left = maxi(d.air_jumps, 1)   # grace jump when flight ends mid-air
	_takeoff_t = 0.0


## Re-apply the current form's art and data (a new hero or dinosaur was just
## equipped on it), keeping the animation that's playing.
func refresh_form() -> void:
	var anim := sprite.animation
	_apply_form(form)
	armor = data().armor
	sprite.play(anim if sprite.sprite_frames.has_animation(anim) else "run")


func shift_to(f: int) -> void:
	if f == form:
		return
	react_stop()
	attack_stop()
	var anim := sprite.animation
	_apply_form(f)
	armor = data().armor
	var fr := sprite.frame
	_celebrating = false
	if anim == "celebrate":
		anim = "run" if on_ground else "jump"
	if not on_ground and flies():
		anim = "glide"
	elif not on_ground and (anim == "fly" or anim == "glide" or anim == "takeoff"):
		anim = "jump"
	elif on_ground and anim == "land":
		anim = "run"
	sprite.play(anim if sprite.sprite_frames.has_animation(anim) else "run")
	if anim == "jump" and not on_ground:
		sprite.pause()
	if low != Low.NONE and low != Low.DUCK:
		sprite.pause()   # slide frames are driven by _update_low
		sprite.frame = fr
	# squash-and-stretch pop + flash
	sprite.scale = Vector2(data().scale * 1.35, data().scale * 0.7)
	var t := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(sprite, "scale", Vector2.ONE * data().scale, 0.3)
	sprite.modulate = Color(2.2, 2.2, 2.2)
	create_tween().tween_property(sprite, "modulate", Color.WHITE, 0.35)
	shifted.emit(f)


## Spinosaurus in water: float at the surface with the swim animation.
func set_swimming(on: bool) -> void:
	if on == swimming:
		return
	swimming = on
	if on:
		_end_low()
		sprite.play("swim")
		sprite.offset = -Vector2(112, 105)   # waterline anchor of the swim frames
	else:
		sprite.offset = -data().pivot
		sprite.play("run")


func is_low() -> bool:
	if low == Low.NONE:
		return false
	if low == Low.RECOVER and sprite.frame >= 7:
		return false
	return true


func hitbox() -> Rect2:
	var d := data()
	if flies() and not on_ground:
		var fb: Vector2 = d.fly_box * d.scale
		var cx: float = position.x + d.fly_offset_x * d.scale
		return Rect2(cx - fb.x * 0.5, position.y - d.fly_box_bottom * d.scale - fb.y, fb.x, fb.y)
	var box: Vector2 = d.hitbox
	if is_low():
		box = d.duck_box if low == Low.DUCK else d.slide_box
	return box_at(box)


func standing_hitbox() -> Rect2:
	return box_at(data().hitbox)


func box_at(box: Vector2) -> Rect2:
	var hb: Vector2 = box * data().scale
	var cx: float = position.x + data().get("box_offset_x", 0.0) * data().scale
	return Rect2(cx - hb.x * 0.5, position.y - hb.y, hb.x, hb.y)


# ------------------------------------------------------------ slide / duck

func press_slide() -> void:
	_slide_held = true
	if dead:
		return
	if on_ground:
		_start_slide()
	else:
		vy = maxf(vy, Tuning.FAST_FALL_SPEED)   # slam down, slide on landing
		_slide_buffer = Tuning.JUMP_BUFFER * 2.5


func release_slide() -> void:
	_slide_held = false


func _start_slide() -> void:
	if low == Low.ENTER or low == Low.GLIDE or low == Low.DUCK:
		return
	if slide_cd > 0.0:   # still cooling down: a press just before it's ready slides the moment it is
		if slide_cd <= Tuning.SLIDE_BUFFER:
			_slide_buffer = slide_cd + 0.05
		return
	# the cooldown runs from the press (shorter with more Speed)
	slide_cd = Tuning.SLIDE_COOLDOWN * Dinos.cooldown_mult(String(data().id), "speed")
	slide_cd_max = slide_cd
	low = Low.ENTER
	_low_t = 0.0
	_slide_total = 0.0
	_slide_buffer = 0.0
	sprite.play("slide")
	sprite.pause()
	sprite.frame = 0
	slid.emit()


func _can_stand() -> bool:
	return headroom_clear.is_null() or headroom_clear.call()


func _update_low(delta: float) -> void:
	_low_t += delta
	_slide_total += delta
	match low:
		Low.ENTER:
			sprite.frame = 0 if _low_t < 0.08 else 1
			if _low_t >= 0.16:
				low = Low.GLIDE
				_low_t = 0.0
		Low.GLIDE:
			var c := fmod(_low_t, 0.46)   # frames 2-4 repeat while gliding
			sprite.frame = 2 if c < 0.1 else (3 if c < 0.28 else 4)
			# one press = one slide of SLIDE_MIN; holding doesn't stretch it
			# into a duck (the user's rule). Under a ledge it keeps gliding
			# until there is headroom.
			if _slide_total >= Tuning.SLIDE_MIN and _can_stand():
				low = Low.RECOVER
				_low_t = 0.0
		Low.DUCK:
			if not _slide_held and _can_stand():
				_finish_low()
				sprite.play("run")
		Low.RECOVER:
			sprite.frame = 5 if _low_t < 0.1 else (6 if _low_t < 0.2 else 7)
			if _low_t >= 0.38:
				_finish_low()
				sprite.play("run")


func _end_low() -> void:
	if low != Low.NONE:
		_finish_low()


## A slide is over (its cooldown started with the press, _start_slide).
func _finish_low() -> void:
	low = Low.NONE


func press_jump() -> void:
	_jump_held = true
	_buffer = Tuning.JUMP_BUFFER


## Letting go of JUMP early cuts the jump short (hold for higher). A release
## that comes before the buffered jump has even started (a very quick tap) is
## remembered and cut just after takeoff, so a tap is always the small hop
## (it used to give the full jump, which made holding seem to do nothing).
func release_jump() -> void:
	_jump_held = false
	if vy < 0.0 and not on_ground:
		vy *= Tuning.JUMP_CUT
	elif _buffer > 0.0:
		_cut_after = Tuning.JUMP_TAP_TIME


func _do_jump(air: bool) -> void:
	_end_low()
	if swimming:
		set_swimming(false)
	_jump_v = data().jump * (0.92 if air else 1.0) * jump_mult
	if not air and sand_grip < 1.0:
		_jump_v *= sand_grip
		air_jumps_left = 0   # scrambling out of quicksand: one weak hop only
	vy = -_jump_v
	if _cut_after >= 0.0 and _jump_held:
		_cut_after = -1.0   # pressed again and held: no cut
	on_ground = false
	_coyote = 0.0
	_buffer = 0.0
	_celebrating = false
	if flies():
		sprite.play("takeoff")
		_takeoff_t = 0.84
	elif celebrate_t > 0.0 and not air and sprite.sprite_frames.has_animation("celebrate"):
		# a new best: this jump is the hero's celebration (launch .. land)
		celebrate_t = 0.0
		_celebrating = true
		sprite.play("celebrate")
		sprite.pause()
		sprite.frame = int(SpriteLib.celebrate_meta(data().id).get("launch", 2))
	else:
		sprite.play("jump")
		sprite.pause()
	jumped.emit(air)


## A new run: no slide, slide cooldown or attack clip carried over.
func reset_actions() -> void:
	_end_low()
	slide_cd = 0.0
	_slide_buffer = 0.0
	_slide_held = false
	attack_stop()
	body.scale = Vector2.ONE


## A new run: forget any celebration in progress.
func reset_celebration() -> void:
	celebrate_t = 0.0
	_celebrating = false


## support_y: highest surface under the player this frame (ground or platform).
func step(delta: float, support_y: float, world_speed: float) -> void:
	_react_step(delta)
	if dead:
		# Mario-style: freeze on the hit, then hop up and fall off the screen
		if _death_freeze > 0.0:
			_death_freeze -= delta
			if _death_freeze <= 0.0:
				vy = -Tuning.DEATH_HOP
				sprite.play("hop")
			return
		vy += Tuning.GRAVITY * 0.85 * delta
		position.y += vy * delta
		return
	invuln = maxf(invuln - delta, 0.0)
	celebrate_t = maxf(celebrate_t - delta, 0.0)
	_buffer = maxf(_buffer - delta, 0.0)
	_slide_buffer = maxf(_slide_buffer - delta, 0.0)
	if slide_cd > 0.0:
		slide_cd = maxf(slide_cd - delta, 0.0)
		if slide_cd == 0.0 and on_ground and not dead and low == Low.NONE and _slide_buffer > 0.0:
			_start_slide()   # pressed just before it was ready
	_coyote = maxf(_coyote - delta, 0.0)

	jump_cd = maxf(jump_cd - delta, 0.0)
	if _buffer > 0.0:
		if (on_ground or _coyote > 0.0) and jump_cd > 0.0:
			_buffer = maxf(_buffer, jump_cd + 0.02)   # still cooling down: jump the moment it's ready
		elif on_ground or _coyote > 0.0:
			_do_jump(false)
		elif air_jumps_left > 0:
			air_jumps_left -= 1
			_do_jump(true)

	if _cut_after >= 0.0:
		if on_ground and _buffer <= 0.0:
			_cut_after = -1.0   # the tap never became a jump
		elif not on_ground:
			_cut_after -= delta
			if _cut_after <= 0.0:
				_cut_after = -1.0
				if vy < 0.0 and not _jump_held:
					vy *= Tuning.JUMP_CUT
	if not on_ground:
		var prev_vy := vy
		if flies():
			_fly(delta)
		else:
			vy += Tuning.GRAVITY * delta
		position.y += vy * delta
		if flies() and position.y < Tuning.FLY_CEILING:
			position.y = Tuning.FLY_CEILING
			vy = maxf(vy, 0.0)
		if vy >= 0.0 and position.y >= support_y:
			position.y = support_y
			on_ground = true
			air_jumps_left = data().air_jumps
			jump_cd = Tuning.JUMP_COOLDOWN * Dinos.cooldown_mult(String(data().id), "jump")   # the next ground jump waits a moment
			jump_cd_max = jump_cd
			landed.emit(prev_vy > 900.0)
			if _celebrating and sprite.sprite_frames.has_animation("celebrate"):
				_celebrating = false
				sprite.play("celebrate")   # land and recover, then back to running
				sprite.frame = int(SpriteLib.celebrate_meta(data().id).get("land", 6))
			else:
				_celebrating = false
				sprite.play("land" if flies() else "run")
			if flies():
				sprite.speed_scale = 2.0
			if _slide_buffer > 0.0:
				_start_slide()   # pressed in the air: slide on landing
		elif _celebrating:
			_update_celebrate_frame()
		elif not flies():
			_update_jump_frame()
	else:
		if support_y > position.y + Tuning.GROUND_SNAP:
			# ran off a ledge, platform edge or into a pit
			on_ground = false
			_end_low()
			_coyote = Tuning.COYOTE_TIME
			vy = 0.0
			_jump_v = data().jump
			if flies():
				sprite.play("glide")
			else:
				sprite.play("jump")
				sprite.pause()
		else:
			position.y = support_y
			if low != Low.NONE:
				sprite.speed_scale = 1.0
				_update_low(delta)
			elif swimming or ((sprite.animation == "land" or sprite.animation == "celebrate") and sprite.is_playing()):
				pass   # swimming / letting the Pteranodon fold its wings first
			else:
				if sprite.animation != "run":
					sprite.play("run")
				sprite.speed_scale = clampf(world_speed / Tuning.START_SPEED, 0.8, 1.9)

	# shadow sits on whatever surface is below
	shadow.visible = support_y < Tuning.VIEW_H
	shadow.position.y = support_y - position.y
	var h := clampf(1.0 - (support_y - position.y) / 400.0, 0.3, 1.0)
	shadow.scale = Vector2(h, h) * data().scale
	var shown := invuln <= 0.0 or fmod(invuln, 0.12) < 0.07
	_attack_step()
	sprite.visible = shown and attack_clip == "" and react_kind == ""
	atk.visible = shown and attack_clip != ""
	# squash while low so the crouch reads clearly (the drawn poses are tall)
	var target_y: float = data().low_squash if low != Low.NONE else 1.0
	body.scale.y = lerpf(body.scale.y, target_y, minf(delta * 18.0, 1.0))


## Pteranodon in the air: hold JUMP to flap upward, release to glide down.
func _fly(delta: float) -> void:
	_takeoff_t = maxf(_takeoff_t - delta, 0.0)
	if _jump_held:
		vy = move_toward(vy, -Tuning.FLY_RISE, Tuning.FLY_ACCEL * delta)
	elif vy < Tuning.GLIDE_FALL:
		vy = move_toward(vy, Tuning.GLIDE_FALL, Tuning.GRAVITY * 0.6 * delta)
	else:
		vy = move_toward(vy, Tuning.GLIDE_FALL, Tuning.GRAVITY * 2.0 * delta)  # ease out of a dive
	if _takeoff_t > 0.0:
		return
	var want := "fly" if _jump_held or vy < -60.0 else "glide"
	if sprite.animation != want:
		sprite.play(want)
	sprite.speed_scale = 1.0


## The celebration's airborne frames (launch .. just before landing) follow
## the jump's vertical velocity, like the normal jump frames.
func _update_celebrate_frame() -> void:
	var m := SpriteLib.celebrate_meta(data().id)
	var first := int(m.get("launch", 2))
	var last := int(m.get("land", 6)) - 1
	var p := clampf((_jump_v + vy) / (2.0 * _jump_v), 0.0, 1.0) if _jump_v > 0.0 else 0.0
	sprite.frame = first + int(round(p * (last - first)))


func _update_jump_frame() -> void:
	if _jump_v <= 0.0:
		_jump_v = data().jump
	# map vertical velocity to frames 1..6 (takeoff .. descent)
	var p := clampf((_jump_v + vy) / (2.0 * _jump_v), 0.0, 1.0)
	sprite.frame = 1 + int(round(p * 5.0))


func die() -> void:
	react_stop()
	attack_stop()
	dead = true
	swimming = false
	_end_low()
	vy = 0.0
	_death_freeze = Tuning.DEATH_FREEZE
	body.scale = Vector2.ONE
	body.position = Vector2.ZERO
	sprite.scale = Vector2.ONE   # death frames are already at the form's on-screen size
	sprite.sprite_frames = SpriteLib.death(form)
	sprite.offset = -SpriteLib.death_pivot(form)
	sprite.speed_scale = 1.0
	sprite.play("die")
	sprite.modulate = Color(1.3, 1.3, 1.3)
	create_tween().tween_property(sprite, "modulate", Color.WHITE, 0.3)
	shadow.visible = false
	z_index = 60   # in front of everything while it falls away


func idle() -> void:
	sprite.play("idle")
	sprite.speed_scale = 1.0
