class_name Terrain
extends Node2D
## Scrolling ground built from the Terrain Tiles pack: flat runs of grass-top
## blocks at three levels, slope pieces (Terrain-variation_01/02) between
## levels, the curved step tile (Terrain-tiles_10) for drops, rounded end caps
## (tiles 01/04) at pit edges, and the seamless dirt texture underneath.
##
## The game keeps two lists in local coordinates (the node scrolls left):
##  * segs: physics segments {x0, x1, y0, y1, pit} — y is the feet line.
##  * features: what was generated (flat / slope_up / slope_down / drop / pit).
##    A feature's sprites are built once the next feature is known, so flats
##    know whether they need an end cap beside a pit.

const BOTTOM := 760.0
const PIT := 100000.0             # height_at() inside a pit
const OUTLINE := Color(0.24, 0.12, 0.05)

var segs: Array[Dictionary] = []
var features: Array[Dictionary] = []   # {type, x0, x1, level, built, nodes}
var end_x := 0.0
## Ground is generated at least this far past the screen edge (px), so
## combos spawned just off-screen can find flat ground for their parts.
const LOOK_AHEAD := 1400.0
var level := 0
var difficulty := 0.0             # Progression.pressure
var metres := 0.0                 # set by main; gates which features appear
signal introduced(key: String)
signal gate_built(key: String, world_x0: float, world_x1: float)
signal deep_sand_built(world_x0: float, world_x1: float)   # Course adds amber + a Raptor marker
var _seen := {}
var speed := Tuning.START_SPEED   # set by main; sizes the gate canyons
var runner_ready := false   # set by main: the Raptor's button is unlocked (deep quicksand)
var calm := false           # a bonus zone: only flat ground is generated (main)
var pending_gate := ""            # requested by Course
var introduce_ok: Callable        # main: may a not-yet-taught feature appear now?
## Log bridges over pits: {x0, x1, y, sturdy, node, collapsed}. Crumbling
## (twig) bridges give way under heavy forms; sturdy ones hold anyone.
var bridges: Array[Dictionary] = []
var meta := {}
var tex := {}
var step := 47.0
var plants: Node2D

const PLANTS := ["Grasses_01", "Grasses_02", "Grasses_03", "Grasses_04",
		"Grasses_05", "Grasses_10", "Grasses_12", "Grasses_13", "Grasses_14"]


func _ready() -> void:
	meta = JSON.parse_string(FileAccess.open("res://assets/terrain/terrain.json", FileAccess.READ).get_as_text())
	for n in ["mid_a", "mid_b", "cap_left", "cap_right", "slope_up", "slope_down", "drop", "dirt",
			"desert_ground", "canyon_ground", "volcanic_ground", "forest_ground"]:
		var path := "res://assets/terrain/%s.png" % n
		if ResourceLoader.exists(path):
			tex[n] = SpriteLib.tex(path)   # the seamless pack, drawn from its sharp @2x twin
	step = meta.level_step
	reset()


func reset() -> void:
	for c in get_children():
		c.queue_free()
	segs.clear()
	features.clear()
	bridges.clear()
	pending_gate = ""
	calm = false
	_seen.clear()
	metres = 0.0
	position.x = 0.0
	end_x = -300.0
	level = 0
	plants = Node2D.new()
	add_child(plants)
	_flat(1500.0)  # safe start
	_generate()


## Feet line of a level.
func level_y(l: int) -> float:
	return Tuning.GROUND_Y - l * step


## Grass-tip line of a level (where tile tops are aligned).
func grass_y(l: int) -> float:
	return level_y(l) - Tuning.FEET_BELOW_GRASS


func view_width() -> float:
	return maxf(get_viewport_rect().size.x, Tuning.VIEW_W)


