class_name TutorialRun
extends RefCounted
## The training run (the user's request): a short scripted first run that
## teaches the controls one at a time. main starts it (main.start_tutorial) on
## a fresh save's first tap, or from the main menu's "?" button.
##
## Each step spawns one thing ahead of Rok. When it's at the right distance
## the world FREEZES (main skips _play_step; Rok and the hunter hold their
## pose) and a coach ring sits on the button to press, with a few words. That
## press un-freezes the world at exactly the moment it works. A miss (Rok gets
## hit) just repeats the step ("Try again!"). Nothing costs hearts and the
## hunter can't catch up. Random hazards are held off, the ground stays flat,
## and the Raptor is lent for its step only. Stop skips the whole run.
##
## Nothing moves on by itself (the user's rule): each step opens with a note
## (its title and hint, frozen, until a tap), and the HUD is explained along
## the way the same way ("notes": the coach points at one part of the screen).
## Notes have Next and Back chips; any tap is Next, Back returns to the
## previous note of the same group. Explained: hearts, the
## hunter meter, points and distance first; the meat counter once meat is
## grabbed; the PRIMAL bar after the amber. A finished run then hands over to
## the menu tour (menu_tour.gd: Marketplace, Camp, Encyclopedia).
##
## Steps (STEPS): jump a rock, hold JUMP over a log, double-jump a wall, slide
## under a ledge, ATTACK a rock, an egg and its slot, become the Raptor for its
## crumbling bridge and back to Rok, amber (it only exists once a dinosaur is
## unlocked: config/requirements.cfg), then a card about the Market,
## Camp and Encyclopedia. Afterwards coach hints (tutorial.gd) cover the rest.

## Per step: what to spawn, the button, the trigger distance (px from Rok's
## hitbox to the thing), and the words. "card" is [title, line] shown at the
## moment to act (a big card at the top, after the user's mockups; [WORD] is
## highlighted); "air" the double jump's mid-air card, "back" the card for
## turning back into Rok; "arc" draws the move ("jump", "high", "slide").
## "intro" steps first show a note with their title and hint (they have
## something to explain or grab before any button). "notes": [HUD part,
## words] shown one at a time (Hud.coach_part), before the step's spawn when
## it has none, or once its pickup is collected.
const STEPS := [
	{"id": "hud", "intro": true, "title": "YOUR SCREEN", "hint": "A quick look around before the T-rex catches up.",
		"notes": [["hearts", "Your [HEARTS]. Crashing into things costs\none. Lose them all and the run ends."],
			["chase", "The [HUNTER] behind you. Stumbles let it\ncatch up. If it reaches Rok, you're caught!"],
			["score", "Your [POINTS]. Clear hazards and\ngrab things to score more."],
			["distance", "How [FAR] you've run, and the zone.\nRun farther to unlock new dinosaurs."]]},
	{"id": "jump", "spawn": "small", "button": "jump", "at": 70.0, "arc": "jump",
		"card": ["JUMP THE ROCK", "Tap [JUMP] to clear the obstacle."]},
	# (a held jump stays above a log ~0.6 s, ~230 px at START_SPEED: 60 px out
	# centres that window on this log; 150 px landed Rok on it)
	{"id": "high_jump", "spawn": "log", "button": "jump", "at": 60.0, "hold": true, "arc": "high",
		"card": ["JUMP HIGHER!", "Hold [JUMP] longer to leap over the log."]},
	{"id": "double_jump", "spawn": "wall", "button": "jump", "at": 140.0, "arc": "high",
		"card": ["TALL WALL!", "Tap [JUMP] to start your leap..."],
		"air": ["JUMP AGAIN!", "Tap [JUMP] again in mid-air!"]},
	{"id": "slide", "spawn": "ledge", "button": "slide", "at": 110.0, "arc": "slide",
		"card": ["STAY LOW!", "Tap [SLIDE] to duck under branches."]},
	{"id": "attack", "spawn": "small", "button": "attack", "at": 60.0,
		"card": ["SMASH THROUGH!", "Tap [ATTACK] to break small obstacles."]},
	{"id": "meat", "intro": true, "spawn": "meat", "title": "GRAB THE MEAT", "hint": "Meat is your money. Run through it!",
		"notes": [["meat", "[MEAT] you collected this run. Spend it\nin the MARKETPLACE after the run."]]},
	{"id": "booster", "intro": true, "spawn": "egg", "button": "slot_0", "title": "POWER-UPS", "hint": "Grab the Dino Egg. It waits in a slot until you use it.",
		"card": ["USE YOUR POWER-UP", "Tap the [EGG] slot for a burst of speed."]},
	{"id": "shift", "spawn": "raptor_gate", "button": "form_1", "at": 520.0,
		"card": ["BECOME THE RAPTOR", "Tap the [RAPTOR] to cross the crumbling bridge."],
		"back": ["BACK TO ROK", "Tap [ROK] to save your PRIMAL energy."]},
	{"id": "amber", "intro": true, "spawn": "amber", "title": "GRAB THE AMBER", "hint": "Dinosaurs use PRIMAL energy. Amber fills it back up.",
		"notes": [["primal", "[PRIMAL] energy. Dinosaurs use it up and\namber fills it. Empty means back to Rok."]]},
	{"id": "finish"},
]

