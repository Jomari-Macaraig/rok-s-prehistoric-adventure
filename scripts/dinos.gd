class_name Dinos
## The Dinosaur Expansion: 28 creatures sold in the Market (21 dinosaurs and
## 7 pterosaurs), all playable on their category's button. With the playable
## four that's 8 per category (the balanced roster). The first 16 come from
## the Dinosaur Expansion pack, the last 12 from the Balanced 32-Form Pack.
##
## Art and catalogue text come from assets/dinos (tools/prepare_dinos.gd).
## Prices and the best distance that puts each on sale are in
## config/progression.cfg [market] / [market_unlocks]. Owned ones are saved
## (SaveData.load/save_dinos_owned, main.dinos_owned).

const DIR := "res://assets/dinos"

## The four dino roles, one per dino button. Every dinosaur (the four playable
## forms and the 28 expansion ones) belongs to one, so later a button can be
## swapped for another member of its category. Each category leans on one
## attribute: its members score 4-5 there, and it's their best one.
const CATEGORIES := {
	"runner": {"name": "Runner", "form": Forms.RAPTOR, "lean": "speed", "role": "Fast: outruns the T-rex"},
	"smasher": {"name": "Smasher", "form": Forms.TRICERATOPS, "lean": "power", "role": "Strong: smashes rocks and wood"},
	"tank": {"name": "Tank", "form": Forms.SPINOSAURUS, "lean": "armor", "role": "Tough: shrugs off a hit, tramples thorns"},
	"flyer": {"name": "Flyer", "form": Forms.PTERANODON, "lean": "jump", "role": "Airborne: flies over gaps"},
}
## Each category's own badge, earned by playing that category. Market
## dinosaurs come in tiers: Starter (distance only), then Skilled, Expert and
## Legend, which need this badge at Bronze, Silver and Gold (config
## [market_badges]), so playing a category unlocks more of it.
const CATEGORY_BADGE := {"runner": "swift", "smasher": "smasher", "tank": "ironhide", "flyer": "flyer"}
const TIER_NAMES := ["Starter", "Skilled", "Expert", "Legend"]
## Attributes, 1-10. Stamina = energy efficiency (lower drain).
const ATTRS := ["speed", "jump", "stamina", "power", "armor"]
const ATTR_NAMES := {"speed": "Speed", "jump": "Jump", "stamina": "Stamina", "power": "Power", "armor": "Armor"}
## id -> category and attributes. **Higher tiers are stronger**, so buying
## dinosaurs is worth it: each tier has its own attribute budget and cap on
## its category's lean attribute (TIER_BUDGET / TIER_LEAN_MAX, index 0 = the
## button's original, then Starter, Skilled, Expert, Legend). Only Experts
## and Legends can reach 10 in their lean, and only by levelling (bases are
## low on purpose since levels add points; the original Raptor's Speed is 5).
## Within a tier they're trade-offs: the same budget, so none is at least as
## good as another at everything, and the lean attribute is always its best.
## Gameplay numbers are shifted relative to the button's original (form_data),
## so the original four play exactly as they always have.
const TIER_BUDGET := [17, 19, 21, 25, 29]
const TIER_LEAN_MAX := [5, 7, 7, 9, 9]   # base values: levels take them higher (nothing starts at 10)
const ATTR_MAX := 10

## LEVELS (config/leveling.cfg, docs/systems/leveling.md): a hero or dinosaur
## levels up by itself the moment it has the XP, from 1 to max_level (20); no
## meat, no Camp trip. Its level is worked out from its XP alone (level()), so
## nothing else is saved. Each dinosaur level raises one attribute by about half
## a point (+0.5 below 5, +0.4 below 7, +0.3 below 9, +0.2 above), the
## attribute picked by the growth pattern (mostly its best one), so its points
## are worked out from its level too (_pts_at()). Levelling can't lift the lean
## attribute past LEVEL_LEAN_MAX (one below the next tier's base), so a higher
## tier keeps its edge; other attributes go up to ATTR_MAX. Heroes don't grow
## attributes by level (they get skill points). Attributes can hold decimals
## (fmt() shows them).
const DEFAULT_MAX_LEVEL := 20
const DEFAULT_FIRST_LEVEL_M := 300.0
const DEFAULT_STEP_M := 150.0
const DEFAULT_TEAM_SHARE := 0.1
const DEFAULT_PATTERN := [1, 2, 1, 3]
static var max_level := DEFAULT_MAX_LEVEL
static var first_level_m := DEFAULT_FIRST_LEVEL_M
static var step_m := DEFAULT_STEP_M
static var team_share := DEFAULT_TEAM_SHARE
static var pattern: Array = DEFAULT_PATTERN
static var _config_loaded := false
## [below this value, a level-up adds this much]; above the last, GAIN_TOP.
const GAIN_STEPS := [[5.0, 0.5], [7.0, 0.4], [9.0, 0.3]]
const GAIN_TOP := 0.2
## What levels used to cost (meat x the new level, by tier), kept only to
## refund old saves (main._migrate_levels).
const OLD_LEVEL_COST := [30, 45, 60, 80, 100]