func scroll(dx: float) -> void:
	position.x -= dx
	# keep the *second-to-last* feature past the right edge so every visible
	# feature has a known neighbour and can be built
	while features.size() < 2 or features[-2].x1 + position.x < view_width() + LOOK_AHEAD:
		_generate()
	var built := false
	for i in features.size() - 1:
		if not features[i].built:
			_build(i)
			built = true
	if built:
		move_child(plants, -1)   # grass tufts in front of the tiles
	while features.size() > 0 and features[0].x1 + position.x < -400.0:
		for n in features.pop_front().nodes:
			n.queue_free()
	while segs.size() > 0 and segs[0].x1 + position.x < -400.0:
		segs.pop_front()
	while bridges.size() > 0 and bridges[0].x1 + position.x < -400.0:
		bridges.pop_front()
	for p in plants.get_children():
		if p.position.x + position.x < -300.0:
			p.queue_free()


# ------------------------------------------------------------ queries (world x)

func height_at(world_x: float) -> float:
	var lx := world_x - position.x
	for s in segs:
		if lx >= s.x0 and lx < s.x1:
			if s.pit:
				return PIT
			var t: float = (lx - s.x0) / (s.x1 - s.x0)
			return lerpf(s.y0, s.y1, t)
	return Tuning.GROUND_Y


## Ground gradient dy/dx at world x: negative uphill, positive downhill.
func slope_at(world_x: float) -> float:
	var lx := world_x - position.x
	for s in segs:
		if lx >= s.x0 and lx < s.x1:
			return 0.0 if s.pit else (s.y1 - s.y0) / (s.x1 - s.x0)
	return 0.0


## Returns the shared surface y if [x0, x1] is one flat, solid run, else -1.
func flat_y(world_x0: float, world_x1: float) -> float:
	var a := world_x0 - position.x
	var b := world_x1 - position.x
	if b > end_x:
		return -1.0
	var y := -1.0
	for s in segs:
		if s.x1 <= a or s.x0 >= b:
			continue
		if s.pit or s.get("soft", false) or s.y0 != s.y1 or (y >= 0.0 and s.y0 != y):
			return -1.0
		y = s.y0
	return y


## World-x range of the next pit at or ahead of world_x, or Vector2(-1, -1).
func next_pit(world_x: float) -> Vector2:
	var lx := world_x - position.x
	for s in segs:
		if s.pit and s.x1 > lx:
			return Vector2(s.x0 + position.x, s.x1 + position.x)
	return Vector2(-1, -1)


# ------------------------------------------------------------ generation

## Course asks for a canyon / bridge gate. The unseen ground generated ahead
## is trimmed so the gate starts just off-screen (far enough that its amber
## cache, placed before it, also spawns unseen) instead of seconds later.
## Zone-specific name of a gate (for its banner / Field Guide entry).
static func gate_variant(k: String, zid: String) -> String:
	if k == "gate_ptera" and zid == "volcanic":
		return "gate_lava"
	if k == "gate_spino" and zid == "forest":
		return "gate_water"
	return k


func request_gate(k: String) -> void:
	pending_gate = k
	_trim_after(view_width() + 720.0 - position.x)
	_generate()        # builds the gate now


## A bonus zone is coming: drop the ground generated past world x (nobody has
## seen it) and only build flat ground until `calm` is lifted.
func calm_from(world_x: float) -> void:
	calm = true
	_trim_after(maxf(world_x, view_width() + 40.0) - position.x)


## Drop (or shorten) generated ground past local x `cut`, ending on flat
## ground so whatever comes next starts cleanly.
func _trim_after(cut: float) -> void:
	while features.size() > 1 and features[-1].x0 > cut:
		_drop_last_feature()   # starts off-screen, so nobody has seen it
	var f: Dictionary = features[-1]
	if f.type == "flat" and f.x1 > cut:
		f.x1 = maxf(cut, f.x0 + 120.0)
		segs[-1].x1 = f.x1
		end_x = f.x1
		for p in plants.get_children():
			if p.position.x > f.x1 - 40.0:
				p.queue_free()
		if f.built:   # redraw the shortened flat (its visible part looks the same)
			for n in f.nodes:
				n.queue_free()
			f.nodes.clear()
			f.built = false
			f.keep_plants = true
	var last: Dictionary = features[-1]
	level = last.get("to_level", last.level)
	if last.type != "flat":
		_flat(160.0)   # a short run-up after a slope or pit


