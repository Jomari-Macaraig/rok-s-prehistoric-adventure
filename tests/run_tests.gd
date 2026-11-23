extends SceneTree
## Headless smoke test. Run with:
##   godot --headless --path . --fixed-fps 60 -s tests/run_tests.gd

const RUN_SECONDS := 120

var main
var bot: Autopilot
var frame := 0
var failures: Array[String] = []
var runs := 0
var max_score := 0
var smashes := 0
var obstacles_seen := {}
var forms_used := {}
var landed_on_platform := false
var pits_met := 0
var heights := {}
var deaths: Array[String] = []


func check(cond: bool, msg: String) -> void:
	if not cond:
		failures.append(msg)


const TEST_SAVE := "user://test_rok_runner.cfg"
# runs jump ahead to cover every stage (past pits, ledges and the first dino traps)
var BOT_START_M := [Progression.intro_m("boulder") + 80.0, Progression.intro_m("steam") + 20.0,
		Progression.intro_m("wall") + 300.0, Progression.intro_m("tall_fence") + 150.0]


func _initialize() -> void:
	SaveData.path = TEST_SAVE   # never touch the player's real save
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE))
	# headless windows are tiny squares: with the project's "expand" aspect the
	# view would be 1280 x 1280, so the tests keep the height fixed at 720
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP_HEIGHT
	main = load("res://main.tscn").instantiate()
	main.pause_for_info = false   # info cards would wait for a tap
	root.add_child(main)
	main.roll_override = 0.999   # Power rolls never break through, unless a check says otherwise
	main.loot_override = 0.999   # broken obstacles drop nothing, unless a check says otherwise
	main.tutorial_run_done = true   # every check but _training_run_checks starts normal runs


func _process(_delta: float) -> bool:
	frame += 1
	if frame == 2:
		main.tutorial_run_done = SaveData.load_tutorial_run_done()   # a fresh save: false
		_training_run_checks()   # (before anything else plays: it needs a fresh save)
		main.tutorial_run_done = true
	if frame == 3:
		_unit_checks()
		_config_checks()
		_progression_checks()
		_guide_checks()
		_market_checks()
		_species_checks()
		_fun_checks()
		_intro_checks()
		_death_checks()
		_info_checks()
		_zone_checks()
		_trap_checks()
		_combo_checks()
		_milestone_checks()
		_variety_checks()
		_feedback_checks()
		_animation_pack_checks()
		_hill_chase_checks()
		_guide_scroll_check()
		main.start_run(false)
		check(main.unlocked == [Forms.ROK], "fresh save: only Rok unlocked")
		main.distance = (Progression.UNLOCKS[Forms.RAPTOR] + 10.0) * Tuning.PX_PER_M
	if frame == 4:
		_banner_checks()
		check(main.unlocked.has(Forms.RAPTOR), "Raptor unlocks at its distance")
		check(SaveData.load_unlocked().has(Forms.RAPTOR), "unlock is saved")
		check(not main.unlocked.has(Forms.TRICERATOPS), "Triceratops still locked just past the Raptor unlock")
		check(main.course.holding and (main.course.forced_gate == "gate_raptor" or main.terrain.pending_gate == "gate_raptor"),
				"Raptor unlock makes the crumbling bridge come next")
		main._request_form(Forms.TRICERATOPS)
		check(main.player.form != Forms.TRICERATOPS, "locked form can't be used")
		check(Progression.eligible_gates(9999.0, [Forms.ROK]).is_empty(), "no dino gates before any dino is unlocked")
		_unlock_gate_checks()
		main.unlocked = Forms.ORDER.duplicate()   # the rest of the tests use every form
		_gate_checks()
	if frame >= 5 and frame < 40:
		_touch_checks()
		return false
	if frame >= 40 and frame < 200:
		_flight_checks()
		return false
	if frame == 200:
		main.start_run(false)
		main.distance = BOT_START_M[0] * Tuning.PX_PER_M
		main.course.skip_intros_before(BOT_START_M[0])
		main.best_m = maxf(main.best_m, BOT_START_M[0])   # jumping ahead = having been there
		bot = Autopilot.new(main)
		runs = 1
	if bot:
		bot.tick()
		forms_used[main.player.form] = true
		for o in main.course.obstacles:
			obstacles_seen[o.kind] = true
		var np: Vector2 = main.terrain.next_pit(main.player.position.x)
		if np.x > 0.0 and np.x - main.player.position.x < 40.0 and np.x - main.player.position.x > 30.0:
			pits_met += 1
		if main.player.on_ground and main.state == main.State.PLAYING:
			heights[int(round(main.player.position.y / 32.0))] = true
			var t: float = main.terrain.height_at(main.player.position.x)
			if main.player.position.y < t - 50.0:
				landed_on_platform = true

		if main.state == main.State.OVER:
			deaths.append(main.death_cause)
			max_score = maxi(max_score, int(main.score))
			main.start_run(false)
			main.distance = BOT_START_M[runs % BOT_START_M.size()] * Tuning.PX_PER_M
			main.course.skip_intros_before(BOT_START_M[runs % BOT_START_M.size()])
			main.best_m = maxf(main.best_m, BOT_START_M[runs % BOT_START_M.size()])
			runs += 1
		max_score = maxi(max_score, int(main.score))
	if frame >= RUN_SECONDS * 60:
		_report()
		return true
	return false


func _touch(pos: Vector2, pressed: bool, index := 0) -> void:
	var e := InputEventScreenTouch.new()
	e.position = pos
	e.pressed = pressed
	e.index = index
	main._input(e)


func _center(b: TouchButton) -> Vector2:
	return b.global_position + b.size * 0.5


func _touch_checks() -> void:
	var hud: Hud = main.hud
	match frame:
		5:
			# thumb clusters: every button on screen, in a corner cluster, and
			# never over Rok's running lane
			var lane := Rect2(Tuning.PLAYER_X - 80.0, Tuning.GROUND_Y - 240.0, 200.0, 240.0)
			var vw: float = hud.root.get_viewport_rect().size.x
			# no two controls overlap, their sandstone rings included (TouchButton.FRAME_OUT)
			var ctrls: Array = hud.form_buttons.values() + [hud.jump_button, hud.slide_button, hud.attack_button] + hud.slot_buttons
			var clash := ""
			for i in ctrls.size():
				for j in range(i + 1, ctrls.size()):
					var b1: TouchButton = ctrls[i]
					var b2: TouchButton = ctrls[j]
					var r1: float = b1.radius() * (TouchButton.FRAME_OUT if b1.frame else 1.0)
					var r2: float = b2.radius() * (TouchButton.FRAME_OUT if b2.frame else 1.0)
					if (b1.global_position + b1.size * 0.5).distance_to(b2.global_position + b2.size * 0.5) < r1 + r2 + 2.0:
						clash += " %s/%s" % [b1.action, b2.action]
			check(clash == "", "no control overlaps another%s" % clash)
			for b in hud.form_buttons.values() + [hud.jump_button, hud.slide_button] + hud.slot_buttons:
				var r := Rect2(b.global_position, b.size)
				check(r.end.y <= Tuning.VIEW_H and r.position.x >= 0.0 and r.end.x <= vw, "%s button on screen" % b.action)
				check(not r.intersects(lane), "%s button clear of Rok's lane" % b.action)
				check(r.end.x < Tuning.PLAYER_X or r.position.x > vw - 330.0, "%s button in a thumb cluster" % b.action)
			check(hud.form_buttons[Forms.ROK].size.x > hud.form_buttons[Forms.RAPTOR].size.x, "Rok is the big left-thumb button")
			check(hud.jump_button.size.x > hud.slide_button.size.x, "JUMP is the big right-thumb button")
			check(hud.action_at(_center(hud.jump_button)) == "jump", "jump button hit-test")
			_touch(_center(hud.jump_button), true, 0)
		7:
			check(main.player.vy < 0.0, "touching JUMP makes Rok jump")
			# second finger taps the Triceratops while jump is still held
			_touch(_center(hud.form_buttons[Forms.TRICERATOPS]), true, 1)
		8:
			check(main.player.form == Forms.TRICERATOPS, "multitouch: form tap while holding jump")
			_touch(_center(hud.form_buttons[Forms.TRICERATOPS]), false, 1)
			_touch(_center(hud.jump_button), false, 0)
		9:
			_touch(_center(hud.pause_button), true, 2)
			_touch(_center(hud.pause_button), false, 2)
		10:
			check(main.state == main.State.PAUSED, "pause button pauses")
			_touch(Vector2(640, 300), true, 3)
			_touch(Vector2(640, 300), false, 3)
		11:
			check(main.state == main.State.PLAYING, "tap resumes")
			main.player.shift_to(Forms.ROK)
			# land him (a held jump now lasts past frame 25) so the slide check can run
			main.player.vy = 0.0
			main.player.position.y = main.terrain.height_at(main.player.position.x)
			main.player.on_ground = true
		25:
			if main.player.on_ground:
				_touch(_center(hud.slide_button), true, 4)
		27:
			check(main.player.is_low(), "SLIDE button starts a slide")
			check(main.player.hitbox().size.y < Tuning.LEDGE_CLEARANCE, "sliding hitbox is low")
			_touch(_center(hud.slide_button), false, 4)
		38:
			check(main.player.low != Player.Low.NONE or main.player.hitbox().size.y > 120.0, "slide ends after release")


var _min_y := 9999.0


func _flight_checks() -> void:
	var p: Player = main.player
	match frame:
		40:
			main.start_run(false)
			main.energy = Tuning.ENERGY_MAX
		42:
			main._request_form(Forms.PTERANODON)
			check(p.form == Forms.PTERANODON, "shift to Pteranodon")
			check(p.hitbox().size.y < 110.0, "Pteranodon fits under ledges standing")
			p.press_jump()
		45:
			check(not p.on_ground and p.sprite.animation == "takeoff", "takeoff animation on jump")
	if frame > 45 and frame < 130:
		main.energy = Tuning.ENERGY_MAX
		_min_y = minf(_min_y, p.position.y)
	match frame:
		130:
			check(_min_y >= Tuning.FLY_CEILING - 0.5, "flight stops at the ceiling")
			check(p.position.y < Tuning.GROUND_Y - 250.0, "holding JUMP climbs high (y=%.0f)" % p.position.y)
			check(p.sprite.animation == "fly", "flapping uses fly animation")
			var fb := p.hitbox()
			check(fb.size.y < 80.0 and fb.end.y < p.position.y, "flight hitbox is the torso above the origin")
			p.release_jump()
		170:
			check(not p.on_ground, "still gliding")
			check(p.vy <= Tuning.GLIDE_FALL + 1.0 and p.vy > 0.0, "glide sinks slowly (vy=%.0f)" % p.vy)
			check(p.sprite.animation == "glide", "gliding uses glide animation")
			main.energy = 0.5   # run out mid-air -> back to Rok with a grace jump
		175:
			check(p.form == Forms.ROK, "flight ends when energy runs out")
			check(p.air_jumps_left >= 1, "grace jump after flight ends mid-air")


## The Market's details for an item: its tab, picked off the shelf, shown in
## the merchant's bubble.
func _market_card(id: String) -> Control:
	main.market.show_tab(Market.category(id))
	main.market._drag_dist = 0.0
	main.market.select(id)
	return main.market.detail


func _picks(metres: float, n: int) -> Array:
	var c: Course = main.course
	c.metres = metres
	c.intro_counts.clear()
	var out := []
	for i in n:
		var k := c._next_key()
		c.intro_counts[k] = c.intro_counts.get(k, 0) + 1
		out.append(k)
	return out


func _gate_checks() -> void:
	main.start_run(false)
	var c: Course = main.course
	var p: Player = main.player
	check(Progression.eligible_gates(Progression.intro_m("gate_ptera") + 10.0, main.unlocked).size() == 4, "all four gates once every dino is unlocked")
	c._ground = Tuning.GROUND_Y
	# towering walls: no form can jump or fly over them
	var wall := c.boulder_wall(p.position.x + 700.0)
	check(wall.hitbox().position.y <= 0.0, "boulder wall reaches the top of the screen")
	var bramble := c.bramble_wall(p.position.x + 1100.0)
	check(bramble.hitbox().position.y <= 0.0, "bramble wall reaches the top of the screen")
	check("rock" in Forms.get_data(Forms.TRICERATOPS).breaks, "Triceratops smashes the boulder wall")
	check("thorns" in Forms.get_data(Forms.SPINOSAURUS).breaks, "Spinosaurus tramples thorns")
	check(not "thorns" in Forms.get_data(Forms.ROK).breaks, "Rok can't trample thorns")
	# wide canyon: wider than Raptor's best double-jump distance at that speed
	for spd in [500.0, 700.0, 900.0]:
		main.terrain.speed = spd
		var up := 1180.0 / Tuning.GRAVITY
		var top := 1180.0 * 1180.0 / (2.0 * Tuning.GRAVITY) + pow(1180.0 * 0.92, 2) / (2.0 * Tuning.GRAVITY)
		var air := up + 1180.0 * 0.92 / Tuning.GRAVITY + sqrt(2.0 * top / Tuning.GRAVITY)
		check(main.terrain.gate_width() > air * spd, "gate canyon wider than any jump at %d" % int(spd))
	# glow: a gate marker ahead lights up the matching button strongly
	wall.gate_form = Forms.TRICERATOPS
	c._gate_extras("gate_tri", wall.position.x - wall.size.x * 0.5, wall.position.x)
	check(main._glow_hint() == Vector2i(Forms.TRICERATOPS, 2), "gate ahead makes the Triceratops button glow (%s)" % str(main._glow_hint()))
	# a Spinosaurus shield doesn't get you through a gate
	p.shift_to(Forms.SPINOSAURUS)
	p.armor = 1
	wall.position.x = p.position.x + 10.0
	main._collide()
	check(main.state == main.State.DYING and main.death_cause.begins_with("gate"), "shield doesn't pass a dino gate")
	# crumbling bridges: heavy forms break them, light ones cross
	main.start_run(false)
	p = main.player
	for f in [Forms.ROK, Forms.RAPTOR, Forms.PTERANODON, Forms.TRICERATOPS]:
		var b := {"x0": 0.0, "x1": 900.0, "y": Tuning.GROUND_Y, "sturdy": false, "node": Node2D.new(), "collapsed": false}
		main.terrain.add_child(b.node)
		p.shift_to(f)
		p.on_ground = true
		p.position.y = Tuning.GROUND_Y
		main._bridge = b
		main._check_bridge()
		var light: bool = Forms.get_data(f).get("light", false)
		check(b.collapsed != light, "crumbling bridge %s under form %d" % ["holds" if light else "breaks", f])
	var sb := {"x0": 0.0, "x1": 900.0, "y": Tuning.GROUND_Y, "sturdy": true, "node": Node2D.new(), "collapsed": false}
	main.terrain.add_child(sb.node)
	p.shift_to(Forms.ROK)
	main._bridge = sb
	main._check_bridge()
	check(not sb.collapsed, "sturdy bridge holds Rok")
	main._bridge = {}
	main.start_run(false)
	# thorn bushes prick (energy) instead of ending the run
	p = main.player
	c._ground = Tuning.GROUND_Y
	c.metres = 0.0   # a Forest bush (the course may still hold the last check's distance; Volcanic has no bushes)
	main.chase_gap = Tuning.CHASE_GAP_MAX
	var bush := c.thorn_bush(p.position.x)
	main._collide()
	check(main.state == main.State.PLAYING, "a thorn bush doesn't end the run")
	check(absf(main.chase_gap - (Tuning.CHASE_GAP_MAX - Tuning.STUMBLE_THORN)) < 0.1, "a thorn bush lets the T-rex gain")
	check(p.invuln > 0.0, "brief protection after a stumble")
	# mushrooms: squashed for a dizzy debuff instead of ending the run
	main.start_run(false)
	p = main.player
	p.invuln = 0.0
	c.metres = 0.0   # in the Forest (the only zone with mushrooms)
	c._ground = Tuning.GROUND_Y
	var smalls: Array = []
	for i in 60:
		smalls.append(c.small(p.position.x + 3000.0 + i * 10.0))
	check(smalls.any(func(o): return o.mushroom) and smalls.any(func(o): return not o.mushroom), "Forest small hazards include both rocks and mushrooms")
	for o in smalls:
		c.remove_obstacle(o)
	main.chase_gap = Tuning.CHASE_GAP_MAX
	var shroom := c._obstacle("small", ["Mushrooms_02"], 1.0, p.position.x)
	shroom.mushroom = true
	main._collide()
	check(main.state == main.State.PLAYING and not c.obstacles.has(shroom), "running into a mushroom squashes it and the run goes on")
	var dizzy_text: Array = main.fx.find_children("*", "Label", true, false).filter(func(l): return l.text == "Dizzy!")
	check(not dizzy_text.is_empty() and dizzy_text[0].get_theme_color("font_color").b > dizzy_text[0].get_theme_color("font_color").g + 0.3, "the Dizzy! text is purple")
	check(main.dizzy_t == Tuning.DIZZY_TIME and absf(main.chase_gap - (Tuning.CHASE_GAP_MAX - Tuning.STUMBLE_MUSHROOM)) < 0.1, "its spores make Rok dizzy and the T-rex gains a little")
	main._dizzy_step(0.1)
	p.on_ground = true
	p._do_jump(false)
	check(absf(p.vy + p.data().jump * Tuning.DIZZY_JUMP) < 0.1, "dizzy Rok jumps lower")
	main._dizzy_step(Tuning.DIZZY_TIME)
	check(main.dizzy_t == 0.0 and p.jump_mult == 1.0 and p.sprite.rotation == 0.0, "the dizziness wears off")
	# hit reactions: every character has them; they play on their own sprite
	var chars: Array = ["rok", "raptor", "triceratops", "spinosaurus", "pteranodon"] + Dinos.ids()
	var clips := ["trip", "dizzy_enter", "dizzy", "dizzy_exit", "snag_enter", "snag", "snag_exit"]
	var missing := []
	for id in chars:
		var rf := SpriteLib.reactions(id)
		for clip in clips:
			if rf == null or not rf.has_animation(clip) or rf.get_frame_texture(clip, 0) == null:
				missing.append("%s:%s" % [id, clip])
	check(missing.is_empty(), "Rok and all 32 dinosaurs have trip, dizzy and snag animations: %s" % str(missing))
	p.position.y = Tuning.GROUND_Y
	p.on_ground = true
	check(p.react_play("dizzy", 1.0) and p.react.animation == "dizzy_enter" and p.react.visible and not p.sprite.visible, "a dizzy reaction starts with its enter clip, replacing the normal sprite")
	p._on_react_finished()
	check(p.react.animation == "dizzy", "...then loops while dazed")
	p._react_step(1.1)
	check(p.react.animation == "dizzy_exit", "...and recovers when the time is up")
	p._on_react_finished()
	check(p.react_kind == "" and p.sprite.visible and not p.react.visible, "after recovering the normal animation is back")
	p.react_play("snag", Tuning.SNAG_HOLD)
	p.on_ground = false
	p._react_step(1.0 / 60.0)
	check(p.react_kind == "" and p.sprite.visible, "jumping cancels a reaction at once")
	p.on_ground = true
	main.dizzy_t = 2.0
	main._dizzy_step(1.0 / 60.0)
	check(p.react_kind == "dizzy" and p.react.animation == "dizzy", "still dizzy after landing: the dizzy loop resumes")
	main.dizzy_t = 0.0
	main._dizzy_step(0.0)
	p.react_stop()
	p.jump_mult = 1.0
	p.react_play("trip")
	main.energy = 100.0
	main.unlocked = Forms.ORDER.duplicate()
	p.shift_to(Forms.RAPTOR)
	check(p.react_kind == "" and p.sprite.visible, "shapeshifting cancels a reaction")
	p.shift_to(Forms.ROK)
	var rock := c._obstacle("small", ["Stones_03"], 1.0, p.position.x)
	p.invuln = 0.0
	p.position.y = Tuning.GROUND_Y
	main.chase_gap = Tuning.CHASE_GAP_MAX
	main._collide()
	check(main.state == main.State.PLAYING and absf(main.chase_gap - (Tuning.CHASE_GAP_MAX - Tuning.STUMBLE_ROCK)) < 0.1 and p.invuln > 0.0, "a small rock trips Rok (the T-rex gains) instead of ending the run")
	check(p.react_kind == "trip" and p.react.animation == "trip", "tripping plays the trip animation")
	c.remove_obstacle(rock)
	# a Forest vine snags (once) instead of ending the run
	p.invuln = 0.0
	main.chase_gap = Tuning.CHASE_GAP_MAX
	c.metres = 0.0
	var vine := c.ledge(p.position.x)
	p.position.y = Tuning.GROUND_Y
	check(vine.vine and vine.hitbox().intersects(p.hitbox()), "the Forest ledge is a vine, at Rok's head height")
	main._collide()
	check(main.state == main.State.PLAYING and absf(main.chase_gap - (Tuning.CHASE_GAP_MAX - Tuning.STUMBLE_VINE)) < 0.1, "running into a vine snags Rok (the T-rex gains) instead of ending the run")
	check(p.react_kind == "snag", "a vine plays the snag animation")
	p.invuln = 0.0
	main._collide()
	check(not c.obstacles.has(vine) and absf(main.chase_gap - (Tuning.CHASE_GAP_MAX - Tuning.STUMBLE_VINE)) < 0.1, "a vine only snags once")
	c.metres = Zones.ZONE_LEN_M + 100.0   # the Desert's fossil arch is solid
	var arch := c.ledge(p.position.x)
	check(not arch.vine, "the Desert fossil arch is not a vine")
	c.remove_obstacle(arch)
	c.metres = 0.0
	p.invuln = 0.0
	# hearts: a crash costs hearts instead of the run; out of hearts, it ends
	var full_h := Tuning.MAX_HEARTS * Hearts.QUARTERS
	check(main.health < full_h, "the trips and snag above cost hearts")
	main.health = full_h   # (start_run refills them: checked below)
	var gap_h: float = main.chase_gap
	main.course.boulder(p.position.x)
	main._collide()
	check(main.state == main.State.PLAYING and main.health == full_h - Hearts.damage("crash", Dinos.stat("rok", "armor")) and main.chase_gap < gap_h, "crashing into a boulder as Rok costs a heart and lets the hunter gain, not the run")
	check(p.invuln >= Tuning.CRASH_INVULN - 0.01 and main.course.obstacles.all(func(o): return o.kind != "rock" or o.position.x > p.position.x + 200.0), "...then a moment of invulnerability, and the boulder breaks")
	main._refresh_hud()
	check(main.hud.hearts_box.get_child_count() == Tuning.MAX_HEARTS and int((main.hud.hearts_box.get_child(Tuning.MAX_HEARTS - 1) as TextureRect).get_meta("fill", -1)) == 0, "the HUD shows the lost heart (draining to empty)")
	check(Hearts.damage("crash", 1) == 4 and Hearts.damage("crash", 10) == 2 and Hearts.damage("snag", 10) == 1 and Hearts.damage("trip", 10) == 1 and Hearts.damage("trip", 1) == 1, "hearts split in quarters: a crash costs a whole heart, halved at Armor 10; small hits always a quarter")
	check(Hearts.damage("crash", 6) == 3 and Hearts.text(3) == "¾ heart" and Hearts.text(6) == "1½ hearts", "Armor between softens a crash to three quarters")
	main.course._pickup("heart", p.position + Vector2(0, -60))
	main._collide()
	check(main.health == full_h, "a heart pickup heals a heart")
	var sc_h: float = main.score
	main.course._pickup("heart", p.position + Vector2(0, -60))
	main._collide()
	check(main.health == full_h and main.score > sc_h, "at full health a heart is just points")
	# trips, snags and dizzy mushrooms cost hearts too
	p.invuln = 0.0
	main._trip()
	check(main.health == full_h - Hearts.damage("trip", Dinos.stat("rok", "armor")), "a trip costs a quarter heart")
	p.invuln = 0.0
	main._hurt("snag", "test")
	check(main.health == full_h - 1 - Hearts.damage("snag", Dinos.stat("rok", "armor")), "a snag costs half a heart (as Rok)")
	main.health = 1
	p.invuln = 0.0
	main._trip()
	check(main.state != main.State.PLAYING and main.death_cause == "small", "a trip with the last quarter heart ends the run")
	main.start_run(false)
	p = main.player
	check(main.health == full_h, "a new run starts with full hearts (counted in quarters)")
	# a Power roll that wins smashes a rock (no trip, no heart lost); one that loses trips
	var hp_r: int = main.health
	main.roll_override = 0.0
	p.invuln = 0.0
	var pr_rock: Obstacle = main.course._obstacle("small", ["Stones_03"], 1.0, p.position.x)
	main._collide()
	check(not main.course.obstacles.has(pr_rock) and main.health == hp_r and p.react_kind != "trip", "winning the Power roll smashes a small rock straight through")
	var pr_vine: Obstacle = main.course.ledge(p.position.x)
	if pr_vine.vine:
		p.position.y = Tuning.GROUND_Y
		main._collide()
		check(not main.course.obstacles.has(pr_vine) and main.health == hp_r, "...and snaps a vine")
	main.roll_override = 0.999
	main.health = 2
	p.invuln = 0.0
	main.course.obstacles.duplicate().map(func(o): main.course.remove_obstacle(o))
	main.course.boulder(p.position.x)
	main._collide()
	check(main.state != main.State.PLAYING, "out of hearts, a crash ends the run")
	main.start_run(false)
	p = main.player
	# the T-rex's snout sits exactly chase_gap behind Rok
	main.trex.follow(Tuning.PLAYER_X, main.chase_gap, main.terrain, 1.0)
	check(absf(main.trex.position.x + Trex.SNOUT - (Tuning.PLAYER_X - main.chase_gap)) < 0.5, "T-rex snout at the chase gap")
	check(main.trex.get_index() < main.player.get_index(), "Rok is drawn in front of the T-rex")
	# two quick stumbles in a row and it catches him
	main.chase_gap = 5.0
	main._play_step(1.0 / 60.0)
	main.chase_gap = -1.0
	main._play_step(1.0 / 60.0)
	check(main.state == main.State.DYING and main.death_cause == "caught", "T-rex catches Rok when the gap closes")
	# low ledges use the floating-island art and keep slide clearance
	var l := c.ledge(p.position.x + 900.0)
	check((l.get_child(0) as Sprite2D).texture.resource_path.ends_with("forest_overhead.png"), "forest ledge is a branch with vines")
	check(absf(l.hitbox().end.y - (Tuning.GROUND_Y - Tuning.LEDGE_CLEARANCE)) < 1.0, "ledge underside at the slide clearance")
	main.start_run(false)


## Unlocking the Triceratops mid-run: the very next obstacle is its gate.
func _unlock_gate_checks() -> void:
	# Raptor: its crumbling-bridge gate is built just off-screen within a second
	main.unlocked = [Forms.ROK]
	main.start_run(false)
	main.distance = (Progression.UNLOCKS[Forms.RAPTOR] + 5.0) * Tuning.PX_PER_M
	var marker: Node2D = null
	for i in 60:
		main.player.invuln = 999.0
		main._process(1.0 / 60.0)
		for m in main.course.markers:
			if m.get_meta("form") == Forms.RAPTOR:
				marker = m
		if marker:
			break
	check(marker != null, "Raptor unlock builds its bridge gate within a second")
	if marker:
		var dist := Course.gate_x0(marker) - Tuning.PLAYER_X
		check(dist < main.course.view_width() + 900.0, "bridge gate starts just off-screen (%d px ahead)" % int(dist))
		check(main.terrain.bridges.size() > 0 and not main.terrain.bridges[-1].sturdy, "it is a crumbling bridge")
	# Triceratops: the first new obstacle after the unlock is the Boulder Wall
	main.unlocked = [Forms.ROK, Forms.RAPTOR]
	main.start_run(false)
	main.player.invuln = 999.0
	main.distance = (Progression.UNLOCKS[Forms.TRICERATOPS] + 5.0) * Tuning.PX_PER_M
	var before: Array = main.course.obstacles.duplicate()
	var first: Obstacle = null
	for i in 60 * 8:
		main.player.invuln = 999.0
		main._process(1.0 / 60.0)
		for o in main.course.obstacles:
			if not before.has(o):
				first = o
				break
		if first:
			break
	check(main.unlocked.has(Forms.TRICERATOPS), "Triceratops unlocks at its distance")
	check(first != null and first.gate_form == Forms.TRICERATOPS, "first obstacle after the unlock is the barricade (got %s)" % ("none" if first == null else "%s gate=%d" % [first.kind, first.gate_form]))
	main.player.invuln = 0.0