const STEP_PAUSE := 1.2   # s of plain running between steps
const NOTE_MIN := 0.45    # s a note stays before a tap moves on (so a stray tap doesn't skip it)
const MIN_HOLD := 0.2     # s every jump here counts as held (a 0.07 s tap is too small a hop to clear a rock)

var game                  # main.gd
var i := 0                # current step
var phase := "start"      # start, approach, frozen, air, after, back, done
var frozen := false
var thing: Node2D         # the spawned obstacle (or gate marker)
var hit := false          # Rok got hit during this step (it repeats)
var _wait := 0.0
var _taught: Array = []   # coach lessons this run taught (marked learned at the end)
var hold_left := 0.0      # MIN_HOLD still to run after a jump press
var release_pending := false   # the player let go during it (main._release_jump)
var note_i := 0           # which note is showing (phase "note")
var note_list: Array = [] # the notes now: [HUD part or "", title, text]
var note_after := ""      # when they're done: "spawn" (the step's thing) or "advance" (next step)
var _note_t := 0.0
var _intro_done := -1     # step whose intro note was shown (a retry skips it)
var tap_grace := 0.0      # s after a note closes when a stray screen tap isn't a jump (main._touch_pressed)
var _meat: Array = []     # the meat step's pieces


func _init(main_node, start_step := 0) -> void:
	game = main_node
	i = start_step
	_wait = 1.0   # a moment of running first


func step_data() -> Dictionary:
	return STEPS[i]


## Every frame of the training run (also while frozen).
func step(delta: float) -> void:
	var g = game
	g.health = g.max_health()            # nothing costs hearts here
	g.chase_gap = Tuning.CHASE_GAP_MAX   # and the hunter can't catch up
	g.speed = Tuning.START_SPEED
	g.course.holding = true              # no random hazards
	g.course.starter_egg = false
	g.terrain.calm = true                # flat ground only
	if String(step_data().id) == "shift":
		g.energy = maxf(g.energy, 60.0)  # the lent Raptor mustn't tire out on its bridge
	if hold_left > 0.0:
		hold_left -= delta
		if hold_left <= 0.0 and release_pending:
			release_pending = false
			g.player.release_jump()
	if g.player.invuln > 0.0 and phase in ["approach", "air", "after"]:
		hit = true
	var s := step_data()
	_note_t += delta
	tap_grace = maxf(tap_grace - delta, 0.0)
	match phase:
		"start":
			_wait -= delta
			if _wait > 0.0:
				return
			if s.id == "finish":
				g.queue_info("YOU'RE READY!", "Run as far as you can. Collect meat and spend it in the MARKETPLACE. " \
						+ "Level up and equip your dinosaurs at the CAMP. Learn about everything you meet in the ENCYCLOPEDIA.\n\n" \
						+ "New dinosaurs join you the farther you run. Good luck!", SpriteLib.tex("res://assets/portraits/rok.png"), Color(1.0, 0.8, 0.35))
				phase = "done"
				return
			hit = false
			var notes := []
			if _intro_done != i and s.get("intro", false):
				_intro_done = i
				notes.append(["", String(s.title), String(s.hint)])   # the step's intro, until a tap
			if not s.has("spawn") and s.has("notes"):
				notes.append_array(s.notes)   # nothing to dodge: just the notes
			if not notes.is_empty():
				_start_notes(notes, "spawn" if s.has("spawn") else "advance")
				return
			thing = _spawn(s)
			phase = "approach"
		"approach":
			if s.id == "amber":
				if thing == null or not is_instance_valid(thing) or not g.course.pickups.has(thing) or thing.position.x < Tuning.PLAYER_X - 200.0:
					_start_notes(s.notes, "advance")   # collected (or passed): what the PRIMAL bar is
				return
			if s.id == "meat":
				# wait until every piece is grabbed or behind Rok (freezing on the
				# first one, with the rest right ahead, looked broken)
				var left := _meat.filter(func(k): return is_instance_valid(k) and g.course.pickups.has(k) and k.position.x > Tuning.PLAYER_X - 60.0)
				if not left.is_empty():
					return
				if g.run_meat > 0:
					_start_notes(s.notes, "advance")   # the counter has something to point at
				else:
					_repeat()   # missed them all
				return
			if s.id == "booster":
				if g.slots[0] != "":
					_freeze(s.button, s.card)
				elif thing == null or not is_instance_valid(thing) or (g.course.pickups.has(thing) and thing.position.x < Tuning.PLAYER_X - 150.0):
					_repeat()   # missed the egg
				return
			if s.id == "shift":
				var mk = _gate_marker()
				if mk != null and Course.gate_x0(mk) - Tuning.PLAYER_X <= float(s.at):
					thing = mk
					_freeze(s.button, s.card)
				return
			if not _alive(thing):
				return
			if _ahead(thing) <= float(s.at) and g.player.on_ground:
				_freeze(s.button, s.card)
		"frozen", "note":
			pass   # waiting for the press (pressed() / note_tap())
		"air":
			if g.player.vy >= -60.0 and not g.player.on_ground:
				_freeze(s.button, s.air, "air")
			elif g.player.on_ground:
				phase = "after"
		"after":
			if s.id == "booster":
				_wait -= delta
				if _wait <= 0.0:
					_next()
				return
			if s.id == "shift":
				# the whole bridge behind Rok (turning back mid-bridge would drop him in)
				if thing == null or not is_instance_valid(thing) or not g.course.markers.has(thing) \
						or Course.gate_x0(thing) + g.terrain.gate_width() < Tuning.PLAYER_X - 120.0:
					phase = "back"
					_freeze("form_0", s.back, "")
				return
			if not _alive(thing) or thing.hitbox().end.x < g.player.hitbox().position.x - 10.0:
				if hit:
					_repeat()   # hurt (even if the crash broke the thing): try again
				else:
					_next()
		"done":
			if g.state == g.State.PLAYING:   # the last card was tapped away
				g.end_tutorial(false)