func _drop_last_feature() -> void:
	var f: Dictionary = features.pop_back()
	while segs.size() > 0 and segs[-1].x0 >= f.x0 - 0.01:
		segs.pop_back()
	while bridges.size() > 0 and bridges[-1].x0 >= f.x0 - 0.01:
		bridges.pop_back()
	for n in f.nodes:
		n.queue_free()
	end_x = f.x0
	if features.size() > 0:
		level = features[-1].get("to_level", features[-1].level)
	for p in plants.get_children():
		if p.position.x > f.x0:
			p.queue_free()


## Gate canyons must be wider than any jump at the current speed
## (Rok's double jump is ~1.25 s of air time).
func gate_width() -> float:
	return maxf(720.0, speed * 1.6 + 160.0)


func _generate() -> void:
	if calm and pending_gate == "":
		_flat(randf_range(Tuning.FLAT_MIN, Tuning.FLAT_MAX))
		return
	var r := randf()
	var ok := func(k: String) -> bool:
		return Progression.available(k, metres) and (_seen.has(k) or introduce_ok.is_null() or introduce_ok.call(k))
	var z := gen_zone()
	var hill_chance: float = Tuning.HILL_CHANCE * z.hill
	# a terrain lesson that is due gets built at the first chance, so it
	# lands on schedule instead of waiting on a random roll
	var due := ""
	for k in ["pit", "quicksand", "large_hill"]:
		if not _seen.has(k) and ok.call(k) and (k != "quicksand" or z.id == "desert") \
				and (k != "large_hill" or level == 0):
			due = k
			break
	if pending_gate != "":
		var k := pending_gate
		pending_gate = ""
		var zid: String = gen_zone().id
		var liquid := ""
		if k == "gate_ptera" and zid == "volcanic":
			liquid = "lava"
		elif k == "gate_spino":
			liquid = "water"
		_note(gate_variant(k, zid))
		var f := _pit(gate_width(), liquid)
		if k == "gate_raptor":
			_bridge(f, false)
		gate_built.emit(k, f.x0 + position.x, f.x1 + position.x)
	elif due == "pit" or (due == "" and ok.call("pit") and randf() < (Tuning.PIT_CHANCE + 0.2 * difficulty) * z.pit):
		_note("pit")
		var pf := _pit(randf_range(Tuning.PIT_MIN, lerpf(Tuning.PIT_MIN + 30.0, Tuning.PIT_MAX, difficulty)))
		if ok.call("bridge") and randf() < 0.3:
			_note("bridge")
			_bridge(pf, true)   # sturdy: holds anyone (no transform needed)
	elif due == "quicksand" or (due == "" and ok.call("quicksand") and z.id == "desert" and randf() < Tuning.QUICKSAND_CHANCE):
		_note("quicksand")
		_quicksand(quicksand_width(randf_range(Tuning.QUICKSAND_MIN, Tuning.QUICKSAND_MAX)))
	elif due == "large_hill" or (due == "" and ok.call("large_hill") and level == 0 and randf() < Tuning.LARGE_HILL_CHANCE * z.big_hill):
		_note("large_hill")
		_large_hill()
	elif ok.call("hill") and r < hill_chance and level < 2:
		_hill()
		if ok.call("slope") and randf() < 0.3 and level < 2:
			_flat(randf_range(120.0, 260.0))
			_hill()   # rolling double bump
	elif ok.call("slope") and r < hill_chance + 0.25 and level < 2:
		_slope_up()
	elif ok.call("slope") and r < hill_chance + 0.55 and level > 0:
		if ok.call("drop") and randf() < 0.5 * z.drop:
			_drop()
		else:
			_slope_down()
	_flat(randf_range(Tuning.FLAT_MIN, Tuning.FLAT_MAX))


func _note(key: String) -> void:
	if not _seen.has(key):
		_seen[key] = true
		introduced.emit(key)


## Zone of the ground being generated now (it is generated ahead of Rok).
func gen_zone() -> Dictionary:
	return Zones.zone_at(metres + (end_x + position.x - Tuning.PLAYER_X) / Tuning.PX_PER_M)