## EXPERIENCE: 1 XP for every metre Rok runs as a character (main.add_xp).
## `xp` (id -> XP) is main.dino_xp (SaveData.load/save_dino_xp).
static var xp: Dictionary = {}
static var _pts_cache: Dictionary = {}   # "id:level" -> {attr: points}


static func _load_config() -> void:
	if _config_loaded:
		return
	_config_loaded = true
	var c := ConfigFile.new()
	if c.load("res://config/leveling.cfg") != OK:
		return
	max_level = int(c.get_value("xp", "max_level", DEFAULT_MAX_LEVEL))
	first_level_m = float(c.get_value("xp", "first_level_m", DEFAULT_FIRST_LEVEL_M))
	step_m = float(c.get_value("xp", "step_m", DEFAULT_STEP_M))
	team_share = float(c.get_value("xp", "team_share", DEFAULT_TEAM_SHARE))
	var pt: Variant = c.get_value("growth", "pattern", DEFAULT_PATTERN)
	if pt is Array and not pt.is_empty():
		pattern = pt


static func xp_of(id: String) -> float:
	return float(xp.get(id, 0.0))


## Total XP needed to reach level `l`.
static func xp_for(l: int) -> float:
	_load_config()
	var n := float(l - 1)
	return first_level_m * n + step_m * n * (n - 1.0) / 2.0


## [XP into this level, XP this level needs] for a progress bar.
static func xp_progress(id: String) -> Vector2:
	var l := level(id)
	if l >= max_level:
		return Vector2(1, 1)
	var lo := xp_for(l)
	return Vector2(clampf(xp_of(id) - lo, 0.0, xp_for(l + 1) - lo), xp_for(l + 1) - lo)


## The level `x` XP reaches (1 to max_level).
static func level_for_xp(x: float) -> int:
	_load_config()
	var l := 1
	while l < max_level and x >= xp_for(l + 1) - 0.001:
		l += 1
	return l


