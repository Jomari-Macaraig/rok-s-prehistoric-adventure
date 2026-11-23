class_name Course
extends Node2D
## Spawns and scrolls obstacles, floating platforms and pickups.

const P := "res://assets/props/%s.png"

var obstacles: Array[Obstacle] = []
var debris: Array[Node2D] = []   # smashed obstacles playing their break animation
var platforms: Array[FloatingPlatform] = []
var pickups: Array[Pickup] = []
var boosters_owned: Array = ["egg"]   # set by main: only owned power-ups spawn
var _next_gap := 600.0   # px until next spawn
signal introduced(key: String)   # first spawn of a pattern this run

var difficulty := 0.0    # 0..1 (Progression.pressure)
var metres := 0.0        # set by main every frame
var specials: Array = []  # the run event and lap twist running now (main sets them; they pick special materials)
var _spot_x := 0.0       # where the reward spot being filled is (its zone picks its materials)
var speed := Tuning.START_SPEED
## A long pattern waiting for enough flat ground, and how far it has waited (px).
const LONG_KEYS := ["combo", "hard_combo", "ledge"]
const WANT_WAIT_MAX := 2400.0
## A pattern that found no flat ground for WANT_WAIT_MAX px is skipped for
## this many metres so something that fits can come instead. (Before, a due
## lesson that needed a long flat, like the first combo in the hilly Desert,
## kept its turn and nothing at all spawned for hundreds of metres, which
## pushed every later lesson back.)
const NO_ROOM_SKIP_M := 120.0
var _no_room := {}   # pattern key -> metres until which it's skipped
var _want := ""
var _want_wait := 0.0
var _last_meat_m := 0.0   # where the last meat was placed (metres)
var force_meat := false   # set by main during a Golden Hour: every reward spot is meat
var intro_counts := {}   # pattern key -> spawns this run
var unlocked: Array = [Forms.ROK]   # set by main
var introduce_ok: Callable          # main: may this not-yet-taught hazard be introduced now?
var markers: Array[Node2D] = []     # floating dino icons over gates
var next_gate_m := 0.0
var starter_egg := true          # every run offers an egg early on
var forced_gate := ""            # set on a dino unlock: its gate comes next
var holding := false             # no regular hazards until the forced gate is passed
var _hold_marker: Node2D = null
var _last_platform_end := -INF   # world x where the last platform group ends (scrolls)
const PLATFORM_GROUP_GAP := 600.0
var gate_counts := {}
var _zone_idx := 0              # to spot zone changes (showcase gate)
var _zone_gate_counts := {}     # gates per type during this zone visit
var terrain: Terrain
var _ground := Tuning.GROUND_Y   # surface y for the pattern being spawned


func reset() -> void:
	for c in get_children():
		c.queue_free()
	obstacles.clear()
	platforms.clear()
	pickups.clear()
	debris.clear()
	intro_counts.clear()
	_want = ""
	_want_wait = 0.0
	_no_room.clear()
	_last_meat_m = 0.0
	gate_counts.clear()
	markers.clear()
	next_gate_m = 0.0
	_zone_idx = 0
	_zone_gate_counts.clear()
	_last_platform_end = -INF
	starter_egg = true
	forced_gate = ""
	holding = false
	_hold_marker = null
	_next_gap = 700.0


## Treat everything introduced before `m` as already met this run (used
## when a run is started part-way along the curriculum, e.g. by tests).
func skip_intros_before(m: float) -> void:
	for k in Progression.PATTERN_KEYS:
		if Progression.intro_m(k) < m:
			intro_counts[k] = Progression.INTRO_SOLO_SPAWNS
	if Progression.intro_m("diver") < m:
		intro_counts["diver"] = Progression.INTRO_SOLO_SPAWNS


func view_width() -> float:
	return maxf(get_viewport_rect().size.x, Tuning.VIEW_W)