## Hills and the chase: climbing lets the T-rex gain, sliding downhill and
## the fast Raptor build a lead; the meter follows the gap.
func _hill_chase_checks() -> void:
	main.start_run(false)
	var p: Player = main.player
	main.chase_gap = 200.0
	main._update_chase(0.5, -0.4)            # Rok climbing
	check(main.chase_gap < 200.0, "climbing lets the hunter gain (%.0f)" % main.chase_gap)
	p.shift_to(Forms.RAPTOR)
	main.chase_gap = 200.0
	main._update_chase(0.5, -0.4)            # Raptor climbing
	check(main.chase_gap > 200.0, "the fast Raptor still pulls away uphill")
	p.shift_to(Forms.ROK)
	main.chase_gap = Tuning.CHASE_GAP_MAX
	p.on_ground = true
	p._start_slide()
	main._update_chase(1.0, 0.4)             # sliding downhill
	check(main.chase_gap > Tuning.CHASE_GAP_MAX, "sliding downhill builds a lead past the usual gap")
	p._end_low()
	var lead: float = main.chase_gap
	main._update_chase(1.0, 0.0)
	check(main.chase_gap == lead, "the lead is kept back on foot")
	main._refresh_hud()
	check(main.hud.chase_meter.visible and main.hud.chase_meter.gap == main.chase_gap, "T-rex meter follows the gap")
	# large hills: climb several levels then come back down, no obstacles on them
	var t: Terrain = main.terrain
	t.metres = 2000.0
	t._large_hill()
	var top: float = Tuning.GROUND_Y
	for sg in t.segs:
		top = minf(top, sg.y0)
	check(top <= t.level_y(Tuning.LARGE_HILL_STEPS) + 0.5, "large hill climbs %d levels" % Tuning.LARGE_HILL_STEPS)
	check(t.level == 0, "large hill comes back down")
	check(t.slope_at(Tuning.PLAYER_X) == 0.0, "flat ground has no slope")
	main.start_run(false)
	# every dinosaur has its own energy cost and speed
	var drains := {}
	var net := {}
	for f in Forms.ORDER:
		var d := Forms.get_data(f)
		if f != Forms.ROK:
			drains[d.drain] = true
		net[f] = Tuning.CHASE_RECOVER + d.chase_rate
		check(Codex.dino_stats(f).size() == 3, "guide shows speed, jump and energy for form %d" % f)
	check(drains.size() == 4, "each dinosaur uses energy at its own rate")
	# staying a dino gets tiring: the drain climbs with time as a dino
	var unl_e: Array = main.unlocked.duplicate()
	main.unlocked = Forms.ORDER.duplicate()
	main.start_run(false)
	var pe: Player = main.player
	var drain_over := func(secs: float) -> float:
		var e0: float = main.energy
		for i in int(secs * 60):
			pe.invuln = 99.0
			main.chase_gap = Tuning.CHASE_GAP_MAX
			main._play_step(1.0 / 60.0)
		return e0 - main.energy
	main._shift(Forms.RAPTOR)
	main.energy = 100.0
	var fresh_drain: float = drain_over.call(0.5)
	main.dino_time = Tuning.DRAIN_DOUBLE_TIME
	main.energy = 100.0
	var tired_drain: float = drain_over.call(0.5)
	check(tired_drain > fresh_drain * 1.8, "after DRAIN_DOUBLE_TIME as a dino, energy drains about twice as fast (%.1f vs %.1f)" % [tired_drain, fresh_drain])
	main._refresh_hud()
	check(main.hud._energy_fill.bg_color != Hud.ENERGY_COLOR, "the energy bar reddens as the drain climbs")
	main._shift(Forms.TRICERATOPS)
	drain_over.call(0.05)
	check(main.dino_time > Tuning.DRAIN_DOUBLE_TIME, "switching to another dino doesn't reset the drain")
	main.energy = 50.0
	main.course._ground = Tuning.GROUND_Y
	main.course._pickup("amber", pe.position + Vector2(0, -60))
	main._collide()
	check(absf(main.energy - (50.0 + Tuning.AMBER_ENERGY_DINO)) < 0.5, "amber gives less energy while you're a dino")
	main._shift(Forms.ROK)
	drain_over.call(0.05)
	main._refresh_hud()
	check(main.dino_time == 0.0 and main.hud._energy_fill.bg_color == Hud.ENERGY_COLOR, "changing back to Rok resets the drain")
	main.energy = 50.0
	main.course._pickup("amber", pe.position + Vector2(0, -60))
	main._collide()
	check(absf(main.energy - (50.0 + Tuning.AMBER_ENERGY)) < 0.5 and Tuning.AMBER_ENERGY > Tuning.AMBER_ENERGY_DINO, "amber recharges more as Rok")
	main.unlocked = unl_e
	main.start_run(false)
	check(net[Forms.RAPTOR] > net[Forms.PTERANODON] and net[Forms.PTERANODON] > 0.0,
			"Raptor > Pteranodon, both outrun the T-rex")
	check(net[Forms.ROK] == 0.0, "Rok runs at the T-rex's pace")
	check(net[Forms.TRICERATOPS] < 0.0 and net[Forms.SPINOSAURUS] < net[Forms.TRICERATOPS],
			"Triceratops and (even more) Spinosaurus are slower than the T-rex")
	main.player.shift_to(Forms.SPINOSAURUS)
	main.chase_gap = 200.0
	main._update_chase(1.0, 0.0)
	check(main.chase_gap < 200.0, "the T-rex gains on a running Spinosaurus")
	# Rok holds the gap; a lead from a fast form is kept once back on foot
	main.player.shift_to(Forms.ROK)
	main.chase_gap = 180.0
	main._update_chase(2.0, 0.0)
	check(absf(main.chase_gap - 180.0) < 0.01, "on foot the gap holds steady (no free recovery)")
	main.player.shift_to(Forms.RAPTOR)
	main.chase_gap = Tuning.CHASE_GAP_MAX
	main._update_chase(3.0, 0.0)
	var raptor_lead: float = main.chase_gap
	check(raptor_lead > Tuning.CHASE_GAP_MAX, "the Raptor builds a lead")
	main.player.shift_to(Forms.ROK)
	main._update_chase(30.0, 0.0)
	check(main.chase_gap == raptor_lead, "back in Rok's form the Raptor's lead is kept (the hunter only matches his pace)")
	main._stumble(Tuning.STUMBLE_ROCK, "Trip!")
	check(main.chase_gap < raptor_lead, "only a stumble takes distance away")
	# eggs: a short speed boost that pulls away
	main.start_run(false)
	main.chase_gap = 150.0
	main.course._ground = Tuning.GROUND_Y
	main.course._pickup("egg", main.player.position + Vector2(0, -60))
	main._collide()
	check(main.slots[0] == "egg" and main.boost_t == 0.0, "picking up an egg puts it in a booster slot (no automatic boost)")
	main._refresh_hud()
	var sb: TouchButton = main.hud.slot_buttons[0]
	check(sb.enabled and sb.icon != null, "the slot button shows the egg")
	check(main.hud.slot_buttons.size() == 3, "three booster slot buttons")
	check(main.slot_count == 1, "a fresh save has one booster slot open")
	check(main.hud.slot_buttons[1].locked and main.hud.slot_buttons[1].lock_text == "%d m" % int(Progression.SLOT_UNLOCK_M), "the second slot shows its unlock distance")
	check(main.hud.slot_buttons[2].locked and main.hud.slot_buttons[2].lock_text == "Market", "the third slot is marked for the Market")
	main._touch_pressed("slot_0")
	check(main.slots[0] == "" and main.boost_t > 0.0, "tapping the slot eats the egg for a speed boost")
	main.use_slot(0)
	check(main.boost_t > 0.0 and main.slots[0] == "", "an empty slot does nothing")
	for i in 30:
		main._play_step(1.0 / 60.0)
	check(main.speed_mod > 1.05, "the boost speeds Rok up (%.2f)" % main.speed_mod)
	check(main.chase_gap > 150.0, "the boost pulls away from the T-rex")
	for i in int(Tuning.EGG_BOOST_TIME * 60.0) + 60:
		main.player.invuln = 99.0
		main._play_step(1.0 / 60.0)
	check(main.boost_t == 0.0, "the boost wears off")
	# locked power-ups don't exist in a run yet (market later)
	main.slots = ["", "", ""]
	check(not main.collect_booster("amber_shield", Vector2.ZERO) and main.slots == ["", "", ""], "a locked power-up can't be collected")
	# kart-style slots: only open slots take boosters (any type, even one already held)
	check(main.collect_booster("egg", Vector2.ZERO), "a booster fills a free slot")
	check(not main.collect_booster("egg", Vector2.ZERO) and main.slots.count("egg") == 1 and main.slots[1] == "", "with every open slot full a booster is just points")
	var owned_before: Array = main.boosters_owned
	main.boosters_owned = ["egg", "amber_shield", "fossil_magnet"]
	check(not main.collect_booster("amber_shield", Vector2.ZERO), "with one slot open, a full slot takes nothing more")
	var unlocked_before: Array = main.unlocked.duplicate()
	main.unlocked = Forms.ORDER.duplicate()   # only the slot can unlock here
	main.distance = Progression.SLOT_UNLOCK_M * Tuning.PX_PER_M + 10.0
	main._check_unlocks()
	check(main.slot_count == 2 and SaveData.load_booster_slots() == 2, "reaching %d m unlocks and saves the second slot" % int(Progression.SLOT_UNLOCK_M))
	main.distance = 99999.0 * Tuning.PX_PER_M
	main._check_unlocks()
	check(main.slot_count == 2, "distance never unlocks the third (Market) slot")
	check(main.collect_booster("egg", Vector2.ZERO) and main.slots[0] == "egg" and main.slots[1] == "egg", "a free slot takes a booster you already hold")
	main.slots[1] = ""
	check(main.collect_booster("amber_shield", Vector2.ZERO) and main.slots[1] == "amber_shield", "the second slot takes a different booster")
	check(not main.collect_booster("fossil_magnet", Vector2.ZERO) and main.slots[2] == "", "the locked Market slot stays empty")
	main.slot_count = 3
	check(main.collect_booster("fossil_magnet", Vector2.ZERO), "a Market-bought third slot takes a third booster")
	main.boosters_owned = owned_before
	main.unlocked = unlocked_before
	main.slot_count = 1
	SaveData.save_booster_slots(1)
	main.slots = ["", "", ""]
	main._info_queue.clear()
	main.hud.hide_info()
	# every run offers an egg early on
	main.start_run(false)
	main.distance = (Progression.intro_m("egg") + 1.0) * Tuning.PX_PER_M
	for i in 10:
		main.player.invuln = 99.0
		main._play_step(1.0 / 60.0)
	check(main.course.pickups.any(func(k): return k.kind == "egg"), "an egg appears early in every run")
	main.start_run(false)


## Zones by distance and the day/night cycle.
func _zone_checks() -> void:
	var zl := Zones.ZONE_LEN_M   # (config/progression.cfg [zones] length_m)
	check(Zones.index_at(0.0) == 0 and Zones.index_at(zl * 1.5) == 1 and Zones.index_at(zl * 2.5) == 2, "Forest, Desert, Volcanic by distance")
	check(Zones.index_at(zl * 3.2) == 0, "zones repeat after the Volcanic Badlands")
	for m in [0.0, zl - 10.0, zl, zl + 10.0, zl * 1.5, zl * 3.0 - 5.0, zl * 3.0 + 5.0]:
		var w: Array = Zones.weights(m)
		check(absf(w[0] + w[1] + w[2] - 1.0) < 0.001, "zone weights sum to 1 at %d m" % int(m))
	var w2: Array = Zones.weights(zl)
	check(w2[0] > 0.0 and w2[1] > 0.0, "looks cross-fade at the border")
	var saw_day := false
	var saw_night := false
	for m in range(0, int(Zones.DAY_CYCLE_M), 50):
		saw_day = saw_day or Zones.daylight(m) > 0.99
		saw_night = saw_night or Zones.daylight(m) < 0.01
	check(saw_day and saw_night, "every day/night cycle has both day and night")
	check(Zones.daylight(0.0) == 1.0, "runs start in daytime")
	var night_m := Zones.DAY_CYCLE_M * 0.7
	check(Zones.light(night_m).v < Zones.light(0.0).v, "night lighting is darker than day")
	# ground generated in the desert uses the sandstone strip
	main.start_run(false)
	var t: Terrain = main.terrain
	t.metres = zl * 1.3
	var before := t.features.size()
	t._flat(500.0)
	check(t.features[-1].style == "desert", "ground generated in the Desert is sandstone")
	t.metres = zl * 2.3
	t._flat(500.0)
	check(t.features[-1].style == "volcanic", "ground generated in the Volcanic Badlands is basalt")
	t.metres = 100.0
	t._flat(500.0)
	check(t.features[-1].style == "forest", "forest ground is the seamless forest strip")
	main.bg.apply_environment(zl * 1.5)
	check(main.bg.groups[1].visible and not main.bg.groups[0].visible, "desert backdrop shows in the Desert")
	main.bg.apply_environment(0.0)
	# entering a zone shows a banner
	main.start_run(false)
	main.distance = (zl + 1.0) * Tuning.PX_PER_M
	main._refresh_hud()
	check(main.zone_index == 1 and main.seen.has("zone_desert"), "entering the Desert announces it")
	main.start_run(false)


## Combo streak and Primal Frenzy (combo.gd, main._combo_step).
func _combo_checks() -> void:
	var cb := Combo.new()
	var tiers := []
	cb.tier_up.connect(func(t): tiers.append(t))
	var need: int = int(Tuning.COMBO_TIERS[1][0])
	for i in need - 1:
		cb.feat()
	check(cb.tier == 0 and cb.mult() == 1.0, "a short streak doesn't multiply yet")
	cb.feat()
	check(cb.tier == 1 and cb.mult() == float(Tuning.COMBO_TIERS[1][1]) and tiers == [1], "%d clean feats reach the first combo tier" % need)
	check(cb.meat_per_pickup() == 1, "x1.5 still gives one meat per pickup")
	while cb.tier < 2:
		cb.feat()
	check(cb.meat_per_pickup() == 2, "x2 gives two meat per pickup")
	var mults := []
	for t in Tuning.COMBO_TIERS:
		mults.append(float(t[1]))
	var rising := true
	for i in range(1, mults.size()):
		rising = rising and mults[i] > mults[i - 1] and int(Tuning.COMBO_TIERS[i][0]) > int(Tuning.COMBO_TIERS[i - 1][0])
	check(rising and mults[-1] == 5.0, "combo tiers rise to x5, each needing more feats")
	var n := cb.count
	cb.keep_alive()
	check(cb.count == n, "a pickup keeps the streak alive without adding to it")
	cb.step(Tuning.COMBO_WINDOW + 0.1)
	check(cb.count == 0 and cb.tier == 0, "the streak lapses after COMBO_WINDOW with no feat")
	cb.reset()
	for i in 20:
		cb.feat()
	var m := cb.meter
	cb.hit()
	check(cb.count == 0 and cb.meter < m and cb.meter > 0.0, "a stumble ends the streak and knocks the frenzy meter down")
	cb.reset()
	var started := [false]
	cb.frenzy_started.connect(func(): started[0] = true)
	var feats := 0
	while not cb.in_frenzy() and feats < 200:
		cb.feat()
		feats += 1
	check(started[0] and cb.frenzy_t == Tuning.FRENZY_TIME and feats >= 20 and feats <= 50,
			"a full meter starts Primal Frenzy (after %d feats)" % feats)
	cb.feat()
	check(cb.meter < 1.0 or cb.frenzy_t == Tuning.FRENZY_TIME, "feats in a frenzy don't refill the meter")
	var ended := [false]
	cb.frenzy_ended.connect(func(): ended[0] = true)
	cb.step(Tuning.FRENZY_TIME * 0.5)
	check(cb.in_frenzy() and absf(cb.meter - 0.5) < 0.01 and cb.count > 0, "the meter drains through the frenzy and the streak holds")
	cb.step(Tuning.FRENZY_TIME)
	check(ended[0] and not cb.in_frenzy() and cb.meter == 0.0, "the frenzy ends")

	# in a run
	main.start_run(false)
	var c: Course = main.course
	var p: Player = main.player
	c._ground = Tuning.GROUND_Y
	var base: float = main.points_mult()
	for i in need:
		main.combo.feat()
	check(is_equal_approx(main.points_mult(), base * float(Tuning.COMBO_TIERS[1][1])), "the combo multiplies points")
	check(main.hud.combo_meter.combo == main.combo, "the HUD shows the combo")
	main._stumble(10.0, "Trip!")
	check(main.combo.count == 0 and is_equal_approx(main.points_mult(), base), "a stumble ends the combo")
	# an obstacle Rok got past cleanly is a feat; one he stumbled through isn't
	p.invuln = 0.0
	var passed := c.small(p.position.x - 300.0)
	main._combo_step(1.0 / 60.0)
	check(main.combo.count == 1 and passed.get_meta("combo", false), "an obstacle passed cleanly adds to the combo")
	main._combo_step(1.0 / 60.0)
	check(main.combo.count == 1, "...once")
	p.invuln = 0.5
	c.small(p.position.x - 300.0)
	main._combo_step(1.0 / 60.0)
	check(main.combo.count == 1, "an obstacle stumbled through (invulnerable) doesn't count")
	p.invuln = 0.0
	# a pit crossed just now counts
	main.start_run(false)
	var t: Terrain = main.terrain
	var lx: float = main.player.position.x - t.position.x
	t.features.insert(0, {"type": "pit", "x0": lx - 300.0, "x1": lx - 100.0, "level": 0})
	main._combo_step(1.0 / 60.0)
	check(main.combo.count == 1, "a pit crossed adds to the combo")
	# meat per pickup follows the tier
	main.start_run(false)
	c = main.course
	p = main.player
	while main.combo.tier < 2:
		main.combo.feat()
	var meat0: int = main.run_meat
	c._pickup("meat", p.position + Vector2(0, -60))
	main._collide()
	check(main.run_meat == meat0 + 2, "at x2 a meat pickup gives 2 meat")
	# Primal Frenzy
	main.start_run(false)
	c = main.course
	p = main.player
	c._ground = Tuning.GROUND_Y
	while not main.combo.in_frenzy():
		main.combo.feat()
	check(main.frenzies == 1, "the run counts its frenzies")
	var hp: int = main.health
	var wall := c.rock_wall(p.position.x + 10.0, 3)
	var boulder := c.boulder(p.position.x)
	main._collide()
	check(main.state == main.State.PLAYING and main.health == hp and not c.obstacles.has(wall) and not c.obstacles.has(boulder),
			"in a frenzy Rok smashes through walls and boulders unhurt")
	var gate := c.boulder_wall(p.position.x)
	main._collide()
	check(main.state == main.State.PLAYING and not c.obstacles.has(gate), "...and through dino gate walls")
	var gap0: float = main.chase_gap
	main._combo_step(0.5)
	check(main.chase_gap > gap0, "a frenzy pulls away from the hunter")
	var meats: int = c.pickups.filter(func(k): return k.kind == "meat").size()
	for i in 5:
		main._combo_step(Tuning.FRENZY_MEAT_EVERY)
	check(c.pickups.filter(func(k): return k.kind == "meat").size() > meats, "meat rains down ahead during a frenzy")
	main._combo_step(Tuning.FRENZY_TIME)
	check(not main.combo.in_frenzy() and p.invuln > 0.0, "after the frenzy Rok gets a moment of grace")
	main.start_run(false)
	check(main.combo.count == 0 and main.frenzies == 0 and not main.combo.in_frenzy(), "a new run starts without a combo")


## Milestone chests and escalating pickups (chest.gd, main._chest_step /
## _open_chest, Course.big_meat_chance / fossil_chance).
func _milestone_checks() -> void:
	check(Chest.rarity(1, 0.0) == "epic" and Chest.rarity(1, 0.99) == "common", "chest rarity follows the roll")
	var c1 := Chest.chances(1)
	var c5 := Chest.chances(5)
	var c50 := Chest.chances(50)
	check(c5.x > c1.x and c5.y > c1.y and is_equal_approx(c50.y, Tuning.CHEST_EPIC_MAX) and is_equal_approx(c50.x, Tuning.CHEST_RARE_MAX) and c50.x + c50.y < 1.0,
			"later milestones give rarer chests, up to a cap")
	check(Chest.meat("epic", 1) > Chest.meat("rare", 1) and Chest.meat("rare", 1) > Chest.meat("common", 1) and Chest.meat("common", 5) > Chest.meat("common", 1),
			"rarer and later chests hold more meat")
	check(Chest.xp("epic", 1) > Chest.xp("common", 1), "rarer chests hold more XP")
	# a chest is placed on flat ground at the milestone
	main.start_run(false)
	main.distance = (Tuning.CHEST_EVERY_M - 20.0) * Tuning.PX_PER_M
	main._chest_step()
	var chests: Array = main.course.pickups.filter(func(k): return k.kind == "chest")
	check(chests.size() == 1 and int(chests[0].get_meta("milestone")) == 1, "the 1000 m milestone puts a chest ahead")
	if chests.size() == 1:
		var k: Pickup = chests[0]
		check(absf(k.position.y - main.terrain.height_at(k.position.x)) < 1.0, "...sitting on the ground")
		check(main.next_chest_m == 2.0 * Tuning.CHEST_EVERY_M, "...and the next one waits for 2000 m")
		# running into it opens it
		k.place(Vector2(main.player.position.x + 10.0, main.player.position.y))
		main._collide()
		check(k.opened and main.chests_opened == 1 and not main.course.pickups.has(k) and main.course.debris.has(k),
				"running into a chest opens it (it stays, open)")
	var c: Course = main.course
	var p: Player = main.player
	var rewards := {}
	for r in ["meat", "xp", "heart", "full_heal", "booster", "frenzy"]:
		main.start_run(false)
		c = main.course
		p = main.player
		main.health = main.max_health() - 6
		main.slots = ["", "", ""]
		c._pickup("chest", p.position + Vector2(400, 0))
		var k: Pickup = c.pickups[-1]
		var meat0: int = main.run_meat
		var xp0 := float(main.dino_xp.get("rok", 0.0))
		var hp0: int = main.health
		main._open_chest(k, 0.0, r)
		match r:
			"meat": rewards[r] = main.run_meat > meat0
			"xp": rewards[r] = float(main.dino_xp.get("rok", 0.0)) > xp0
			"heart": rewards[r] = main.health == hp0 + Hearts.QUARTERS
			"full_heal": rewards[r] = main.health == main.max_health()
			"booster": rewards[r] = main.slots.has("egg")
			"frenzy": rewards[r] = main.combo.in_frenzy() and main.frenzies == 1
	check(rewards.values().all(func(v): return v), "every chest reward works: %s" % rewards)
	check(main.combo.count >= Tuning.CHEST_COMBO_WEIGHT, "a chest adds to the combo")
	# escalating pickups
	check(Course.big_meat_chance(Tuning.BIG_MEAT_FROM_M - 1.0) == 0.0 and Course.big_meat_chance(Tuning.BIG_MEAT_FULL_M) == Tuning.BIG_MEAT_MAX_CHANCE
			and Course.big_meat_chance(4000.0) > 0.0 and Course.big_meat_chance(4000.0) < Tuning.BIG_MEAT_MAX_CHANCE, "big meat grows more common as a run goes on")
	check(Course.fossil_chance(Tuning.FOSSIL_FROM_M - 1.0) == 0.0 and Course.fossil_chance(20000.0) == Tuning.FOSSIL_MAX_CHANCE
			and Course.fossil_chance(Tuning.FOSSIL_FROM_M) > 0.0, "fossils only turn up deep into a run, more often later")
	main.start_run(false)
	c = main.course
	p = main.player
	c.metres = 500.0
	var golds := 0
	for i in 100:
		c._pickup("meat", Vector2(-1000, 0))
		golds += 1 if c.pickups[-1].kind == "big_meat" else 0
	check(golds == 0, "no big meat early in a run")
	c.metres = Tuning.BIG_MEAT_FULL_M
	golds = 0
	for i in 300:
		c._pickup("meat", Vector2(-1000, 0))
		golds += 1 if c.pickups[-1].kind == "big_meat" else 0
	check(golds > 60 and golds < 180, "late in a run about %d%% of meat is golden (%d/300)" % [int(Tuning.BIG_MEAT_MAX_CHANCE * 100), golds])
	c.metres = 9000.0
	var fossils := 0
	for i in 1000:
		fossils += 1 if c._spot_kind() == "fossil" else 0
	check(fossils > 30 and fossils < 140 and Course._single("fossil"), "deep runs have rare fossil spots, one fossil each (%d/1000)" % fossils)
	main.start_run(false)
	c = main.course
	p = main.player
	c.metres = 9000.0
	var m0: int = main.run_meat
	var s0: float = main.score
	var k2 := Pickup.new().setup("big_meat")
	c.add_child(k2)
	k2.place(p.position + Vector2(0, -60))
	c.pickups.append(k2)
	main._collide()
	check(main.run_meat == m0 + Tuning.BIG_MEAT_VALUE, "big meat is worth %d meat" % Tuning.BIG_MEAT_VALUE)
	var k3 := Pickup.new().setup("fossil")
	c.add_child(k3)
	k3.place(p.position + Vector2(0, -60))
	c.pickups.append(k3)
	main._collide()
	check(main.run_meat == m0 + Tuning.BIG_MEAT_VALUE + Tuning.FOSSIL_MEAT and main.fossils_found == 1 and main.score >= s0 + Tuning.FOSSIL_SCORE,
			"a rare fossil is worth %d meat and %d points" % [Tuning.FOSSIL_MEAT, Tuning.FOSSIL_SCORE])
	main.start_run(false)