func _feature(type: String, length: float, lvl: int) -> Dictionary:
	var f := {"type": type, "x0": end_x, "x1": end_x + length, "level": lvl,
			"built": false, "nodes": [], "style": gen_zone().ground}
	features.append(f)
	end_x += length
	return f


func _seg(x0: float, x1: float, y0: float, y1: float, pit := false, soft := false) -> void:
	segs.append({"x0": x0, "x1": x1, "y0": y0, "y1": y1, "pit": pit, "soft": soft})


func _flat(length: float) -> void:
	var f := _feature("flat", length, level)
	_seg(f.x0, f.x1, level_y(level), level_y(level))


## A small hill: slope up, a short top of 1-3 blocks, slope back down.
func _hill() -> void:
	_slope_up()
	_flat(float(Tuning.HILL_TOP_TILES_MIN + randi() % (Tuning.HILL_TOP_TILES_MAX - Tuning.HILL_TOP_TILES_MIN + 1)) * (tex.mid_a.get_width() - 2.0))
	_slope_down()


## A big hill: three climbs with short ledges between, a plateau, then a long
## descent back down, made for sliding. Goes above the usual top level.
func _large_hill() -> void:
	var start := level
	for i in Tuning.LARGE_HILL_STEPS:
		_slope_up()
		if i < Tuning.LARGE_HILL_STEPS - 1:
			_flat(randf_range(70.0, 130.0))
	_flat(randf_range(240.0, 420.0))
	while level > start:
		_slope_down()
		if level > start:
			_flat(randf_range(30.0, 60.0))


func _slope_up() -> void:
	_profile_feature("slope_up", level, level + 1)
	level += 1


func _slope_down() -> void:
	_profile_feature("slope_down", level, level - 1)
	level -= 1


func _drop() -> void:
	_profile_feature("drop", level, level - 1)
	level -= 1


## Physics for a slope/step piece follows its drawn grass line (from the
## pipeline's profile), with the ends pinned to the two level lines.
func _profile_feature(type: String, from_level: int, to_level: int) -> void:
	var m: Dictionary = meta[type]
	var w: float = m.size[0]
	var f := _feature(type, w, from_level)
	f.to_level = to_level
	var top := _piece_top(type, from_level, to_level)
	var prof: Array = m.profile
	var pts: Array[Vector2] = []
	for i in prof.size():
		var y: float = top + prof[i][1] + Tuning.FEET_BELOW_GRASS
		pts.append(Vector2(f.x0 + prof[i][0], y))
	pts[0].y = level_y(from_level)
	pts[-1] = Vector2(f.x1, level_y(to_level))
	# keep it monotonic so small grass bumps don't make Rok hop
	for i in range(1, pts.size()):
		if to_level > from_level:
			pts[i].y = minf(pts[i].y, pts[i - 1].y)
		else:
			pts[i].y = maxf(pts[i].y, pts[i - 1].y)
	for i in range(1, pts.size()):
		if pts[i].x > pts[i - 1].x:
			_seg(pts[i - 1].x, pts[i].x, pts[i - 1].y, pts[i].y)


## y of a slope/step piece's top edge so its ends meet the level grass lines.
func _piece_top(type: String, from_level: int, to_level: int) -> float:
	var m: Dictionary = meta[type]
	if type == "slope_up":
		return grass_y(to_level) - m.right   # the high (right) end anchors it
	return grass_y(from_level) - m.left      # slope_down / drop: high (left) end


func _pit(width: float, liquid := "") -> Dictionary:
	var f := _feature("pit", width, level)
	f.liquid = liquid
	_seg(f.x0, f.x1, level_y(level), level_y(level), true)
	return f


## How wide a quicksand patch is at the current speed. Before the Raptor is
## unlocked Rok must always be able to clear it in one bound. After, it grows
## with the speed past Rok's longest bound plus the one weak hop he gets after
## landing in it (QUICKSAND_GRIP), so only a stronger jumper (the Raptor, who
## also barely sinks) or a flyer gets across.
func quicksand_width(base: float) -> float:
	var rok := Forms.get_data(Forms.ROK)
	var bound := speed * Forms.air_time(rok)
	if not runner_ready:
		return minf(base, bound * Tuning.QUICKSAND_SAFE)
	var hop := speed * Forms.air_time(rok, Tuning.QUICKSAND_GRIP)
	return maxf(base, (bound + hop) * Tuning.QUICKSAND_DEEP)