func scroll(spd: float, delta: float) -> void:
	speed = spd
	var dx := spd * delta
	for o in obstacles:
		o.position.x -= dx + o.roll_speed * delta
	for d in debris:
		d.position.x -= dx
	for p in platforms:
		p.position.x -= dx
	for k in pickups:
		k.position.x -= dx
	for m in markers:
		m.position.x -= dx
	_last_platform_end -= dx
	if starter_egg and metres >= Progression.intro_m("egg"):
		_spawn_starter_egg()
	_cull()
	_next_gap -= dx
	if holding:
		# release once Rok is past the forced gate
		if _hold_marker != null and (not is_instance_valid(_hold_marker) or gate_x0(_hold_marker) < Tuning.PLAYER_X - 120.0):
			holding = false
			_hold_marker = null
			_next_gap = randf_range(Tuning.GAP_EARLY.x, Tuning.GAP_EARLY.y) * spd * 0.5
	if _next_gap <= 0.0:
		if _try_gate(spd):
			return
		if holding:
			_next_gap = 60.0
			return
		var x := view_width() + 150.0
		var key := _next_key()
		# a long pattern waiting for flat ground keeps its turn, unless a
		# lesson (something not met yet this run) is due
		if _want != "" and intro_counts.get(key, 0) > 0:
			key = _want
		# only spawn on a flat, solid stretch long enough for the pattern;
		# otherwise try again shortly. Long patterns (combos, ledges) keep
		# their turn for a while instead of being re-rolled, or they'd hardly
		# ever find enough flat ground.
		var y := terrain.flat_y(x - 340.0, x + _pattern_length(key))
		if y < 0.0:
			_next_gap = 60.0
			_want_wait += 60.0
			if _want_wait >= WANT_WAIT_MAX:
				_no_room[key] = metres + NO_ROOM_SKIP_M   # no room here: let something shorter go first
				_want = ""
				_want_wait = 0.0
			else:
				_want = key if key in LONG_KEYS else ""
			return
		_want = ""
		_want_wait = 0.0
		_ground = y
		var solo: bool = intro_counts.get(key, 0) < Progression.INTRO_SOLO_SPAWNS
		if intro_counts.get(key, 0) == 0:
			introduced.emit(key)
		intro_counts[key] = intro_counts.get(key, 0) + 1
		var used := _spawn_key(key, x)
		_rewards(x, used, key)
		var gap_range: Vector2 = Tuning.GAP_EARLY.lerp(Tuning.GAP_LATE, difficulty)
		var gap_t := randf_range(gap_range.x, gap_range.y)
		if solo:
			gap_t *= Tuning.INTRO_GAP_MULT
		_next_gap = used + gap_t * spd


func _cull() -> void:
	for arr in [obstacles, platforms, pickups, markers, debris]:
		for i in range(arr.size() - 1, -1, -1):
			if arr[i].position.x < -400.0:
				arr[i].queue_free()
				arr.remove_at(i)


func remove_obstacle(o: Obstacle) -> void:
	obstacles.erase(o)
	o.queue_free()


## Smash: no more collision, but the obstacle stays as scrolling rubble.
func shatter_obstacle(o: Obstacle) -> void:
	obstacles.erase(o)
	o.shatter()
	debris.append(o)


func remove_pickup(p: Pickup) -> void:
	pickups.erase(p)
	p.queue_free()


# ---------------------------------------------------------------- spawning

func _obstacle(kind: String, parts: Array, s: float, x: float) -> Obstacle:
	var o := Obstacle.new().setup(kind, parts.map(func(n): return P % n), s)
	o.position = Vector2(x, _ground + 6.0)
	add_child(o)
	obstacles.append(o)
	return o


## What a reward spot holds. Each spot is usually ONE kind of pickup:
## "amber" (energy), "meat" (Market currency) or "power" (a single power-up
## on its own). Only rarely ("mixed", MIXED_SPOT_CHANCE) do amber and meat
## share a spot. Meat also comes once MEAT_DUE_M metres pass without any, so
## long fast runs still earn some.
## How many pickups an amber, meat or mixed spot holds: 1-4, fewer more often
## (SPOT_COUNT_WEIGHTS), so energy and meat aren't a steady stream.
func _spot_count() -> int:
	var w: Array = Loot.num("counts", "weights")
	var r: float = randf() * w.reduce(func(a, b): return a + float(b), 0.0)
	for i in w.size():
		r -= float(w[i])
		if r <= 0.0:
			return i + 1
	return w.size()


## Escalating pickups: the share of meat that comes as big meat, from 0
## at BIG_MEAT_FROM_M to BIG_MEAT_MAX_CHANCE at BIG_MEAT_FULL_M.
static func big_meat_chance(m: float) -> float:
	var from: float = Loot.num("escalation", "big_meat_from_m")
	if m < from:
		return 0.0
	return float(Loot.num("escalation", "big_meat_max")) * clampf(inverse_lerp(from, float(Loot.num("escalation", "big_meat_full_m")), m), 0.0, 1.0)


## ...and the share of reward spots holding a rare fossil (0 before FOSSIL_FROM_M).
static func fossil_chance(m: float) -> float:
	var from: float = Loot.num("escalation", "fossil_from_m")
	if m < from:
		return 0.0
	return lerpf(float(Loot.num("escalation", "fossil_min")), float(Loot.num("escalation", "fossil_max")),
			clampf(inverse_lerp(from, float(Loot.num("escalation", "fossil_full_m")), m), 0.0, 1.0))