## The user's playtest feedback: attack, gear and cards, the Camp, first
## sight intros, big meat, wall heights, wild dinosaurs, slower levels.
func _feedback_checks() -> void:
	_quiet_missions()
	# --- attack
	main.start_run(false)
	var c: Course = main.course
	var p: Player = main.player
	c._ground = Tuning.GROUND_Y
	main.roll_override = 0.999
	check(main.hud.attack_button.visible and main.hud.attack_button.position.y + main.hud.attack_button.size.y * 0.5 > Tuning.GROUND_Y,
			"there's an ATTACK button on the dirt")
	var rock := c.small(p.position.x + 120.0)
	if rock.mushroom:
		c.remove_obstacle(rock)
		rock = c.small(p.position.x + 120.0)
	main._attack_marker_step()
	check(main.attack_marker.visible and main.attack_marker.breaks and main.attack_marker.box == rock.hitbox(),
			"a green marker shows the small rock ATTACK would hit")
	var hit: Obstacle = main._attack()
	check(hit == rock and not c.obstacles.has(rock), "ATTACK breaks a small hazard just ahead")
	main.attack_cd = 0.0
	var stone := c._obstacle("small", ["Stones_02"], 1.3, p.position.x + 120.0)
	main._attack()
	check(stone.shattered and stone.get_children().any(func(n): return n is AnimatedSprite2D and n.is_playing()),
			"a smashed small rock plays its crumble animation")
	check(main._attack() == null and main.attack_cd > 0.0, "...then waits for its cooldown")
	main.attack_cd = 0.0
	var far := c.small(p.position.x + 900.0)
	check(main._attack() == null and c.obstacles.has(far), "it can't reach things far ahead")
	main.attack_cd = 0.0
	var wall := c.rock_wall(p.position.x + 120.0, 2)
	main._attack_marker_step()
	check(main.attack_marker.visible and not main.attack_marker.breaks, "the marker turns red on something ATTACK can't break")
	check(main._attack() == null and c.obstacles.has(wall), "bare-handed Rok can't break a wall (CLANG!)")
	main.attack_cd = 0.0
	c.remove_obstacle(wall)
	c.metres = Progression.intro_m("stampede") + 50.0
	c._spawn_key("stampede", p.position.x + 140.0 - 300.0)   # (_spawn_key puts it 300 px further out)
	var critter: Obstacle = c.obstacles[-1]
	check(critter.critter != "" and main._attack() == critter and not c.obstacles.has(critter), "ATTACK bonks a wild dinosaur")
	main.attack_cd = 0.0
	check(p.attack_clip == "" and p.sprite.visible, "bare-handed Rok has no attack clip (the code-drawn lunge stands in)")
	var clips_ok := true
	for hero in ["rok", "nira", "boro"]:
		var hf := SpriteLib.attacks(hero)
		for w in Gear.ITEMS:
			if Gear.ITEMS[w].slot == "weapon":
				clips_ok = clips_ok and hf != null and hf.has_animation("attack_" + w) and hf.get_frame_count("attack_" + w) == 8 \
						and not hf.get_animation_loop("attack_" + w)
	for f in [Forms.RAPTOR, Forms.TRICERATOPS, Forms.SPINOSAURUS, Forms.PTERANODON]:
		var df := SpriteLib.attacks(String(Forms.get_data(f).id))
		clips_ok = clips_ok and df != null and df.get_frame_count("attack") == 8
	check(clips_ok, "Rok, Nira and Boro have a one-shot attack clip for every weapon, and the four dinosaurs one each")
	p.shift_to(Forms.RAPTOR)
	main._attack()
	check(p.attack_clip == "attack" and p.atk.visible and not p.sprite.visible, "a dinosaur's ATTACK plays its attack clip in place of its body")
	p.atk.animation_finished.emit()
	check(p.attack_clip == "" and p.sprite.visible and not p.atk.visible, "...and hands back to the body when it ends")
	main.attack_cd = 0.0
	main._attack()
	p.shift_to(Forms.ROK)
	check(p.attack_clip == "" and p.sprite.visible, "shapeshifting cuts an attack clip short")
	main.attack_cd = 0.0
	var gate := c.boulder_wall(p.position.x + 120.0)
	gate.gate_form = Forms.TRICERATOPS   # (the gate spawn sets this)
	check(not main.attack_breaks(gate, 10.0), "no attack breaks a dino gate")
	check(main.attack_breaks(c.log_(p.position.x + 600.0), Tuning.ATTACK_POWER_WOOD) and not main.attack_breaks(c.boulder(p.position.x + 700.0), Tuning.ATTACK_POWER_ROCK - 0.5),
			"Power decides what an attack breaks")
	main.roll_override = 0.999
	# --- hold JUMP for higher (a very quick tap used to give the full jump)
	var jump_heights := []
	for hold_frames in [1, 4, 40]:
		main.start_run(false)
		var pj: Player = main.player
		for o in main.course.obstacles.duplicate():
			main.course.remove_obstacle(o)
		var y0: float = pj.position.y
		var top: float = y0
		pj.press_jump()
		for f in 90:
			if f == hold_frames:
				pj.release_jump()
			pj.invuln = 99.0
			main._play_step(1.0 / 60.0)
			top = minf(top, pj.position.y)
		jump_heights.append(y0 - top)
	check(jump_heights[0] < jump_heights[2] - 30.0 and jump_heights[1] < jump_heights[2] - 30.0, "holding JUMP jumps clearly higher than a tap, however quick (%s)" % str(jump_heights.map(func(h): return int(h))))
	# --- slide: one press = one slide, cooldown from the press
	main.start_run(false)
	p = main.player
	c = main.course
	for i in 5:
		main._play_step(1.0 / 60.0)
	p.press_slide()
	check(p.is_low() and p.slide_cd > 0.0 and is_equal_approx(p.slide_cd, p.slide_cd_max), "a slide's cooldown starts on the press")
	check(p.slide_cd_max > Tuning.SLIDE_MIN + 0.5, "...and lasts longer than the slide itself")
	for i in int((Tuning.SLIDE_MAX + 1.0) * 60.0):   # held well past the old duck point
		p.invuln = 99.0
		main.chase_gap = Tuning.CHASE_GAP_MAX
		for o in c.obstacles.duplicate():
			c.remove_obstacle(o)
		main._play_step(1.0 / 60.0)
	check(not p.is_low() and p.low != Player.Low.DUCK, "holding SLIDE doesn't keep the runner sliding")
	var cd_left := p.slide_cd
	for i in int(cd_left * 60.0) + 10:
		p.invuln = 99.0
		main.chase_gap = Tuning.CHASE_GAP_MAX
		main._play_step(1.0 / 60.0)
	check(not p.is_low(), "...and still holding it when the cooldown ends doesn't start another")
	p.release_slide()
	p.press_slide()
	check(p.is_low(), "a new press slides again")
	p.release_slide()
	p.press_slide()
	check(p.slide_cd > Tuning.SLIDE_BUFFER and p._slide_buffer == 0.0, "a press early in the cooldown is ignored, not queued")
	p.release_slide()
	# --- loot from broken obstacles (config/pickups.cfg [break_loot])
	main.start_run(false)
	c = main.course
	p = main.player
	var k0 := c.pickups.size()
	main.loot_override = 0.999
	check(main._break_loot(Vector2(600, 400)) == "" and c.pickups.size() == k0, "most broken obstacles drop nothing")
	var lc: float = Loot.num("break_loot", "chance")
	var lh: float = Loot.num("break_loot", "heart")
	main.loot_override = 0.0
	var unl_keep: Array = main.unlocked.duplicate()
	main.unlocked = [Forms.ROK]
	check(main._break_loot(Vector2(600, 400)) == "" and c.pickups.size() == k0, "before any dinosaur, an amber drop is nothing (amber needs a dinosaur)")
	main.unlocked = [Forms.ROK, Forms.RAPTOR]
	check(main._break_loot(Vector2(600, 400)) == "amber" and c.pickups.size() == k0 + int(Loot.num("break_loot", "amber_count")),
			"at full health a heart roll drops amber instead")
	main.health = main.max_health() - 1
	check(main._break_loot(Vector2(600, 400)) == "heart" and c.pickups[-1].kind == "heart", "a hurt runner can get a heart from a broken obstacle")
	main.loot_override = lc * (lh + 0.01)
	check(Boosters.is_booster(main._break_loot(Vector2(600, 400))), "...or a power-up")
	main.loot_override = lc * 0.99
	check(main._break_loot(Vector2(600, 400)) == "amber", "...or amber")
	main.loot_override = 0.0
	var rock2 := c.small(p.position.x + 120.0)
	var k1 := c.pickups.size()
	main._smash(rock2, Color.WHITE)
	check(c.pickups.size() > k1, "smashing an obstacle rolls for loot")
	main.loot_override = 0.999
	main.health = main.max_health()
	main.unlocked = unl_keep
	# --- the dependency tree (config/requirements.cfg)
	var rq := ConfigFile.new()
	check(rq.load(Requires.PATH) == OK and Requires.of("pickup.amber").has("dino"), "requirements load from config/requirements.cfg (amber needs a dinosaur)")
	main.unlocked = [Forms.ROK]
	var pk0 := c.pickups.size()
	c._pickup("amber", Vector2(700, 400))
	check(c.pickups.size() == pk0 and not Requires.ok("pickup.amber") and not RunEvents.pool(true).has("amber_storm"),
			"with no dinosaur unlocked there's no amber and no Amber Storm")
	c._pickup("meat", Vector2(700, 400))
	check(c.pickups.size() == pk0 + 1, "...but other pickups still come")
	main.unlocked = [Forms.ROK, Forms.RAPTOR]
	c._pickup("amber", Vector2(760, 400))
	check(c.pickups.size() == pk0 + 2 and RunEvents.pool(true).has("amber_storm"), "once a dinosaur is unlocked, amber appears")
	Requires.set_rule("intro.log", ["form:triceratops", "best_m:100"])
	main.best_m = 500
	check(not Progression.available("log", 99999.0), "a hazard waits for its requirements (a test rule: logs need the Triceratops)")
	main.unlocked = [Forms.ROK, Forms.TRICERATOPS]
	check(Progression.available("log", 99999.0), "...and comes once they're met")
	Requires.set_rule("market.time_crystal", ["form:pteranodon"])
	check(not Market.on_sale("time_crystal", 99999.0) and Market.lock_text("time_crystal", 99999.0).contains("unlock the Pteranodon"),
			"a Market item can need something too, and its lock says what")
	Requires.reload()
	main.unlocked = unl_keep
	main.best_m = 0
	# --- pickup odds and placement come from config/pickups.cfg
	var pcfg := ConfigFile.new()
	check(pcfg.load("res://config/pickups.cfg") == OK and is_equal_approx(float(Loot.num("spots", "heart")), float(pcfg.get_value("spots", "heart")))
			and is_equal_approx(float(Loot.num("break_loot", "chance")), float(pcfg.get_value("break_loot", "chance"))), "pickup odds load from config/pickups.cfg")
	var all_keys := true
	for sec in Loot.DEFAULTS:
		for key in Loot.DEFAULTS[sec]:
			all_keys = all_keys and pcfg.has_section_key(sec, key)
	check(all_keys, "config/pickups.cfg lists every pickup setting")
	Loot.set_value("spots", "heart", 1.0)
	check(c._spot_kind() == "heart", "a spot's kind follows the config's odds")
	Loot.set_value("power_ups", "egg_share", 0.0)
	for k in Boosters.DATA:
		Loot.set_value("power_ups", k, 1.0 if k == "golden_fossil" else 0.0)
	var keep_owned: Array = c.boosters_owned
	c.boosters_owned = Boosters.DATA.keys()
	check(c._booster() == "golden_fossil", "power-up weights come from the config")
	c.boosters_owned = keep_owned
	Loot.reload()
	check(is_equal_approx(float(Loot.num("spots", "heart")), float(pcfg.get_value("spots", "heart"))), "(reloads cleanly)")
	# --- coach hints (the tutorial): rules
	var tu := Tutorial.new()
	check(tu.can_show("jump") and tu.show("jump") != "" and tu.current == "jump" and not tu.can_show("slide"), "one coach hint at a time")
	tu.hide()
	check(not tu.can_show("slide"), "...with a quiet gap after each")
	tu.step(Tutorial.GAP + 0.1)
	check(tu.can_show("slide") and not tu.can_show("jump"), "a lesson shows at most once per run")
	tu.new_run()
	tu.step(Tutorial.START_QUIET + 0.1)
	for i in int(Tutorial.LESSONS.jump.need):
		tu.done("jump")
	check(tu.learned("jump") and not tu.can_show("jump"), "a lesson done enough times is learned and never shows again")
	for r in Tutorial.MAX_SHOWS:
		tu.new_run()
		tu.step(Tutorial.START_QUIET + 0.1)
		tu.show("slide")
		tu.hide()
	tu.new_run()
	tu.step(Tutorial.START_QUIET + 0.1)
	check(not tu.can_show("slide"), "an ignored lesson stops after %d shows (no nagging)" % Tutorial.MAX_SHOWS)
	var tu2 := Tutorial.new()
	tu2.enabled = false
	check(not tu2.can_show("jump"), "tips can be switched off")
	# --- coach hints in a run
	main.tutorial = Tutorial.new()
	main.start_run(false)
	c = main.course
	p = main.player
	for o in c.obstacles.duplicate():
		c.remove_obstacle(o)
	for i in int(Tutorial.START_QUIET * 60.0) + 5:
		main._coach_step(1.0 / 60.0)
	var rk := c.small(p.position.x + 220.0)
	main._coach_step(1.0 / 60.0)
	check(main.tutorial.current == "jump" and main.hud.coach_marker != null and main.hud.coach_marker.visible
			and main.hud.coach_marker.target == main.hud.jump_button, "a rock coming up shows a hint on the JUMP button, without pausing")
	check(main.state == main.State.PLAYING, "(the run keeps going)")
	main._coach_done("jump")
	check(main.tutorial.current == "" , "doing it ends the hint")
	main._coach_done("jump")
	c.remove_obstacle(rk)
	main.tutorial.step(Tutorial.GAP + 0.1)
	var rk2 := c.small(p.position.x + 150.0)
	main.attack_cd = 0.0
	main._coach_step(1.0 / 60.0)
	check(main.tutorial.learned("jump") and main.tutorial.current == "attack" and main.hud.coach_marker.target == main.hud.attack_button,
			"once jumping is learned, a breakable rock in reach teaches ATTACK")
	c.remove_obstacle(rk2)
	main._coach_step(1.0 / 60.0)
	check(main.tutorial.current == "", "a hint goes away when its moment passes")
	var old_save := Tutorial.new()
	old_save.skip_basics()
	check(old_save.learned("jump") and old_save.learned("slide") and not old_save.learned("attack"), "a returning player's save skips the basic move lessons")
	# --- the pause screen's Tips switch
	main.tutorial = Tutorial.new()
	main.start_run(false)
	main._refresh_hud()
	check(not main.hud.tips_button.visible, "no Tips button during a run")
	main._pause()
	main._refresh_hud()
	check(main.hud.tips_button.visible and main.hud.tips_button.caption == "TIPS ON", "the pause screen has a Tips button (on)")
	main._touch_pressed("tips")
	main._refresh_hud()
	check(not main.tutorial.enabled and not SaveData.load_tips() and main.state == main.State.PAUSED and main.hud.tips_button.caption == "TIPS OFF",
			"tapping it switches coach hints off (saved) without resuming")
	main._touch_pressed("tips")
	check(main.tutorial.enabled and SaveData.load_tips(), "...and back on")
	main._resume()
	main.tutorial = Tutorial.new()
	main.tutorial.enabled = false
	# --- the summary card leads to the main menu
	main.start_run(false)
	main.combo.feat()
	main.run_meat = 0
	main._press_stop()
	main._press_stop()
	main._refresh_hud()
	check(main.state == main.State.OVER and main.summary.visible and not main.hud.market_button.visible and not main.hud.combo_meter.visible,
			"the summary card has the screen to itself (no side buttons or combo meter over it)")
	main._touch_pressed("")
	main._refresh_hud()
	check(main.state == main.State.TITLE and not main.summary.visible and main.hud.market_button.visible and main.hud.herd_button.visible
			and main.hud.codex_button.visible and main.hud.sub_label.text.contains("again"), "a tap on the summary opens the main menu: run again, Field Guide, Camp or Market")
	main._touch_pressed("")
	check(main.state == main.State.TITLE, "the tap that closed the summary can't start a run by accident")
	main._menu_t = 0.0
	main._touch_pressed("")
	check(main.state != main.State.TITLE, "a tap on the main menu starts a run")
	main.start_run(false)
	# --- gear
	main.start_run(false)
	p = main.player
	main.gear_owned.clear()
	main.gear_equipped.clear()
	main.cards.clear()
	main._sync_gear()
	var power0 := Dinos.stat("rok", "power")
	check(not main.equip_gear("rok", "weapon", "stone_axe#1"), "gear you don't own can't be equipped")
	main.meat_bank = 100000
	check(not Market.items().has("stone_axe") and not main.buy("stone_axe"), "weapons aren't sold in the Market (they're crafted)")
	main.best_m = 10000
	main.materials.clear()
	check(not main.can_craft("stone_axe") and main.craft("stone_axe") == "", "without its materials a weapon can't be crafted")
	main.grant_materials({"wood": 200, "stone": 200, "fiber": 200, "flint": 50, "hide": 50, "bone": 50, "resin": 20, "dino_scale": 20, "shell": 10}, false)
	var wood0 := Crafting.have("wood")
	var axe: String = main.craft("stone_axe", "", 0.0)   # roll 0 = Common
	check(axe.begins_with("stone_axe#") and main.gear_owned.has(axe) and Gear.rarity_of(axe) == 0 and Crafting.have("wood") == wood0 - int(Crafting.recipe("stone_axe").wood),
			"crafting spends the recipe and adds a Common copy on a low roll")
	check(main.equip_gear("rok", "weapon", axe) and Gear.slot_item("rok", "weapon") == axe, "...and it can be equipped on a hero")
	check(is_equal_approx(Dinos.stat("rok", "power"), power0 + 2.0), "the Stone Axe adds 2 Power to Rok")
	check(not main.equip_gear("rok", "armor", axe), "a weapon doesn't go in the armor slot")
	check(main.attack_reach() == Gear.reach("rok") and Gear.reach("rok") > Tuning.ATTACK_REACH_HAND, "a weapon reaches further than bare hands")
	main.attack_cd = 0.0
	main._attack()
	check(main.player.attack_clip == "attack_stone_axe" and main.player.atk.visible, "Rok swings his Stone Axe with its own attack clip")
	main.player.attack_stop()
	# --- the seamless running attack (the user's Rok_Running_Club)
	var club: String = main.craft("club", "", 0.0)
	check(club != "" and main.equip_gear("rok", "weapon", club), "(the club, crafted and equipped)")
	p.on_ground = true
	p.sprite.play("run")
	p.set_carry(main.carry_weapon())
	check(p.carry == "club" and p.sprite.sprite_frames == SpriteLib.carry_frames(Forms.ROK, "club") and p.sprite.sprite_frames != SpriteLib.character(Forms.ROK),
			"carrying the club, Rok's run has it drawn in")
	p.sprite.frame = 5
	p.gear._place()
	check(not p.gear._weapon.visible, "...and the separate club isn't drawn on top while he runs")
	main.attack_cd = 0.0
	main._attack()
	check(p.run_attack_phase == 5 and p.attack_clip == "run_attack_club" and String(p.atk.animation) == "p5" and p.atk.frame == 0 and p.atk.visible,
			"ATTACK while running plays the running swing made for the current run phase")
	for k in 4:
		p.sprite.frame = (p.sprite.frame + 1) % 8
	check(p.atk.frame == 4 and p.attack_clip == "run_attack_club", "...stepped by the run's own frames (the hit on frame 4)")
	for k in 4:
		p.sprite.frame = (p.sprite.frame + 1) % 8
	check(p.attack_clip == "" and p.sprite.frame == 5 and String(p.sprite.animation) == "run", "...and after 8 frames the run carries on at the phase it started from")
	main.attack_cd = 0.0
	main._attack()
	p.on_ground = false
	p._attack_step()
	check(p.attack_clip == "" and p.run_attack_phase == -1, "leaving the ground ends the running swing")
	p.sprite.play("jump")
	main.attack_cd = 0.0
	main._attack()
	check(p.attack_clip == "attack_club", "in the air the standing swing plays instead")
	p.attack_stop()
	p.on_ground = true
	main.equip_gear("rok", "weapon", axe)
	p.set_carry(main.carry_weapon())
	check(p.carry == "" and p.sprite.sprite_frames == SpriteLib.character(Forms.ROK),
			"a weapon without a running sheet keeps the plain run (the held weapon drawn on)")
	main.equip_gear("rok", "armor", main.craft("shell_plate", "", 0.0))
	check(Forms.get_data(Forms.ROK).has("stumble_mult") and float(Forms.get_data(Forms.ROK).stumble_mult) < 1.0, "armor makes Rok tougher in play")
	var lv0 := Dinos.trained_stat("rok", "armor")
	check(Dinos.stat("rok", "armor") > lv0 and Dinos.can_raise("rok", "armor") == (lv0 < Dinos.level_cap("rok", "armor") - 0.001), "gear never blocks levelling")
	var saved := SaveData.load_gear()
	check((saved.owned as Array).has(axe) and saved.equipped.rok.weapon == axe and int(saved.materials.wood) == Crafting.have("wood"), "gear and materials are saved")
	# --- weapon durability (each connecting ATTACK wears it; broken = no bonus until repaired)
	check(Gear.durability(axe) == Gear.max_durability(axe) and Gear.max_durability(axe) > 0 and Gear.max_durability("shell_plate") == 0,
			"a new weapon has full durability and armor doesn't wear")
	main.gear_wear[axe] = 2
	main.wear_weapon(axe)
	check(Gear.durability(axe) == 1 and not Gear.broken(axe) and is_equal_approx(Dinos.stat("rok", "power"), power0 + 2.0), "a hit wears a weapon down by one")
	main.wear_weapon(axe)
	check(Gear.broken(axe) and is_equal_approx(Dinos.stat("rok", "power"), power0) and Gear.reach("rok") == Tuning.ATTACK_REACH_HAND
			and main.audio.played.has("weapon_break"), "at 0 the weapon breaks: no bonus, bare-hand reach, a snap")
	check(main.attack_clip() == "", "a broken weapon has no attack clip (bare hands)")
	check(int(SaveData.load_gear().wear[axe]) == 0, "wear is saved")
	var rcost := Gear.repair_cost(axe)
	var rwood := Crafting.have("wood")
	var rbank: int = main.meat_bank
	check(not rcost.is_empty() and int(rcost.get("wood", 0)) <= int(Crafting.recipe("stone_axe").wood) and main.repair_gear(axe) and main.meat_bank == rbank
			and Crafting.have("wood") == rwood - int(rcost.get("wood", 0)) and Gear.durability(axe) == Gear.max_durability(axe) and not Gear.broken(axe),
			"repairing at the Camp costs materials (not meat) and restores it")
	check(Gear.repair_cost(axe).is_empty() and not main.repair_gear(axe), "a weapon at full durability needs no repair")
	# --- crafting (the user's design: gear is crafted, never bought; config/crafting.cfg)
	Crafting.forget()
	check(Crafting.materials().size() == 12 and Crafting.recipes().size() == Gear.ITEMS.size(), "crafting.cfg lists 12 materials and a recipe for every weapon and armor")
	check(Crafting.recipes().all(func(k): return Crafting.recipe(k).keys().all(func(m): return Crafting.is_material(m))), "every recipe uses real materials")
	var c_bm := Crafting.bench_m()
	main.best_m = c_bm - 1.0
	check(c_bm > 0 and not main.bench_open() and not main.can_craft("club"), "the Crafting Bench is closed before its distance (%d m)" % c_bm)
	main.open_bench()
	check(not main.bench.visible, "...and can't be opened")
	check(not Market.on_sale("mat_wood", main.best_m), "...and the Market doesn't sell materials yet")
	main.best_m = 10000
	check(main.bench_open() and Market.on_sale("mat_wood", main.best_m), "past it the bench opens and wood is on sale")
	var c_legend: String = main.craft("stone_axe", "", 0.9999)
	check(Gear.rarity_of(c_legend) == 4 and Gear.full_name(c_legend).begins_with("Legendary"), "a lucky roll crafts a Legendary copy")
	check(float(Gear.item_bonus(c_legend).power) > float(Gear.item_bonus(axe).power) and Gear.max_durability(c_legend) > Gear.max_durability(axe),
			"rarity raises its bonus and durability")
	main.gear_rarity["bone_hammer#99"] = 4
	check(Gear.item_bonus("bone_hammer#99").speed == Gear.ITEMS.bone_hammer.bonus.speed and Gear.item_bonus("bone_hammer#99").power > Gear.ITEMS.bone_hammer.bonus.power,
			"rarity raises the good and never makes a drawback worse")
	main.gear_rarity.erase("bone_hammer#99")
	check(float(Crafting.odds("primal_crystal")[0]) == 0.0 and float(Crafting.odds("")[0]) > 0.5, "a catalyst changes the odds (a Primal Crystal never rolls Common)")
	main.materials["primal_crystal"] = 1
	var c_pc: String = main.craft("club", "primal_crystal", 0.0)
	check(Gear.rarity_of(c_pc) >= 1 and Crafting.have("primal_crystal") == 0, "crafting with a catalyst spends it and rolls better")
	check(not main.can_craft("club", "primal_crystal"), "a catalyst you don't have can't be used")
	var c_back := Crafting.salvage_return("stone_axe", 4)
	var s_wood := Crafting.have("wood")
	check(main.salvage(c_legend) and not main.gear_owned.has(c_legend) and Crafting.have("wood") == s_wood + int(c_back.wood) and c_back.has("primal_crystal"),
			"salvaging returns half the recipe, plus a catalyst for rare and better")
	check(not main.salvage(Gear.slot_item("rok", "weapon")), "equipped gear can't be salvaged")
	Gear.rarity.erase("club")
	check(Gear.base("club") == "club" and Gear.rarity_of("club") == 0 and Gear.max_durability("club") == int(Gear.ITEMS.club.durability), "gear from old saves counts as Common")
	# materials from runs
	var c_rock := Obstacle.new()
	main.world.add_child(c_rock)
	c_rock.kind = "rock"
	main.mat_drop_override = 0.0
	var c_got: Dictionary = main._break_materials(c_rock, c_rock.position)
	check(not c_got.is_empty() and c_got.keys().all(func(m): return ["stone", "flint", "obsidian"].has(m)), "a broken c_rock drops stone, flint or obsidian")
	c_rock.kind = "wood"
	check(main._break_materials(c_rock, c_rock.position).keys().all(func(m): return ["wood", "fiber"].has(m)), "a broken log drops wood or fiber")
	c_rock.critter = "gallimimus"
	var c_wg: Dictionary = main._wild_materials(c_rock)
	check(not c_wg.is_empty() and c_wg.keys().all(func(m): return Crafting.num("wild_drops", "land").has(m)), "a bonked wild dinosaur drops hide, bone or scales")
	main.mat_drop_override = 0.999
	check(main._break_materials(c_rock, c_rock.position).is_empty(), "...and only by chance")
	main.mat_drop_override = -1.0
	c_rock.queue_free()
	var rw := Crafting.rarity_weighted({"wood": 1.0, "resin": 1.0, "primal_crystal": 1.0})
	check(float(rw.wood) > float(rw.resin) * 3.0 and float(rw.resin) > float(rw.primal_crystal) * 3.0, "drop rarity: rarer materials drop far less often (config [drop_rarity])")
	check(float(Crafting.num("break_drops", "chance")) <= 0.25 and float(Crafting.num("spots", "chance")) <= 0.1, "materials are rare in runs")
	check(Chest.REWARDS.common.has("materials") and Chest.REWARDS.epic.has("materials"), "chests can hold materials")
	var c_cm := Crafting.have("shell") + Crafting.have("fossil_shard") + Crafting.have("dino_scale") + Crafting.have("primal_crystal")
	var c_chest := Pickup.new().setup("chest")
	main.course.add_child(c_chest)
	main.course.pickups.append(c_chest)
	main._open_chest(c_chest, 0.0, "materials")
	check(Crafting.have("shell") + Crafting.have("fossil_shard") + Crafting.have("dino_scale") + Crafting.have("primal_crystal") > c_cm, "an epic c_chest's materials are rare ones")
	check(main.course._fill("material", false).begins_with(Crafting.PICKUP_PREFIX), "a material reward spot holds material pickups")
	var c_mp := Pickup.new().setup("m_flint")
	check(c_mp.sprite is Sprite2D and (c_mp.sprite as Sprite2D).texture != null, "a material pickup shows its icon")
	c_mp.free()
	check(Crafting.spot_table("forest", 0.0, 0.0) == Crafting.num("spots", "forest") and Crafting.spot_table("forest", 99999.0, 0.0) == Crafting.num("spots", "deep"),
			"deep in a run material spots can hold the rare table")
	main.run_materials = {"wood": 2}
	main.new_this_run.clear()
	main._bank_meat()
	check(main.new_this_run.any(func(n): return String(n).begins_with("Found")), "materials found in a run are news on the summary")
	# the Crafting Bench and Items screens (from the Camp's header)
	main.open_herd("rok")
	check(main.herd.find_child("BenchButton", true, false) != null and main.herd.find_child("ItemsButton", true, false) != null, "the Camp's header has Crafting and Items")
	main.open_bench("weapon")
	var c_bn: Workshop = main.bench
	check(c_bn.visible and c_bn.list.get_child_count() == Crafting.recipes().filter(func(k): return Gear.ITEMS[k].slot == "weapon").size(), "the bench lists every weapon recipe")
	c_bn.select("flint_spear")
	check(c_bn.detail.find_child("Materials", true, false) != null and c_bn.detail.find_child("Odds", true, false) != null and c_bn.detail.find_child("Craft", true, false) != null,
			"a recipe shows its materials, the odds and Craft")
	var n_gear: int = main.gear_owned.size()
	c_bn.press_craft()
	check(main.gear_owned.size() == n_gear, "one tap only arms Craft")
	var c_made := c_bn.press_craft()
	check(c_made.begins_with("flint_spear#") and main.gear_owned.size() == n_gear + 1 and (c_bn.detail.find_child("Result", true, false) as Label).visible, "the second crafts it and shows the result")
	c_bn.close_screen()
	main.open_items("materials")
	var c_it: Workshop = main.items
	check(c_it.visible and c_it.list.get_child_count() == Crafting.materials().filter(func(m): return Crafting.have(m) > 0).size(), "the Items screen lists the materials you have")
	c_it.show_tab("weapon")
	c_it.select(c_made)
	check(c_it.detail.find_child("Salvage", true, false) != null and c_it.detail.find_child("Stats", true, false) != null, "an unequipped weapon shows its stats and Salvage")
	c_it.press_salvage()
	check(main.gear_owned.has(c_made), "one tap only arms Salvage")
	c_it.press_salvage()
	check(not main.gear_owned.has(c_made), "the second salvages it")
	c_it.close_screen()
	main.herd.close_herd()
	# --- cooldowns shortened by attributes (ATTACK by Power, the slide by Speed)
	check(Dinos.cooldown_mult("raptor", "speed") < Dinos.cooldown_mult("spinosaurus", "speed") and Dinos.cooldown_mult("rok", "power") < 1.0,
			"more Speed or Power means a shorter cooldown")
	check(Tuning.JUMP_COOLDOWN == 0.0, "jumping has no cooldown")
	# --- cards
	# cards are dropped by wild dinosaurs (not sold): always the first time per species, then by chance
	check(not Market.items().has(Gear.CARD_PACK), "dinosaur cards aren't sold in the Market")
	var wild := Obstacle.new()
	main.world.add_child(wild)
	wild.critter = "gallimimus"
	main.seen.erase("card_gallimimus")
	var n0 := int(main.cards.get("gallimimus", 0))
	main.card_drop_override = 0.999   # every roll fails
	main._drop_card(wild)
	check(int(main.cards.get("gallimimus", 0)) == n0 + 1 and main.last_card == "gallimimus", "the first wild Gallimimus bonked drops its card")
	main._drop_card(wild)
	check(int(main.cards.get("gallimimus", 0)) == n0 + 1, "after that a card drops only by chance")
	main.card_drop_override = 0.0
	main._drop_card(wild)
	check(int(main.cards.get("gallimimus", 0)) == n0 + 2, "...and a lucky roll drops another")
	main.card_drop_override = -1.0
	wild.queue_free()
	var card: String = Gear.CARD_PREFIX + main.last_card
	check(Gear.choices("weapon").has(card) and not Gear.choices("armor").has(card), "cards go in the weapon slot")
	var lean: String = Dinos.CATEGORIES[Dinos.category_of(String(main.last_card))].lean
	var before := Dinos.stat("rok", lean)
	main.equip_gear("rok", "weapon", card)
	check(Dinos.stat("rok", lean) > before - 2.0 + 0.001 or Dinos.stat("rok", lean) >= 10.0, "a card adds its dinosaur's best attribute (%s)" % lean)
	check(Chest.REWARDS.rare.has("card") and Chest.REWARDS.epic.has("card"), "rare and epic chests can hold cards")
	main.equip_gear("rok", "weapon", "")
	main.equip_gear("rok", "armor", "")
	check(not Gear.has_any("rok") and is_equal_approx(Dinos.stat("rok", "power"), power0), "emptying the slots takes the bonuses away")
	# --- Camp: equipment and red dots
	main.open_herd("rok")
	var h: Herd = main.herd
	h.select("rok")
	check(h.detail.find_child("Slot_weapon", true, false) != null and h.detail.find_child("Slot_armor", true, false) != null, "the Camp shows a hero's weapon and armor slots")
	check(main.gear_ready(), "owned gear with an empty slot puts a red dot on the Camp")
	h.press_slot("weapon")
	check(h.list.find_child("Gear_" + axe, true, false) != null and h.list.find_child("Gear_none", true, false) != null, "Change lists what can go in the slot")
	h.press_gear(axe)
	check(Gear.slot_item("rok", "weapon") == axe and h.picking == "", "picking one equips it")
	h.close_herd()
	check(main.herd.find_child("Backdrop", true, false) != null and main.market.find_child("Backdrop", true, false) != null and main.codex.find_child("Backdrop", true, false) != null,
			"the Camp, Market and Field Guide are their own full screens")
	# the loading screen preloads what a run draws (the user's request)
	check(main.loader == null, "test scripts skip the loading screen (only a normal launch shows it)")
	var plc := Preloader.collect()
	check((plc[0] as Array).any(func(x): return String(x).contains("characters/rok/run")) and (plc[1] as Array).any(func(x): return String(x).contains("attacks/")),
			"the loading screen loads the forms' body and attack sheets")
	var pl := Preloader.new()
	main.add_child(pl)
	pl.run_all()
	check(pl._done == pl._total and Preloader.keep.size() >= (plc[0] as Array).size() and SpriteLib._cache.has("attack_raptor"),
			"...loads everything and builds the run's animation frames")
	pl.queue_free()
	# the Dinosaur Camp's stage: the chosen one idles and now and then attacks
	main.unlocked = Forms.ORDER.duplicate()
	main.open_herd("runner")
	var hs: Herd = main.herd
	check(hs.stage_body.visible and hs.stage_body.is_playing() and String(hs.stage_body.animation) == "idle" and hs.stage.texture == null,
			"the Dinosaur Camp's dinosaur plays its idle loop (not a still picture)")
	hs._stage_attack()
	check(hs.stage_atk.visible and not hs.stage_body.visible and String(hs.stage_atk.animation) == "attack", "...and now and then its attack")
	hs._stage_idle()
	check(hs.stage_body.visible and not hs.stage_atk.visible, "...then idles again")
	check(hs.find_child("TitleBanner", true, false) != null and (not SceneKit.has() or (hs.find_child("TitleBanner", true, false).get_child(0) as Label).text == "DINOSAUR CAMP"),
			"the screen is called the Dinosaur Camp")
	hs.close_herd()
	main.unlocked = [Forms.ROK]
	# the user's card pack: a card for the four originals and the first 16 species
	var carded := ["raptor", "triceratops", "spinosaurus", "pteranodon"] + Dinos.ids().slice(0, 16)
	check(carded.all(func(d): return CardView.art(d) != null) and Gear.icon(Gear.CARD_PREFIX + "gallimimus") == CardView.art("gallimimus"),
			"the 20 dinosaurs in the card pack have their card art, also on tiles")
	# Elder Numa speaks (the user's request)
	check(Codex.NUMA_LINES.keys().all(func(k): return (Codex.NUMA_LINES[k] as Array).size() >= 5) and range(7).all(func(i): return Codex.NUMA_LINES.has("tab_%d" % i)),
			"Elder Numa has at least five lines for every situation and a pool per tab")
	main.open_guide()
	var cx: Codex = main.codex
	if cx.numa_label:
		check(cx.numa_bubble.visible and Codex.NUMA_LINES.greet.has(cx.numa_label.text), "opening the Encyclopedia, Numa greets you")
		cx._show_tab(1)
		check(Codex.NUMA_LINES.tab_1.has(cx.numa_label.text), "...each tab has her own words")
		var lk := cx.grid.get_children().find_custom(func(t): return t.get_meta("locked", false))
		if lk >= 0:
			cx.select(lk)
			check(Codex.NUMA_LINES.locked.has(cx.numa_label.text), "...and an undiscovered entry gets a 'not yet'")
		check(cx.numa_bubble.position.y + cx.numa_bubble.size.y <= cx.elder.position.y + 1.0, "her bubble sits above her, not over her")
	cx.close_guide()
	main.gear_owned.clear()
	main.gear_equipped.clear()
	main.cards.clear()
	main._save_gear()
	main.meat_bank = 0
	# --- levelling is slower and ready level-ups show a dot
	check(Dinos.XP_STEP >= 400.0, "levels need more XP than before")
	main.dino_xp["rok"] = Dinos.xp_for(Dinos.level("rok") + 1)
	Dinos.xp = main.dino_xp
	main.meat_bank = Dinos.level_cost("rok")
	check(main.level_ready().has("rok"), "a hero with the XP and meat to level up is ready (red dot)")
	main.meat_bank = 0
	check(not main.level_ready().has("rok"), "...and isn't without the meat")
	main.dino_xp.erase("rok")
	# --- first sight: new things are introduced before they're picked up
	main.start_run(false)
	c = main.course
	main.seen.erase("fossil")
	main.hud.clear_banner()
	c._pickup("fossil", Vector2(main.get_viewport().get_visible_rect().size.x - 200.0, Tuning.GROUND_Y - 100.0))
	main._first_sight_step()
	check(main.seen.has("fossil") and main.hud.banner_title.text.contains("RARE FOSSIL"), "a rare fossil is introduced as soon as it comes on screen")
	main.seen.erase("power_time_crystal")
	main.boosters_owned.append("time_crystal")
	c._pickup("time_crystal", Vector2(900.0, Tuning.GROUND_Y - 100.0))
	main._first_sight_step()
	check(main.seen.has("power_time_crystal"), "a newly bought power-up is introduced when it first appears")
	main.boosters_owned.erase("time_crystal")
	# --- big meat is the meat art, bigger
	var bm := Pickup.new().setup("big_meat")
	var mm := Pickup.new().setup("meat")
	check(bm.sprite.scale.x > mm.sprite.scale.x * 1.4, "big meat is the meat drawn bigger")
	bm.free()
	mm.free()
	# --- walls are as tall in every zone; wild dinosaurs come often
	main.start_run(false)
	c = main.course
	c._ground = Tuning.GROUND_Y
	var heights := []
	for m in [150.0, Zones.ZONE_LEN_M * 1.3, Zones.ZONE_LEN_M * 2.3]:
		c.metres = m
		var w := c.rock_wall(Tuning.PLAYER_X + 500.0, 3)
		heights.append(w.hitbox().size.y)
		c.remove_obstacle(w)
	check(absf(heights[1] - heights[0]) < 12.0 and absf(heights[2] - heights[0]) < 12.0, "a 3-high wall is as tall in every zone %s" % [heights])
	check(Progression.intro_m("stampede") < 3200.0 and Progression.intro_m("swooper") < 3200.0 and Tuning.CRITTER_WEIGHT > 1.5,
			"wild dinosaurs arrive early and come often")
	check(Tuning.BONUS_FROM_M <= 1000.0 and Tuning.BONUS_GAP_MAX <= 2000.0, "bonus zones come early and often")
	# --- the Stop button: two taps end the run (meat kept), no death
	main.start_run(false)
	main._refresh_hud()
	check(main.hud.stop_button.visible, "a Stop button shows during a run")
	main.run_meat = 5
	var bank1: int = main.meat_bank
	main._press_stop()
	check(main.state == main.State.PLAYING and main.stop_armed > 0.0, "one tap only asks")
	main._press_stop()
	check(main.state == main.State.OVER and main.death_cause == "stopped" and main.meat_bank >= bank1 + 5 and main.summary.visible,
			"a second tap ends the run, keeps the meat and shows the summary")
	main._refresh_hud()
	check(not main.hud.stop_button.visible, "no Stop button outside a run")
	main.start_run(false)
	main._press_stop()
	main.stop_armed = 0.0
	main._press_stop()
	check(main.state == main.State.PLAYING, "a second tap after the wait only asks again")
	main.stop_armed = 0.0
	main._pause()
	main._press_stop()
	main._press_stop()
	check(main.state == main.State.OVER, "the run can be stopped while paused")
	# --- side buttons and full-screen scenes
	main._to_title()
	main._refresh_hud()
	var vw: float = main.get_viewport().get_visible_rect().size.x
	var hd: Hud = main.hud
	check(hd.codex_button.position.x < 60.0 and hd.herd_button.position.x < 60.0 and hd.market_button.position.x + hd.market_button.size.x > vw - 60.0,
			"the Guide and Camp buttons sit on the left edge, the Market on the right")
	check([hd.codex_button, hd.market_button, hd.herd_button].all(func(b): return b.caption != "" or b.banner != null), "the side buttons say what they open")
	check(hd.codex_button.banner != null and hd.codex_button.banner.resource_path.ends_with("square_encyclopedia.png")
			and hd.market_button.banner.resource_path.ends_with("square_marketplace.png") and hd.herd_button.banner.resource_path.ends_with("square_dinosaurs.png"),
			"the side buttons are the user's square Encyclopedia, Marketplace and Dinosaurs buttons")
	var titles_ok := true
	var kit := SceneKit.has()   # the user's scene kit brings its own title plaques
	for pair in [[main.market, "market/ui/title.png"], [main.herd, "scenes/title_blank.png" if kit else "banner_dinosaurs.png"], [main.codex, "scenes/encyclopedia_title.png" if kit else "banner_encyclopedia.png"]]:
		var tb: Node = pair[0].find_child("TitleBanner", true, false)
		var art: String = "" if tb == null else (String(tb.get_meta("art")) if tb.has_meta("art") else (tb as TextureRect).texture.resource_path)
		titles_ok = titles_ok and art.ends_with(pair[1])
	check(titles_ok, "the user's title plaques head the Field Guide (the scene kit's; the Dinosaur Camp's name on its blank plaque), the Marketplace UI pack's the Market")
	check(hd.market_button.hit(hd.market_button.global_position + Vector2(hd.market_button.size.x - 8.0, hd.market_button.size.y * 0.5)), "a banner button takes a tap anywhere on it")
	for scr in [main.market, main.herd, main.codex]:
		var back: Node = scr.find_child("Back", true, false)
		check(back != null and back.get_index() == 0, "%s has a Back button first in its header" % scr.name)
	main.open_market()
	check(main.market.visible and main.market.root.modulate.a < 1.0, "opening the Market fades in like a scene")
	main.market.close_market()
	main.start_run(false)