const LEVEL_LEAN_MAX := [6, 8, 8, 10, 10]
const ROSTER := {
	# Runners: speed
	"raptor":             {"cat": "runner", "speed": 5, "jump": 5, "stamina": 5, "power": 1, "armor": 1},  # the original: all-round sprinter
	"gallimimus":         {"cat": "runner", "speed": 7, "jump": 3, "stamina": 7, "power": 1, "armor": 1},  # endurance, low jump
	"oviraptor":          {"cat": "runner", "speed": 7, "jump": 5, "stamina": 5, "power": 1, "armor": 1},  # quick all-rounder
	"coelophysis":        {"cat": "runner", "speed": 7, "jump": 7, "stamina": 3, "power": 1, "armor": 3},  # light and springy
	"dilophosaurus":      {"cat": "runner", "speed": 7, "jump": 5, "stamina": 3, "power": 5, "armor": 1},  # quick and bitey
	"deinonychus":        {"cat": "runner", "speed": 9, "jump": 7, "stamina": 3, "power": 3, "armor": 3},  # leaping claw
	"carnotaurus":        {"cat": "runner", "speed": 9, "jump": 3, "stamina": 3, "power": 7, "armor": 3},  # top-speed bruiser, poor jumper
	"utahraptor":         {"cat": "runner", "speed": 9, "jump": 5, "stamina": 5, "power": 7, "armor": 3},  # legend: blazing and strong
	# Smashers: power
	"triceratops":        {"cat": "smasher", "speed": 3, "jump": 3, "stamina": 3, "power": 5, "armor": 3},  # the original: steady horns
	"pachycephalosaurus": {"cat": "smasher", "speed": 5, "jump": 5, "stamina": 1, "power": 7, "armor": 1},  # nimble headbutter
	"centrosaurus":       {"cat": "smasher", "speed": 3, "jump": 3, "stamina": 3, "power": 7, "armor": 3},  # balanced herd horn
	"styracosaurus":      {"cat": "smasher", "speed": 3, "jump": 3, "stamina": 5, "power": 7, "armor": 3},  # spiked frill
	"stegosaurus":        {"cat": "smasher", "speed": 1, "jump": 1, "stamina": 7, "power": 7, "armor": 5},  # plated, lasts long
	"kentrosaurus":       {"cat": "smasher", "speed": 5, "jump": 3, "stamina": 3, "power": 9, "armor": 5},  # spiky battering ram
	"euoplocephalus":     {"cat": "smasher", "speed": 3, "jump": 1, "stamina": 5, "power": 9, "armor": 7},  # armoured club-tail
	"ankylosaurus":       {"cat": "smasher", "speed": 1, "jump": 1, "stamina": 9, "power": 9, "armor": 9},  # legend: a living fortress
	# Tanks: armor
	"spinosaurus":        {"cat": "tank",   "speed": 1, "jump": 3, "stamina": 5, "power": 3, "armor": 5},  # the original: sturdy swimmer
	"parasaurolophus":    {"cat": "tank",   "speed": 5, "jump": 3, "stamina": 3, "power": 1, "armor": 7},  # fast herbivore, no punch
	"iguanodon":          {"cat": "tank",   "speed": 1, "jump": 3, "stamina": 5, "power": 3, "armor": 7},  # hardy, slow
	"baryonyx":           {"cat": "tank",   "speed": 5, "jump": 3, "stamina": 3, "power": 3, "armor": 7},  # quick river hunter
	"allosaurus":         {"cat": "tank",   "speed": 3, "jump": 5, "stamina": 1, "power": 5, "armor": 7},  # balanced hunter, tires fast
	"therizinosaurus":    {"cat": "tank",   "speed": 3, "jump": 3, "stamina": 3, "power": 7, "armor": 9},  # giant claws
	"diplodocus":         {"cat": "tank",   "speed": 3, "jump": 1, "stamina": 7, "power": 5, "armor": 9},  # long, whip tail
	"brachiosaurus":      {"cat": "tank",   "speed": 3, "jump": 3, "stamina": 7, "power": 7, "armor": 9},  # legend: towering giant
	# Flyers: jump (lift)
	"pteranodon":         {"cat": "flyer",  "speed": 5, "jump": 5, "stamina": 3, "power": 1, "armor": 3},  # the original: balanced flyer
	"tapejara":           {"cat": "flyer",  "speed": 3, "jump": 7, "stamina": 5, "power": 1, "armor": 3},  # steady cruiser
	"tupandactylus":      {"cat": "flyer",  "speed": 1, "jump": 7, "stamina": 3, "power": 3, "armor": 5},  # giant crest, sturdy
	"rhamphorhynchus":    {"cat": "flyer",  "speed": 5, "jump": 7, "stamina": 3, "power": 3, "armor": 3},  # quick fisher
	"nyctosaurus":        {"cat": "flyer",  "speed": 3, "jump": 7, "stamina": 7, "power": 1, "armor": 3},  # long-distance soarer
	"dimorphodon":        {"cat": "flyer",  "speed": 9, "jump": 9, "stamina": 3, "power": 1, "armor": 3},  # darting, tires fast
	"dsungaripterus":     {"cat": "flyer",  "speed": 3, "jump": 9, "stamina": 5, "power": 5, "armor": 3},  # shell-crusher
	"quetzalcoatlus":     {"cat": "flyer",  "speed": 5, "jump": 9, "stamina": 7, "power": 5, "armor": 3},  # legend: huge, tireless glider
}

## Rok has attributes and levels too (the user's call), but no category or
## tier: he is the hero. His Speed above 4 lets him slowly gain on the hunter,
## Stamina makes amber refill more energy, Power 8 smashes small hazards and
## Armor softens every hit (Hearts). He levels like the dinosaurs (cap 10 in
## every attribute) and earns XP on his own feet.
const ROK_STATS := {"speed": 4, "jump": 5, "stamina": 4, "power": 2, "armor": 2}
## Every hero (Heroes): the same 17-point budget as an original dinosaur.
const HERO_STATS := {
	"rok": ROK_STATS,                                                         # all-rounder
	"nira": {"speed": 5, "jump": 6, "stamina": 4, "power": 1, "armor": 1},    # quick scout, fragile
	"boro": {"speed": 3, "jump": 3, "stamina": 4, "power": 4, "armor": 3},    # sturdy guardian, slow
}