func _spot_kind() -> String:
	var r := randf()
	var heart: float = Loot.num("spots", "heart")
	if r < heart:
		return "heart"
	r -= heart
	var fc := fossil_chance(metres)
	if r < fc:
		return "fossil"
	r -= fc
	if force_meat:
		return "meat"
	var power: float = Loot.num("spots", "power")
	if r < power:
		return "power"
	r -= power
	var mats := float(Crafting.num("spots", "chance"))   # crafting materials (config/crafting.cfg [spots])
	if r < mats:
		return "material"
	r -= mats
	var meat: float = Loot.num("spots", "meat")
	if r < meat or metres - _last_meat_m >= float(Loot.num("spots", "meat_due_m")):
		_last_meat_m = metres
		return "meat"
	r -= meat
	if r < float(Loot.num("spots", "mixed")):
		_last_meat_m = metres
		return "mixed"
	return "amber"


## The pickup for one place in a spot of `kind`; "" leaves it empty. A power
## spot holds just its power-up, at the spot's `special` place.
## Spots that hold one thing at their special place: a power-up or a heart.
static func _single(kind: String) -> bool:
	return kind == "power" or kind == "heart" or kind == "fossil"


func _fill(kind: String, special: bool) -> String:
	match kind:
		"power":
			return _booster() if special else ""
		"heart":
			return "heart" if special else ""
		"fossil":
			return "fossil" if special else ""
		"mixed":
			return "meat" if randf() < 0.5 else "amber"
		"material":
			var m := Crafting.drop_pick(Crafting.spot_table(String(zone_at_x(_spot_x).id), metres, -1.0, specials))
			return Crafting.PICKUP_PREFIX + m if m != "" else ""
	return kind


## Which power-up a reward spot (or a break drop) holds: the egg
## [power_ups] egg_share of the time, otherwise another power-up the player
## owns (bought in the Market), picked by its weight (config/pickups.cfg).
func _booster() -> String:
	var others := boosters_owned.filter(func(k): return k != "egg" and Loot.booster_weight(k) > 0.0 and Requires.ok("power." + k))
	if others.is_empty() or randf() < float(Loot.num("power_ups", "egg_share")):
		return "egg"
	var r: float = randf() * others.reduce(func(a, k): return a + Loot.booster_weight(k), 0.0)
	for k in others:
		r -= Loot.booster_weight(k)
		if r <= 0.0:
			return k
	return others[-1]


func _pickup(kind: String, pos: Vector2) -> void:
	if kind == "" or not Requires.ok("pickup." + kind):
		return   # nothing, or not yet (config/requirements.cfg, e.g. amber needs a dinosaur)
	if kind == "meat" and randf() < big_meat_chance(metres):
		kind = "big_meat"   # escalating pickups: richer meat later in a run
	var k := Pickup.new().setup(kind)
	add_child(k)
	k.place(pos)
	pickups.append(k)


func _platform(x: float, y: float) -> FloatingPlatform:
	var p := FloatingPlatform.new().setup(1.5, zone_at_x(x).id)
	p.position = Vector2(x, y)
	add_child(p)
	platforms.append(p)
	return p


## Regular hazards take the zone's look: forest props as drawn; sandstone,
## sun-bleached wood and dry thorns in the Desert; basalt and charred wood in
## the Volcanic Badlands. Boulders and walls there use the zone's barricade
## art, so they shatter with its break animation.
const STONE_TINT := {"desert": Color(1.0, 0.78, 0.52), "volcanic": Color(0.5, 0.45, 0.5)}
const WOOD_TINT := {"desert": Color(1.0, 0.93, 0.8), "volcanic": Color(0.34, 0.28, 0.26)}
const THORN_TINT := {"desert": Color(1.25, 1.05, 0.62)}


func _zid(x: float) -> String:
	return zone_at_x(x).id


func _tinted(o: Obstacle, table: Dictionary, zid: String) -> Obstacle:
	if table.has(zid):
		o.modulate = table[zid]
	return o


func small(x: float) -> Obstacle:
	var zid := _zid(x)
	if zid != "forest":
		var stone: Array = [["Stones_02", 1.3], ["Stones_03", 1.0], ["Stones_01", 1.4]].pick_random()
		return _tinted(_obstacle("small", [stone[0]], stone[1], x), STONE_TINT, zid)
	var pick: Array = [["Stones_02", 1.3], ["Stones_03", 1.0], ["Mushrooms_02", 1.0],
			["Mushrooms_05", 1.0], ["Logs_05", 0.9], ["Stones_01", 1.4]].pick_random()
	var o := _obstacle("small", [pick[0]], pick[1], x)
	o.mushroom = String(pick[0]).begins_with("Mushrooms")
	return o


func log_(x: float) -> Obstacle:
	var pick: Array = [["Logs_03", 1.05], ["Logs_04", 1.0], ["Logs_01", 1.0], ["Logs_02", 1.0]].pick_random()
	return _tinted(_obstacle("wood", [pick[0]], pick[1], x), WOOD_TINT, _zid(x))


func _zone_rock(x: float, scale_f: float, min_h: float) -> Obstacle:
	var anim := "desert_wall_break" if _zid(x) == "desert" else "volcanic_wall_break"
	var o := Obstacle.new().setup_anim_stack(anim, scale_f, min_h)
	o.position = Vector2(x, _ground + 6.0)
	o.shrink = Vector2(0.8, 0.88)
	add_child(o)
	obstacles.append(o)
	return o