## main calls this when the player presses a button; true if it was the one
## the frozen step wanted (the world then moves again).
func pressed(action: String) -> bool:
	if not frozen:
		return false
	var s := step_data()
	var want: String = "form_0" if phase == "back" else String(s.get("button", ""))
	if action != want:
		return false
	_unfreeze()
	if action == "jump":
		hold_left = MIN_HOLD
		release_pending = false
	_taught.append(String(s.id))
	if phase == "back":
		_taught.append("energy")
		phase = "start"
		_advance()
		return true
	if s.has("air") and game.player.on_ground:
		phase = "air"   # now the mid-air tap
	elif s.id == "booster":
		_wait = 1.2
		phase = "after"
	else:
		phase = "after"
	return true


## Freeze on the first of `notes` ([HUD part or "", (title,) text]); after
## the last, `after`: "spawn" the step's thing, or "advance" to the next step.
func _start_notes(notes: Array, after: String) -> void:
	note_list = notes.map(func(n): return n if n.size() == 3 else [n[0], "", n[1]])
	note_after = after
	note_i = 0
	_freeze_world()
	game.hud.clear_banner()   # a banner would sit under the note's bubble
	phase = "note"
	_show_note()


func _show_note() -> void:
	var n: Array = note_list[note_i]
	_note_t = 0.0
	game.hud.coach_note(String(n[0]), String(n[1]), String(n[2]), (["back"] if note_i > 0 else []) + ["next"])


## Next (the chip, or a tap anywhere): the next note, or on with the run.
func note_tap() -> void:
	if phase != "note" or _note_t < NOTE_MIN:
		return
	note_i += 1
	if note_i < note_list.size():
		_show_note()
		return
	_unfreeze()
	tap_grace = 0.35   # a quick second tap shouldn't make Rok jump
	if note_after == "spawn":
		thing = _spawn(step_data())
		phase = "approach"
		return
	_taught.append(String(step_data().id))
	_advance()


## Back: the previous note of this group (nothing before the first).
func note_back() -> void:
	if phase != "note" or note_i == 0:
		return
	note_i -= 1
	_show_note()


func _freeze_world() -> void:
	frozen = true
	game.player.sprite.pause()
	game.trex.process_mode = Node.PROCESS_MODE_DISABLED


## Freeze on the moment to act: the card ([title, line]) at the top, the
## button glowing, and the move drawn (`arc_kind`: the step's "arc", or "air"
## for the double jump's second hop, "" for none).
func _freeze(button: String, card: Array, arc_kind := "step") -> void:
	frozen = true
	if phase != "back":
		phase = "frozen"
	var g = game
	g.player.sprite.pause()
	g.trex.process_mode = Node.PROCESS_MODE_DISABLED
	var kind: String = String(step_data().get("arc", "")) if arc_kind == "step" else arc_kind
	g.hud.coach_card(button, String(card[0]), String(card[1]), _arc(kind))