## Is the quicksand at world x the deep kind (built after the Raptor unlocked)?
func deep_sand_at(world_x: float) -> bool:
	var lx := world_x - position.x
	for f in features:
		if lx >= f.x0 and lx < f.x1:
			return f.get("liquid", "") == "quicksand" and f.get("deep", false)
	return false


## The next quicksand patch ahead of (or under) world x, as Vector2(start, end)
## in world x, or Vector2(-1, -1).
func next_quicksand(world_x: float) -> Vector2:
	for f in features:
		if f.get("liquid", "") == "quicksand" and f.x1 + position.x > world_x:
			return Vector2(f.x0 + position.x, f.x1 + position.x)
	return Vector2(-1.0, -1.0)


## Quicksand: solid ground that swallows whoever lingers on it (desert).
func _quicksand(width: float) -> Dictionary:
	var f := _feature("flat", width, level)
	f.liquid = "quicksand"
	f.deep = runner_ready   # deep sand plunges and grips (main._check_quicksand)
	if f.deep:
		deep_sand_built.emit(f.x0 + position.x, f.x1 + position.x)
	_seg(f.x0, f.x1, level_y(level), level_y(level), false, true)
	return f


const LIQUID_ART := {"water": "forest_water", "lava": "volcanic_lava", "quicksand": "desert_quicksand"}
const LIQUID_DROP := {"water": 26.0, "lava": 30.0, "quicksand": 6.0}   # surface below the feet line


## Liquid at world x: "water", "lava", "quicksand" or "".
func liquid_at(world_x: float) -> String:
	var lx := world_x - position.x
	for f in features:
		if lx >= f.x0 and lx < f.x1:
			return f.get("liquid", "")
	return ""


## Surface line of the liquid at world x (where a swimmer floats).
func liquid_surface(world_x: float) -> float:
	var lx := world_x - position.x
	for f in features:
		if lx >= f.x0 and lx < f.x1 and f.get("liquid", "") != "":
			return level_y(f.level) + LIQUID_DROP[f.liquid]
	return PIT


## Animated liquid across a feature: left bank, repeated centre, right bank,
## drawn in front of Rok (so a swimmer sits in the water).
func _build_liquid(f: Dictionary) -> void:
	var art: String = LIQUID_ART[f.liquid]
	var m: Dictionary = SpriteLib.trap_meta()[art]
	var surface: float = level_y(f.level) + LIQUID_DROP[f.liquid]
	var node := Node2D.new()
	node.z_index = 1
	add_child(node)
	f.nodes.append(node)
	var lw: float = m.left[0]
	var mw: float = m.mid[0]
	var rw: float = m.right[0]
	var add := func(part: String, x: float, flip: bool) -> void:
		var a := AnimatedSprite2D.new()
		a.sprite_frames = SpriteLib.trap(art, part)
		a.centered = false
		a.offset = Vector2(0, -m.surface_y)
		a.position = Vector2(x, surface)
		a.flip_h = flip
		a.play("a")
		node.add_child(a)
	var x: float = f.x0
	while x < f.x1:
		add.call("mid", x, int(x / mw) % 2 == 1)
		x += mw - 1.0
	add.call("left", f.x0 - lw * 0.6, false)
	add.call("right", f.x1 - rw * 0.4, false)