## Today's daily missions, all marked done, so they can't add meat to checks
## that count it.
func _quiet_missions() -> void:
	main.missions.refresh(Time.get_date_string_from_system(), main.best_m, main.unlocked)
	main.missions.done = main.missions.ids.map(func(_i): return true)
	main.missions.last_full = main.missions.date


## Mid-run events, bonus zones, lap twists and daily missions.
func _variety_checks() -> void:
	# --- mid-run events
	main.start_run(false)
	check(main.events.current == "" and main.events.next_m >= Tuning.EVENT_FROM_M, "no event at the start of a run")
	check(not RunEvents.pool(false).has("stampede_rush") and RunEvents.pool(true).has("stampede_rush"), "a stampede rush needs the stampede taught")
	main.distance = (Tuning.EVENT_FROM_M + 800.0) * Tuning.PX_PER_M
	main.events.next_m = 0.0
	main._event_step(1.0 / 60.0)
	check(main.events.current != "" and main.hud.event_label.visible, "a due event starts and the HUD shows it")
	var started_m: float = main.metres()
	check(main.events.next_m >= started_m + Tuning.EVENT_GAP_MIN, "the next event waits at least EVENT_GAP_MIN")
	main._event_step(100.0)
	main._event_step(1.0 / 60.0)
	check(main.events.current == "" and not main.hud.event_label.visible, "an event ends after its time")
	# golden hour: meat counts double and spots are meat
	main.start_run(false)
	var c: Course = main.course
	var p: Player = main.player
	c.metres = 500.0
	main._start_event("golden_hour")
	check(c.force_meat and c._spot_kind() in ["meat", "heart", "power", "fossil"], "a golden hour fills reward spots with meat")
	var meat0: int = main.run_meat
	c._pickup("meat", p.position + Vector2(0, -60))
	main._collide()
	check(main.run_meat == meat0 + Tuning.GOLDEN_HOUR_MEAT, "in a golden hour meat counts double")
	# meteor shower: a rock falls onto the ground ahead
	main.start_run(false)
	c = main.course
	c._ground = Tuning.GROUND_Y
	var n0 := c.obstacles.size()
	main._meteor(Tuning.PLAYER_X + 600.0, Tuning.GROUND_Y)
	check(c.obstacles.size() <= n0 + 1, "a meteor drops one rock")
	if c.obstacles.size() == n0 + 1:
		check(c.obstacles[-1].position.y < Tuning.GROUND_Y - 300.0, "...from high above")
	# while hazards are held (a dino unlock's gate comes first), events drop none
	main.start_run(false)
	c = main.course
	c.holding = true
	var held := c.obstacles.size()
	main._event_spawn("meteor_shower")
	main._event_spawn("stampede_rush")
	check(c.obstacles.size() == held, "events drop no hazards while a dino gate is due")
	c.holding = false
	# a falling meteor can be smashed with ATTACK, even high in the air
	main.start_run(false)
	c = main.course
	c._ground = Tuning.GROUND_Y
	main.attack_cd = 0.0
	var tries_m := 0
	var rock: Obstacle = null
	while rock == null and tries_m < 20:   # (a Forest meteor can come up as a mushroom: those are skipped)
		var before_m := c.obstacles.size()
		main._meteor(Tuning.PLAYER_X + 220.0, Tuning.GROUND_Y)
		if c.obstacles.size() > before_m:
			rock = c.obstacles[-1]
		tries_m += 1
	if rock != null:
		main._attack_marker_step()
		check(main.attack_marker.visible and main.attack_marker.box == rock.hitbox(), "the marker follows a falling meteor")
	check(rock != null and rock.position.y < Tuning.GROUND_Y - 300.0 and main._attack() == rock and not c.obstacles.has(rock),
			"ATTACK smashes a meteor while it's still falling")
	# amber storm and stampede spawn things
	main.start_run(false)
	c = main.course
	var a0 := c.pickups.size()
	main.unlocked.append(Forms.RAPTOR)   # amber needs a dinosaur (config/requirements.cfg)
	main._event_spawn("amber_storm")
	check(c.pickups.size() == a0 + 1 and c.pickups[-1].kind == "amber", "an amber storm drops amber")
	main.unlocked.erase(Forms.RAPTOR)
	# no event during a frenzy
	main.start_run(false)
	main.distance = (Tuning.EVENT_FROM_M + 800.0) * Tuning.PX_PER_M
	main.events.next_m = 0.0
	main.combo.frenzy_t = 5.0
	main._event_step(1.0 / 60.0)
	check(main.events.current == "", "no event starts during a frenzy")

	# --- bonus zones (switched off for now: Tuning.BONUS_ENABLED)
	main.start_run(false)
	if not Tuning.BONUS_ENABLED:
		main.distance = (Tuning.BONUS_FROM_M + 2000.0) * Tuning.PX_PER_M
		main.next_bonus_m = 0.0
		for i in 200:
			main._bonus_step(1.0 / 60.0)
		check(main.portal == null and main.bonus_t <= 0.0, "no bonus portal while bonus zones are switched off")
		main.start_run(false)
	if Tuning.BONUS_ENABLED:
		c = main.course
		p = main.player
		main.distance = (Tuning.BONUS_FROM_M + 2000.0) * Tuning.PX_PER_M
		main.next_bonus_m = 0.0
		main.terrain.metres = main.metres()
		var tries := 0
		while main.portal == null and tries < 400:
			main._bonus_step(1.0 / 60.0)
			main.terrain.scroll(8.0)
			c.scroll(480.0, 1.0 / 60.0)
			tries += 1
		check(main.portal != null and main.terrain.calm and c.holding, "a bonus portal appears on flat ground and calms what's behind it")
		if main.portal != null:
			var px: float = main.portal.position.x
			check(c.obstacles.all(func(o): return o.position.x < px - 200.0), "nothing waits behind the portal")
			var t: Terrain = main.terrain
			var lx := px - t.position.x
			t.calm = true
			for i in 6:
				t._generate()
			check(t.features.filter(func(f): return f.x0 > lx).all(func(f): return f.type == "flat" and f.get("liquid", "") == ""),
					"only flat ground follows the portal")
			main.portal.position.x = p.position.x - 1.0
			main._bonus_step(1.0 / 60.0)
			check(main.bonus_t > 0.0 and main.bonus_zones == 1, "running through the portal starts the bonus zone")
			var k0 := c.pickups.size()
			for i in int(Tuning.BONUS_TIME / Tuning.BONUS_DROP_EVERY) + 3:
				main._bonus_step(Tuning.BONUS_DROP_EVERY)
			check(main.bonus_t <= 0.0 and c.pickups.size() > k0, "treasure rains down, then the bonus zone ends")
			check(not main.terrain.calm and not c.holding, "afterwards hazards and normal ground come back")
		check(main.events.next_m > 0.0, "(events are held off by a bonus zone)")

	# --- lap twists
	main.start_run(false)
	check(main.lap == 1 and Weather.twist_for_lap(1) == "" and main.weather.twist == "", "the first lap has no twist")
	var twists := []
	for n in [2, 3, 4, 5]:
		twists.append(Weather.twist_for_lap(n))
	check(twists == ["storm", "fog", "eclipse", "storm"], "laps 2, 3, 4 bring a storm, fog and an eclipse, then repeat")
	var base: float = main.points_mult()
	var lap_len := Zones.ZONE_LEN_M * Zones.ZONES.size()
	main.distance = (lap_len + 10.0) * Tuning.PX_PER_M
	main._lap_step(1.0 / 60.0)
	check(main.lap == 2 and main.weather.twist == "storm" and is_equal_approx(main.points_mult(), base * (1.0 + Tuning.LAP_BONUS)),
			"lap 2 brings its twist and pays more points")
	main._lap_step(Tuning.LAP_BANNER_DELAY + 0.1)
	main.distance = (lap_len * 3.0 + 10.0) * Tuning.PX_PER_M
	main._lap_step(1.0 / 60.0)
	main._update_environment()
	var dark: Color = main.lighting.color
	check(main.weather.twist == "eclipse" and main.weather.light_mult() < 1.0, "an eclipse darkens the world (%s)" % dark)
	main.start_run(false)
	check(main.lap == 1 and main.weather.twist == "", "a new run starts on lap 1 with clear skies")

	# --- daily missions
	var ms := Missions.new()
	ms.refresh("2026-11-21", 500.0, [Forms.ROK])
	var same := Missions.new()
	same.refresh("2026-11-21", 500.0, [Forms.ROK])
	check(ms.ids.size() == Missions.PER_DAY and ms.ids == same.ids, "three missions a day, the same all day")
	var other := Missions.new()
	var differ := false
	for d in ["2026-11-22", "2026-11-23", "2026-11-24", "2026-11-25"]:
		other.refresh(d, 500.0, [Forms.ROK])
		differ = differ or other.ids != ms.ids
	check(differ, "other days bring other missions")
	check(not Missions.eligible(500.0, [Forms.ROK]).has("gates") and not Missions.eligible(500.0, [Forms.ROK]).has("chests")
			and Missions.eligible(5000.0, Forms.ORDER).has("gates"), "missions only ask for what the player can already do")
	check(not ms.refresh("2026-11-21", 500.0, [Forms.ROK]), "refreshing on the same day keeps them")
	ms.ids = ["meat", "run_m", "amber"]
	ms.targets = [10, 300, 20]
	ms.progress = [0.0, 0.0, 0.0]
	ms.done = [false, false, false]
	check(ms.add("meat", 4).is_empty() and ms.add("meat", 6) == [0] and ms.done[0], "a total mission adds up and completes")
	check(ms.best("run_m", 200.0).is_empty() and ms.best("run_m", 150.0).is_empty() and ms.progress[1] == 200.0 and ms.best("run_m", 300.0) == [1],
			"a best mission keeps the best value")
	check(ms.add("meat", 5).is_empty(), "a done mission doesn't complete twice")
	var round_trip := Missions.new()
	round_trip.from_dict(ms.to_dict())
	check(round_trip.ids == ms.ids and round_trip.done == ms.done and round_trip.progress == ms.progress, "missions save and load")
	ms.add("amber", 20)
	ms.last_full = "2026-11-20"
	ms.streak = 2
	var bonus := ms.complete_day("2026-11-20")
	check(ms.all_done() and ms.streak == 3 and bonus == Tuning.MISSION_ALL_MEAT + 2 * Tuning.MISSION_STREAK_MEAT, "all three done pays a streak bonus")
	ms.last_full = "2026-11-10"
	check(ms.complete_day("2026-11-20") == Tuning.MISSION_ALL_MEAT and ms.streak == 1, "a missed day restarts the streak")
	# in the game
	main.start_run(false)
	main.missions.ids = ["meat", "amber", "ledges"]
	main.missions.targets = [3, 999, 999]
	main.missions.progress = [0.0, 0.0, 0.0]
	main.missions.done = [false, false, false]
	main.missions.date = Time.get_date_string_from_system()
	var bank0: int = main.meat_bank
	main.badge_event("meat", 3)
	check(main.missions.done[0] and main.meat_bank == bank0 + Tuning.MISSION_MEAT and main.new_this_run.any(func(x): return String(x).begins_with("Mission")),
			"completing a mission mid-run banks its meat and is news")
	main._to_title()
	check(main.hud.missions_panel.visible and main.hud.missions_label.text.contains("DAILY MISSIONS"), "the title screen lists today's missions")
	main.start_run(false)
	check(not main.hud.missions_panel.visible, "...and hides them in a run")


## The user's Hunters, Crouches and Best Distance pack
## (tools/prepare_animation_pack.gd).
func _animation_pack_checks() -> void:
	for id in ["carnotaurus", "allosaurus"]:
		check(Hunters.has_art(id) and Hunters.tint(id) == Color.WHITE and Hunters.snout(id) > 100.0,
				"the %s hunts in its own art (no tint)" % id)
		var sf := Hunters.frames(id)
		check(sf != SpriteLib.trex() and sf.has_animation("bite") and sf.get_frame_count("bite") == 8, "the %s has its own bite" % id)
	var dinos: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/dinos/dinos.json"))
	var crouched := 0
	for id in ["gallimimus", "dilophosaurus", "carnotaurus", "ankylosaurus", "pachycephalosaurus", "stegosaurus",
			"kentrosaurus", "baryonyx", "therizinosaurus", "allosaurus", "iguanodon", "parasaurolophus",
			"brachiosaurus", "diplodocus", "quetzalcoatlus", "dimorphodon"]:
		var play: Dictionary = dinos.creatures[id].play
		if play.get("own_duck", false) and (play.times.duck as Array).size() == 8:
			crouched += 1
	check(crouched == 16, "all 16 older expansion dinosaurs crouch with their own art (%d)" % crouched)
	for b in ["swift", "ironhide"]:
		var all4 := true
		for tier in 4:
			all4 = all4 and FileAccess.file_exists("res://assets/badges/%s_%d.png" % [b, tier])
		check(all4, "the %s badge has its four medals" % b)
	# the best-distance flag: waving, then passed
	check(BestFlag.has_art(), "the best-distance flag has its art")
	var flag := BestFlag.new().setup(500)
	check(flag._sprite != null and flag._sprite.animation == "waving", "the flag waves at the record")
	flag.passed = true
	check(flag._sprite.animation == "passed", "...and turns to the passed flag once Rok runs by")
	flag.free()
	# celebration jump: the next jump after a new best
	main.start_run(false)
	var p: Player = main.player
	check(p.sprite.sprite_frames.has_animation("celebrate"), "Rok has a celebration jump")
	var ground := p.position.y
	p.on_ground = true
	p._do_jump(false)
	check(p.sprite.animation == "jump", "an ordinary jump is the normal jump")
	while not p.on_ground:
		p.step(1.0 / 60.0, ground, 400.0)
	main.best_flag = BestFlag.new().setup(1)
	main.world.add_child(main.best_flag)
	main.distance = 2.0 * Tuning.PX_PER_M
	main._best_flag_step()
	check(p.celebrate_t > 0.0, "passing the best flag readies a celebration")
	p._do_jump(false)
	var meta := SpriteLib.celebrate_meta("rok")
	check(p.sprite.animation == "celebrate" and p.sprite.frame == int(meta.launch), "the next jump is the celebration, from its launch frame")
	var frames_seen := {}
	while not p.on_ground:
		p.step(1.0 / 60.0, ground, 400.0)
		frames_seen[p.sprite.frame] = true
	check(frames_seen.size() >= 3 and p.sprite.animation == "celebrate" and p.sprite.frame == int(meta.land),
			"its airborne frames follow the jump and it lands on its landing frame")
	check(p.sprite.is_playing() and not p.sprite.sprite_frames.get_animation_loop("celebrate"), "the landing plays out once")
	p.step(1.0 / 60.0, ground, 400.0)
	check(p.sprite.animation == "celebrate", "...without being cut short by the run")
	p.sprite.stop()   # (headless: animations don't advance) the landing finished
	p.step(1.0 / 60.0, ground, 400.0)
	check(p.sprite.animation == "run", "then Rok runs on")
	p._do_jump(false)
	check(p.sprite.animation == "jump", "only one jump celebrates")
	for hero in ["nira", "boro"]:
		check(not SpriteLib.celebrate_meta(hero).is_empty(), "%s has a celebration jump" % hero.capitalize())
	main.start_run(false)


## Deep quicksand: it grows with speed once the Raptor is unlocked, landing on
## it plunges and grips Rok, so neither one bound nor a hop chain gets across.
func _deep_quicksand_checks() -> void:
	main.start_run(false)
	var t: Terrain = main.terrain
	var p: Player = main.player
	var rok := Forms.get_data(Forms.ROK)
	# Forms.air_time matches the real jump: full jump, air jump just before landing
	var ground := p.position.y
	p.on_ground = true
	p._do_jump(false)
	var air := 0.0
	var used := false
	while not p.on_ground and air < 5.0:
		if not used and p.vy > 0.0 and p.position.y + p.vy / 60.0 >= ground:
			used = true
			p._do_jump(true)
		p.step(1.0 / 60.0, ground, 900.0)
		air += 1.0 / 60.0
	check(absf(air - Forms.air_time(rok)) < 0.05, "Forms.air_time matches Rok's real double jump (%.2f vs %.2f s)" % [air, Forms.air_time(rok)])
	# widths: always clearable before the Raptor, too deep for Rok after
	for v in [380.0, 650.0, 900.0]:
		t.speed = v
		var bound: float = v * Forms.air_time(rok)
		t.runner_ready = false
		check(t.quicksand_width(720.0) < bound, "before the Raptor, Rok can always bound over quicksand (%d px/s)" % int(v))
		t.runner_ready = true
		var w := t.quicksand_width(Tuning.QUICKSAND_MIN)
		var hop: float = v * Forms.air_time(rok, Tuning.QUICKSAND_GRIP)
		check(w > bound + hop, "after the Raptor, quicksand is wider than Rok's bound plus an escape hop (%d px/s)" % int(v))
		var raptor := Forms.get_data(Forms.RAPTOR)
		check(w / v * Tuning.SINK_RATE_FAST < 0.9, "the Raptor can still run all the way across it (%d px/s)" % int(v))
		check(w < v * Forms.air_time(raptor) * 1.35, "deep quicksand stays in reach of the Raptor's bound (%d px/s)" % int(v))
	check(t.quicksand_width(5000.0) == 5000.0, "quicksand never shrinks below its random width")
	t.runner_ready = true
	var had_raptor: bool = main.unlocked.has(Forms.RAPTOR)
	if not had_raptor:
		main.unlocked.append(Forms.RAPTOR)   # deep sand comes with the Raptor (and amber needs a dinosaur)
	var amber0: int = main.course.pickups.filter(func(k): return k.kind == "amber").size()
	var marks0: int = main.course.markers.size()
	check(t._quicksand(800.0).get("deep", false), "quicksand built after the Raptor unlock is deep")
	var sand_marks: Array = main.course.markers.filter(func(m): return m.get_meta("sand", false))
	check(main.course.markers.size() == marks0 + 1 and sand_marks.size() == 1 and int(sand_marks[0].get_meta("form")) == Forms.RAPTOR,
			"deep quicksand gets a floating Raptor marker")
	check(main.course.pickups.filter(func(k): return k.kind == "amber").size() > amber0, "...and an amber cache before it, for the energy to shift")
	if not had_raptor:
		main.unlocked.erase(Forms.RAPTOR)
	# landing on deep sand plunges Rok in and grips his feet
	main.start_run(false)
	p = main.player
	main.terrain.features[0].liquid = "quicksand"
	p.on_ground = false
	main._check_quicksand(1.0 / 60.0)
	p.on_ground = true
	main._check_quicksand(1.0 / 60.0)
	check(main.sink < 0.1 and p.sand_grip == 1.0, "shallow quicksand (before the Raptor) doesn't plunge or grip")
	main.sink = 0.0
	main.terrain.features[0].deep = true
	p.on_ground = false
	main._check_quicksand(1.0 / 60.0)
	check(main.sink == 0.0, "the sink meter doesn't drain or fill in the air over quicksand")
	main.sink = 0.2
	main._check_quicksand(1.0 / 60.0)
	check(is_equal_approx(main.sink, 0.2), "...and doesn't recover while still over it")
	main.sink = 0.0
	p.on_ground = true
	main._check_quicksand(1.0 / 60.0)
	check(main.sink >= Tuning.QUICKSAND_PLUNGE, "landing on quicksand plunges Rok in")
	check(p.sand_grip == Tuning.QUICKSAND_GRIP, "quicksand grips Rok's feet")
	p._do_jump(false)
	check(is_equal_approx(-p.vy, float(rok.jump) * Tuning.QUICKSAND_GRIP) and p.air_jumps_left == 0,
			"a jump off quicksand is weak and has no air jump")
	main._check_quicksand(1.0 / 60.0)   # airborne over the sand
	p.on_ground = true
	main._check_quicksand(1.0 / 60.0)   # a second landing
	check(main.state == main.State.DYING and main.death_cause == "quicksand", "two landings in quicksand swallow Rok (no hop chains)")
	# the Raptor skims: a small plunge, no grip
	main.start_run(false)
	p = main.player
	main.terrain.features[0].liquid = "quicksand"
	main.terrain.features[0].deep = true
	p.shift_to(Forms.RAPTOR)
	p.on_ground = false
	main._check_quicksand(1.0 / 60.0)
	p.on_ground = true
	main._check_quicksand(1.0 / 60.0)
	check(main.sink < 0.2 and p.sand_grip == 1.0, "the Raptor lands on quicksand without sinking in or getting stuck")
	# clear of the sand, the meter drains again
	main.terrain.features[0].liquid = ""
	main._check_quicksand(0.5)
	check(main.sink == 0.0 and p.sand_grip == 1.0, "off the sand, the sink drains and the grip lets go")
	main.start_run(false)
	# zone island art: the user's sandstone/basalt islands once imported, else the forest one
	for zid in ["forest", "desert", "volcanic"]:
		var want := "res://assets/props/Terrain-variation_03_%s.png" % zid
		if zid == "forest" or not ResourceLoader.exists(want):
			want = "res://assets/props/Terrain-variation_03.png"
		check(FloatingPlatform.island_texture(zid).resource_path == want, "%s floating islands use their zone's art (or the forest fallback)" % zid)
		var fp := FloatingPlatform.new().setup(1.5, zid)
		var ok := (fp.get_child(0) as Sprite2D).texture.resource_path == want
		fp.free()
		var ledge := Obstacle.new().setup_ledge(2, 1.15, zid)
		ok = ok and (ledge.get_child(0) as Sprite2D).texture.resource_path == want
		ledge.free()
		check(ok, "%s platforms and low ledges are built from that art" % zid)