static var _data: Dictionary = {}
static var _order: Array = []
static var _frames: Dictionary = {}   # id -> 8 idle frame textures


static func _load() -> void:
	if not _order.is_empty():
		return
	var j: Variant = JSON.parse_string(FileAccess.get_file_as_string(DIR + "/dinos.json"))
	if j == null:
		push_warning("Dinos: %s/dinos.json missing (run tools/prepare_dinos.gd)" % DIR)
		return
	_order = j.order
	_data = j.creatures


## Category id of any dinosaur (playable form or expansion).
static func category_of(id: String) -> String:
	return "rok" if Heroes.is_hero(id) else ROSTER[id].cat   # heroes share the "rok" category


## A dinosaur in the roster, or Rok: anything with attributes.
static func known(id: String) -> bool:
	return Heroes.is_hero(id) or ROSTER.has(id)


## Attribute (1-10, may hold decimals) of any dinosaur, levels included.
## An attribute in play: base + levels, plus a hero's gear (Gear.bonus),
## kept within 0..ATTR_MAX.
static func stat(id: String, attr: String) -> float:
	var v := trained_stat(id, attr)
	if Heroes.is_hero(id):
		v = clampf(v + Gear.bonus(id, attr), 0.0, float(ATTR_MAX))
	return snappedf(v, 0.01)


## Base + levels only (what levelling works on: gear never blocks a level-up).
static func trained_stat(id: String, attr: String) -> float:
	return snappedf(float(base_stat(id, attr)) + float(_pts(id).get(attr, 0.0)), 0.01)


## Points its levels added, per attribute.
static func _pts(id: String) -> Dictionary:
	return _pts_at(id, level(id))


## Points a dinosaur has at level `l`: each level from 2 up raises the
## attribute the growth pattern picks (by rank of base value, 1 = best; a
## capped one passes its turn to the next rank). Heroes: none.
static func _pts_at(id: String, l: int) -> Dictionary:
	if Heroes.is_hero(id):
		return {}
	var key := "%s:%d" % [id, l]
	if _pts_cache.has(key):
		return _pts_cache[key]
	_load_config()
	var ranked: Array = ATTRS.duplicate()
	ranked.sort_custom(func(a, b): return base_stat(id, a) > base_stat(id, b) or (base_stat(id, a) == base_stat(id, b) and ATTRS.find(a) < ATTRS.find(b)))
	var pts := {}
	for lv in range(2, l + 1):
		var r := int(pattern[(lv - 2) % pattern.size()]) - 1
		for k in ranked.size():
			var a: String = ranked[(r + k) % ranked.size()]
			var g := _gain_at(float(base_stat(id, a)) + float(pts.get(a, 0.0)), float(level_cap(id, a)))
			if g > 0.001:
				pts[a] = snappedf(float(pts.get(a, 0.0)) + g, 0.01)
				break
		var evo := Milestones.stage_at(id, lv)
		if evo > Milestones.stage_at(id, lv - 1):   # Evolution: +1 to every attribute (the 2nd lets the best pass its cap by 1)
			for a in ATTRS:
				var cap := float(level_cap(id, a)) + (1.0 if evo >= 2 and a == ranked[0] else 0.0)
				var add := minf(1.0, cap - (float(base_stat(id, a)) + float(pts.get(a, 0.0))))
				if add > 0.001:
					pts[a] = snappedf(float(pts.get(a, 0.0)) + add, 0.01)
	_pts_cache[key] = pts
	return pts


static func _gain_at(v: float, cap: float) -> float:
	for step in GAIN_STEPS:
		if v < step[0]:
			return minf(step[1], cap - v)
	return minf(GAIN_TOP, cap - v)


## What its next level adds: {attr: points} ({} for a hero or at the top).
static func next_growth(id: String) -> Dictionary:
	var l := level(id)
	if Heroes.is_hero(id) or l >= max_level:
		return {}
	var now := _pts_at(id, l)
	var nxt := _pts_at(id, l + 1)
	var out := {}
	for a in nxt:
		var d := float(nxt[a]) - float(now.get(a, 0.0))
		if d > 0.001:
			out[a] = snappedf(d, 0.01)
	return out