func boulder(x: float) -> Obstacle:
	if _zid(x) != "forest":
		return _zone_rock(x, 0.62, 1.0)   # a single sandstone / basalt chunk
	var pick: Array = [["Stones_04", 1.15], ["Stones_05", 1.25], ["Other_02", 1.2], ["Other_05", 0.95]].pick_random()
	return _obstacle("rock", [pick[0]], pick[1], x)


func rock_wall(x: float, h: int) -> Obstacle:
	if _zid(x) != "forest":
		# exactly h pieces, each ZONE_WALL_PIECE_H tall, so an h-high wall is
		# as tall as the Forest's (the sandstone and basalt art differ in size)
		var anim := "desert_wall_break" if _zid(x) == "desert" else "volcanic_wall_break"
		var b: Array = SpriteLib.trap_meta()[anim].bounds0
		return _zone_rock(x, Tuning.ZONE_WALL_PIECE_H / float(b[3] - b[1]), (h - 0.5) * 0.82 * Tuning.ZONE_WALL_PIECE_H)
	var parts := []
	for i in h:
		parts.append(["Tile-3_07", "Tile-3_08"].pick_random())
	var o := _obstacle("rock", parts, 1.45, x)
	o.shrink = Vector2(0.85, 0.94)
	return o


func fence(x: float, tall: bool) -> Obstacle:
	var o: Obstacle
	if tall:
		o = _obstacle("fence", ["Fences_03"], 1.5, x)
		o.shrink = Vector2(0.75, 0.9)
	else:
		o = _obstacle("fence", [["Fences_01", "Fences_02"].pick_random()], 1.35, x)
	return _tinted(o, WOOD_TINT, _zid(x))


## Zone at world x (spawns happen ahead of Rok).
func zone_at_x(x: float) -> Dictionary:
	return Zones.zone_at(metres + (x - Tuning.PLAYER_X) / Tuning.PX_PER_M)


## The low ledge you slide under, in the zone's look: a branch with hanging
## vines (forest), a fossil rib arch (desert), floating rock (volcanic).
func ledge(x: float) -> Obstacle:
	var zid: String = zone_at_x(x).id
	var o: Obstacle
	if zid == "forest":
		o = Obstacle.new().setup_overhead_static("forest_overhead", 1.1)
		o.vine = true
	elif zid == "desert":
		o = Obstacle.new().setup_overhead_static("desert_fossil_arch", 1.15)
	else:
		o = Obstacle.new().setup_ledge(2 + randi() % 2, 1.15, zid)
	o.position = Vector2(x, _ground - Tuning.LEDGE_CLEARANCE)
	add_child(o)
	obstacles.append(o)
	if zid != "volcanic":
		_last_platform_end = x + o.size.x * 0.5
		return o   # branches and bones can't be stood on
	# you can also land on top of it (grass top sits a little below the sprite top)
	var top := FloatingPlatform.new().setup_invisible(o.size.x * 0.9)
	top.position = Vector2(x, o.position.y - o.size.y + FloatingPlatform.TOP_INSET * 1.15)
	add_child(top)
	platforms.append(top)
	_last_platform_end = x + o.size.x * 0.5
	return o


# ---------------------------------------------------------------- gates

## Spawns (or asks Terrain to build) a dino gate when one is due. Returns
## true if this spawn slot was used.
func _try_gate(spd: float) -> bool:
	var zone_now := int(floor(metres / Zones.ZONE_LEN_M))
	if zone_now != _zone_idx:
		# new zone: show off one of its signature dino traps soon
		_zone_idx = zone_now
		_zone_gate_counts.clear()
		next_gate_m = minf(next_gate_m, metres + Progression.ZONE_SHOWCASE_M)
	var k := forced_gate
	if k == "":
		if metres < next_gate_m or holding:
			return false
		var zid: String = zone_at_x(view_width() + 720.0).id
		var options := Progression.eligible_gates(metres, unlocked).filter(func(g):
			# a trap nobody has met yet waits its turn like any new hazard
			return introduce_ok.is_null() or introduce_ok.call(Terrain.gate_variant(g, zid)))
		if options.is_empty():
			return false
		var signature: Array = Progression.ZONE_GATES.get(zone_at_x(view_width() + 720.0).id, [])
		var score := func(g: String) -> float:
			return _zone_gate_counts.get(g, 0) * 1.5 - (2.5 if g in signature else 0.0) + randf() * 0.8
		var scored := options.map(func(g): return [score.call(g), g])
		scored.sort_custom(func(a, b): return a[0] < b[0])
		k = scored[0][1]
	var as_terrain: bool = k in Progression.TERRAIN_GATES or \
			(k == "gate_spino" and zone_at_x(view_width() + 720.0).id == "forest")
	if as_terrain:
		if terrain.pending_gate != "":
			return false
		terrain.request_gate(k)   # Terrain calls back terrain_gate() once it is built
		forced_gate = ""
	else:
		# spawned well off-screen so its amber cache can sit before it unseen
		var x := view_width() + 720.0
		var y := terrain.flat_y(x - 300.0, x + 260.0)
		if y < 0.0:
			_next_gap = 60.0
			return true
		_ground = y
		forced_gate = ""
		var o := boulder_wall(x) if k == "gate_tri" else bramble_wall(x)
		o.gate_form = Progression.GATE_FORM[k]
		_gate_extras(k, x - o.size.x * 0.5, x)
		var gap_t := randf_range(Tuning.GAP_EARLY.x, Tuning.GAP_EARLY.y)
		_next_gap = (x - view_width() - 150.0) + o.size.x + gap_t * spd
	gate_counts[k] = gate_counts.get(k, 0) + 1
	_zone_gate_counts[k] = _zone_gate_counts.get(k, 0) + 1
	next_gate_m = metres + randf_range(Progression.GATE_SPACING_M.x, Progression.GATE_SPACING_M.y)
	return not as_terrain