## The trap expansion: break animations, zone skins, liquids, quicksand,
## steam vents and rolling boulders.
func _trap_checks() -> void:
	main.start_run(false)
	var c: Course = main.course
	var t: Terrain = main.terrain
	var p: Player = main.player
	c._ground = Tuning.GROUND_Y
	# smashing plays a break animation and leaves scrolling rubble
	var b := c.boulder(p.position.x + 600.0)
	main._smash(b, Color.WHITE)
	check(not c.obstacles.has(b) and c.debris.has(b) and b.shattered, "smashed obstacles become rubble (no collision)")
	var has_anim := false
	for ch in b.get_children():
		has_anim = has_anim or (ch is AnimatedSprite2D and ch.visible)
	check(has_anim, "a smashed boulder plays its break animation")
	# zone skins
	c.metres = Zones.ZONE_LEN_M * 1.1
	var dl := c.ledge(p.position.x + 900.0)
	check((dl.get_child(0) as Sprite2D).texture.resource_path.ends_with("desert_fossil_arch.png"), "desert ledge is a fossil arch")
	var dw := c.boulder_wall(p.position.x + 1300.0)
	check((dw.get_child(0) as AnimatedSprite2D).sprite_frames == SpriteLib.trap("desert_wall_break"), "desert Triceratops gate is cracked sandstone")
	check(dw.hitbox().position.y <= 0.0, "the sandstone barricade reaches the top of the screen")
	c.metres = Zones.ZONE_LEN_M * 2.1
	var vl := c.ledge(p.position.x + 1700.0)
	check((vl.get_child(0) as Sprite2D).texture.resource_path.ends_with("Terrain-variation_03_volcanic.png"), "volcanic ledge is floating basalt rock")
	c.metres = 0.0
	# forest Spinosaurus gate: a water crossing the Spinosaurus swims
	main.start_run(false)
	t = main.terrain
	t.metres = 0.0
	t.request_gate("gate_spino")
	var water_x := -1.0
	for f in t.features:
		if f.get("liquid", "") == "water":
			water_x = (f.x0 + f.x1) * 0.5 + t.position.x
	check(water_x > 0.0, "forest Spinosaurus gate is a flooded crossing")
	if water_x > 0.0:
		t.position.x -= water_x - Tuning.PLAYER_X   # move it under Rok
		main.player.position.y = Tuning.GROUND_Y
		main.player.on_ground = true
		check(main._support_y() >= Terrain.PIT, "Rok sinks into the water")
		main.player.shift_to(Forms.SPINOSAURUS)
		check(main._support_y() < Terrain.PIT, "the Spinosaurus floats on the water")
	# volcanic Pteranodon gate: lava
	main.start_run(false)
	t = main.terrain
	t.metres = Zones.ZONE_LEN_M * 2.1
	t.request_gate("gate_ptera")
	check(t.features.any(func(f): return f.get("liquid", "") == "lava"), "volcanic Pteranodon gate is a lava channel")
	# quicksand: Rok sinks and is swallowed; the Raptor skims across
	main.start_run(false)
	main.terrain.features[0].liquid = "quicksand"
	main.player.on_ground = true
	main.player.shift_to(Forms.RAPTOR)
	main._check_quicksand(0.5)
	check(main.state == main.State.PLAYING and main.sink < 0.3, "the Raptor barely sinks in quicksand")
	main.player.shift_to(Forms.ROK)
	main._check_quicksand(0.5)
	main._check_quicksand(0.5)
	check(main.state == main.State.DYING and main.death_cause == "quicksand", "lingering on quicksand swallows Rok")
	_deep_quicksand_checks()
	# steam vents: only the blast frames hurt, and they make you stumble
	main.start_run(false)
	c = main.course
	c._ground = Tuning.GROUND_Y
	var v := c.steam_vent(main.player.position.x)
	v.anim.pause()
	v.anim.frame = 0
	check(v.hitbox().size == Vector2.ZERO, "a resting steam vent is harmless")
	v.anim.frame = 4
	main.chase_gap = Tuning.CHASE_GAP_MAX
	main._collide()
	check(main.state == main.State.PLAYING and main.chase_gap < Tuning.CHASE_GAP_MAX, "a steam blast makes Rok stumble")
	# rolling boulders come at you faster than the ground
	var rb := c.rolling_boulder(1200.0)
	var x0 := rb.position.x
	c.scroll(400.0, 0.5)
	check(x0 - rb.position.x > 200.0 + 1.0, "rolling boulders move faster than the ground")
	# zone-only hazards
	var desert_picks := _picks(1300.0, 200)
	check(not desert_picks.has("steam") and not desert_picks.has("rolling_boulder"), "no steam vents or rolling boulders outside the Volcanic zone")
	main.course.skip_intros_before(0.0)
	main.start_run(false)


## New things pause the game on an info card; new hazards wait their turn.
func _info_checks() -> void:
	var saved_seen: Array = main.seen.duplicate()
	main.pause_for_info = true
	main.unlocked = [Forms.ROK]
	main.start_run(false)
	main.distance = (Progression.UNLOCKS[Forms.RAPTOR] + 2.0) * Tuning.PX_PER_M
	main._play_step(1.0 / 60.0)
	check(main.state == main.State.INFO and main.hud.info_card.visible, "a dino unlock pauses on an info card")
	var tx: float = main.terrain.position.x
	for i in 20:
		main._process(1.0 / 60.0)
	check(main.terrain.position.x == tx, "the world is frozen while the card is up")
	main._dismiss_info()
	check(main.state == main.State.INFO, "the card can't be tapped away instantly")
	for i in int(Tuning.INFO_MIN_TIME * 60.0) + 2:
		main._process(1.0 / 60.0)
	while main.state == main.State.INFO:
		main._dismiss_info()
		for i in int(Tuning.INFO_MIN_TIME * 60.0) + 2:
			main._process(1.0 / 60.0)
	check(main.state == main.State.PLAYING and not main.hud.info_card.visible, "tapping continues the run")
	# marination: right after something new, an untaught hazard waits
	main.seen = []
	main.best_m = 0
	main.last_new_m = main.metres()
	check(not main._can_introduce("log"), "a new hazard waits while the last new thing sinks in")
	check(main._can_introduce("hill"), "features without a lesson are never held back")
	main.seen = Zones.ZONES.map(func(z): return "zone_" + z.id) + Progression.ZONE_LESSONS.keys()   # no zone visits ahead, zone lessons learnt
	var unl_before: Array = main.unlocked.duplicate()
	var slots_before: int = main.slot_count
	main.unlocked = Forms.ORDER.duplicate()
	main.slot_count = 2
	main.distance += (Progression.MARINATE_M + 5.0) * Tuning.PX_PER_M
	check(main._can_introduce("log"), "after marinating, the next new hazard can come")
	# big moments are kept clear: no new hazard just before a dino unlock or a new zone
	# (zone lessons count as learnt, so being inside a zone doesn't hold "log" back)
	main.seen = Zones.ZONES.map(func(z): return "zone_" + z.id) + Progression.ZONE_LESSONS.keys()
	main.unlocked = [Forms.ROK]
	main.last_new_m = -INF
	main.distance = (Progression.UNLOCKS[Forms.RAPTOR] - Progression.BIG_CLEARANCE_M * 0.5) * Tuning.PX_PER_M
	check(not main._can_introduce("log"), "no new hazard just before a dino unlock")
	main.distance = (Progression.UNLOCKS[Forms.RAPTOR] - Progression.BIG_CLEARANCE_M - 20.0) * Tuning.PX_PER_M
	check(main._can_introduce("log"), "...but one is fine well before it")
	main.unlocked = Forms.ORDER.duplicate()
	main.seen = []
	main.distance = (Zones.ZONE_LEN_M - 50.0) * Tuning.PX_PER_M
	check(main.next_big_m(main.metres()) == Zones.ZONE_LEN_M and not main._can_introduce("log"), "no new hazard just before the first visit to a zone")
	# a zone's own lesson goes first: in the Desert with quicksand still to
	# learn, another new hazard waits for it
	main.seen = ["zone_desert"]
	main.distance = (Progression.intro_m("quicksand") + 20.0) * Tuning.PX_PER_M
	check(not main._can_introduce("boulder"), "in the Desert, quicksand is taught before other new hazards")
	main.seen = ["zone_desert", "quicksand"]
	check(main._can_introduce("boulder"), "...and once quicksand is known the others can come")
	main.unlocked = unl_before
	main.slot_count = slots_before
	main.pause_for_info = false
	# put the fresh save back for the unlock checks that follow
	main.unlocked = [Forms.ROK]
	SaveData.save_unlocked(main.unlocked)
	main.seen = saved_seen
	SaveData.save_seen(main.seen)
	main.start_run(false)


## Mario-style death: freeze on the hit, then hop up and fall off-screen.
func _death_checks() -> void:
	for f in [Forms.ROK, Forms.SPINOSAURUS]:
		main.start_run(false)
		main.player.shift_to(f)
		var p: Player = main.player
		var tx: float = main.terrain.position.x
		var rx: float = main.trex.position.x
		main._game_over()
		check(p.sprite.sprite_frames == SpriteLib.death(f) and p.sprite.animation == "die", "form %d plays its death frames" % f)
		var y0 := p.position.y
		for i in int(Tuning.DEATH_FREEZE * 60.0) - 2:
			main._process(1.0 / 60.0)
		check(absf(p.position.y - y0) < 0.5, "it freezes on the hit first")
		var top := p.position.y
		for i in 90:
			main._process(1.0 / 60.0)
			top = minf(top, p.position.y)
		check(p.sprite.animation == "hop" and top < y0 - 60.0, "then hops up (%.0f px)" % (y0 - top))
		for i in 60:
			main._process(1.0 / 60.0)
		check(p.position.y > Tuning.VIEW_H, "and falls off the screen")
		check(main.terrain.position.x == tx and main.trex.position.x == rx, "the world and the T-rex stop while Rok dies")
		check(main.trex.process_mode == Node.PROCESS_MODE_DISABLED and main.course.process_mode == Node.PROCESS_MODE_DISABLED, "everyone else is frozen")
		check(main.audio.streams.has("death_jingle") and main.audio._duck <= -60.0, "the music cuts out for the death jingle")
	main.start_run(false)
	check(main.course.process_mode == Node.PROCESS_MODE_INHERIT, "a new run unfreezes the world")
	check(main.audio._duck == 0.0, "the music comes back on the next run")


func _intro_checks() -> void:
	main.start_run()
	main.audio.played.clear()
	check(main.state == main.State.INTRO, "a run opens with the T-rex intro")
	var t := 0.0
	var roared := false
	while main.state == main.State.INTRO and t < 3.0:
		main._process(1.0 / 60.0)
		t += 1.0 / 60.0
		roared = roared or main.trex.sprite.animation == "roar"
	check(roared, "the T-rex roars in the intro")
	check(main.audio.played.has("rok_alarm") and main.audio.played.find("trex_roar") < main.audio.played.find("rok_alarm"), "after the roar Rok shouts to run (rok_alarm, the user's recording once supplied)")
	check(main.state == main.State.PLAYING and absf(t - Tuning.INTRO_TIME) < 0.1, "intro hands over to the run after %.1f s" % t)
	check(main.speed >= Tuning.START_SPEED - 1.0, "running at start speed after the intro")
	check(main.trex.position.x + Trex.SNOUT < Tuning.PLAYER_X, "T-rex is behind Rok")


## The guide handles drags itself (the cards would swallow them otherwise).
## Real scrolling is checked visually by screenshot.gd (guide_scrolled.png).
func _guide_scroll_check() -> void:
	main.codex.open_guide(Forms.ORDER.duplicate(), 9999.0, [], [])
	var e := InputEventScreenDrag.new()
	var down := InputEventScreenTouch.new()
	down.pressed = true
	main.codex._input(down)
	e.position = main.codex.scroll.get_global_rect().get_center()
	e.relative = Vector2(-120, 0)
	e.velocity = Vector2(-600, 0)
	main.codex._input(e)
	check(main.codex._dragging and main.codex._fling == 600.0, "a drag along the guide's shelf is taken as scrolling (sideways)")
	var up := InputEventScreenTouch.new()
	up.pressed = false
	main.codex._input(up)
	check(not main.codex._dragging, "releasing ends the drag (momentum continues)")
	main.codex.close_guide()


func _guide_checks() -> void:
	check(Codex.known_ids([Forms.ROK], 0.0, []) == ["dino_0", "trex", "islands", "zone_forest"], "fresh guide knows Rok, the T-rex, floating islands and the Forest")
	check(not Codex.ITEMS.any(func(it): return it.name == "Floating Islands"), "floating islands are terrain, not an item")
	check(not Codex.ITEMS.any(func(it): return it.name == "Dino Egg"), "the egg lives in the Power-Ups section, not Items")
	# power-ups: six in the catalogue, only the egg owned; the rest locked
	check(Boosters.DATA.size() == 6, "six power-ups in the catalogue")
	check(main.boosters_owned == ["egg"], "a fresh save owns only the Dino Egg")
	main.codex.boosters_owned = main.boosters_owned
	main.codex.open_guide(main.unlocked, main.best_m, main.seen, main.guide_viewed)
	main.codex._show_tab(3)
	var live: Array = main.codex.grid.get_children().filter(func(c): return not c.is_queued_for_deletion())
	check(live.size() == Boosters.DATA.size(), "Power-Ups tab lists every power-up")
	main.codex.close_guide()
	# learning facts: every form and the T-rex has real-world facts
	for f in Forms.ORDER:
		var fid: String = Forms.get_data(f).id
		var fx: Dictionary = DinoFacts.for_id(fid)
		check(not fx.is_empty() and fx.fact != "" and fx.quiz != "", "%s has real-world facts" % fid)
		check(DinoFacts.text(fid).contains("When:") and DinoFacts.text(fid).contains("Food:"), "%s facts list when, where, size and food" % fid)
	check(not DinoFacts.for_id("trex").is_empty(), "the T-rex has real-world facts")
	check(DinoFacts.for_id("pteranodon").what.to_lower().contains("pterosaur"), "the Pteranodon is called a pterosaur, not a dinosaur")
	main.codex.open_guide(main.unlocked, main.best_m, main.seen, main.guide_viewed)
	main.codex._show_tab(0)
	var dcards: Array = main.codex.grid.get_children().filter(func(c): return not c.is_queued_for_deletion())
	check(dcards[0].find_child("Facts", true, false) != null, "Rok's card shows a facts panel")
	check(dcards[1].find_child("Facts", true, false) == null, "a locked dino card hides its facts")
	main.codex._show_tab(1)
	var hcards: Array = main.codex.grid.get_children().filter(func(c): return not c.is_queued_for_deletion())
	check(hcards[0].find_child("Facts", true, false) != null, "the T-rex card shows a facts panel")
	main.codex.close_guide()
	check(Codex.has_new(main.unlocked, main.best_m, main.seen, main.guide_viewed), "guide badge on a fresh save")
	check(main.hud.codex_button.visible, "guide button on the title screen")
	_touch(_center(main.hud.codex_button), true, 7)
	_touch(_center(main.hud.codex_button), false, 7)
	check(main.codex.visible, "tapping the book opens the Field Guide")
	check(main.codex.grid.get_child_count() >= Forms.ORDER.size(), "dinosaur cards listed")
	_touch(Vector2(640, 400), true, 8)
	_touch(Vector2(640, 400), false, 8)
	check(main.state == main.State.TITLE, "taps inside the guide don't start a run")
	main.codex._show_tab(1)
	check(main.codex.grid.get_child_count() >= Codex.HAZARDS.size(), "hazard cards listed")
	main.codex.close_guide()
	check(not main.codex.visible, "guide closes")
	check(main.guide_viewed.has("dino_0"), "viewed entries are remembered")
	check(not Codex.has_new(main.unlocked, main.best_m, main.seen, main.guide_viewed), "badge clears after viewing")
	# already-taught hazards are revealed and get no hint banner
	var past_log: float = Progression.intro_m("log") + 100.0
	check(Progression.taught("log", past_log, []), "logs count as taught once a best run went past them")
	check(not Progression.taught("pit", past_log, []), "pits not taught that early")
	check(Codex.known_ids([Forms.ROK], past_log, []).has("log"), "taught hazards appear in the guide")
	# every card builds once everything is unlocked and taught
	main.codex.open_guide(Forms.ORDER.duplicate(), 9999.0, [], [])
	for t in 5:
		main.codex._show_tab(t)
	check(main.codex.grid.get_child_count() > 0, "all guide tabs build with everything unlocked")
	main.codex.close_guide()


func _banner_checks() -> void:
	var saved_best: int = main.best_m
	var saved_seen: Array = main.seen.duplicate()
	main.best_m = 1000
	main.seen = []
	main._on_introduced("log")
	check(not main.seen.has("log"), "no hint banner for a hazard the best run already passed")
	main.best_m = 0
	main._on_introduced("pit")
	check(main.seen.has("pit"), "hint banner for a hazard not yet taught")
	main.best_m = saved_best
	main.seen = saved_seen