## An attribute as text: "7", "7.5", "8.3".
static func fmt(v: float) -> String:
	return str(int(v)) if is_equal_approx(v, roundf(v)) else "%.1f" % v


## The attribute as the dinosaur comes, before any levels.
static func base_stat(id: String, attr: String) -> int:
	return int(HERO_STATS[id][attr]) if Heroes.is_hero(id) else int(ROSTER[id][attr])


## Its level, 1 to max_level, worked out from its XP.
static func level(id: String) -> int:
	return level_for_xp(xp_of(id))


## Has its levels changed its attributes? (A hero's never do.)
static func has_levels(id: String) -> bool:
	return not _pts(id).is_empty()


## The highest an attribute can be levelled to.
static func level_cap(id: String, attr: String) -> int:
	if Heroes.is_hero(id):
		return ATTR_MAX
	if attr == CATEGORIES[category_of(id)].lean:
		return LEVEL_LEAN_MAX[tier(id)]
	return ATTR_MAX


## A speed (1-10) in words.
static func speed_label(v: int) -> String:
	return SPEED_LABELS[clampi(ceili(v / 2.0), 1, 5)]


## Its trade-off in words: "Best: Speed · Weakest: Power". The best is its
## category's lean attribute; the weakest is its lowest (first if tied).
static func tradeoff(id: String) -> String:
	var best: String = ATTRS[0] if Heroes.is_hero(id) else CATEGORIES[category_of(id)].lean
	var worst: String = ATTRS[0]
	for a in ATTRS:
		if stat(id, a) < stat(id, worst):
			worst = a
		if Heroes.is_hero(id) and stat(id, a) > stat(id, best):
			best = a
	return "Best: %s · Weakest: %s" % [ATTR_NAMES[best], ATTR_NAMES[worst]]


## A Market dinosaur's tier, 1-4 (Starter, Skilled, Expert, Legend): 1 plus
## the tier of its category badge it needs (Progression.MARKET_BADGES).
static func tier(id: String) -> int:
	if not has(id):
		return 0   # the button's original dinosaur
	var r: Array = Progression.MARKET_BADGES.get(id, [])
	if r.is_empty() or r[0] != CATEGORY_BADGE.get(category_of(id), ""):
		return 1
	return 1 + int(r[1])


## The tier's name ("Expert"; "Original" for the button's own dinosaur).
## Tiers are names with a colour (levels show as "Lv 7").
static func tier_label(id: String) -> String:
	var t := tier(id)
	return "Original" if t == 0 else TIER_NAMES[t - 1]


const TIER_COLORS := [Color(0.5, 0.42, 0.32), Color(0.35, 0.55, 0.25), Color(0.2, 0.45, 0.7), Color(0.55, 0.3, 0.7), Color(0.85, 0.55, 0.1)]


static func tier_color(id: String) -> Color:
	return TIER_COLORS[tier(id)]


## Its level as text: "Lv 7", or "Lv 20 MAX".
static func level_text(id: String) -> String:
	var l := level(id)
	return "Lv %d%s" % [l, " MAX" if l >= max_level else ""]


## The chance (0-1) to smash through a small rock, mushroom or vine instead of
## tripping, getting dizzy or snagged, for `id` on button `slot`.
static func break_chance(id: String, slot: int) -> float:
	var c := clampf((stat(id, "power") - 1.0) / 9.0, 0.0, 1.0)
	if slot == Forms.TRICERATOPS:
		c += SMASHER_BREAK_BONUS
	return clampf(c, 0.0, 1.0)


## What a dinosaur's attributes add in play beyond its button's ability
## (the same rules as form_data), for the Herd screen.
static func perks(id: String) -> Array:
	var cat := category_of(id)
	var out := []
	var slot := Forms.ROK if Heroes.is_hero(id) else slot_of(cat)
	out.append("Breaks through rocks, mushrooms and vines: %d%% of the time" % roundi(break_chance(id, slot) * 100.0))
	if cat == "smasher" and stat(id, "power") >= POWER_FENCE:
		out.append("Mighty: also smashes fences")
	if stat(id, "armor") >= ARMOR_SHIELD and cat != "tank" and cat != "rok":
		out.append("Armoured: a shield each time Rok turns into it")
	var a := stat(id, "armor")
	out.append("A crash costs %s, a trip %s" % [Hearts.text(Hearts.damage("boulder", a)), Hearts.text(Hearts.damage("small", a))])
	out.append("Attack every %.2f s (Power), slide again after %.2f s (Speed)" % [
			Tuning.ATTACK_COOLDOWN * cooldown_mult(id, "power"), Tuning.SLIDE_COOLDOWN * cooldown_mult(id, "speed")])
	return out