## A log bridge spanning pit feature f at its ground level.
func _bridge(f: Dictionary, sturdy: bool) -> void:
	var y := level_y(f.level)
	var node := Node2D.new()
	node.z_index = 0
	add_child(node)
	if not sturdy and f.style in ["desert", "canyon"]:
		# a sandstone bridge (desert_bridge_collapse) that crumbles under weight
		var xs: float = f.x0 - 30.0
		var pw: float = SpriteLib.trap_meta().desert_bridge_collapse.frame[0] * 0.92
		while xs < f.x1 + 30.0:
			var a := SpriteLib.trap_sprite("desert_bridge_collapse", false)
			a.position = Vector2(xs + pw * 0.5, y + 4.0)
			node.add_child(a)
			xs += pw - 18.0
		f.nodes.append(node)
		bridges.append({"x0": f.x0, "x1": f.x1, "y": y, "sturdy": false, "node": node, "collapsed": false})
		return
	if sturdy and f.style == "canyon" and ResourceLoader.exists(CANYON % "rope_bridge"):
		# the canyon's rope bridge, stretched across the gap, its planks on the ground line
		var rb := Sprite2D.new()
		rb.texture = SpriteLib.tex(CANYON % "rope_bridge")
		rb.centered = false
		var k: float = (f.x1 - f.x0 + 40.0) / rb.texture.get_width()
		rb.scale = Vector2(k, minf(k, 1.0))
		rb.position = Vector2(f.x0 - 20.0, y - float(canyon_meta().bridge.surface) * rb.scale.y + 6.0)
		node.add_child(rb)
		f.nodes.append(node)
		bridges.append({"x0": f.x0, "x1": f.x1, "y": y, "sturdy": true, "node": node, "collapsed": false})
		return
	var x: float = f.x0 - 14.0
	while x < f.x1 + 14.0:
		var s := Sprite2D.new()
		if sturdy:
			s.texture = SpriteLib.tex("res://assets/props/%s.png" % ["Logs_03", "Logs_04"].pick_random())
			s.scale = Vector2.ONE * 0.8
		else:
			s.texture = SpriteLib.tex("res://assets/props/Logs_05.png")   # thin twigs
			s.scale = Vector2.ONE * 0.95
			s.rotation = randf_range(-0.12, 0.12)
			s.modulate = Color(0.85, 0.75, 0.62)
		s.centered = false
		var w := s.texture.get_width() * s.scale.x
		s.position = Vector2(x, y - 16.0)
		node.add_child(s)
		x += w - (14.0 if sturdy else 22.0)
	f.nodes.append(node)
	bridges.append({"x0": f.x0, "x1": f.x1, "y": y, "sturdy": sturdy, "node": node, "collapsed": false})


## Bridge under world x (with the walker's half width), or {}.
func bridge_at(world_x: float, half_w: float) -> Dictionary:
	var lx := world_x - position.x
	for b in bridges:
		if not b.collapsed and lx > b.x0 - half_w * 0.4 and lx < b.x1 + half_w * 0.4:
			return b
	return {}


## A heavy foot on a crumbling bridge: it gives way after a short shudder.
func crumble(b: Dictionary) -> void:
	if b.collapsed:
		return
	b.collapsed = true
	var i := 0
	for s in b.node.get_children():
		if s is AnimatedSprite2D:   # sandstone: its own collapse animation
			s.speed_scale = 2.5
			s.frame = 1
			s.play("a")
			continue
		var t: Tween = s.create_tween()
		t.tween_property(s, "position:x", s.position.x + 3.0, 0.04)
		t.tween_property(s, "position:x", s.position.x - 3.0, 0.04)
		t.tween_property(s, "position:y", s.position.y + 420.0, 0.6).set_delay(0.03 * i) \
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		t.parallel().tween_property(s, "rotation", randf_range(-1.2, 1.2), 0.6)
		i += 1


# ------------------------------------------------------------ visuals

func _build(i: int) -> void:
	var f: Dictionary = features[i]
	f.built = true
	var prev_pit: bool = i > 0 and features[i - 1].type == "pit"
	var next_pit: bool = i + 1 < features.size() and features[i + 1].type == "pit"
	if f.get("liquid", "") == "quicksand":
		if f.style == "tiles":
			_build_flat(f, prev_pit, next_pit)
		else:
			_build_strip(f, prev_pit, next_pit)
		_build_liquid(f)
		return
	if f.style != "tiles" and f.type != "pit":
		_build_strip(f, prev_pit, next_pit)
		return
	if f.type == "pit" and f.get("liquid", "") != "":
		_build_liquid(f)
	match f.type:
		"flat":
			_build_flat(f, prev_pit, next_pit)
		"pit":
			var dark := Polygon2D.new()
			var y := grass_y(f.level) + 34.0
			dark.polygon = PackedVector2Array([Vector2(f.x0 - 6, y), Vector2(f.x1 + 6, y),
					Vector2(f.x1 + 6, BOTTOM), Vector2(f.x0 - 6, BOTTOM)])
			dark.color = Color(0.16, 0.08, 0.04)
			add_child(dark)
			move_child(dark, 0)
			f.nodes.append(dark)
		_:
			var top := _piece_top(f.type, f.level, f.to_level)
			var s := _sprite(f.type, Vector2(f.x0, top))
			f.nodes.append(s)
			f.nodes.append(_fill(f.x0, f.x1, top + s.texture.get_height() - 3.0))