## An egg at running height early in every run, so the speed boost is
## discovered straight away (with a "NEW" banner the first time).
func _spawn_starter_egg() -> void:
	var x := view_width() + 120.0
	var gy := terrain.height_at(x)
	if gy >= Terrain.PIT:
		return   # over a pit: try again next frame
	starter_egg = false
	_pickup("egg", Vector2(x, gy - 85.0))
	introduced.emit("egg")


## A dino was just unlocked: make its gate the very next hazard. Hazards
## already spawned but still off-screen are cleared, and regular spawns pause
## until Rok is past the gate.
func force_gate(k: String) -> void:
	forced_gate = k
	holding = true
	_hold_marker = null
	var edge := view_width()
	for arr in [obstacles, platforms, pickups]:
		for i in range(arr.size() - 1, -1, -1):
			var n: Node2D = arr[i]
			var half: float = n.size.x * 0.5 if n is Obstacle else (n.width * 0.5 if n is FloatingPlatform else 0.0)
			if n.position.x - half > edge:
				n.queue_free()
				arr.remove_at(i)
	_next_gap = 0.0


## Called by Terrain when it has built a canyon / crumbling-bridge gate.
func terrain_gate(k: String, world_x0: float, world_x1: float) -> void:
	_gate_extras(k, world_x0, world_x0 + 70.0)   # icon right where the gap starts


## Banner on first meeting, a guaranteed amber cache before it, and the
## floating icon of the dino that gets through.
func _gate_extras(k: String, start_x: float, icon_x: float) -> void:
	if gate_counts.get(k, 0) <= 1:
		introduced.emit(Terrain.gate_variant(k, zone_at_x(start_x).id))
	_amber_cache(start_x)
	var m := _marker(Progression.GATE_FORM[k], start_x, icon_x)
	if holding and _hold_marker == null:
		_hold_marker = m


## Called by Terrain when it has built deep quicksand (after the Raptor's
## unlock): like a gate, an amber cache before it (so there's energy to
## become the Raptor) and a floating Raptor marker, which also makes the
## Raptor's button glow (main._glow_hint). Marked "sand", so it doesn't count
## as a dino gate for badges.
func deep_sand(world_x0: float, _world_x1: float) -> void:
	_amber_cache(world_x0)
	var m := _marker(Forms.RAPTOR, world_x0, world_x0 + 70.0)
	m.set_meta("sand", true)


## 4 amber on the ground, ending a little before start_x.
func _amber_cache(start_x: float) -> void:
	for i in 4:
		var px := start_x - 620.0 + i * 85.0
		var gy := terrain.height_at(px)
		if gy < Terrain.PIT:
			_pickup("amber", Vector2(px, gy - 55.0))


## The floating icon of the dino that gets through what starts at start_x.
func _marker(f: int, start_x: float, icon_x: float) -> Node2D:
	var m := Node2D.new()
	m.position = Vector2(icon_x, 150.0)
	m.set_meta("form", f)
	m.set_meta("gate_dx", start_x - icon_x)   # gate start relative to the (scrolling) icon
	var ring := Polygon2D.new()
	var pts := PackedVector2Array()
	for i in 24:
		pts.append(Vector2.from_angle(TAU * i / 24.0) * 40.0)
	ring.polygon = pts
	ring.color = Color(1.0, 0.95, 0.82, 0.95)
	m.add_child(ring)
	var edge := Line2D.new()
	pts.append(pts[0])
	edge.points = pts
	edge.width = 5.0
	edge.default_color = Forms.get_data(f).color.darkened(0.2)
	m.add_child(edge)
	var arrow := Polygon2D.new()
	arrow.polygon = PackedVector2Array([Vector2(-12, 40), Vector2(12, 40), Vector2(0, 58)])
	arrow.color = edge.default_color
	m.add_child(arrow)
	var pic := Sprite2D.new()
	pic.texture = SpriteLib.tex("res://assets/portraits/%s.png" % Forms.get_data(f).id)
	var sz := pic.texture.get_size()
	pic.scale = Vector2.ONE * (58.0 / maxf(sz.x, sz.y))
	m.add_child(pic)
	m.z_index = 50
	add_child(m)
	markers.append(m)
	var t := m.create_tween().set_loops()
	t.tween_property(pic, "position:y", -5.0, 0.5).set_trans(Tween.TRANS_SINE)
	t.tween_property(pic, "position:y", 0.0, 0.5).set_trans(Tween.TRANS_SINE)
	return m