## How much an attribute shortens a cooldown (the user's request): ATTACK by
## Power, the slide by Speed (the jump has none: Tuning.JUMP_COOLDOWN 0); each point cuts COOLDOWN_CUT_PER_POINT (40% at
## 10). Levels, gear and cards raise the attribute, so they shorten it too.
static func cooldown_mult(id: String, attr: String) -> float:
	var v := stat(id, attr) if known(id) else 3.0
	return clampf(1.0 - Tuning.COOLDOWN_CUT_PER_POINT * v, 0.5, 1.0)


## Attribute thresholds that unlock something in play (10-point scale).
## POWER ROLL: running into a small rock, a mushroom or a vine rolls the dice
## (main._collide): with break_chance it's smashed straight through, otherwise
## it trips, dizzies or snags as usual. (Power - 1) / 9: 0% at Power 1, 44% at
## 5, 100% at 10; the Smasher button adds SMASHER_BREAK_BONUS.
const SMASHER_BREAK_BONUS := 0.3
const POWER_FENCE := 10   # a Smasher also smashes fences
const ARMOR_SHIELD := 10  # a non-Tank gets a shield per transformation


## A hero or species whose art and bounds the game has (form_data's art branch).
static func _play_of(id: String) -> Dictionary:
	if Heroes.has(id):
		return Heroes.play(id)
	_load()
	return _data[id].play


## True once a species has the full playable art (jump, slide, die...).
static func playable(id: String) -> bool:
	if Heroes.has(id):
		return true
	_load()
	return _data.has(id) and _data[id].has("play")


## The playable form id (Forms.RAPTOR...) of a category's button.
static func slot_of(cat: String) -> int:
	return CATEGORIES[cat].form


const SPEED_LABELS := {1: "Slow", 2: "Steady", 3: "Quick", 4: "Fast", 5: "Blazing"}