## Desert / volcanic ground: the zone's ground texture wrapped over the
## surface as narrow textured quads (so it follows slopes), pit-side edges
## outlined. The grass/crust top sits FEET_BELOW_GRASS above the feet line.
func _build_strip(f: Dictionary, cap_l: bool, cap_r: bool) -> void:
	var t: Texture2D = tex[f.style + "_ground"]
	var poly := Polygon2D.new()
	poly.texture = t
	poly.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	var pts := PackedVector2Array()
	var uvs := PackedVector2Array()
	var quads := []
	var x0: float = f.x0
	var x1: float = f.x1
	var n := maxi(1, int(ceil((x1 - x0) / 16.0)))
	for i in n + 1:
		var x := lerpf(x0, x1, float(i) / n)
		var top := _local_height(clampf(x, x0, x1 - 0.01)) - Tuning.FEET_BELOW_GRASS - 4.0
		pts.append(Vector2(x, top))
		uvs.append(Vector2(x, 0.0))
		pts.append(Vector2(x, BOTTOM))
		uvs.append(Vector2(x, minf(BOTTOM - top, t.get_height() - 1.0)))
	for i in n:
		quads.append(PackedInt32Array([i * 2, i * 2 + 2, i * 2 + 3, i * 2 + 1]))
	poly.polygon = pts
	poly.uv = uvs
	poly.polygons = quads
	add_child(poly)
	f.nodes.append(poly)
	if f.style == "canyon":
		_canyon_dressing(f, cap_l, cap_r, pts[0].y + Tuning.FEET_BELOW_GRASS + 4.0, pts[pts.size() - 2].y + Tuning.FEET_BELOW_GRASS + 4.0)
		return
	if cap_l:
		f.nodes.append(_edge(x0 + 2.0, pts[0].y + 4.0))
	if cap_r:
		f.nodes.append(_edge(x1 - 2.0, pts[pts.size() - 2].y + 4.0))


const CANYON := "res://assets/canyon/%s.png"
const CANYON_DECOR := ["dry_shrub", "stone_scatter", "dry_shrub", "fossil_outcrop"]
static var _canyon_meta := {}


static func canyon_meta() -> Dictionary:
	if _canyon_meta.is_empty() and FileAccess.file_exists("res://assets/canyon/canyon.json"):
		_canyon_meta = JSON.parse_string(FileAccess.get_file_as_string("res://assets/canyon/canyon.json"))
	return _canyon_meta


## The Canyon's ground: the pack's cliff edges where it meets a gap (their
## lip on the ground line) and a few dry shrubs, stones and fossil outcrops
## along the top, behind the runner.
func _canyon_dressing(f: Dictionary, cap_l: bool, cap_r: bool, y_l: float, y_r: float) -> void:
	var m := canyon_meta()
	if m.is_empty():
		return
	for side in [["left", cap_l, f.x0, y_l], ["right", cap_r, f.x1, y_r]]:
		if not side[1]:
			continue
		# a ground's left end drops away to its left: the pack's "left" edge (open drop on the left)
		var s := Sprite2D.new()
		s.texture = SpriteLib.tex(CANYON % ("cliff_" + side[0]))
		s.centered = false
		var piv: Array = m["cliff_" + side[0]]
		s.position = Vector2(float(side[2]) - float(piv[0]), float(side[3]) - float(piv[1]))
		add_child(s)
		f.nodes.append(s)
	var px: float = f.x0 + randf_range(80.0, 260.0)
	while px < f.x1 - 100.0:
		var d := Sprite2D.new()
		d.texture = SpriteLib.tex(CANYON % CANYON_DECOR.pick_random())
		d.centered = false
		d.scale = Vector2.ONE * randf_range(0.55, 0.8)
		var sz := d.texture.get_size() * d.scale
		d.position = Vector2(px - sz.x * 0.5, _local_height(px) - sz.y + 6.0)
		d.modulate = Color(0.92, 0.88, 0.84)
		add_child(d)
		move_child(d, 0)   # behind the ground's edge pieces and the runner
		f.nodes.append(d)
		px += randf_range(260.0, 620.0)