## Field Guide pages for the new dinosaurs, the best-distance flag, T-rex
## charges and badges.
func _fun_checks() -> void:
	# --- Field Guide pages + facts for the 28 new dinosaurs
	check(Dinos.ids().all(func(id):
		var f := DinoFacts.for_id(id)
		return ["what", "era", "where", "size", "ate", "fact", "quiz"].all(func(k): return String(f.get(k, "")) != "")),
		"every new dinosaur has real-world facts")
	check(DinoFacts.for_id("quetzalcoatlus").what.contains("not a dinosaur") and DinoFacts.for_id("dimorphodon").what.contains("not a dinosaur"), "the pterosaurs are called flying reptiles, not dinosaurs")
	var owned_keep: Array = main.dinos_owned.duplicate()
	main.dinos_owned = ["gallimimus"]
	Codex.species_owned = main.dinos_owned
	check(Codex.known_ids(main.unlocked, main.best_m, main.seen).has("dino_gallimimus") and not Codex.known_ids(main.unlocked, main.best_m, main.seen).has("dino_iguanodon"), "an owned dinosaur's page is discovered, others aren't")
	main.state = main.State.TITLE
	main.open_guide()
	main.codex._show_tab(0)
	var page := _codex_card("Gallimimus")
	check(page != null and page.find_child("Facts", true, false) != null, "an owned dinosaur's page shows its facts")
	check(_codex_card("???") != null, "a dinosaur you don't own is a silhouette")
	main.codex.close_guide()
	main.dinos_owned = owned_keep
	Codex.species_owned = owned_keep
	# --- the best-distance flag
	var best_keep: float = main.best_m
	main.best_m = 120
	main.start_run(false)
	check(main.best_flag != null and main.best_flag.metres == 120, "a run with a record plants a flag at the best distance")
	main._best_flag_step()
	check(main.best_flag.position.x > Tuning.PLAYER_X + 100.0 * Tuning.PX_PER_M, "the flag waits ahead, at the record")
	main.hud.clear_banner()
	main.distance = 121.0 * Tuning.PX_PER_M
	main._best_flag_step()
	check(main.best_flag.passed and main.hud.banner_title.text == "NEW BEST!", "running past it celebrates the new record")
	main.best_m = 0
	main.start_run(false)
	check(main.best_flag == null, "no flag without a record")
	main.best_m = best_keep
	# --- T-rex charges at set distances
	check(Progression.next_charge_m(0.0) == Progression.TREX_CHARGE_M[0] and Progression.next_charge_m(Progression.TREX_CHARGE_M[-1] + 1.0) == Progression.TREX_CHARGE_M[-1] + Progression.TREX_CHARGE_EVERY_M, "charges come at the configured distances, then every charge_every_m")
	main.start_run(false)
	main.pause_for_info = false
	main.hud.clear_banner()
	main.distance = (Progression.TREX_CHARGE_M[0] + 1.0) * Tuning.PX_PER_M
	main._charge_step(1.0 / 60.0)
	check(main.charge_state == "warn" and main.hud.banner_title.text == "THE T-REX CHARGES!", "at its distance the T-rex roars a warning")
	main._charge_step(Tuning.CHARGE_WARN + 0.01)
	check(main.charge_state == "charge", "...then charges")
	main.chase_gap = Tuning.CHASE_GAP_MAX
	main._update_chase(1.0, 0.0)
	var hd: Dictionary = Hunters.DATA[main.hunter_id]
	check(absf(main.chase_gap - (Tuning.CHASE_GAP_MAX - hd.charge_rate)) < 0.5, "while charging the hunter gains fast")
	var escapes := float(main.badge_stats.get("charges", 0.0))
	main._charge_step(hd.charge_time + 0.01)
	check(main.charge_state == "" and float(main.badge_stats.get("charges", 0.0)) == escapes + 1.0, "surviving it counts as an escape")
	main._charge_step(1.0 / 60.0)
	check(main.charge_state == "", "each charge happens once")
	# --- a different hunter per zone
	check(Hunters.for_zone("forest") == "trex" and Hunters.for_zone("desert") != "trex" and Hunters.for_zone("volcanic") != Hunters.for_zone("desert"), "each zone has its own hunter")
	var hunt_profiles := {}
	for id in Hunters.DATA:
		hunt_profiles[str([Hunters.DATA[id].charge_rate, Hunters.DATA[id].charge_time])] = true
	check(hunt_profiles.size() == Hunters.DATA.size(), "every hunter hunts its own way")
	check(Hunters.DATA.keys().all(func(id): return not Critters.DATA.has(id)), "no species is both hunter and prey")
	main.start_run(false)
	check(main.hunter_id == "trex" and main.trex.hunter == "trex", "runs start with the Forest's hunter")
	main.hud.clear_banner()
	main.distance = (Zones.ZONE_LEN_M + 5.0) * Tuning.PX_PER_M
	main._hunter_step()
	check(main.hunter_id == Hunters.for_zone("desert") and main.trex.hunter == main.hunter_id, "entering the Desert, its hunter takes over")
	check(main.hud.banner_title.text.contains(String(Hunters.DATA[main.hunter_id].name).to_upper()), "...with a banner naming it")
	check(main.trex.sprite.self_modulate == Hunters.tint(main.hunter_id), "until it has its own art it wears the T-rex's, tinted")
	main.distance = (2.0 * Zones.ZONE_LEN_M + 5.0) * Tuning.PX_PER_M
	main._hunter_step()
	main.chase_gap = Tuning.CHASE_GAP_MAX
	main._update_chase(1.0, 0.0)
	check(main.hunter_id == "allosaurus" and main.chase_gap == Tuning.CHASE_GAP_MAX, "no hunter creeps closer while Rok runs clean")
	main.start_run(false)
	# --- wild dinosaurs (stampedes and swoopers), a pair per zone
	for z in ["forest", "desert", "volcanic"]:
		check(Critters.for_zone(z, "stampede") != "" and Critters.for_zone(z, "swooper") != "", "the %s has its own stampede and swooper" % z)
	var profiles_c := {}
	for id in Critters.DATA:
		var d: Dictionary = Critters.DATA[id]
		profiles_c[str([d.speed, d.scale, d.bump, d.snack])] = true
	check(profiles_c.size() == Critters.DATA.size(), "every wild dinosaur has its own attributes")
	check(Critters.DATA.keys().all(func(id): return Critters.frames(id).get_frame_count("a") == 8 and Critters.art_bounds(id).size.x > 20.0), "every wild dinosaur has its art")
	main.start_run(false)
	var pc: Player = main.player
	pc.invuln = 0.0
	pc.position.y = Tuning.GROUND_Y
	pc.on_ground = true
	var cc: Course = main.course
	cc.metres = 0.0
	cc._ground = Tuning.GROUND_Y
	for o in cc.obstacles.duplicate():
		cc.remove_obstacle(o)
	cc._spawn_key("stampede", pc.position.x - 300.0)
	var st: Obstacle = cc.obstacles[-1]
	check(st.critter == Critters.for_zone("forest", "stampede") and st.roll_speed > 0.0, "a Forest stampede is its species, closing in on its own")
	main.chase_gap = Tuning.CHASE_GAP_MAX
	main._collide()
	check(main.state == main.State.PLAYING and st.bumped and absf(main.chase_gap - (Tuning.CHASE_GAP_MAX - Critters.DATA[st.critter].bump)) < 0.5, "running into one bumps Rok (its own strength), it doesn't end the run")
	check(pc.react_kind == "trip", "...with the trip animation")
	pc.invuln = 0.0
	main._collide()
	check(absf(main.chase_gap - (Tuning.CHASE_GAP_MAX - Critters.DATA[st.critter].bump)) < 0.5, "a critter only bumps once")
	var gap_before: float = main.chase_gap
	var snacks0 := float(main.badge_stats.get("snacks", 0.0))
	st.position.x = Tuning.PLAYER_X - main.chase_gap
	main._eat_critters()
	check(not cc.obstacles.has(st) and main.trex.sprite.animation == "bite", "once past, the T-rex eats it")
	check(absf(main.chase_gap - (gap_before + Critters.DATA[st.critter].snack)) < 0.5 and float(main.badge_stats.get("snacks", 0.0)) == snacks0 + 1.0, "...stopping to eat (you win back ground) and counting for the Bait badge")
	pc.react_stop()
	cc._spawn_key("swooper", pc.position.x - 300.0)
	var sw: Obstacle = cc.obstacles[-1]
	sw.position.x = pc.position.x
	sw._bob = 0.0
	sw.position.y = sw._base_y
	check(sw.hitbox().intersects(pc.standing_hitbox()), "a swooper hits Rok standing")
	pc.press_slide()
	main._play_step(1.0 / 60.0)
	check(pc.is_low() and not sw.hitbox().intersects(pc.hitbox()), "...but he can slide under it")
	pc.release_slide()
	cc.remove_obstacle(sw)
	# --- diving flyers (a swooper that comes in high and dives at Rok)
	pc.react_stop()
	main._play_step(1.0 / 60.0)
	check(Progression.intro_m("diver") > Progression.intro_m("swooper") and Progression.intro_entry("diver").size() > 0, "diving flyers come after swoopers, as their own lesson")
	var seen_keep: Array = main.seen.duplicate()
	var dcount_keep: int = cc.intro_counts.get("diver", 0)
	cc.intro_counts["diver"] = 0
	cc.metres = Progression.intro_m("diver") - 50.0
	cc._spawn_key("swooper", pc.position.x + 400.0)
	check(not (cc.obstacles[-1] as Obstacle).dive, "no diving flyer before its lesson")
	cc.remove_obstacle(cc.obstacles[-1])
	if not main.seen.has("diver"):
		main.seen.append("diver")
	cc.metres = Progression.intro_m("diver") + 10.0
	cc._spawn_key("swooper", pc.position.x + 400.0)
	check((cc.obstacles[-1] as Obstacle).dive and cc.intro_counts.get("diver", 0) == 1, "once due, its lesson's swoopers dive")
	cc.remove_obstacle(cc.obstacles[-1])
	cc.intro_counts["diver"] = dcount_keep
	main.seen = seen_keep
	cc.metres = 0.0
	var dv: Obstacle = Obstacle.new().setup_critter(Critters.for_zone("forest", "swooper"))
	cc.add_child(dv)
	dv.position.x = Tuning.PLAYER_X + Tuning.DIVE_FROM_X + 200.0
	dv.place_critter(cc._ground)
	var low_y := dv.position.y
	var spd0 := dv.roll_speed
	dv.make_diver()
	cc.obstacles.append(dv)
	check(dv.dive and not dv.dive_started and dv.hitbox().end.y < cc._ground - Tuning.DIVE_START_H + 40.0 and dv.roll_speed > spd0, "a diver comes in high, out of reach, and faster")
	main._eat_critters()
	check(not dv.get_meta("screeched", false), "...silent until it dives")
	dv.position.x = Tuning.PLAYER_X + (Tuning.DIVE_FROM_X + Tuning.DIVE_TO_X) * 0.5
	dv.update_dive()
	main._eat_critters()
	check(dv.dive_started and dv.position.y < low_y - 5.0 and dv.position.y > low_y - (Tuning.DIVE_START_H - Critters.DATA[dv.critter].height) + 5.0 and dv.get_meta("screeched", false), "it screeches and dives as it nears Rok")
	dv.position.x = pc.position.x
	dv.update_dive()
	check(absf(dv.position.y - (low_y + Tuning.DIVE_DIP)) < 0.5 and dv.hitbox().intersects(pc.standing_hitbox()), "it bottoms out at head height as it reaches Rok")
	check(main.attack_target() == dv, "...where ATTACK can reach it")
	pc.press_slide()
	main._play_step(1.0 / 60.0)
	dv.update_dive()
	check(pc.is_low() and not dv.hitbox().intersects(pc.hitbox()), "...and he can slide under the dive")
	pc.release_slide()
	# --- lesson flow: a pattern with no room steps aside; the Forest is never a "new" zone
	main.start_run(false)
	check(main.seen.has("zone_" + Zones.ZONES[0].id), "runs start in the Forest, so its next lap isn't a first visit")
	cc = main.course
	cc.metres = Progression.intro_m("combo") + 400.0
	cc.skip_intros_before(cc.metres)
	for k in Progression.PATTERN_KEYS + ["combo", "hard_combo"]:
		if k != "small":
			cc._no_room[k] = INF
	var only_small := true
	for i in 30:
		only_small = only_small and cc._next_key() == "small"
	check(only_small, "a pattern that found no flat ground steps aside for one that fits")
	cc._no_room.clear()
	cc.metres = 0.0
	cc.intro_counts.clear()
	# --- the first 800 m: slide is taught before the Raptor, a starter chest, a wild-dinosaur preview
	check(Progression.intro_m("ledge") <= Progression.unlock_m(Forms.RAPTOR) - Progression.BIG_CLEARANCE_M and Progression.intro_m("ledge") >= Progression.intro_m("log") + Progression.MARINATE_M,
			"low ledges (SLIDE) are taught before the Raptor, after logs have sunk in")
	main.start_run(false)
	check(Progression.STARTER_CHEST_M > 0.0 and Progression.STARTER_CHEST_M < Tuning.CHEST_EVERY_M and main.next_chest_m == Progression.STARTER_CHEST_M, "every run has a starter chest before the first milestone")
	var seen_keep2: Array = main.seen.duplicate()
	var best_keep2: float = main.best_m
	main.seen.erase("stampede")
	main.best_m = 0.0
	cc = main.course
	for o in cc.obstacles.duplicate():
		cc.remove_obstacle(o)
	main.distance = (Progression.STAMPEDE_PREVIEW_M - 20.0) * Tuning.PX_PER_M
	main._preview_step()
	check(not cc.obstacles.any(func(o): return o.get_meta("preview", false)), "no wild-dinosaur preview before its distance")
	main.distance = (Progression.STAMPEDE_PREVIEW_M + 1.0) * Tuning.PX_PER_M
	for f in 900:   # it waits for flat ground (real runs retry for 200 m)
		main._preview_step()
		if main.preview_done:
			break
		main.chase_gap = Tuning.CHASE_GAP_MAX
		main.player.invuln = 99.0
		main._play_step(1.0 / 60.0)
	main.player.invuln = 0.0
	var pv: Array = cc.obstacles.filter(func(o): return o.get_meta("preview", false))
	check(pv.size() == 1 and (pv[0] as Obstacle).critter == Critters.for_zone(Zones.zone_at(main.metres()).id, "stampede")
			and (pv[0] as Obstacle).roll_speed < Critters.DATA[(pv[0] as Obstacle).critter].speed, "a slow wild dinosaur of the zone previews the stampedes")
	main._preview_step()
	check(cc.obstacles.filter(func(o): return o.get_meta("preview", false)).size() == 1, "...only once a run")
	main.start_run(false)
	main.seen.append("stampede")
	main.distance = (Progression.STAMPEDE_PREVIEW_M + 1.0) * Tuning.PX_PER_M
	main._preview_step()
	check(main.preview_done and not main.course.obstacles.any(func(o): return o.get_meta("preview", false)), "no preview once stampedes have been taught")
	main.seen = seen_keep2
	main.best_m = best_keep2
	main.start_run(false)
	# --- the main menu's Tutorial button replays the training run
	main._to_title()
	main._menu_t = 0.0
	main._refresh_hud()
	var tb: TouchButton = main.hud.tutorial_button
	var vr: Rect2 = main.get_viewport().get_visible_rect()
	var tb_box := Rect2(tb.global_position, tb.size + Vector2(0, 26))   # with its name below
	check(tb.visible and vr.encloses(tb_box) and not tb_box.intersects(main.hud.market_button.get_global_rect())
			and not tb_box.intersects(main.hud.center_panel.get_global_rect()), "the main menu has a Tutorial button, on screen and clear of the others")
	check(main.tutorial_run_done, "(the training run was already played)")
	main._touch_pressed("tutorial")
	check(main.tutorial_run != null, "tapping Tutorial plays the training run again")
	main._refresh_hud()
	check(not main.hud.tutorial_button.visible, "...and the button hides during it")
	main.end_tutorial(true)
	check(main.state == main.State.TITLE and main.tutorial_run == null and main.tutorial_run_done, "skipping it goes back to the main menu")
	main.start_run(false)
	main._refresh_hud()
	check(not main.hud.tutorial_button.visible, "no Tutorial button in a normal run")
	# --- the user's shapeshift burst (assets/fx/transform_burst)
	main.start_run(false)
	var unl_keep: Array = main.unlocked.duplicate()
	main.unlocked = Forms.ORDER.duplicate()
	main.energy = 100.0
	main.shift_cd = 0.0
	var rok_d: Dictionary = main.player.data()
	main._request_form(Forms.SPINOSAURUS)
	var tf: AnimatedSprite2D = main.player.tfx
	var cov: Array = SpriteLib.transform_meta().cover
	var need := Player._art_size(rok_d).max(Player._art_size(main.player.data()))
	check(main.player.form == Forms.SPINOSAURUS and tf.visible and tf.frame == Tuning.TRANSFORM_FX_START,
			"shapeshifting is instant and plays the burst from its covering frame")
	check(tf.scale.x * float(cov[0]) >= need.x - 0.5 and tf.scale.y * float(cov[1]) >= need.y - 0.5,
			"...its solid cloud big enough to hide both forms")
	tf.frame = tf.sprite_frames.get_frame_count("a") - 1
	tf.animation_finished.emit()
	check(not tf.visible, "...and it's gone when it ends")
	main.unlocked = unl_keep
	main.start_run(false)
	# --- the user's power-up effects
	main.start_run(false)
	var pwp: Player = main.player
	main.slots = ["", "", ""]
	main.audio.played.clear()
	main.collect_booster("egg", pwp.position)
	check(pwp.pfx_once.visible and String(pwp.pfx_once.animation) == "pickup", "collecting a power-up plays the pickup effect")
	check(main.audio.played.has("powerup_pickup"), "...and the pickup sound")
	main.use_slot(0)
	check(String(pwp.pfx_once.animation) == "activation", "using it plays the activation effect")
	check(main.audio.played.has("powerup_activate"), "...and the activation sound")
	main._power_step(0.016)
	check(pwp.pfx_aura.visible and String(pwp.pfx_aura.animation) == "aura" and pwp.pfx_aura.get_index() == 0, "while it runs the aura loops behind the character")
	main.boost_t = 0.0
	main._power_step(0.016)
	check(not pwp.pfx_aura.visible and String(pwp.pfx_once.animation) == "expire" and pwp.pfx_once.visible, "when it ends the expire effect plays")
	check(main.audio.played.has("powerup_expire"), "...and the expire sound")
	for n in ["powerup_pickup", "powerup_activate", "powerup_expire"]:
		check(main.audio.streams.has(n), "the %s sound exists" % n)
	main.start_run(false)
	check(not main.player.pfx_aura.visible and not main.player.pfx_once.visible, "a new run starts without power-up effects")
	# --- the Encyclopedia's Cards tab (the user's card art)
	var cards_keep: Dictionary = main.cards.duplicate()
	var seen_keep3: Array = main.seen.duplicate()
	main.cards.clear()
	main._sync_gear()
	main.grant_card("raptor")
	main.seen.append("card_raptor")
	main.open_guide()
	main.codex._show_tab(6)
	var ctiles: Array = main.codex.grid.get_children().filter(func(c): return not c.is_queued_for_deletion())
	var raptor_tile: Node = main.codex.grid.get_node_or_null("Card_raptor")
	var tri_tile: Node = main.codex.grid.get_node_or_null("Card_triceratops")
	check(ctiles.size() == Forms.ORDER.size() - 1 + Dinos.ids().size() and raptor_tile != null and String(raptor_tile.get_meta("title")) == "Raptor Card"
			and tri_tile != null and bool(tri_tile.get_meta("locked")), "the Cards tab lists every dinosaur card; found ones by name, the rest locked")
	check(CardView.art("raptor") != null and CardView.art("pteranodon") != null, "the four original dinosaurs have the user's card art")
	main.codex.select(raptor_tile.get_index())
	var cv: Node = main.codex.find_child("CardView", true, false)
	check(cv != null and (cv as CardView).text == Gear.bonus_text(Gear.CARD_PREFIX + "raptor") and (cv as CardView).text != "",
			"a found card shows on the book's page with what it gives a weapon written on it")
	main.codex.close_guide()
	main.cards.clear()
	for k in cards_keep:
		main.cards[k] = cards_keep[k]
	main._sync_gear()
	main.seen = seen_keep3
	# --- hazard icons (info cards and Field Guide), in each zone's look
	var missing := []
	for e in Progression.INTROS:
		if e[2] == "":
			continue
		for z in Zones.ZONES:
			if HazardIcons.icon(e[1], z.id) == null:
				missing.append("%s/%s" % [e[1], z.id])
	check(missing.is_empty(), "every lesson's info card has a picture in every zone %s" % [missing])
	check(HazardIcons.icon("boulder", "forest") != HazardIcons.icon("boulder", "desert") and HazardIcons.icon("boulder", "desert") != HazardIcons.icon("boulder", "volcanic"),
			"a hazard shows its own zone's look (Forest rock, Desert sandstone, Volcanic basalt)")
	check(HazardIcons.icon("ledge", "desert").resource_path.ends_with("desert_fossil_arch.png") and HazardIcons.icon("ledge", "forest").resource_path.ends_with("forest_overhead.png"),
			"the low ledge is a vine branch in the Forest and a fossil arch in the Desert")
	check(HazardIcons.icon("gate_lava", "forest") == HazardIcons.icon("gate_lava", "volcanic"), "a one-zone hazard always shows its own zone")
	check(HazardIcons.icon("swooper", "desert").resource_path.ends_with("%s.png" % Critters.for_zone("desert", "swooper")), "wild dinosaur cards show the zone's species")
	var dist_keep: float = main.distance
	main.distance = (Zones.ZONE_LEN_M + 100.0) * Tuning.PX_PER_M
	check(main._intro_icon("ledge") == HazardIcons.icon("ledge", "desert"), "an info card shows the zone Rok is in")
	main.distance = dist_keep
	var looks: Control = main.codex._zone_looks("boulder")
	check(looks != null and looks.get_child_count() == 3 and main.codex._zone_looks("steam") == null, "the Field Guide shows a hazard's look in each zone (not for one-zone hazards)")
	looks.free()
	cc.remove_obstacle(dv)
	main.start_run(false)
	# --- badges
	var stats_keep: Dictionary = main.badge_stats.duplicate()
	var tiers_keep: Dictionary = main.badge_tiers.duplicate()
	var bank_keep: int = main.meat_bank
	main.badge_stats = {}
	main.badge_tiers = {}
	main.meat_bank = 0
	_quiet_missions()
	check(Badges.DATA.size() >= 10 and Badges.DATA.keys().all(func(id): return (Badges.DATA[id].tiers as Array).size() == 3 and Badges.DATA[id].tiers[0] < Badges.DATA[id].tiers[1] and Badges.DATA[id].tiers[1] < Badges.DATA[id].tiers[2]), "every badge has three rising tiers")
	main.start_run(false)
	for i in Badges.DATA.smasher.tiers[0] - 1:
		main.badge_event("smashed")
	check(int(main.badge_tiers.get("smasher", 0)) == 0, "no badge before its target")
	main.hud.clear_banner()
	main.badge_event("smashed")
	check(main.badge_tiers.smasher == 1 and main.meat_bank == Badges.TIER_REWARD[0], "reaching it earns Bronze and its meat")
	check(main.hud.banner_title.text.begins_with("BADGE:") and main.new_badges.size() == 1, "a badge earned mid-run shows a banner and joins the run's news")
	check(SaveData.load_badges()[1].get("smasher", 0) == 1 and SaveData.load_meat() == Badges.TIER_REWARD[0], "badges and their meat are saved")
	main.badge_best("run_m", Badges.DATA.marathon.tiers[2] + 1.0)
	check(main.badge_tiers.marathon == 3 and main.meat_bank == Badges.TIER_REWARD[0] + Badges.TIER_REWARD[0] + Badges.TIER_REWARD[1] + Badges.TIER_REWARD[2], "a big jump earns every tier it passes")
	main.badge_best("run_m", 10.0)
	check(main.badge_stats.run_m > 10.0, "a best stat keeps its best")
	check(Badges.DATA.keys().all(func(id): return Badges.icon(id, 0) != null and Badges.icon(id, 3) != null), "every badge has a medal (placeholder art until the real one)")
	# perk badges: Point Hunter (more points) and Seasoned (more XP) for good
	check(Badges.PERKS.has("scorer") and Badges.PERKS.has("veteran") and Badges.DATA.scorer.stat == "points" and Badges.DATA.veteran.stat == "xp", "Point Hunter and Seasoned are perk badges")
	var bt_keep: Dictionary = main.badge_tiers.duplicate()
	main.badge_tiers.erase("scorer")
	main.badge_tiers.erase("veteran")
	var pm0: float = main.points_mult()
	check(is_equal_approx(main.xp_mult(), 1.0), "without the perks, 1 XP per metre")
	main.badge_tiers["scorer"] = 2
	check(is_equal_approx(main.points_mult(), pm0 * (1.0 + Badges.PERKS.scorer[2])), "Point Hunter Silver adds its bonus to every point")
	main.badge_tiers["veteran"] = 1
	check(is_equal_approx(main.xp_mult(), 1.0 + Badges.PERKS.veteran[1]), "Seasoned Bronze adds its bonus to XP")
	check(Badges.perk_text("veteran", 3) == "+35% XP" and Badges.perk_text("smasher", 1) == "", "perks read as text, and other badges have none")
	main.badge_tiers.clear()
	for k in bt_keep:
		main.badge_tiers[k] = bt_keep[k]
	# (no new run here: the badges earned above must reach this run's news)
	var pts0 := float(main.badge_stats.get("points", 0.0))
	var sc_keep: float = main.score
	var rk_keep: bool = main._ranked
	main._ranked = false
	main.score = 1234.0
	main._apply_rank()
	check(float(main.badge_stats.get("points", 0.0)) == pts0 + 1234.0, "each run's score counts toward Point Hunter")
	main.score = sc_keep
	main._ranked = rk_keep
	# nothing you can farm by mashing a button
	check(Badges.DATA.values().all(func(b): return not (b.stat in ["slides", "shifts", "jumps"])), "no badge counts bare slides, jumps or transformations")
	main.state = main.State.PLAYING
	var pl: Player = main.player
	main.course.metres = 0.0
	main.course._ground = Tuning.GROUND_Y
	pl.position.y = Tuning.GROUND_Y
	pl.on_ground = true
	var ledges0 := float(main.badge_stats.get("ledges", 0.0))
	var lg: Obstacle = main.course.ledge(pl.position.x)
	pl.press_slide()
	main._course_badges()
	lg.position.x = pl.position.x - lg.size.x - 100.0
	main._course_badges()
	check(float(main.badge_stats.get("ledges", 0.0)) == ledges0 + 1.0, "sliding under a low ledge counts for Limbo Master")
	pl.release_slide()
	pl.low = Player.Low.NONE
	var lg2: Obstacle = main.course.ledge(pl.position.x)
	main._course_badges()
	lg2.position.x = pl.position.x - lg2.size.x - 100.0
	main._course_badges()
	check(float(main.badge_stats.get("ledges", 0.0)) == ledges0 + 1.0, "...but passing one without sliding doesn't")
	var gates0 := float(main.badge_stats.get("gates", 0.0))
	var mk := Node2D.new()
	mk.set_meta("gate_dx", 0.0)
	mk.position = Vector2(pl.position.x + 200.0, 150.0)
	main.course.add_child(mk)
	main.course.markers.append(mk)
	main._course_badges()
	check(float(main.badge_stats.get("gates", 0.0)) == gates0, "a dino gate ahead doesn't count yet")
	mk.position.x = pl.position.x - main.GATE_CLEAR - 10.0
	main._course_badges()
	main._course_badges()
	check(float(main.badge_stats.get("gates", 0.0)) == gates0 + 1.0, "getting through a dino gate counts once for Gate Crasher")
	# category badges count metres in that category
	main.energy = 100.0
	main._shift(Forms.RAPTOR)
	var run0 := float(main.badge_stats.get("runner_m", 0.0))
	var tank0 := float(main.badge_stats.get("tank_m", 0.0))
	main._badge_run_step(50.0)
	check(float(main.badge_stats.get("runner_m", 0.0)) == run0 + 50.0 and float(main.badge_stats.get("tank_m", 0.0)) == tank0, "metres as a Runner count for Swift Feet (and not Iron Hide)")
	main.shift_cd = 0.0
	main._shift(Forms.SPINOSAURUS)
	main._badge_run_step(30.0)
	check(main.player.form == Forms.SPINOSAURUS and float(main.badge_stats.get("tank_m", 0.0)) == tank0 + 30.0, "metres as a Tank count for Iron Hide")
	main._game_over()
	main._finish_game_over()
	check((main.summary.panel.find_child("News", true, false) as Label).text.contains("Badge:"), "the game-over news lists badges earned")
	check(Codex.has_new(main.unlocked, main.best_m, main.seen, main.guide_viewed), "a new badge lights the Field Guide button")
	main.open_guide()
	main.codex._show_tab(5)
	check(main.codex.grid.get_children().filter(func(c): return String(c.name).begins_with("Badge_")).size() == Badges.DATA.size(), "the Badges tab lists every badge")
	check(_codex_badge("smasher").find_child("Progress", true, false) != null, "a badge shows its progress to the next tier")
	main.codex.close_guide()
	main.guide_viewed = main.codex.viewed_after_open()
	check(not Codex.badges_new, "opening the guide clears the badge alert")
	# some dinosaurs also need a badge before they go on sale
	check(Progression.MARKET_BADGES.size() >= 5 and Progression.MARKET_BADGES.keys().all(func(k):
		var r: Array = Progression.MARKET_BADGES[k]
		return Market.items().has(k) and Badges.DATA.has(r[0]) and r[1] >= 1 and r[1] <= 3), "badge requirements come from the config and name real badges and tiers")
	# dinosaur tiers: per category 2 Starters, 2 Skilled, 2 Expert, 1 Legend;
	# higher tiers need the category's own badge; Starters arrive with the button
	var tiers_ok := true
	var tier_bad := []
	for cat in Dinos.CATEGORIES:
		var mine: Array = Dinos.ids().filter(func(id): return Dinos.category_of(id) == cat)
		var counts := [0, 0, 0, 0]
		for id in mine:
			var t := Dinos.tier(id)
			counts[t - 1] += 1
			var r: Array = Progression.MARKET_BADGES.get(id, [])
			if t == 1 and (not r.is_empty() or Market.unlock_m(id) < Progression.UNLOCKS[Dinos.slot_of(cat)]):
				tier_bad.append(id)
			if t > 1 and (r[0] != Dinos.CATEGORY_BADGE[cat] or r[1] != t - 1):
				tier_bad.append(id)
		tiers_ok = tiers_ok and counts == [2, 2, 2, 1]
		mine.sort_custom(func(a, b): return Market.unlock_m(a) < Market.unlock_m(b))
		for i in range(1, mine.size()):
			if Dinos.tier(mine[i]) < Dinos.tier(mine[i - 1]):
				tier_bad.append(mine[i])
	check(tiers_ok, "each category has 2 Starter, 2 Skilled, 2 Expert and 1 Legend dinosaur")
	check(tier_bad.is_empty(), "Starters need only distance and come after their button; higher tiers need their category's badge, in tier order: %s" % str(tier_bad))
	check(Dinos.CATEGORY_BADGE.values().all(func(b): return Badges.DATA.has(b)) and Dinos.tier_label("utahraptor") == "Legend" and Dinos.tier_label("raptor") == "Original", "every category has its own badge, and tiers have names (stars are levels)")
	# power-ups and slots arrive before the stretch they help with
	check(Market.unlock_m("time_crystal") < Progression.TREX_CHARGE_M[0] and Progression.SLOT_UNLOCK_M < Progression.TREX_CHARGE_M[0], "the Time Crystal and the second slot come before the first hunter charge")
	check(Progression.MARKET_BADGES.get("fossil_magnet", [""])[0] == "amber" and Progression.MARKET_BADGES.get("golden_fossil", [""])[0] == "clean", "power-ups that match a badge need it")
	var req: Array = Progression.MARKET_BADGES["ankylosaurus"]
	var best_b: float = main.best_m
	main.badge_stats = {}
	main.badge_tiers = {}
	main.new_market.clear()
	main.best_m = Market.unlock_m("ankylosaurus") + 10
	check(not Market.on_sale("ankylosaurus", main.best_m) and Market.lock_text("ankylosaurus", main.best_m).contains(Badges.DATA[req[0]].name), "reaching its distance isn't enough: it names the badge it still needs")
	check(Market.lock_text("ankylosaurus", main.best_m).contains("m in one run ✓"), "...and ticks off the distance already reached")
	main.badge_best(Badges.DATA[req[0]].stat, Badges.DATA[req[0]].tiers[req[1] - 1]) if Badges.DATA[req[0]].kind == "best" else main.badge_event(Badges.DATA[req[0]].stat, Badges.DATA[req[0]].tiers[req[1] - 1])
	check(Market.on_sale("ankylosaurus", main.best_m), "earning the badge puts it on sale")
	check(main.new_market.has("ankylosaurus"), "...and it's announced as new in the Market")
	main.open_guide()
	main.codex._show_tab(5)
	check(_codex_badge(req[0]).find_child("Unlocks", true, false) != null, "the badge's card says which dinosaur it unlocks")
	main.codex.close_guide()
	main.best_m = best_b
	main.badge_stats = stats_keep
	main.badge_tiers = tiers_keep
	main.meat_bank = bank_keep
	SaveData.save_badges(stats_keep, tiers_keep)
	SaveData.save_meat(bank_keep)
	main.start_run(false)


func _codex_card(title: String) -> Control:
	for c in main.codex.grid.get_children():
		if c.is_queued_for_deletion():
			continue
		for l in c.find_children("*", "Label", true, false):
			if l.text == title:
				return c
	return null


func _codex_badge(id: String) -> Control:
	var found: Array = main.codex.grid.get_children().filter(func(c): return c.name == "Badge_" + id)
	return found[0] if not found.is_empty() else null