## Form data for a dinosaur on its category's button: the button's base form
## (Forms.DATA) keeps its abilities (smashing, flying, swimming, light feet,
## score bonus); an expansion species brings its art and hitboxes (the
## original keeps its own); and the attributes, levels included, shift the
## numbers relative to the button's original as it comes (so an unlevelled
## original plays exactly as Forms.DATA). Per point on the 10-point scale:
##   speed   -> chase rate (+-5 px/s) and the speed label
##   jump    -> jump strength (+-3%)
##   stamina -> energy drain (-+7.5%)
##   power   -> the chance to break through small hazards (break_chance); a POWER_FENCE
##              Smasher smashes fences too
##   armor   -> stumbles cost +-5%; ARMOR_SHIELD gives a non-Tank a shield,
##              and Armor softens every hit (Hearts.damage, applied in main._hurt)
## Rok (slot ROK, id "rok") uses no energy, so for him Stamina instead makes
## amber refill more (amber_mult, +7.5% per point).
static func form_data(slot: int, id: String) -> Dictionary:
	_load()
	var d: Dictionary = Forms.DATA[slot].duplicate(true)
	var base: String = d.id
	var delta := func(a: String) -> float: return stat(id, a) - float(base_stat(base, a))
	if has(id) or Heroes.has(id):
		var p: Dictionary = _play_of(id)
		d.id = id
		d.sound_id = base
		d.name = Heroes.name_of(id) if Heroes.is_hero(id) else name_of(id)
		d.species = true
		d.frame = Vector2(p.frame[0], p.frame[1])
		d.pivot = Vector2(p.pivot[0], p.pivot[1])
		d.scale = 1.0
		d.times = p.times
		# hitboxes from the measured art (a little inside it, like the originals)
		d.hitbox = Vector2(p.stand[0] * 0.66, p.stand[1] * 0.78)
		d.box_offset_x = p.stand[2] * 0.5
		d.slide_box = Vector2(p.slide[0] * 0.68, minf(p.slide[1] * 0.85, 96.0))
		d.duck_box = Vector2(p.slide[0] * 0.66, minf(p.slide[1] * 0.95, 104.0))
		d.low_squash = 1.0   # the art has real low poses
		if p.has("fly"):
			d.fly_box = Vector2(p.fly[0] * 0.5, p.fly[1] * 0.4)
			d.fly_box_bottom = p.fly[2] + p.fly[1] * 0.25
			d.fly_offset_x = p.fly[3]
		# extra clips the button's form uses, from the species' own sheets
		var extra := {}
		if d.get("flies", false):
			extra = {"fly": "fly", "glide": "glide", "takeoff": "jump", "land": "jump"}
		elif d.get("swims", false):
			extra = {"swim": "run"}
		d.extra_files = extra
		d.desc = String(Heroes.INFO[id].blurb) if Heroes.is_hero(id) else "%s. %s" % [CATEGORIES[category_of(id)].role, tradeoff(id)]
	# attributes (levels included), relative to the button's original as it comes
	d.speed = stat(id, "speed")
	d.speed_label = speed_label(d.speed)
	d.chase_rate = float(d.chase_rate) + delta.call("speed") * 5.0
	d.jump = float(d.jump) * (1.0 + delta.call("jump") * 0.03)
	if slot == Forms.ROK:
		d.amber_mult = 1.0 + delta.call("stamina") * 0.075
	else:
		d.drain = maxf(float(d.drain) * (1.0 - delta.call("stamina") * 0.075), 2.0)
	var breaks: Array = (d.breaks as Array).duplicate()
	if slot == Forms.TRICERATOPS and stat(id, "power") >= POWER_FENCE and not breaks.has("fence"):
		breaks.append("fence")
	d.breaks = breaks
	d.stumble_mult = 1.0 - delta.call("armor") * 0.05
	if stat(id, "armor") >= ARMOR_SHIELD and int(d.armor) == 0:
		d.armor = 1
	if Milestones.knows(id, "thick_skull") and not (d.breaks as Array).has("wood"):
		d.breaks = (d.breaks as Array) + ["wood"]   # Thick Skull: logs too, no Power roll
	if Milestones.knows(id, "double_shield"):
		d.armor = maxi(int(d.armor), int(Milestones.value("double_shield", 2)))
	if Milestones.knows(id, "triple_jump"):
		d.air_jumps = int(d.air_jumps) + int(Milestones.value("triple_jump", 1))
	if Milestones.knows(id, "pack_instinct"):
		d.score_mult = maxf(float(d.score_mult), float(Milestones.value("pack_instinct", 2.5)))
	if slot == Forms.ROK and Skills.knows(id, "air_step"):
		d.air_jumps = int(d.air_jumps) + int(Skills.value("air_step", 1))   # a third jump as the hero
	return d


## Every dinosaur in a category, playable form first.
static func members(cat: String) -> Array:
	return ROSTER.keys().filter(func(id): return ROSTER[id].cat == cat)


## Every expansion creature id, in catalogue order.
static func ids() -> Array:
	_load()
	return _order


static func has(id: String) -> bool:
	_load()
	return _data.has(id)


static func name_of(id: String) -> String:
	_load()
	return _data[id].name


## One line for the Market card: its look, plus what owning it means.
static func desc(id: String) -> String:
	_load()
	var kind := "pterosaur (a flying reptile, not a dinosaur)" if _data[id].group == "pterosaurs" else "dinosaur"
	return "A %s: %s." % [kind, String(_data[id].feature).to_lower()]


## First idle frame, for still icons.
static func icon(id: String) -> Texture2D:
	return _frame(id, 0)


## How long each idle frame shows, in seconds (8 frames).
static func frame_times(id: String) -> Array:
	_load()
	return (_data[id].duration_ms as Array).map(func(ms): return float(ms) / 1000.0)


## Idle frame i (0-7). Market cards animate by swapping these themselves:
## AnimatedTexture is deprecated, and freeing one broke the shared frames
## (cards went white after switching tabs).
static func frame(id: String, i: int) -> Texture2D:
	return _frame(id, i % 8)


## One idle frame as its own texture, cut out of the sheet once and cached.
static func _frame(id: String, i: int) -> Texture2D:
	_load()
	if not _frames.has(id):
		var fs: Array = _data[id].frame
		var sheet: Image = (load("%s/%s_idle.png" % [DIR, id]) as Texture2D).get_image()
		var list := []
		for k in 8:
			list.append(ImageTexture.create_from_image(sheet.get_region(Rect2i(k % 4 * int(fs[0]), k / 4 * int(fs[1]), int(fs[0]), int(fs[1])))))
		_frames[id] = list
	return _frames[id][i]