## World x where the gate behind marker m begins (markers scroll with the world).
static func gate_x0(m: Node2D) -> float:
	return m.position.x + float(m.get_meta("gate_dx"))


## The Triceratops gate: a barricade stacked past the top of the screen, in
## the zone's look (logs, cracked sandstone, basalt). It shatters with its
## break animation when charged.
func boulder_wall(x: float) -> Obstacle:
	var anim: String = {"forest": "forest_log_break", "desert": "desert_wall_break",
			"volcanic": "volcanic_wall_break"}[zone_at_x(x).id]
	var o := Obstacle.new().setup_anim_stack(anim, 1.3, _ground + 60.0)
	o.position = Vector2(x, _ground + 6.0)
	add_child(o)
	obstacles.append(o)
	return o


## Cracked stone blocks stacked past the top of the screen (kept for reference).
func stone_wall(x: float) -> Obstacle:
	var parts := []
	var h := 0.0
	while h < _ground + 60.0:
		parts.append(["Tile-3_09", "Tile-3_10"].pick_random())
		h += 58.0 * 1.7 - 17.0
	var o := _obstacle("rock", parts, 1.7, x)
	o.shrink = Vector2(0.86, 1.0)
	return o


## Thorns stacked past the top of the screen: Spinosaurus only.
func bramble_wall(x: float) -> Obstacle:
	var layers := int(ceil((_ground + 60.0) / (96.0 * 1.4 * 0.62))) + 1
	var o := Obstacle.new().setup_thorns(layers, 1.4)
	o.shrink = Vector2(0.8, 1.0)
	o.position = Vector2(x, _ground + 6.0)
	add_child(o)
	obstacles.append(o)
	return o


func steam_vent(x: float) -> Obstacle:
	var o := Obstacle.new().setup_steam(1.2)
	o.position = Vector2(x, _ground + 6.0)
	add_child(o)
	obstacles.append(o)
	return o


func rolling_boulder(x: float) -> Obstacle:
	var o := Obstacle.new().setup_rolling(0.78)
	o.position = Vector2(x, _ground + 6.0)
	add_child(o)
	obstacles.append(o)
	return o


## A thorn bush (dry tumble-thorns in the Desert). Nothing grows in the
## Volcanic Badlands, so a basalt rock takes its place there.
func thorn_bush(x: float) -> Obstacle:
	var zid := _zid(x)
	if zid == "volcanic":
		return small(x)
	var o := Obstacle.new().setup_thorns(1, 1.05)
	o.position = Vector2(x, _ground + 6.0)
	add_child(o)
	obstacles.append(o)
	return _tinted(o, THORN_TINT, zid)


# ---------------------------------------------------------------- choosing

const COMBO_PARTS := ["small", "thorn_bush", "log", "boulder", "fence"]
const HARD_PARTS := ["small", "thorn_bush", "log", "boulder", "fence", "wall", "tall_fence"]


