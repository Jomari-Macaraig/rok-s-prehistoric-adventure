class_name Drops
## What things drop, written for the Field Guide from the SAME config the game
## rolls with (the user's rule: the Encyclopedia stays in sync with the game):
##   broken obstacles   config/pickups.cfg [break_loot] + config/crafting.cfg [break_drops]
##   wild dinosaurs     config/crafting.cfg [wild_drops] + config/pickups.cfg [cards]
##   hunters            config/crafting.cfg [trophies]
##   chests             config/pickups.cfg [chests] (odds, rewards, weights)
## Nothing here is a number of its own: change the config and the guide follows.

## Which break-drop table a Field Guide hazard uses (Crafting.break_table's
## kinds): "rock" (by zone), "wood", "fiber", "mushroom", "meteor".
const HAZARD_TABLE := {"small": "rock", "boulder": "rock", "wall": "rock", "rolling_boulder": "rock",
		"log": "wood", "fence": "wood", "tall_fence": "wood", "thorn_bush": "fiber", "ledge": "fiber",
		"mushroom": "mushroom", "meteor": "meteor"}
const HUNTER_KEYS := {"trex": "trex", "hunter_carnotaurus": "carnotaurus", "hunter_allosaurus": "allosaurus"}


static func pct(v: float) -> String:
	var p := v * 100.0
	return ("%d%%" % int(roundf(p))) if p >= 1.0 else ("%.1f%%" % p)


## "Stone, Flint" (highest weight first).
static func mats(table: Dictionary) -> String:
	var ids: Array = table.keys()
	ids.sort_custom(func(a, b): return float(table[a]) > float(table[b]))
	return ", ".join(ids.map(func(m): return Crafting.mat_name(String(m))))


static func _count_text(section: String) -> String:
	var c: Array = Crafting.num(section, "count")
	return str(c[0]) if int(c[0]) == int(c[1]) else "%d-%d" % [int(c[0]), int(c[1])]


## The materials a break-drop kind gives, per zone where it differs.
static func break_mats(kind: String) -> String:
	if kind == "rock":
		var parts: Array = []
		for z in Zones.ZONES:
			var o := Obstacle.new()
			o.kind = "rock"
			var t := Crafting.break_table(o, String(z.id))
			o.free()
			var v: Variant = Crafting.num("break_drops", t)
			if v is Dictionary:
				parts.append("%s in the %s" % [mats(v), z.name])
		return "; ".join(parts)
	var plain: Variant = Crafting.num("break_drops", kind)
	var out := mats(plain) if plain is Dictionary else ""
	for z in Zones.ZONES:   # a zone's own table (fiber_desert: cactus spines)
		var zv: Variant = Crafting.num("break_drops", "%s_%s" % [kind, z.id])
		if zv is Dictionary and not (zv as Dictionary).is_empty():
			out += "; %s in the %s" % [mats(zv), z.name]
	return out


## A breakable hazard's drops ("" if it can't be broken or drops nothing).
static func for_hazard(key: String) -> String:
	if HUNTER_KEYS.has(key):
		return for_hunter(HUNTER_KEYS[key])
	if key in ["stampede", "swooper", "diver"]:
		return for_wild_kind(key)
	if not HAZARD_TABLE.has(key):
		return ""
	var kind: String = HAZARD_TABLE[key]
	var lines: Array = []
	var loot := float(Loot.num("break_loot", "chance"))
	if loot > 0.0:
		lines.append("%s: amber (a heart if you're hurt %s of the time, a power-up %s)" % [pct(loot), pct(float(Loot.num("break_loot", "heart"))), pct(float(Loot.num("break_loot", "power")))])
	var m := break_mats(kind)
	var mc := float(Crafting.num("break_drops", "chance"))
	if m != "" and mc > 0.0:
		lines.append("%s: %s materials (%s)" % [pct(mc), _count_text("break_drops"), m])
	if lines.is_empty():
		return ""
	return "BREAK IT AND IT MAY DROP:\n• " + "\n• ".join(lines)


## A wild dinosaur's drops when bonked with ATTACK (or bowled over in a frenzy).
static func for_wild(species: String) -> String:
	var flyer := String(Critters.DATA.get(species, {}).get("kind", "stampede")) == "swooper"
	var lines: Array = ["%s: %s materials (%s)" % [pct(float(Crafting.num("wild_drops", "chance"))), _count_text("wild_drops"), mats(Crafting.wild_table(species, flyer))]]
	lines.append("its card: %s the first time, %s after" % [pct(card_chance(species, true)), pct(card_chance(species, false))])
	return "BONK IT WITH ATTACK AND IT MAY DROP:\n• " + "\n• ".join(lines)


## The wild-dinosaur lessons: what every wild one of that kind drops.
static func for_wild_kind(kind: String) -> String:
	var k := "swooper" if kind == "diver" else kind
	var land := k != "swooper"
	var lines: Array = ["%s: %s materials (%s, plus extras per species)" % [pct(float(Crafting.num("wild_drops", "chance"))), _count_text("wild_drops"), mats(Crafting.num("wild_drops", "land" if land else "flyer"))]]
	lines.append("its own card: up to %s the first time, %s after (rarer for higher-tier dinosaurs)" % [pct(float(Loot.num("cards", "first_drop_chance"))), pct(float(Loot.num("cards", "drop_chance")))])
	return "BONK ONE WITH ATTACK AND IT MAY DROP:\n• " + "\n• ".join(lines)


## A hunter's trophy for escaping its charge.
static func for_hunter(id: String) -> String:
	var t := Crafting.trophy(id)
	if t == "":
		return ""
	return "ESCAPE ITS CHARGE AND IT MAY DROP:\n• %s: its trophy, %s" % [pct(float(Crafting.num("trophies", "chance"))), Crafting.mat_name(t)]


## The card drop chance (main.card_chance, without a running game).
static func card_chance(d: String, first: bool) -> float:
	var base := float(Loot.num("cards", "first_drop_chance" if first else "drop_chance"))
	var mult: Array = Loot.num("cards", "tier_mult")
	return base * float(mult[clampi(Dinos.tier(d), 0, mult.size() - 1)])


## Where a species runs wild ("the Desert and the Canyon"), or "".
static func wild_zones(species: String) -> String:
	if not Critters.DATA.has(species):
		return ""
	var zs: Array = []
	for z in Zones.ZONES:
		if Critters.for_zone(String(z.id), String(Critters.DATA[species].kind)) == species:
			zs.append("the " + String(z.name))
	return " and ".join(zs)


## Milestone chests: their odds and what each tier can hold.
static func for_chests() -> String:
	var c1 := Chest.chances(1)
	var lines: Array = ["%s of milestones have one (the early starter chest always comes)" % pct(float(Loot.num("chests", "appear")))]
	lines.append("at the first: rare %s, ultra rare %s, legendary %s (better further on)" % [pct(c1.rare), pct(c1.ultra_rare), pct(c1.legendary)])
	var w: Dictionary = Loot.num("chests", "reward_weights") if Loot.num("chests", "reward_weights") is Dictionary else {}
	for r in Chest.RARITY:
		var opts: Array = Chest.rewards(r)
		var total := 0.0
		for o in opts:
			total += float(w.get(o, 1.0))
		lines.append("%s: %s" % [String(Chest.RARITY_NAME[r]).capitalize(), ", ".join(opts.map(func(o): return "%s %s" % [String(o).replace("_", " "), pct(float(w.get(o, 1.0)) / total)]))])
	return "CHESTS:\n• " + "\n• ".join(lines)