## The dashed path for a move, in screen points: a hop from Rok over the
## thing (higher for "high"), a low dash under it ("slide"), or from Rok in
## mid-air on over it ("air"). Empty if there's nothing to draw.
func _arc(kind: String) -> PackedVector2Array:
	var pts := PackedVector2Array()
	if kind == "" or not _alive(thing):
		return pts
	var hb: Rect2 = game.player.hitbox()
	var ob: Rect2 = thing.hitbox()
	var ground: float = game.player.position.y
	var a := Vector2(hb.end.x + 4.0, ground - 34.0)   # from Rok's front knee...
	var b := Vector2(ob.end.x + 56.0, ground - 14.0)   # ...arching well over the thing to land past it
	if kind == "slide":
		var y := ground - 22.0
		pts.append(Vector2(hb.end.x + 10.0, y))
		pts.append(Vector2(ob.end.x + 60.0, y))
		return pts
	var top := ob.position.y - (130.0 if kind == "high" else 95.0)
	if kind == "air":
		a = Vector2(hb.end.x + 6.0, hb.get_center().y)
		top = minf(a.y, ob.position.y) - 50.0
	for k in 15:   # a parabola from a to b peaking at `top`
		var t := k / 14.0
		var x := lerpf(a.x, b.x, t)
		var base := lerpf(a.y, b.y, t)
		var lift := 4.0 * t * (1.0 - t) * (minf(a.y, b.y) - top)
		pts.append(Vector2(x, base - lift))
	return pts


func _unfreeze() -> void:
	frozen = false
	var g = game
	g.player.sprite.play()
	g.trex.process_mode = Node.PROCESS_MODE_INHERIT
	g.hud.hide_coach()


func _next() -> void:
	_advance()


func _advance() -> void:
	i = mini(i + 1, STEPS.size() - 1)
	phase = "start"
	_wait = STEP_PAUSE
	thing = null


## Rok was hit (or missed the egg): the same step again.
func _repeat() -> void:
	game.hud.show_banner("TRY AGAIN!", "Wait for the hint, then tap.", Color(1.0, 0.7, 0.5), 1.6)
	phase = "start"
	_wait = STEP_PAUSE
	if _alive(thing):
		game.course.remove_obstacle(thing)
	thing = null


func _alive(n) -> bool:
	return n != null and is_instance_valid(n) and n is Obstacle and game.course.obstacles.has(n)


func _ahead(o: Obstacle) -> float:
	return o.hitbox().position.x - game.player.hitbox().end.x


func _gate_marker():
	for m in game.course.markers:
		if is_instance_valid(m) and m.get_meta("form", -1) == Forms.RAPTOR:
			return m
	return null


func _spawn(s: Dictionary):
	var g = game
	var c: Course = g.course
	var x: float = c.view_width() + 160.0
	c._ground = g.terrain.height_at(x) if g.terrain.height_at(x) < Terrain.PIT else Tuning.GROUND_Y
	match String(s.spawn):
		"small":
			return c._obstacle("small", ["Stones_02"], 1.3, x)   # always the same rock (random ones vary in size)
		"log":
			return c._obstacle("wood", ["Logs_01"], 1.0, x)   # always the short log (114 px of hitbox; Logs_03/04 are ~162 and a held jump lands on their far end)
		"wall":
			return c.rock_wall(x, 2)
		"ledge":
			return c.ledge(x)
		"amber":
			for k in 5:
				var t := k / 4.0
				c._pickup("amber", Vector2(x + k * 70.0, c._ground - 90.0 - sin(t * PI) * 60.0))
			return c.pickups[-1]
		"egg":
			c._pickup("egg", Vector2(x, c._ground - 70.0))
			return c.pickups[-1]
		"meat":
			_meat = []
			for k in 3:
				c._pickup("meat", Vector2(x + k * 70.0, c._ground - 60.0))
				_meat.append(c.pickups[-1])
			return c.pickups[-1]
		"raptor_gate":
			if not g.unlocked.has(Forms.RAPTOR):
				g.unlocked.append(Forms.RAPTOR)   # lent for this step (end_tutorial takes it back)
				g.lent_raptor = true
			g.energy = 100.0
			c.force_gate("gate_raptor")
			return null
	return null


## Lessons this run taught (the coach won't repeat them).
func taught() -> Array:
	return _taught.duplicate()