## Next pattern: a newly available hazard is shown on its own first
## (INTRO_SOLO_SPAWNS times); otherwise a weighted pick of what the player
## has met, with combos once familiar hazards exist.
func _next_key() -> String:
	var zid: String = zone_at_x(view_width() + 150.0).id
	var keys := (Progression.PATTERN_KEYS + ["combo", "hard_combo"]).filter(
			func(k): return Progression.ZONE_ONLY.get(k, zid) == zid)
	# a zone's own hazards go first while you're in that zone (they can't be
	# taught anywhere else), then everything else in lesson order
	keys.sort_custom(func(a, b):
		var za := Progression.ZONE_ONLY.has(a)
		var zb := Progression.ZONE_ONLY.has(b)
		if za != zb:
			return za
		return Progression.intro_m(a) < Progression.intro_m(b))
	var may := func(k: String) -> bool:
		if _no_room.get(k, -INF) > metres:
			return false   # found no room for it just now
		# first meeting this run must wait for marination (if it's still new)
		return intro_counts.get(k, 0) > 0 or introduce_ok.is_null() or introduce_ok.call(k)
	# the diving flyers' lesson: the next swoopers come (and dive)
	if intro_counts.get("diver", 0) < Progression.INTRO_SOLO_SPAWNS and intro_counts.get("swooper", 0) > 0 and _diver_due():
		return "swooper"
	for k in keys:
		if not Progression.available(k, metres) or not may.call(k):
			continue
		if k == "combo" or k == "hard_combo":
			# combos take their turn in the lesson order: the first one comes
			# as soon as it's due, then they join the mix below
			var parts: Array = COMBO_PARTS if k == "combo" else HARD_PARTS
			if intro_counts.get(k, 0) == 0 and not _familiar_parts(parts).is_empty():
				return k
		elif intro_counts.get(k, 0) < Progression.INTRO_SOLO_SPAWNS:
			return k
	var pool := []
	var weights := []
	for k in Progression.PATTERN_KEYS:
		if Progression.available(k, metres) and Progression.ZONE_ONLY.get(k, zid) == zid and may.call(k):
			pool.append(k)
			# recently met hazards come up a bit more, for practice
			var w := 1.0 if Progression.familiar(k, metres) else 1.6
			if k == "stampede" or k == "swooper":
				w *= Tuning.CRITTER_WEIGHT   # wild dinosaurs come round often (the user's call)
			weights.append(w)
	if Progression.available("combo", metres) and _familiar_parts(COMBO_PARTS).size() >= 1 and may.call("combo"):
		pool.append("combo")
		weights.append(1.0 + difficulty)
	if Progression.available("hard_combo", metres) and may.call("hard_combo"):
		pool.append("hard_combo")
		weights.append(0.6 + difficulty)
	if pool.is_empty():
		return "small"   # everything else is waiting for room
	var total := 0.0
	for w in weights:
		total += w
	var r := randf() * total
	for i in pool.size():
		r -= weights[i]
		if r <= 0.0:
			return pool[i]
	return pool[-1]


## The early wild-dinosaur preview (main._preview_step): one of the zone's
## stampede species, slowed by speed_mult, on flat ground just off-screen.
## Returns it, or null if the ground ahead isn't flat yet.
func wild_preview(speed_mult: float) -> Obstacle:
	var x := view_width() + 150.0
	var y := terrain.flat_y(x - 60.0, x + 460.0)
	if y < 0.0:
		return null
	_ground = y
	var c := Obstacle.new().setup_critter(Critters.for_zone(_zid(x), "stampede"))
	c.roll_speed *= speed_mult
	c.position.x = x + 300.0
	add_child(c)
	c.place_critter(_ground)
	obstacles.append(c)
	c.set_meta("preview", true)
	_next_gap = maxf(_next_gap, c.size.x + 300.0 + Tuning.GAP_EARLY.y * speed)   # nothing on top of it
	return c


## Should this swooper be a diving flyer? Its lesson (the first
## INTRO_SOLO_SPAWNS once "diver" is due and may be introduced) always dives;
## after that Tuning.DIVE_CHANCE.
func _wants_dive() -> bool:
	if not _diver_due():
		return false
	if intro_counts.get("diver", 0) < Progression.INTRO_SOLO_SPAWNS:
		return true
	return randf() < Tuning.DIVE_CHANCE


func _diver_due() -> bool:
	if not Progression.available("diver", metres) or not Progression.available("swooper", metres):
		return false
	return intro_counts.get("diver", 0) > 0 or introduce_ok.is_null() or introduce_ok.call("diver")


func _familiar_parts(parts: Array) -> Array:
	return parts.filter(func(k): return Progression.familiar(k, metres))


## Room needed after the spawn point (for the flat-ground check).
func _pattern_length(key: String) -> float:
	match key:
		"combo", "hard_combo":
			# the first two parts must share one flat; a third is only
			# added where the ground allows (see _chain)
			return _combo_spacing() + 300.0
		"ledge":
			return 640.0
	return 560.0


## Space between hazards in a combo: enough time to land and jump again.
func _combo_spacing() -> float:
	return maxf(300.0, speed * lerpf(0.95, 0.75, difficulty))