## Feet line at local x (segments only, no pits).
func _local_height(lx: float) -> float:
	for s in segs:
		if lx >= s.x0 and lx < s.x1:
			return lerpf(s.y0, s.y1, (lx - s.x0) / (s.x1 - s.x0))
	return Tuning.GROUND_Y


func _sprite(name: String, pos: Vector2, clip_w := -1.0) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = tex[name]
	s.centered = false
	s.position = pos
	if clip_w > 0.0 and clip_w < s.texture.get_width():
		s.region_enabled = true
		s.region_rect = Rect2(0, 0, clip_w, s.texture.get_height())
	add_child(s)
	return s


## Seamless dirt below the tiles, mapped in terrain space so it is
## continuous across features.
func _fill(x0: float, x1: float, top: float) -> Polygon2D:
	var p := Polygon2D.new()
	p.texture = tex.dirt
	p.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	var pts := PackedVector2Array([Vector2(x0, top), Vector2(x1, top), Vector2(x1, BOTTOM), Vector2(x0, BOTTOM)])
	p.polygon = pts
	p.uv = pts
	add_child(p)
	move_child(p, 0)   # draw order only (a negative z_index would sink it behind the background)
	return p


func _edge(x: float, top: float) -> Line2D:
	var l := Line2D.new()
	l.width = 4.5
	l.default_color = OUTLINE
	l.points = PackedVector2Array([Vector2(x, top), Vector2(x, BOTTOM)])
	add_child(l)
	return l


func _build_flat(f: Dictionary, cap_l: bool, cap_r: bool) -> void:
	var top := grass_y(f.level) - float(meta.mid_a.mid)
	var tile_h: float = tex.mid_a.get_height()
	var x: float = f.x0
	var limit: float = f.x1
	var cap_w: float = tex.cap_right.get_width()
	if cap_r:
		limit -= cap_w - 1.0
	if cap_l:
		f.nodes.append(_sprite("cap_left", Vector2(x, top)))
		x += tex.cap_left.get_width() - 2.0
	var n := 0
	while x < limit - 0.5:
		var name := "mid_a" if (int(f.x0 / 7.0) + n) % 3 != 1 else "mid_b"
		var w: float = tex[name].get_width()
		f.nodes.append(_sprite(name, Vector2(x, top), limit - x))
		x += w - 2.0
		n += 1
	if cap_r:
		f.nodes.append(_sprite("cap_right", Vector2(f.x1 - cap_w, top)))
	# dirt below; pit-side columns get the tile outline continued down
	var fx0: float = f.x0 + (3.0 if cap_l else 0.0)
	var fx1: float = f.x1 - (3.0 if cap_r else 0.0)
	f.nodes.append(_fill(fx0, fx1, top + tile_h - 3.0))
	if cap_l:
		f.nodes.append(_edge(f.x0 + 3.0, top + tile_h - 12.0))
	if cap_r:
		f.nodes.append(_edge(f.x1 - 3.0, top + tile_h - 12.0))
	# wind-animated grass tufts along the top (kept as-is when redrawn)
	if f.get("keep_plants", false):
		return
	var px: float = f.x0 + randf_range(60.0, 200.0)
	while px < f.x1 - 80.0:
		var a := Background.make_wind(PLANTS.pick_random(), randf_range(0.42, 0.55))
		a.position = Vector2(px, level_y(f.level) + randf_range(2.0, 8.0))
		plants.add_child(a)
		px += randf_range(160.0, 400.0)
