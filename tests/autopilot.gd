class_name Autopilot
## Simple bot that plays the game: shifts into a form that can smash the
## next obstacle when it has energy, otherwise jumps (double-jumps tall ones).

var main
var shifts := 0
var jumps := 0
var pits := 0
var ledges_slid := 0
var ledges_passed := 0
var gates_passed := 0
var _gates_counted := {}
var _counted := {}
var flights := 0
var _sliding_under: Obstacle = null
var _second_jump_pending := false


func _init(m) -> void:
	main = m


func _form_for(kind: String) -> int:
	for f in [Forms.TRICERATOPS, Forms.SPINOSAURUS]:
		if kind in Forms.get_data(f).breaks:
			return f
	return -1


func tick() -> void:
	if main.state != main.State.PLAYING:
		return
	var p: Player = main.player
	if _sliding_under != null:
		if not is_instance_valid(_sliding_under) or _sliding_under.hitbox().end.x < p.hitbox().position.x:
			p.release_slide()
			ledges_slid += 1
			_sliding_under = null
	var hb := p.hitbox()
	if main.slots.has("egg") and main.chase_gap < 140.0:
		main.use_slot(main.slots.find("egg"))   # eat the egg booster when the T-rex gets close
	if p.on_ground and p.low == Player.Low.NONE and main.terrain.slope_at(p.position.x + 40.0) > 0.05:
		p.press_slide()   # slide downhill to pull away from the T-rex
		p.release_slide()
	for o in main.course.obstacles:
		if (o.kind == "overhead" or o.kind == "swooper") and not _counted.has(o) and o.hitbox().end.x < hb.position.x:
			_counted[o] = true
			ledges_passed += 1
	# deep quicksand (wider than Rok's longest bound): become the Raptor
	var qs: Vector2 = main.terrain.next_quicksand(p.position.x)
	var deep_ahead: bool = qs.x > 0.0 and qs.x - p.position.x < 900.0 \
			and qs.y - qs.x > main.speed * Forms.air_time(Forms.get_data(Forms.ROK)) * 0.95 \
			and main.unlocked.has(Forms.RAPTOR)
	if deep_ahead:
		if p.form != Forms.RAPTOR and main.shift_cd <= 0.0:
			main._request_form(Forms.RAPTOR)   # it skims across (the hop below skips fast forms)
	# quicksand: hop over it (or skim across as the Raptor)
	if p.on_ground and not p.data().get("fast", false) \
			and main.terrain.liquid_at(p.position.x + 70.0) == "quicksand" \
			and main.terrain.liquid_at(p.position.x) != "quicksand":
		p.press_jump()
		_second_jump_pending = true
		return
	# dino gates: become the form the marker shows
	for m in main.course.markers:
		var gx: float = Course.gate_x0(m)
		if gx < p.position.x - 300.0 and not _gates_counted.has(m):
			_gates_counted[m] = true
			gates_passed += 1
		elif gx > p.position.x - 20.0 and gx - p.position.x < 900.0:
			var want: int = m.get_meta("form")
			# deep sand before the gate: stay the Raptor until across it
			if p.form != want and main.shift_cd <= 0.0 and not (deep_ahead and qs.y < gx):
				main._request_form(want)
			break
	var pit: Vector2 = main.terrain.next_pit(p.position.x)
	# Pteranodon: fly over pits when there is plenty of energy
	if p.flies():
		var over := pit.x > 0.0 and pit.x - p.position.x < 260.0 and pit.y > p.position.x - 40.0
		if over and p.on_ground:
			p.press_jump()
			flights += 1
		elif over and not p.on_ground and p.position.y > Tuning.GROUND_Y - 220.0:
			p.press_jump()
		elif not p.on_ground:
			p.release_jump()
			if (pit.x < 0.0 or pit.y < p.position.x - 60.0) and not _gate_ahead(p):
				main._request_form(Forms.ROK)
		if over:
			return
	elif pit.x > 0.0 and pit.x - p.position.x < 420.0 and main.energy > 55.0 and p.on_ground and main.shift_cd <= 0.0 \
			and pit.x - p.position.x > 150.0 and randf() < 0.5:
		main._request_form(Forms.PTERANODON)
		return
	# pits: take off just before the edge
	if pit.x > 0.0 and p.on_ground:
		var to_edge := pit.x - p.position.x
		if to_edge < 60.0 and to_edge > -10.0:
			p.press_jump()
			jumps += 1
			pits += 1
			return
	if not p.on_ground and p.vy > 0.0 and pit.x > 0.0 and pit.x < p.position.x and pit.y > p.position.x \
			and p.air_jumps_left > 0 and p.position.y > Tuning.GROUND_Y - 120.0:
		p.press_jump()  # double jump to finish crossing a wide pit
	var next: Obstacle = null
	for o in main.course.obstacles:
		if o.hitbox().end.x > hb.position.x and (next == null or o.position.x < next.position.x):
			next = o
	if next == null:
		return
	var dist := next.hitbox().position.x - hb.end.x
	if next.kind in p.data().breaks:
		return
	if next.kind == "overhead" or next.kind == "swooper":
		var fits := p.standing_hitbox().position.y >= next.hitbox().end.y
		if not fits and dist < (main.speed + next.roll_speed) * 0.2 and p.on_ground and _sliding_under != next:
			p.press_slide()
			_sliding_under = next
		return
	var want := _form_for(next.kind)
	if want != -1 and not _gate_ahead(p) and main.energy > 30.0 and dist < 500.0 and dist > 60.0 and main.shift_cd <= 0.0:
		main._request_form(want)
		if p.form == want:
			shifts += 1
			return
	var tall := next.size.y * next.shrink.y > 150.0
	var closing: float = main.speed + next.roll_speed   # rolling boulders close in faster
	var lead: float = closing * (0.30 if tall else 0.22)
	if p.on_ground and dist < lead and dist > -20.0:
		p.press_jump()
		jumps += 1
		_second_jump_pending = tall and p.data().air_jumps > 0 and p.data().jump < 1100.0
	elif _second_jump_pending and not p.on_ground and p.vy > -150.0:
		p.press_jump()
		_second_jump_pending = false
	if p.on_ground == false and p.vy > 0.0:
		p.release_jump()


func _gate_ahead(p: Player) -> bool:
	for m in main.course.markers:
		var gx: float = Course.gate_x0(m)
		if gx > p.position.x - 20.0 and gx - p.position.x < 900.0:
			return true
	return false