func _spawn_key(key: String, x: float) -> float:
	match key:
		"small":
			return small(x).size.x
		"thorn_bush":
			return thorn_bush(x).size.x
		"steam":
			# a pair of vents with different timing
			steam_vent(x)
			return steam_vent(x + randf_range(260.0, 360.0)).position.x - x
		"rolling_boulder":
			return rolling_boulder(x + 280.0).size.x + 280.0
		"stampede", "swooper":
			# a wild dinosaur of this zone, a little further out: it closes in fast
			var id := Critters.for_zone(_zid(x), key)
			var c := Obstacle.new().setup_critter(id)
			c.position.x = x + 300.0
			add_child(c)
			c.place_critter(_ground)
			if key == "swooper" and _wants_dive():
				if intro_counts.get("diver", 0) == 0:
					introduced.emit("diver")
				intro_counts["diver"] = intro_counts.get("diver", 0) + 1
				c.make_diver()
			obstacles.append(c)
			return c.size.x + 300.0
		"log":
			return log_(x).size.x
		"boulder":
			return boulder(x).size.x
		"fence":
			return fence(x, false).size.x
		"tall_fence":
			return fence(x, true).size.x
		"wall":
			return rock_wall(x, 2 if randf() > difficulty * 0.6 else 3).size.x
		"ledge":
			# slide under (amber beneath rewards it) or hop on top; pushed out
			# so there is run-up time after the previous hazard
			var lx := x + 220.0
			var l := ledge(lx)
			var n := mini(_spot_count(), 3)
			for i in n:
				_pickup("amber", Vector2(lx + (i - (n - 1) * 0.5) * 90.0, _ground - 48.0))
			return l.size.x + 220.0
		"combo":
			return _chain(x, _familiar_parts(COMBO_PARTS), 2)
		"hard_combo":
			var parts := _familiar_parts(HARD_PARTS)
			return _chain(x, parts, 3 if randf() < 0.5 else 2)
	return small(x).size.x


func _chain(x: float, parts: Array, n: int) -> float:
	if parts.is_empty():
		parts = ["small"]
	var cx := x
	var last: Obstacle
	for i in n:
		if i >= 2 and terrain != null and terrain.flat_y(cx - 200.0, cx + 300.0) != _ground:
			break   # no flat ground for another part: keep the combo short
		last = _spawn_single(parts.pick_random(), cx)
		cx += _combo_spacing()
	return last.position.x - x + last.size.x * 0.5


func _spawn_single(k: String, x: float) -> Obstacle:
	match k:
		"thorn_bush":
			return thorn_bush(x)
		"log":
			return log_(x)
		"boulder":
			return boulder(x)
		"fence":
			return fence(x, false)
		"tall_fence":
			return fence(x, true)
		"wall":
			return rock_wall(x, 2)
	return small(x)


## Pickups that reward the pattern just spawned. Floating islands only go
## over simple single hazards, never next to a ledge, wall, gate or combo,
## and separate island groups keep PLATFORM_GROUP_GAP apart.
func _rewards(x: float, used: float, key := "small") -> void:
	_spot_x = x
	var islands_ok: bool = key in ["small", "thorn_bush", "log", "boulder", "fence"] \
			and x - 200.0 > _last_platform_end + PLATFORM_GROUP_GAP
	if Progression.available("sky_trail", metres) and randf() < float(Loot.num("placement", "sky_trail")):
		# a high wavy trail, easiest to reach flying (a power spot is just the
		# power-up at its far end)
		var kind := _spot_kind()
		var n := 7 if _single(kind) else 3 + _spot_count()   # 4-7 along the trail
		for i in 7:
			if i < 7 - n and not _single(kind):
				continue   # a shorter trail: keep its far end
			var t := float(i) / 6.0
			_pickup(_fill(kind, i == 6), Vector2(x - 120.0 + i * 95.0, _ground - float(Loot.num("placement", "trail_height")) - sin(t * TAU) * 45.0))
	elif islands_ok and randf() < float(Loot.num("placement", "islands")):
		var kind := _spot_kind()
		if randf() < float(Loot.num("placement", "staircase")) and metres > float(Loot.num("placement", "staircase_from_m")):
			# a staircase of floating islands, the prize on the highest step
			var steps := 2 + randi() % 2
			var down := randf() < 0.35
			for i in steps:
				var top := (i == 0) if down else (i == steps - 1)
				var lift: float = 150.0 + (steps - 1 - i if down else i) * 75.0
				var p := _platform(x - 60.0 + i * 240.0, _ground - lift)
				_pickup(_fill(kind, top), Vector2(p.position.x, p.position.y - 45.0))
				_last_platform_end = p.position.x + p.width * 0.5
		else:
			var py := _ground - randf_range(float(Loot.num("placement", "island_min_lift")), float(Loot.num("placement", "island_max_lift")))
			var p := _platform(x + used * 0.5 + 40.0, py)
			_last_platform_end = p.position.x + p.width * 0.5
			var n := 1 if _single(kind) else mini(_spot_count(), int(Loot.num("counts", "island_max")))
			for i in n:
				_pickup(_fill(kind, true), Vector2(p.position.x + (i - (n - 1) * 0.5) * 70.0, py - 45.0))
	elif randf() < float(Loot.num("placement", "arc")):
		# an arc over the obstacle rewards the jump
		var kind := _spot_kind()
		var n := 1 if _single(kind) else _spot_count()
		for i in n:
			var t := 0.5 if n == 1 else float(i) / float(n - 1)
			_pickup(_fill(kind, true), Vector2(x - 90.0 + t * 180.0, _ground - float(Loot.num("placement", "arc_height")) - sin(t * PI) * 60.0))