## The 28 expansion dinosaurs as playable forms on their category's button.
func _species_checks() -> void:
	var originals := {}
	for f in Forms.ORDER:
		originals[f] = Forms.get_data(f)
	var unl_before: Array = main.unlocked.duplicate()
	var owned_before: Array = main.dinos_owned.duplicate()
	main.unlocked = Forms.ORDER.duplicate()
	check(not main.equip("gallimimus"), "a dinosaur you don't own can't be equipped")
	main.dinos_owned = Dinos.ids().duplicate()
	var anims_ok := true
	var fits_ok := true
	var bad := []
	for id in Dinos.ids():
		check(Dinos.playable(id), "%s has its playable art" % id)
		check(main.equip(id), "an owned %s can be equipped" % id)
		var slot := Dinos.slot_of(Dinos.category_of(id))
		var d := Forms.get_data(slot)
		check(d.id == id and main.equipped_in(Dinos.category_of(id)) == id, "%s is on the %s button" % [id, Dinos.category_of(id)])
		var sf := SpriteLib.character(slot)
		var need := ["idle", "run", "jump", "duck", "slide"]
		if d.get("flies", false):
			need.append_array(["fly", "glide", "takeoff", "land"])
		if d.get("swims", false):
			need.append("swim")
		for anim in need:
			if not sf.has_animation(anim) or sf.get_frame_count(anim) != 8 or sf.get_frame_texture(anim, 0) == null:
				anims_ok = false
				bad.append("%s:%s" % [id, anim])
		var df := SpriteLib.death(slot)
		anims_ok = anims_ok and df.has_animation("die") and df.has_animation("hop")
		# slide and duck boxes must fit under a ledge; standing boxes are sane
		fits_ok = fits_ok and d.slide_box.y < Tuning.LEDGE_CLEARANCE and d.duck_box.y < Tuning.LEDGE_CLEARANCE \
				and d.hitbox.y > 40.0 and d.hitbox.x > 40.0
		# the button's abilities stay
		var orig: Dictionary = Forms.DATA[slot]
		check(d.get("flies", false) == orig.get("flies", false) and d.get("swims", false) == orig.get("swims", false) \
				and d.get("light", false) == orig.get("light", false) and (orig.breaks as Array).all(func(k): return d.breaks.has(k)),
				"%s keeps its button's abilities" % id)
	check(anims_ok, "every equipped dinosaur has all its animations: %s" % str(bad))
	check(fits_ok, "every dinosaur's slide and duck boxes fit under a ledge")
	# attributes change the numbers, relative to the button's original
	main.equip("gallimimus")
	check(Forms.get_data(Forms.RAPTOR).drain < Forms.DATA[Forms.RAPTOR].drain and Forms.get_data(Forms.RAPTOR).jump < Forms.DATA[Forms.RAPTOR].jump, "Gallimimus: more stamina (less drain) but a lower jump than the Raptor")
	main.equip("carnotaurus")
	var bc0 := Dinos.break_chance("carnotaurus", Forms.RAPTOR)
	check(bc0 > 0.5 and bc0 < 1.0, "a base Carnotaurus (Power 7) breaks through small hazards most of the time (%.2f)" % bc0)
	var lv_c: Dictionary = main.dino_levels.duplicate(true)
	var xp_c: Dictionary = main.dino_xp.duplicate()
	for k in Dinos.ROSTER:
		main.dino_xp[k] = 1e6   # plenty of experience: these checks are about attributes
	Dinos.xp = main.dino_xp
	main.meat_bank = 99999
	for i in 4:
		main.level_up("carnotaurus", "power")   # 7 -> 7.3 -> 7.6 -> 7.9 -> 8.2
	check(Dinos.break_chance("carnotaurus", Forms.RAPTOR) > bc0, "levelling its Power raises the chance")
	main.equip("ankylosaurus")
	check(Forms.get_data(Forms.TRICERATOPS).armor == 0 and not Forms.get_data(Forms.TRICERATOPS).breaks.has("fence"), "a base Ankylosaurus (Armor 9, Power 9) has no shield or fence-smashing yet")
	for i in 5:
		main.level_up("ankylosaurus", "armor")
	check(Forms.get_data(Forms.TRICERATOPS).armor == 1, "levelling its Armor to 10 gives it a shield")
	main.dino_levels = lv_c
	Dinos.levels = main.dino_levels
	main.dino_xp = xp_c
	Dinos.xp = main.dino_xp
	Forms.clear_cache()
	check(Forms.get_data(Forms.TRICERATOPS).chase_rate < Forms.DATA[Forms.TRICERATOPS].chase_rate, "...but it's slower than the Triceratops")
	# playing as one: shift, run, slide and die without trouble
	main.start_run(false)
	var p: Player = main.player
	main.energy = 100.0
	main._shift(Forms.TRICERATOPS)
	check(p.sprite.sprite_frames == SpriteLib.character(Forms.TRICERATOPS) and p.data().id == "ankylosaurus", "shifting uses the equipped dinosaur's art")
	check(main.hud.form_buttons[Forms.TRICERATOPS].icon == load("res://assets/portraits/ankylosaurus.png"), "its button shows its portrait")
	for i in 30:
		p.invuln = 99.0
		main.chase_gap = Tuning.CHASE_GAP_MAX
		main._play_step(1.0 / 60.0)
	p.press_slide()
	main._play_step(1.0 / 60.0)
	check(p.is_low() and p.hitbox().size.y < Tuning.LEDGE_CLEARANCE, "an equipped dinosaur slides under ledges")
	p.release_slide()
	p.invuln = 0.0
	p.die()
	check(p.sprite.sprite_frames == SpriteLib.death(Forms.TRICERATOPS), "it dies with its own animation")
	# unequip goes back to the original; equips are saved
	main.equip("quetzalcoatlus")
	check(SaveData.load_equipped().get("flyer", "") == "quetzalcoatlus", "equipped dinosaurs are saved")
	# --- the Herd: choose and compare dinosaurs per category
	main.state = main.State.TITLE
	main.open_herd("runner")
	var herd: Herd = main.herd
	check(herd.visible and herd.tab == "runner", "the Herd opens on a category")
	check(Dinos.CATEGORIES.keys().all(func(cat): return Herd.members(cat).size() == 8 and Herd.members(cat)[0] == Forms.DATA[Dinos.slot_of(cat)].id), "each Herd tab lists the category's 8 dinosaurs, original first")
	check(herd.list.get_child_count() == 8, "the Runner tab shows 8 rows")
	main.equip("gallimimus")
	herd.show_tab("runner")
	check(herd.selected == "gallimimus" and herd.detail.find_child("Equip", true, false) == null, "it starts on the equipped dinosaur")
	herd._drag_dist = 0.0
	herd.select("coelophysis")
	var dl := herd.detail.find_child("Delta_stamina", true, false) as Label
	var dexp: float = Dinos.stat("coelophysis", "stamina") - Dinos.stat("gallimimus", "stamina")
	check(dl != null and dl.text == ("+" if dexp > 0 else "-") + Dinos.fmt(absf(dexp)), "selecting another shows the attribute differences from the equipped one")
	var eqb := herd.detail.find_child("Equip", true, false) as Button
	check(eqb != null, "an owned dinosaur can be equipped from the Herd")
	eqb.pressed.emit()
	check(main.equipped_in("runner") == "coelophysis", "Equip in the Herd puts it on the button")
	herd.select("raptor")
	(herd.detail.find_child("Equip", true, false) as Button).pressed.emit()
	check(main.equipped_in("runner") == "raptor" and not Forms.equipped.has(Forms.RAPTOR), "\"Use the original\" goes back to the Raptor")
	var owned_keep_h: Array = main.dinos_owned.duplicate()
	main.dinos_owned = []
	herd.select("utahraptor")
	check(herd.detail.find_child("Equip", true, false) == null and herd.detail.find_child("HowToGet", true, false) != null, "a dinosaur you don't own can be compared, with how to get it, but not equipped")
	main.dinos_owned = owned_keep_h
	herd.close_herd()
	check(not herd.visible, "the Herd closes")
	main.open_market()
	main.market.show_tab("dinos")
	var owned_card := _market_card("gallimimus")
	check(owned_card.find_child("Equip", true, false) == null and owned_card.find_child("HerdHint", true, false) != null, "the Market no longer equips: owned dinosaurs point to the Herd")
	main.market.close_market()
	# --- levels: +1 to a chosen attribute for meat, shown as stars
	var lv_keep: Dictionary = main.dino_levels.duplicate(true)
	var xp_keep: Dictionary = main.dino_xp.duplicate()
	var meat_keep: int = main.meat_bank
	# experience: a level-up needs XP (1 per metre run as the dinosaur) as well as meat
	main.dino_xp = {}
	Dinos.xp = main.dino_xp
	main.meat_bank = 5000
	check(Dinos.xp_for(2) == Dinos.XP_STEP and Dinos.xp_for(3) == Dinos.XP_STEP * 3.0, "each level needs more XP (XP_STEP for level 2, 3 x XP_STEP in all for level 3)")
	check(not Dinos.xp_ok("raptor") and not main.level_up("raptor", "speed") and main.meat_bank == 5000, "without XP a dinosaur can't level up, and no meat is spent")
	main.start_run(false)
	main.unlocked = Forms.ORDER.duplicate()
	main.energy = 100.0
	main._shift(Forms.RAPTOR)
	main._badge_run_step(Dinos.XP_STEP + 1.0)
	check(is_equal_approx(Dinos.xp_of("raptor"), Dinos.XP_STEP + 1.0) and Dinos.xp_ok("raptor"), "running as the Raptor earns it XP, metre for metre")
	check(main.new_this_run.any(func(t): return String(t).contains("Raptor ready for Lv 2")), "reaching a level's XP is news for the run")
	check(Dinos.xp_of("rok") == 0.0 and float(main.run_dino_m.get("raptor", 0.0)) > 0.0, "XP goes to the form running (Rok earns none while he's a dinosaur); the run remembers each one's metres")
	main.player.shift_to(Forms.ROK)
	main._badge_run_step(30.0)
	check(is_equal_approx(Dinos.xp_of("rok"), 30.0 * main.xp_mult()), "Rok earns XP on his own feet")
	for k in Dinos.ROSTER:
		main.dino_xp[k] = 1e6
	Dinos.xp = main.dino_xp
	main.unequip("runner")
	main.meat_bank = 0
	check(not main.level_up("raptor", "jump"), "no meat, no level-up")
	main.meat_bank = 5000
	var cost := Dinos.level_cost("raptor")
	check(Dinos.level("raptor") == 1 and Dinos.level_stars("raptor") == "★" + "☆".repeat(Dinos.MAX_LEVEL - 1) and cost == Dinos.LEVEL_COST[0] * 2, "a dinosaur starts at level 1 (one star of 10); the next level costs its tier's price x 2")
	var sp0 := Dinos.stat("raptor", "speed")
	var g0 := Dinos.gain("raptor", "speed")
	check(is_equal_approx(g0, 0.4) and is_equal_approx(Dinos.gain("raptor", "power"), 0.5) and is_equal_approx(Dinos.gain("raptor", "jump"), 0.4), "a level-up adds about half a point, less the higher the attribute already is (+0.5 below 5, +0.4 from 5)")
	check(main.level_up("raptor", "speed") and main.meat_bank == 5000 - cost and is_equal_approx(Dinos.stat("raptor", "speed"), sp0 + g0) and Dinos.level("raptor") == 2, "levelling the original Raptor raises its Speed for meat")
	check(absf(float(Forms.get_data(Forms.RAPTOR).chase_rate) - (float(Forms.DATA[Forms.RAPTOR].chase_rate) + 5.0 * g0)) < 0.01, "a levelled original plays faster (its numbers follow its attributes)")
	check(Dinos.fmt(Dinos.stat("raptor", "speed")) == "5.4", "decimal attributes show with one decimal")
	var guard := 0
	while Dinos.can_raise("raptor", "speed") and guard < 10:
		main.level_up("raptor", "speed")
		guard += 1
	check(is_equal_approx(Dinos.stat("raptor", "speed"), Dinos.LEVEL_LEAN_MAX[0]) and not main.level_up("raptor", "speed"), "levelling can't lift its lean past one below the next tier (the Raptor's Speed stops at 6)")
	check(Dinos.level_cost("raptor") == Dinos.LEVEL_COST[0] * (Dinos.level("raptor") + 1), "each level costs more")
	guard = 0
	while Dinos.can_level("raptor") and guard < 20:
		main.level_up("raptor", "armor")
		guard += 1
	check(Dinos.level("raptor") == Dinos.MAX_LEVEL and Dinos.MAX_LEVEL == 10 and not main.level_up("raptor", "power"), "level 10 is the most")
	check(float(SaveData.load_dino_levels().get("raptor", {}).get("pts", {}).get("armor", 0.0)) > 0.0, "levels are saved")
	check(Dinos.stat("raptor", "armor") < float(Dinos.base_stat("raptor", "armor")) + 0.5 * (Dinos.MAX_LEVEL - 1), "diminishing returns: many levels in one attribute add less than half a point each")
	var owned_keep_l: Array = main.dinos_owned.duplicate()
	main.dinos_owned = []
	check(not main.level_up("gallimimus", "speed"), "a dinosaur you don't own can't be levelled")
	main.dinos_owned = owned_keep_l
	main.open_herd("runner")
	herd = main.herd
	herd._drag_dist = 0.0
	herd.select("gallimimus")
	var plus := herd.detail.find_child("Level_jump", true, false) as Button
	check(plus != null and herd.detail.find_child("Level", true, false) != null, "the Herd shows an owned dinosaur's level and a + per attribute")
	var j0: float = Dinos.stat("gallimimus", "jump")
	plus.pressed.emit()
	check(Dinos.stat("gallimimus", "jump") == j0 and (herd.detail.find_child("Level_jump", true, false) as Button).text == "Confirm?", "the first + tap only asks to confirm")
	(herd.detail.find_child("Level_jump", true, false) as Button).pressed.emit()
	check(Dinos.stat("gallimimus", "jump") > j0, "the second tap levels it up")
	herd.close_herd()
	# Rok has attributes and levels too
	main.dino_xp["rok"] = 1e6
	Dinos.xp = main.dino_xp
	check(Dinos.known("rok") and is_equal_approx(Dinos.stat("rok", "speed"), float(Dinos.ROK_STATS.speed)) and Dinos.level_cap("rok", "speed") == Dinos.ATTR_MAX, "Rok has attributes (capped at 10)")
	var rok_c0: float = Forms.get_data(Forms.ROK).chase_rate
	check(main.level_up("rok", "speed") and Forms.get_data(Forms.ROK).chase_rate > rok_c0, "levelling Rok's Speed lets him gain on the hunter")
	main.level_up("rok", "stamina")
	check(float(Forms.get_data(Forms.ROK).get("amber_mult", 1.0)) > 1.0 and float(Forms.get_data(Forms.ROK).drain) == 0.0, "Rok's Stamina makes amber refill more (and he still uses no energy)")
	main.open_herd("rok")
	check(main.herd.tab == "rok" and main.herd.list.get_child_count() == 3 and main.herd.detail.find_child("Level_speed", true, false) != null and main.herd.detail.find_child("Equip", true, false) == null, "the Herd's Heroes tab lists Rok, Nira and Boro and levels the hero in play")
	main.herd.close_herd()
	# --- heroes: Nira and Boro, bought in the Market, run in Rok's place
	check(Heroes.has("nira") and Heroes.has("boro") and not Heroes.has("rok") and Market.category("nira") == "heroes", "Nira and Boro are heroes sold in the Market's Heroes tab")
	check(Dinos.stat("nira", "speed") > Dinos.stat("rok", "speed") and Dinos.stat("boro", "armor") > Dinos.stat("rok", "armor") and Dinos.ATTRS.all(func(a): return true) and ["rok", "nira", "boro"].all(func(h): return Dinos.ATTRS.reduce(func(t, a): return t + Dinos.base_stat(h, a), 0) == Dinos.TIER_BUDGET[0]), "each hero has its own attributes on the originals' budget (Nira quicker, Boro tougher)")
	var owned_h: Array = main.dinos_owned.duplicate()
	main.dinos_owned.erase("nira")
	check(not main.equip("nira"), "a hero you don't own can't be played")
	main.dinos_owned.append("nira")
	check(main.equip("nira") and Forms.get_data(Forms.ROK).id == "nira" and main.equipped_in("hero") == "nira" and SaveData.load_equipped().get("hero", "") == "nira", "an owned hero takes Rok's button (saved)")
	var nd := Forms.get_data(Forms.ROK)
	check(nd.chase_rate > Forms.DATA[Forms.ROK].chase_rate and int(nd.air_jumps) == 1 and float(nd.drain) == 0.0, "Nira is quicker than Rok and keeps his double jump and free energy")
	var nsf := SpriteLib.character(Forms.ROK)
	check(["idle", "run", "jump", "duck", "slide"].all(func(a): return nsf.has_animation(a) and nsf.get_frame_count(a) == 8) and SpriteLib.death(Forms.ROK).has_animation("hop") and SpriteLib.reactions("nira") != null, "Nira has her own run, jump, slide, duck, death and hit reactions")
	check(main.player.sprite.sprite_frames == SpriteLib.character(Forms.ROK) and main.player.data().id == "nira", "equipping a hero swaps the running sprite at once")
	check(nd.slide_box.y < Tuning.LEDGE_CLEARANCE and nd.hitbox.y * nd.scale > Tuning.LEDGE_CLEARANCE, "she slides under ledges and has to (standing, she's too tall)")
	main.dino_xp["nira"] = 0.0
	Dinos.xp = main.dino_xp
	main.start_run(false)
	main._badge_run_step(40.0)
	check(is_equal_approx(Dinos.xp_of("nira"), 40.0 * main.xp_mult()), "running as Nira earns her XP")
	main.open_herd("rok")
	main.herd._drag_dist = 0.0
	main.herd.select("rok")
	(main.herd.detail.find_child("Equip", true, false) as Button).pressed.emit()
	check(Forms.get_data(Forms.ROK).id == "rok" and not Forms.equipped.has(Forms.ROK), "\"Play as Rok\" in the Herd puts Rok back")
	main.herd.close_herd()
	main.dinos_owned = owned_h
	main.dino_levels = lv_keep
	Dinos.levels = main.dino_levels
	main.dino_xp = xp_keep
	Dinos.xp = main.dino_xp
	SaveData.save_dino_levels(lv_keep)
	Forms.clear_cache()
	main.meat_bank = meat_keep
	main.equip("quetzalcoatlus")
	for cat in Dinos.CATEGORIES:
		main.unequip(cat)
	check(Forms.ORDER.all(func(f): return Forms.get_data(f) == originals[f]), "unequipping restores the original four exactly")
	check(SaveData.load_equipped().is_empty(), "...and is saved")
	main.dinos_owned = owned_before
	SaveData.save_dinos_owned(owned_before)
	main.unlocked = unl_before
	main.start_run(false)


func _market_checks() -> void:
	var owned_before: Array = main.boosters_owned.duplicate()
	var unlocked_mk: Array = main.unlocked.duplicate()
	if not main.unlocked.has(Forms.RAPTOR):
		main.unlocked.append(Forms.RAPTOR)   # Primal Amber is sold once a dinosaur is unlocked (config/requirements.cfg)
	# the Market sells the third slot and every non-starter power-up, at config prices
	var c := ConfigFile.new()
	c.load(Progression.CONFIG_PATH)
	check(Market.items().size() == 6 + 3 + 28 + 2 + Crafting.market_ids().size() and Market.items().has(Market.SLOT_ID) and not Market.items().has("egg"), "the Market sells the third slot, 3 Heart Containers, the five locked power-ups, 28 dinosaurs, 2 heroes and basic crafting materials (no gear, no card packs)")
	# the Dinosaur Expansion
	check(Dinos.ids().size() == 28 and Dinos.ids().all(func(id): return Market.items().has(id)), "all 28 expansion dinosaurs are for sale")
	check(Dinos.ids().all(func(id): return Market.price(id) == int(c.get_value("market", id, -1)) and Market.unlock_m(id) == int(c.get_value("market_unlocks", id, -1))), "dinosaur prices and distances come from the config")
	var dino_m: Array = Dinos.ids().map(func(id): return Market.unlock_m(id))
	dino_m.sort()
	var spread := true
	for i in range(1, dino_m.size()):
		spread = spread and dino_m[i] > dino_m[i - 1]
	check(spread and dino_m[0] >= Progression.UNLOCKS[Forms.RAPTOR] and dino_m[0] <= Progression.UNLOCKS[Forms.RAPTOR] + 200 and dino_m[-1] >= 4000, "dinosaurs go on sale one at a time, from just after the first button unlocks to long runs: %s" % str(dino_m))
	check(Dinos.ids().all(func(id): return Dinos.icon(id) != null and Dinos.icon(id).get_size().x > 0 and Dinos.name_of(id) != ""), "every dinosaur has its art and name")
	# categories: one per dino button; every dinosaur is in exactly one
	check(Dinos.CATEGORIES.size() == 4 and Dinos.CATEGORIES.values().map(func(c): return c.form).all(func(f): return f != Forms.ROK), "four dino categories, one per dino button (Rok stays Rok)")
	var everyone: Array = Dinos.ids() + ["raptor", "triceratops", "spinosaurus", "pteranodon"]
	check(everyone.all(func(id): return Dinos.ROSTER.has(id) and Dinos.CATEGORIES.has(Dinos.category_of(id))) and Dinos.ROSTER.size() == everyone.size(), "all 32 dinosaurs have a category")
	for cat in Dinos.CATEGORIES:
		var form_id: String = Forms.get_data(Dinos.CATEGORIES[cat].form).id
		check(Dinos.category_of(form_id) == cat, "%s is in its own button's category (%s)" % [form_id, cat])
	var lean_ok := true
	var profiles := {}
	for id in Dinos.ROSTER:
		var lean: String = Dinos.CATEGORIES[Dinos.category_of(id)].lean
		var v := Dinos.base_stat(id, lean)
		var tl := Dinos.tier(id)
		lean_ok = lean_ok and v == Dinos.TIER_LEAN_MAX[tl] and Dinos.ATTRS.all(func(a): var x: int = Dinos.base_stat(id, a); return x >= 1 and x <= Dinos.ATTR_MAX and x <= v)
		profiles[str(Dinos.ATTRS.map(func(a): return Dinos.stat(id, a)))] = true
	check(lean_ok, "each dinosaur leans on its category's attribute (its best), capped by tier: originals 6, Starter/Skilled 8, Expert/Legend 10")
	check(profiles.size() == Dinos.ROSTER.size(), "no two dinosaurs share the same attributes")
	# trade-offs, not upgrades: the same budget for all, so none beats another everywhere
	check(Dinos.ROSTER.keys().all(func(id): return Dinos.ATTRS.reduce(func(t, a): return t + Dinos.base_stat(id, a), 0) == Dinos.TIER_BUDGET[Dinos.tier(id)]), "each tier has its own attribute budget: %s" % str(Dinos.TIER_BUDGET))
	check(range(1, Dinos.TIER_BUDGET.size()).all(func(i): return Dinos.TIER_BUDGET[i] > Dinos.TIER_BUDGET[i - 1]), "higher tiers have more points: buying dinosaurs pays off")
	check(Dinos.base_stat("raptor", "speed") < Dinos.ATTR_MAX and Dinos.ROSTER.keys().all(func(id): return Dinos.tier(id) >= 3 or Dinos.base_stat(id, Dinos.CATEGORIES[Dinos.category_of(id)].lean) < Dinos.ATTR_MAX), "only Experts and Legends max out their category's attribute (not the original Raptor)")
	check(Dinos.ROSTER.keys().all(func(id): return Dinos.ATTRS.all(func(a): return Dinos.base_stat(id, a) >= 1 and Dinos.base_stat(id, a) <= Dinos.ATTR_MAX)), "attributes are on a 10-point scale")
	var dominated := []
	for x in Dinos.ROSTER:
		for y in Dinos.ROSTER:
			if x != y and Dinos.tier(x) == Dinos.tier(y) and Dinos.ATTRS.all(func(a): return Dinos.stat(x, a) >= Dinos.stat(y, a)):
				dominated.append("%s>=%s" % [x, y])
	check(Dinos.CATEGORIES.keys().all(func(cat): return Dinos.members(cat).size() == 8), "every category has 8 dinosaurs (the balanced roster)")
	check(Dinos.ids().all(func(id): return Dinos.desc(id).contains("pterosaur") == (Dinos.category_of(id) == "flyer")), "every Flyer is described as a pterosaur and nothing else is")
	check(dominated.is_empty(), "within a tier, no dinosaur is at least as good as another at everything: %s" % str(dominated))
	check(Dinos.stat("raptor", "speed") > Dinos.stat("triceratops", "speed") and Dinos.stat("pteranodon", "stamina") < Dinos.stat("raptor", "stamina"), "the playable four's attributes match how they play")
	check(Market.price("golden_fossil") == int(c.get_value("market", "golden_fossil", -1)), "Market prices come from the config")
	main._refresh_hud()
	check(main.state == main.State.TITLE and main.hud.market_button.visible, "Market button on the title screen")
	check(main.meat_bank == 0 and not main.buy("amber_shield"), "no meat, no purchase")
	# meat collected in a run is banked when the run ends; amber is only energy
	main.start_run(false)
	main._refresh_hud()
	check(not main.hud.market_button.visible, "no Market button during a run")
	main.course._ground = Tuning.GROUND_Y
	main.course._pickup("amber", main.player.position + Vector2(0, -60))
	main._collide()
	check(main.run_meat == 0, "amber is energy, not Market money")
	main.course._pickup("meat", main.player.position + Vector2(0, -60))
	main._collide()
	check(main.run_meat == 1, "picking up meat counts toward the bank")
	main._refresh_hud()
	check(main.hud.meat_label.text == "1", "the HUD shows the meat collected this run")
	check(main.hud.meat_pill.visible, "the meat counter shows during a run")
	main.course.boosters_owned = ["egg"]
	# reward spots: one kind each, mostly amber; meat, lone power-ups and
	# mixed amber+meat spots are rarer
	var spots := {"amber": 0, "meat": 0, "power": 0, "mixed": 0, "heart": 0, "material": 0}
	for i in 4000:
		spots[main.course._spot_kind()] += 1
	check(spots.amber > 2000, "reward spots are mostly amber: %s" % str(spots))
	var near := func(n: int, chance: float) -> bool: return n > 4000 * chance * 0.6 and n < 4000 * chance * 1.4
	check(near.call(spots.power, Tuning.POWER_SPOT_CHANCE) and near.call(spots.mixed, Tuning.MIXED_SPOT_CHANCE) \
			and near.call(spots.meat, Tuning.MEAT_SPOT_CHANCE), "meat, power-up and mixed spots follow their chances: %s" % str(spots))
	check(spots.heart > 0 and spots.heart < spots.power * 0.5, "heart spots are rare: %s" % str(spots))
	check(main.course._fill("heart", true) == "heart" and main.course._fill("heart", false) == "", "a heart spot holds just one heart")
	check(main.course._fill("power", false) == "" and main.course._fill("power", true) == "egg", "a power spot holds just one power-up")
	var counts := {}
	var total := 0
	for i in 4000:
		var n: int = main.course._spot_count()
		counts[n] = counts.get(n, 0) + 1
		total += n
	check(counts.keys().all(func(k): return k >= 1 and k <= 4) and counts.size() == 4, "amber and meat spots hold a random 1-4 pickups: %s" % str(counts))
	check(counts[1] > counts[4] and total / 4000.0 < 2.6, "fewer pickups are likelier (average %.2f, it used to be 3)" % (total / 4000.0))
	check(main.course._fill("meat", false) == "meat" and main.course._fill("amber", true) == "amber", "a meat or amber spot is all one kind")
	main._game_over()
	check(main.meat_bank == 1 and SaveData.load_meat() == 1 and main.run_meat == 0, "the run's meat is banked (and saved) when it ends")
	main._refresh_hud()
	check(main.hud.meat_pill.visible and main.hud.meat_label.text == "1", "after the run the counter still shows that run's meat (not 0)")
	var st_before = main.state
	main.state = main.State.TITLE
	main._refresh_hud()
	check(not main.hud.meat_pill.visible, "the title screen hides the run counter (it shows the bank)")
	main.state = st_before
	main.start_run(false)
	main.state = main.State.TITLE
	# buying: the first tap arms the button, the second buys
	var plenty := 0
	for id in Market.items():
		plenty += Market.price(id)
	main.meat_bank = plenty   # enough for everything, whatever the prices
	main.open_market()
	check(main.market.visible, "the Market opens")
	# sections: Power-Ups, Dinosaurs, Other, each listing only its own items
	var listed := 0
	for t in Market.TABS:
		main.market.show_tab(t)
		var in_tab: Array = main.market.grid.get_children().filter(func(x): return not x.is_queued_for_deletion() and not x.has_meta("empty"))
		var shown: int = main.market.grid.get_children().filter(func(x): return not x.is_queued_for_deletion()).size()
		check(shown >= Market.GRID_ROWS * main.market.grid.columns and shown % main.market.grid.columns == 0,
				"the %s tab's board is filled out with empty spots (no bare rows)" % t)
		check(in_tab.size() > 0 and in_tab.all(func(x): return Market.category(x.name) == t), "the %s tab lists only its own items" % t)
		check(main.market.tab_buttons[t].button_pressed and Market.TABS.keys().all(func(o): return o == t or not main.market.tab_buttons[o].button_pressed), "the %s tab button shows as selected" % t)
		listed += in_tab.size()
	check(listed == Market.items().size(), "every Market item is in exactly one tab")
	var fits := []
	for id in Market.items():
		main.market.show_tab(Market.category(id))
		main.market.select(id)
		if main.market.panel.get_combined_minimum_size().x > main.market.panel.size.x + 0.5:
			fits.append(id)
	check(fits.is_empty(), "no item's details push the shop panel wider than its place (off the screen) %s" % str(fits))
	var keep_best: float = main.best_m
	main.best_m = 0.0
	var locked_id := ""
	for id in Market.items():
		if Dinos.has(id) and not Market.on_sale(id, 0.0):
			locked_id = id
			break
	main.market.show_tab("dinos")
	main.market.select(locked_id)
	var lk: Node = main.market.detail.find_child("Locked", true, false)
	check(lk != null and lk.get_index() <= 2, "a locked item says what unlocks it right under its name")
	main.best_m = keep_best
	check(Market.category("amber_shield") == "powerups" and Market.category("gallimimus") == "dinos" and Market.category(Market.SLOT_ID) == "other", "power-ups, dinosaurs and the booster slot are grouped apart")
	var dino_card := _market_card("gallimimus")
	check(dino_card.find_child("Category", true, false) != null and (dino_card.find_child("Category", true, false) as Label).text.strip_edges() == "RUNNER" and (dino_card.find_child("Tier", true, false) as Label).text.begins_with("Starter"), "a dinosaur card shows its category and tier")
	check(Dinos.tradeoff("gallimimus") == "Best: Speed · Weakest: Power" and (dino_card.find_child("Tradeoff", true, false) as Label).text == Dinos.tradeoff("gallimimus"), "a dinosaur card says what it's best and weakest at")
	check(dino_card.find_child("Stats", true, false) != null and dino_card.find_child("Stats", true, false).get_child_count() == Dinos.ATTRS.size(), "a dinosaur card shows its five attributes")
	var on_sale_now: bool = main.best_m >= Market.unlock_m("gallimimus")
	check(main.market._anims.any(func(a): return a[1] == "gallimimus") == on_sale_now, "a dinosaur card plays its idle loop once on sale")
	# regression: switching tabs and back must not turn the art into white squares
	var best_tabs: float = main.best_m
	main.best_m = Market.unlock_m("gallimimus")
	main.market.show_tab("dinos")
	main.market.show_tab("powerups")
	main.market.show_tab("dinos")
	main.market._animate(1.0)   # step the loops past a frame change
	var art_ok := true
	for a in main.market._anims:
		var img: Image = (a[0] as TextureRect).texture.get_image()
		var clear := 0
		if img != null:
			for y in range(0, img.get_height(), 4):
				for x in range(0, img.get_width(), 4):
					if img.get_pixel(x, y).a < 0.05:
						clear += 1
		art_ok = art_ok and img != null and clear > 0
	check(not main.market._anims.is_empty() and art_ok, "dinosaur art survives switching tabs (no white squares)")
	main.best_m = best_tabs
	main.market.press_buy("amber_shield")
	check(not main.boosters_owned.has("amber_shield"), "one tap only asks to confirm")
	main.market.press_buy("amber_shield")
	var left: int = plenty - Market.price("amber_shield")
	check(main.boosters_owned.has("amber_shield") and main.meat_bank == left, "the second tap buys it")
	check(SaveData.load_unlocked_boosters().has("amber_shield") and SaveData.load_meat() == left, "purchases and the meat left are saved")
	check(not main.buy("amber_shield"), "an owned item can't be bought twice")
	var best_dino: float = main.best_m
	main.best_m = Market.unlock_m("gallimimus")
	check(main.buy("gallimimus") and main.dinos_owned.has("gallimimus") and SaveData.load_dinos_owned().has("gallimimus"), "buying a dinosaur adds it to your herd (saved)")
	check(not main.buy("gallimimus") and main.market.owns("gallimimus"), "an owned dinosaur can't be bought twice")
	main.best_m = Market.unlock_m("quetzalcoatlus") - 1
	check(not main.buy("quetzalcoatlus"), "a dinosaur not yet on sale can't be bought")
	main.best_m = best_dino
	main.meat_bank = left
	var card: Control = _market_card("amber_shield")
	check(card.find_child("Buy", true, false) == null, "an owned card has no Buy button")
	# items go on sale by best distance; the Market itself is open from the start
	check(Market.unlock_m("amber_shield") == 0 and Market.unlock_m(Market.SLOT_ID) > 0, "something is on sale from the start, the rest by distance")
	check(Market.unlock_m(Market.SLOT_ID) == int(c.get_value("market_unlocks", Market.SLOT_ID, -1)), "Market unlock distances come from the config")
	check(not main.buy(Market.SLOT_ID) and main.slot_count == 1, "an item not yet on sale can't be bought")
	var locked_card := _market_card(Market.SLOT_ID)
	check(locked_card.find_child("Locked", true, false) != null and locked_card.find_child("Buy", true, false) == null, "a locked card says how far to run, with no Buy button")
	var best_m_before: float = main.best_m
	main.best_m = Market.unlock_m(Market.SLOT_ID)
	check(main.buy(Market.SLOT_ID) and main.slot_count == 3 and SaveData.load_booster_slots() == 3, "once on sale, buying the third booster slot opens it")
	main.meat_bank = 0
	card = _market_card("golden_fossil")
	check(card.find_child("Buy", true, false) == null, "a card you can't afford has no Buy button")
	# the Market is a place: the hero outside the merchant's cave, the item on the counter
	var mk: Market = main.market
	mk.close_market()
	main.open_market()
	check(mk.find_child("MarketScene", true, false) != null and mk.hero.sprite_frames == SpriteLib.character(Forms.ROK) and mk.hero.animation == "idle",
			"the Market shows your hero standing outside the merchant's cave")
	mk.selected = ""
	mk.refresh()
	check(mk.on_counter.texture == null and mk.say_label.text != "", "with nothing chosen, the merchant greets you")
	mk._drag_dist = 0.0
	mk.select("golden_fossil")
	check(mk.on_counter.texture == Boosters.icon("golden_fossil") and mk.foot_icon.texture == Boosters.icon("golden_fossil") and mk.say_label.text != "",
			"picking an item: the merchant holds it up and talks about it, and the details strip shows it")
	check(Market.LINES.values().all(func(pool): return (pool as Array).size() >= 5), "the merchant has at least five lines for every situation")
	check(main.audio.played.any(func(n): return String(n).begins_with("mumble_")), "the merchant mumbles when he speaks")
	var said := {}
	for i in 12:
		mk._say_key = ""
		said[mk.say("greet", [], str(i))] = true
	check(said.size() >= 4, "his greetings vary (%d different in 12)" % said.size())
	check(mk.grid.columns == 3 and mk.grid.get_children().all(func(t): return (t as Control).custom_minimum_size.y >= 120.0), "the items are cards three across, with room for picture, name and price")
	check(mk.panel.position.x > mk.scene.hero_spot().x and mk.panel.position.x > mk.scene.mouth().x, "the cave and characters are on the left, the shop panel on the right")
	main.meat_bank = 0
	mk.select("golden_fossil")
	check(mk.buy_box.find_child("Buy", true, false) == null and mk.buy_box.get_child_count() == 1, "without the meat, BUY is greyed (NEED N)")
	main.meat_bank = Market.price("mat_wood")
	main.best_m = maxf(main.best_m, float(Crafting.bench_m()))
	var w0 := Crafting.have("wood")
	mk.show_tab("gear")
	mk.press_buy("mat_wood")
	mk.press_buy("mat_wood")
	check(Crafting.have("wood") == w0 + Crafting.bundle() and mk._say != "" and mk.scene._happy > 0.0, "after a sale the merchant beams and thanks you")
	main.materials.clear()
	main._save_gear()
	main.market.close_market()
	check(not main.market.visible, "the Market closes")
	# Heart Containers: on sale by best score, one after another; each adds a heart
	var bs_keep := Market.best_score
	var hc_keep: int = main.heart_containers
	main.heart_containers = 0
	Market.hearts_owned = 0
	Market.best_score = Market.unlock_score("heart_1") - 1
	check(not Market.on_sale("heart_1", 99999.0) and Market.lock_text("heart_1", 0.0).contains("score %d points" % Market.unlock_score("heart_1")), "a Heart Container goes on sale by best score, not distance")
	Market.best_score = Market.unlock_score("heart_2")
	check(Market.on_sale("heart_1", 0.0) and not Market.on_sale("heart_2", 0.0) and Market.lock_text("heart_2", 0.0).contains("Heart Container I first"), "...and only after the one before it")
	main.meat_bank = Market.price("heart_1")
	check(main.buy("heart_1") and main.heart_containers == 1 and SaveData.load_heart_containers() == 1 and main.max_health() == (Tuning.MAX_HEARTS + 1) * Hearts.QUARTERS, "buying one adds a heart for good (saved)")
	check(Market.on_sale("heart_2", 0.0) and Market.unlock_score("heart_3") > Market.unlock_score("heart_2") * 2 and Market.price("heart_3") > Market.price("heart_2"), "the next goes on sale once owned; they get steeper and dearer")
	main.start_run(false)
	main._refresh_hud()
	check(main.health == main.max_health() and main.hud.hearts_box.get_child_count() == Tuning.MAX_HEARTS + 1, "runs start with the extra heart, and the HUD shows it")
	main.heart_containers = hc_keep
	Market.hearts_owned = hc_keep
	SaveData.save_heart_containers(hc_keep)
	Market.best_score = bs_keep
	main.meat_bank = 0
	main.start_run(false)
	main.best_m = best_m_before
	# crossing an item's distance in a run announces it once (start just short
	# of it, so it's the only new item and the news doesn't push it past "+N more")
	main.best_m = Market.unlock_m("time_crystal") - 20.0
	main.start_run(false)
	main.distance = (Market.unlock_m("time_crystal") + 5.0) * Tuning.PX_PER_M
	main._check_unlocks()
	check(main._market_announced.has("time_crystal"), "reaching an item's distance announces it in the Market")
	check(main.new_market.has("time_crystal"), "an item going on sale joins the run's news")
	var best_keep: float = main.best_m
	main.hud.show_banner("ZONE: TEST", "", Color.WHITE)
	main._finish_game_over()
	check(main.hud.banner.modulate.a == 0.0, "the game-over screen clears any banner covering it")
	check(main.hud.help_label.text.contains("Market: " + Market.item_name("time_crystal")), "the game-over screen lists what went on sale")
	# the summary card: how it ended, the numbers, the rank, the dinosaurs played
	check(main.summary.visible and not main.hud.center_panel.visible, "the run ends on a summary card instead of the plain game-over text")
	check(main.run_dino_m.is_empty() or main.summary.panel.find_child("Dinos", true, false) != null, "the summary has its table of Rok and the dinosaurs played")
	check(["Tile_Distance", "Tile_Score", "Tile_Meat", "Tile_Best run", "Cause", "RankLetter"].all(func(n): return main.summary.panel.find_child(n, true, false) != null), "it shows how the run ended, distance, score, meat, best run and the rank")
	check((main.summary.panel.find_child("News", true, false) as Label).text.contains(Market.item_name("time_crystal")), "...and the run's news")
	check(RunSummary.cause_text("pit").contains("pit") and RunSummary.cause_text("rock (rok, ground=true)").contains("boulder") and RunSummary.cause_text("caught").contains("caught"), "the cause is in plain words")
	main.start_run(false)
	check(not main.summary.visible, "a new run hides the summary")
	# run ranks: steep score tiers with a multiplier on the run's meat and XP
	var rr: Array = Tuning.RUN_RANKS
	check(RunSummary.rank_for(0)[1] == "C" and RunSummary.rank_for(rr[2][0])[1] == rr[2][1] and RunSummary.rank_for(1e9)[1] == rr[-1][1], "a run's score sets its rank")
	check(range(2, rr.size()).all(func(i): return float(rr[i][0]) >= float(rr[i - 1][0]) * 2.0 and float(rr[i][2]) > float(rr[i - 1][2])), "ranks are steep (each needs at least twice the score) and pay more")
	var xp_r: Dictionary = main.dino_xp.duplicate()
	main.score = float(rr[3][0]) + 10.0
	main.run_meat = 10
	main.run_dino_m = {"rok": 50.0, "raptor": 100.0}
	main.dino_xp["raptor"] = 100.0
	Dinos.xp = main.dino_xp
	main._apply_rank()
	check(main.run_rank[1] == rr[3][1] and main.run_meat == int(roundf(10 * float(rr[3][2]))) and main.run_bonus_meat > 0, "the rank multiplies the run's meat")
	check(is_equal_approx(Dinos.xp_of("raptor"), 100.0 * float(rr[3][2])) and Dinos.xp_of("rok") >= 50.0 * (float(rr[3][2]) - 1.0) - 0.01, "...and each one's XP from the run (Rok's too)")
	main._apply_rank()
	check(main.run_meat == int(roundf(10 * float(rr[3][2]))), "the bonus is applied once")
	main.run_meat = 0
	main.dino_xp = xp_r
	Dinos.xp = main.dino_xp
	main.start_run(false)
	# NEW tags: shown on the first Market visit only, and remembered
	main.market_seen = []
	main.meat_bank = 0
	check(main.market_new().has("time_crystal") and main.market_badge(), "a newly on-sale item is NEW and badges the Market button")
	main.open_market()
	check(main.market._new.has("time_crystal"), "the first visit tags it NEW")
	check(main.market.tab_buttons["powerups"].text.contains("●"), "its tab shows a dot for something new")
	main.market.close_market()
	check(SaveData.load_market_seen().has("time_crystal") and main.market_new().is_empty(), "after a visit it's no longer new (saved)")
	main.open_market()
	check(not main.market._new.has("time_crystal"), "the next visit has no NEW tag")
	main.market.close_market()
	check(not main.market_badge(), "no badge with nothing new and nothing affordable")
	main.meat_bank = Market.price("time_crystal")
	check(main.market_badge(), "the badge comes back when something is affordable")
	main.meat_bank = 0
	main.best_m = best_keep
	SaveData.save_best_m(int(best_keep))
	for k in Boosters.DATA:
		if not main.boosters_owned.has(k):
			main.boosters_owned.append(k)
	# bought power-ups appear in runs
	main.course.boosters_owned = main.boosters_owned
	var kinds := {}
	for i in 300:
		kinds[main.course._booster()] = true
	check(kinds.size() == Boosters.DATA.size(), "owned power-ups all show up as pickups")
	# each power-up's effect
	main.start_run(false)
	var p: Player = main.player
	main.energy = Tuning.ENERGY_MAX
	check(not main.booster_ready("amber_shield"), "Primal Amber waits while PRIMAL energy is full")
	main.energy = 10.0
	check(main.booster_ready("amber_shield"), "...and can be used once it's down")
	main.activate_booster("amber_shield")
	check(is_equal_approx(main.energy, Tuning.ENERGY_MAX), "Primal Amber refills PRIMAL energy to full")
	p.invuln = 0.0
	main.start_run(false)
	p = main.player
	main.activate_booster("fossil_magnet")
	main.course._pickup("amber", p.position + Vector2(300, -70))
	var k: Pickup = main.course.pickups[main.course.pickups.size() - 1]
	var d0 := k.position.distance_to(p.position + Vector2(10, -70))
	for i in 10:
		p.invuln = 99.0
		main._play_step(1.0 / 60.0)
	check(not is_instance_valid(k) or k.position.distance_to(p.position + Vector2(10, -70)) < d0 - 100.0, "the Fossil Magnet pulls amber in")
	main.start_run(false)
	main.activate_booster("time_crystal")
	var gap0: float = main.chase_gap
	for i in 60:
		main.player.invuln = 99.0
		main._play_step(1.0 / 60.0)
	check(main.speed_mod < 0.8, "the Time Crystal slows the world (%.2f)" % main.speed_mod)
	check(main.chase_gap > gap0, "the Time Crystal lets Rok pull away from the T-rex")
	check(not main.booster_ready("time_crystal"), "a running power-up can't be stacked")
	for i in int(Tuning.SLOW_TIME * 60.0):
		main.player.invuln = 99.0
		main._play_step(1.0 / 60.0)
	check(not main.power_on("time_crystal"), "the Time Crystal wears off")
	main.start_run(false)
	var unlocked_before: Array = main.unlocked.duplicate()
	main.unlocked = Forms.ORDER.duplicate()
	main.energy = 0.0
	main.activate_booster("primal_berry")
	main.energy = 0.0
	main._request_form(Forms.TRICERATOPS)
	check(main.player.form == Forms.TRICERATOPS and main.shift_cd == 0.0, "the Primal Berry shifts with no energy and no cooldown")
	for i in 30:
		main.player.invuln = 99.0
		main._play_step(1.0 / 60.0)
	check(main.player.form == Forms.TRICERATOPS, "...and the form costs no energy while it lasts")
	main.unlocked = unlocked_before
	main.start_run(false)
	main.activate_booster("golden_fossil")
	var perk_m := 1.0 + Badges.perk_bonus("points")   # Point Hunter's bonus stacks on top
	check(is_equal_approx(main.points_mult(), 2.0 * perk_m), "the Golden Fossil doubles points")
	var s0: float = main.score
	main._smash(main.course.boulder(main.player.position.x + 600.0), Color.WHITE)
	check(absf((main.score - s0) - Tuning.SMASH_SCORE * 2 * perk_m) < 0.01, "a smash is worth double under the Golden Fossil")
	main.start_run(false)
	check(main.power_t.is_empty(), "a new run clears running power-ups")
	# back to a fresh save for the other tests
	main.boosters_owned = owned_before
	SaveData.save_unlocked_boosters(owned_before)
	main.slot_count = 1
	SaveData.save_booster_slots(1)
	main.dinos_owned = []
	SaveData.save_dinos_owned([])
	main.meat_bank = 0
	main.run_meat = 0
	SaveData.save_meat(0)
	main.course.boosters_owned = owned_before
	main.unlocked = unlocked_mk
	main.state = main.State.TITLE
	main.player.shift_to(Forms.ROK)


func _config_checks() -> void:
	var c := ConfigFile.new()
	check(c.load(Progression.CONFIG_PATH) == OK, "config/progression.cfg loads")
	check(Progression.UNLOCKS[Forms.RAPTOR] == int(c.get_value("dinos", "raptor", -1)), "dino unlocks come from the config")
	check(Progression.intro_m("ledge") == float(c.get_value("introductions", "ledge", -1)), "introductions come from the config")
	check(Progression.MARINATE_M == float(c.get_value("pacing", "marinate_m", -1)), "pacing comes from the config")
	for key in Progression.INTRO_TEXT:
		check(c.has_section_key("introductions", key), "config lists when '%s' is introduced" % key)


func _progression_checks() -> void:
	var prev := -1.0
	for e in Progression.INTROS:
		check(e[0] >= prev, "intros are in distance order (%s)" % e[1])
		prev = e[0]
	prev = 0.0
	for f in [Forms.RAPTOR, Forms.TRICERATOPS, Forms.SPINOSAURUS, Forms.PTERANODON]:
		check(Progression.UNLOCKS[f] > prev, "unlocks get farther (%d)" % f)
		prev = Progression.UNLOCKS[f]
	check(Progression.pressure(1000.0) == 0.0, "no pressure ramp while learning")
	# start: only rocks & mushrooms
	var p0 := _picks(0.0, 30)
	check(p0.all(func(k): return k == "small"), "first stretch has only small hazards")
	# when logs arrive they are introduced alone first, then mixed with small
	var p1 := _picks(Progression.intro_m("log") + 10.0, 40)
	check(p1.slice(3, 6) == ["log", "log", "log"], "logs introduced solo: %s" % str(p1.slice(0, 8)))
	check(p1.all(func(k): return k in ["small", "log"]), "only met hazards just after logs arrive")
	# nothing advanced shows up early
	var m2: float = Progression.intro_m("ledge") - 10.0
	var p2 := _picks(m2, 200)
	for k in ["fence", "ledge", "wall", "tall_fence", "combo", "hard_combo"]:
		if Progression.intro_m(k) > m2:
			check(not p2.has(k), "%s not before its intro (%d m)" % [k, int(m2)])
	# combos appear later and only use familiar hazards
	var m3: float = Progression.intro_m("combo") + 150.0
	var p3 := _picks(m3, 300)
	check(p3.has("combo"), "combos appear after their intro")
	check(not p3.has("hard_combo") or Progression.intro_m("hard_combo") <= m3, "no hard combos before theirs")
	main.course.skip_intros_before(Progression.intro_m("ledge") + 1.0)
	var ledge_picks := []
	main.course.metres = Progression.intro_m("ledge") + 60.0
	for i in 300:
		ledge_picks.append(main.course._next_key())
	check(ledge_picks.has("ledge"), "ledges are in the mix after their introduction")
	main.course.metres = Progression.intro_m("combo")
	var fam: Array = main.course._familiar_parts(Course.COMBO_PARTS)
	check(fam.has("small") and fam.has("log"), "familiar combo parts by the first combo")
	main.course.metres = 0.0
	main.course.intro_counts.clear()


func _unit_checks() -> void:
	# rok_alarm is the user's recording (tools/prepare_voice.py): optional until supplied
	check(Audio.SFX.all(func(n): return main.audio.streams.has(n) or (n == "rok_alarm" and not ResourceLoader.exists("res://assets/sounds/rok_alarm.wav"))), "all sound effects load")
	check(main.audio.music.stream != null, "music loads")
	check(main.audio.music_players.size() == Zones.ZONES.size(), "one music track per zone")
	main.audio.set_music_weights(Zones.weights(Zones.ZONE_LEN_M * 1.5))
	check(main.audio.music_players[1].volume_db > main.audio.music_players[0].volume_db + 20.0, "the desert track plays in the Desert")
	main.audio.set_music_weights(Zones.weights(0.0))
	var steps := {}
	for f in Forms.ORDER:
		steps[main.STEP_SOUND[f]] = true
		check(main.audio.streams.has(main.STEP_SOUND[f]) and main.audio.streams.has(main.JUMP_SOUND[f]), "form %d has its own step and jump sounds" % f)
	check(steps.size() >= 3, "dinosaurs don't all sound alike")
	for z in Zones.ZONES:
		check(main.audio.streams.has(main.SURFACE_SOUND[z.id]), "%s has its own footstep surface" % z.id)
	# sprite frames build for every form
	for f in Forms.ORDER:
		var sf := SpriteLib.character(f)
		for a in ["idle", "walk", "run", "jump", "duck", "slide"]:
			check(sf.get_frame_count(a) == 8, "form %d anim %s has 8 frames" % [f, a])
	for n in SpriteLib.wind_meta():
		check(SpriteLib.wind(n).get_frame_count("wind") == 8, "wind %s frames" % n)
	# jump heights clear the obstacles they are meant to
	var h := func(v: float) -> float: return v * v / (2.0 * Tuning.GRAVITY)
	check(h.call(Forms.get_data(Forms.ROK).jump) > 160.0, "Rok single jump clears boulders")
	check(h.call(Forms.get_data(Forms.RAPTOR).jump) > 240.0, "Raptor clears 2-high walls in one jump")
	# every non-flying form can cross pits at the speed it has when they appear:
	# early pits (<= PIT_MIN+30) at the pit intro distance, the widest once
	# the pressure ramp is full
	var speed_at := func(m: float) -> float:
		var px := m * Tuning.PX_PER_M   # solve px = v0*t + ramp/2*t^2
		var a := Tuning.SPEED_RAMP * 0.5
		var t := (-Tuning.START_SPEED + sqrt(Tuning.START_SPEED * Tuning.START_SPEED + 4.0 * a * px)) / (2.0 * a)
		return minf(Tuning.START_SPEED + Tuning.SPEED_RAMP * t, Tuning.MAX_SPEED)
	for f in Forms.ORDER:
		if Forms.get_data(f).get("flies", false):
			continue   # flyers glide across
		var air: float = 2.0 * Forms.get_data(f).jump / Tuning.GRAVITY
		check(air * speed_at.call(Progression.intro_m("pit")) > Tuning.PIT_MIN + 30.0 + 20.0, "form %d clears early pits" % f)
		check(air * speed_at.call(Progression.RAMP_FULL_M) > Tuning.PIT_MAX + 20.0, "form %d clears the widest pit" % f)
	# terrain queries
	var t: Terrain = main.terrain
	check(absf(t.height_at(Tuning.PLAYER_X) - Tuning.GROUND_Y) < 0.1, "terrain starts at ground level")
	check(t.flat_y(0.0, 1200.0) == Tuning.GROUND_Y, "start stretch is flat")
	# a hill's steepest downhill step per frame at top speed stays under the snap limit
	# steepest slope-tile section, per frame at top speed, stays near the snap limit
	var max_slope := 0.0
	for piece in ["slope_up", "slope_down"]:
		var prof: Array = t.meta[piece].profile
		for k in range(1, prof.size()):
			max_slope = maxf(max_slope, absf(prof[k][1] - prof[k - 1][1]) / (prof[k][0] - prof[k - 1][0]))
	check(max_slope * Tuning.MAX_SPEED / 60.0 < Tuning.GROUND_SNAP * 1.5, "slope tiles are runnable (max slope %.2f)" % max_slope)
	check(absf(t.step - (float(t.meta.slope_up.left) - float(t.meta.slope_up.right))) < 0.5 and t.step > 40.0 and t.step < 60.0, "terrain level step matches the slope tile (%.1f)" % t.step)
	# smash rules
	# Power roll: small rocks, mushrooms and vines may be broken straight through
	check(is_equal_approx(Dinos.break_chance("raptor", Forms.RAPTOR), 0.0) and Dinos.break_chance("triceratops", Forms.TRICERATOPS) > Dinos.break_chance("pteranodon", Forms.PTERANODON) and is_equal_approx(Dinos.break_chance("ankylosaurus", Forms.TRICERATOPS), 1.0), "the higher the Power the better the chance, and Smashers get a bonus")
	check(not "small" in Forms.get_data(Forms.TRICERATOPS).breaks, "small hazards aren't a sure smash any more: they're a Power roll")
	check("rock" in Forms.get_data(Forms.TRICERATOPS).breaks, "tri breaks rock")
	check("fence" in Forms.get_data(Forms.SPINOSAURUS).breaks, "spino breaks fence")
	# ledge clearance: Rok and Spinosaurus must slide; every low pose fits under
	var c := Tuning.LEDGE_CLEARANCE
	var hh := func(f: int, key: String) -> float: return Forms.get_data(f)[key].y * Forms.get_data(f).scale
	check(hh.call(Forms.ROK, "hitbox") > c, "standing Rok hits a ledge")
	check(hh.call(Forms.SPINOSAURUS, "hitbox") > c, "standing Spinosaurus hits a ledge")
	for f in Forms.ORDER:
		check(hh.call(f, "slide_box") < c - 8.0, "form %d slides under a ledge" % f)
		check(hh.call(f, "duck_box") < c - 4.0, "form %d ducks under a ledge" % f)
	for a in ["duck", "slide"]:
		for f in Forms.ORDER:
			check(SpriteLib.character(f).get_frame_count(a) == 8, "form %d has %s" % [f, a])


func _report() -> void:
	check(runs >= 1, "a run started")
	check(max_score > 100, "bot scored > 100 (got %d)" % max_score)
	check(obstacles_seen.size() >= 3, "saw >= 3 obstacle kinds: %s" % str(obstacles_seen.keys()))
	check(forms_used.size() >= 2, "used >= 2 forms: %s" % str(forms_used.keys()))
	check(heights.size() >= 3, "ran at >= 3 different heights: %s" % str(heights.keys()))
	check(pits_met > 0 or bot.pits > 0, "bot met at least one pit (%d)" % pits_met)
	# (sliding under ledges is checked directly by the touch/trap checks; the
	# bot may die before it reaches one, so only report it here)
	print("ledges passed=%d slid=%d" % [bot.ledges_passed, bot.ledges_slid])
	check(bot.gates_passed > 0, "bot got through at least one dino gate")
	# shown, or skipped because an earlier run already went past it (taught)
	for k in ["small", "pit"]:
		check(main.seen.has(k) or Progression.taught(k, main.best_m, main.seen), "intro banner shown for %s" % k)
	if obstacles_seen.has("overhead"):
		check(main.seen.has("ledge") or Progression.taught("ledge", main.best_m, main.seen), "intro banner shown for ledges")
	print("flights=%d gates_passed=%d" % [bot.flights, bot.gates_passed])
	print("pits_jumped=%d ledges_slid=%d heights=%s deaths=%s" % [bot.pits, bot.ledges_slid, heights.keys(), deaths])
	print("runs=%d max_score=%d shifts=%d jumps=%d kinds=%s forms=%s platform=%s" % [
		runs, max_score, bot.shifts, bot.jumps, obstacles_seen.keys(), forms_used.keys(), landed_on_platform])
	if failures.is_empty():
		print("ALL TESTS PASSED")
	else:
		for f in failures:
			print("FAIL: ", f)
		print("%d FAILURE(S)" % failures.size())


## The training run (tutorial_run.gd): plays once on a fresh save, teaches
## step by step, can't be lost, and hands over to the coach hints.
func _training_run_checks() -> void:
	check(not main.tutorial_run_done, "a fresh save hasn't played the training run")
	main._touch_pressed("")
	check(main.tutorial_run != null, "the first tap on a fresh save starts the training run")
	var froze := false
	var hold := 0
	var steps_seen := {}
	var parts_seen := {}
	var intros_seen := {}
	var note_back_ok := false
	var tried_back := false
	var tried_still := false
	var note_still := false
	var hurt_in := {}
	var cards_ok := {}
	var bar_ok := true
	var meat_note_clear := true
	check(main.next_chest_m == INF and main.preview_done, "no starter chest or wild-dinosaur preview in the training run")
	for f in 6000:
		var tr: TutorialRun = main.tutorial_run
		if tr == null:
			break
		steps_seen[TutorialRun.STEPS[tr.i].id] = true
		if main.player.invuln > 1.1:
			hurt_in[TutorialRun.STEPS[tr.i].id] = true
		if tr.phase == "note" and TutorialRun.STEPS[tr.i].id == "meat" and tr.note_list[tr.note_i][0] == "meat":
			for k in main.course.pickups:
				if k.kind in ["meat", "big_meat"] and k.position.x > Tuning.PLAYER_X - 60.0:
					meat_note_clear = false
		if hold > 0:
			hold -= 1
			if hold == 0:
				main._release_jump()
		if main.state == main.State.INFO and main._info_t > Tuning.INFO_MIN_TIME:
			main._touch_pressed("")
		if tr.frozen and tr.phase == "note":
			var part: String = tr.note_list[tr.note_i][0]
			if part == "":
				intros_seen[TutorialRun.STEPS[tr.i].id] = main.hud.coach_marker.title == TutorialRun.STEPS[tr.i].title
			else:
				parts_seen[part] = main.hud.coach_marker != null and main.hud.coach_marker.target == main.hud.hud_part(part)
			if not tried_still and tr._note_t > TutorialRun.NOTE_MIN:
				# moving the mouse, a drag or letting go of a key doesn't move on
				tried_still = true
				var before := [tr.i, tr.note_i, tr.phase]
				var mm := InputEventMouseMotion.new()
				mm.position = Vector2(400, 300)
				mm.relative = Vector2(30, 5)
				main._unhandled_input(mm)
				var dr := InputEventScreenDrag.new()
				dr.position = Vector2(420, 300)
				main._unhandled_input(dr)
				var up := InputEventKey.new()
				up.keycode = KEY_SPACE
				up.physical_keycode = KEY_SPACE
				up.pressed = false
				main._unhandled_input(up)
				note_still = before == [tr.i, tr.note_i, tr.phase]
			elif not tried_back and tr.note_i == 1 and tr._note_t > TutorialRun.NOTE_MIN:
				tried_back = true
				var chips_ok: bool = main.hud.coach_marker.chips == ["back", "next"]
				var back_at: Vector2 = (main.hud.coach_marker.chip_rects()["back"] as Rect2).get_center()
				main._touch_pressed(main.hud.action_at(back_at))
				note_back_ok = chips_ok and tr.note_i == 0 and main.hud.coach_marker.chips == ["next"]
			elif f % 10 == 0:
				main._touch_pressed("")   # any tap moves on
		elif tr.frozen:
			froze = true
			var st: Dictionary = TutorialRun.STEPS[tr.i]
			var want_card: Array = st.back if tr.phase == "back" else (st.air if st.has("air") and not main.player.on_ground else st.card)
			cards_ok[st.id] = main.hud.coach_marker.card and main.hud.coach_marker.title == want_card[0] and main.hud.coach_marker.target is TouchButton
			if main.state == main.State.PLAYING:
				main._refresh_hud()
				bar_ok = bar_ok and main.hud.skip_button.visible and main.hud.tutorial_plaque.visible and not main.hud.stop_button.visible
			if f % 10 == 0:
				var b: String = "form_0" if tr.phase == "back" else String(TutorialRun.STEPS[tr.i].button)
				main._touch_pressed(b)
				if b == "jump":
					hold = 20 if TutorialRun.STEPS[tr.i].get("hold", false) else 3
		main._process(1.0 / 60.0)
	check(froze, "the training run freezes on each hint until the right button")
	check(TutorialRun.STEPS.filter(func(st): return st.has("card")).all(func(st): return cards_ok.get(st.id, false)),
			"each moment to act shows its card at the top with the button glowing %s" % [cards_ok])
	check(bar_ok, "during the training run a Tutorial plaque and Skip show (instead of Stop)")
	check(not hurt_in.has("high_jump"), "holding JUMP at the hint clears the log (it used to land Rok on a long one) %s" % [hurt_in.keys()])
	check(meat_note_clear, "the meat note waits until every piece is grabbed or passed")
	check(main.tutorial_run == null and main.tutorial_run_done and SaveData.load_tutorial_run_done(), "the training run ends and is saved as done")
	check(TutorialRun.STEPS.all(func(st): return steps_seen.has(st.id)), "it goes through every step (%s)" % ", ".join(steps_seen.keys()))
	check(main.state == main.State.TITLE, "...and ends on the main menu")
	check(TutorialRun.STEPS.filter(func(st): return st.has("title")).all(func(st): return intros_seen.get(st.id, false)),
			"every step opens with its own note that waits for a tap %s" % [intros_seen])
	check(note_still, "a note waits: moving the mouse, a drag or a key release doesn't move it on")
	check(note_back_ok, "a note's Back chip returns to the previous note (and the first has only Next)")
	check(["hearts", "chase", "score", "distance", "meat", "primal"].all(func(k): return parts_seen.get(k, false)),
			"it points out the hearts, hunter meter, points, distance, meat and PRIMAL energy %s" % [parts_seen])
	# the menu tour: Marketplace, Camp, Encyclopedia
	check(main.menu_tour != null, "a finished training run starts the menu tour")
	main._process(1.0 / 60.0)
	main._touch_pressed("")
	check(main.menu_tour != null and main.state == main.State.TITLE and main.tutorial_run == null, "during the tour a stray tap doesn't start a run (it asks)")
	main.hud.clear_banner()
	main.menu_tour._skip_t = 0.0
	var toured := []
	for k in MenuTour.STEPS.size():
		var st: Dictionary = MenuTour.STEPS[k]
		main._refresh_hud()
		main._process(1.0 / 60.0)
		var btn_ok: bool = main.hud.coach_marker.target != null and (main.hud.coach_marker.target as TouchButton).action == st.button
		main._touch_pressed(st.button)
		for f in 3:
			main._process(1.0 / 60.0)
		var scr: CanvasLayer = {"market": main.market, "herd": main.herd, "codex": main.codex}[st.screen]
		var back_ok: bool = scr.visible and main.hud.coach_marker.target == scr.find_child("Back", true, false)
		if btn_ok and back_ok:
			toured.append(st.screen)
		match st.screen:
			"market": main.market.close_market()
			"herd": main.herd.close_herd()
			"codex": main.codex.close_guide()
		main._process(1.0 / 60.0)
	check(toured.size() == 3, "the tour points at each menu button, then at Back inside its screen %s" % [toured])
	check(main.menu_tour == null, "...and ends after the Encyclopedia")
	main.menu_tour = MenuTour.new(main)
	main._touch_pressed("")
	main._touch_pressed("")
	check(main.menu_tour == null and main.state == main.State.TITLE, "two stray taps skip the tour")
	main.hud.clear_banner()
	# the tour opened the guide and the Market: forget what it looked at
	main.guide_viewed = []
	SaveData.save_viewed([])
	main.market_seen = []
	SaveData.save_market_seen([])
	check(["jump", "double_jump", "slide", "attack", "booster", "shift"].all(func(id): return main.tutorial.learned(id)), "what it taught won't be hinted again")
	check(not main.unlocked.has(Forms.RAPTOR) and main.seen.has("small") and main.seen.has("ledge"), "the lent Raptor goes back, and its hazards count as taught")
	main._menu_t = 0.0
	main._touch_pressed("")
	check(main.tutorial_run == null and main.state != main.State.TITLE, "after that, a tap starts a normal run (it plays only once)")
	# skipping: Stop twice
	main.tutorial_run_done = false
	main.start_tutorial()
	main.state = main.State.PLAYING
	main._press_stop()
	main._press_stop()
	check(main.tutorial_run == null and main.tutorial_run_done and main.state == main.State.TITLE, "Stop (twice) skips the training run")
	# leave a clean save for the rest of the checks (the training run may have earned meat or badges)
	main.meat_bank = 0
	SaveData.save_meat(0)
	main.run_meat = 0
	main.badge_stats = {}
	main.badge_tiers = {}
