class_name Crafting
## Crafting (the user's design): weapons and armor are never bought, only
## crafted at the Crafting Bench from materials. Materials come from runs
## (broken obstacles, wild dinosaurs, reward spots, chests, fossils) and the
## basic ones are sold in bundles in the Market's Gear tab. Every craft rolls
## a rarity (0 Common .. 4 Legendary) that multiplies the item's bonuses and
## durability; a catalyst material improves the odds. Items can be salvaged
## for part of their recipe, and repairs cost materials.
## Everything is read from config/crafting.cfg (DEFAULTS mirror it).
## The material bank lives in main (`materials`); `bank` points at it.

const PATH := "res://config/crafting.cfg"

const DEFAULTS := {
	"materials": {
		"wood": {"name": "Wood", "rarity": 0, "price": 40, "unlock_m": 500, "from": "Breaking logs, fences and bridges."},
		"stone": {"name": "Stone", "rarity": 0, "price": 40, "unlock_m": 500, "from": "Breaking rocks, boulders and walls."},
		"fiber": {"name": "Fiber", "rarity": 0, "price": 40, "unlock_m": 500, "from": "Breaking vines and thorn bushes."},
		"flint": {"name": "Flint", "rarity": 1, "price": 90, "unlock_m": 1200, "from": "Breaking rocks, mostly in the Desert."},
		"hide": {"name": "Hide", "rarity": 1, "price": 90, "unlock_m": 1200, "from": "Bonking wild land dinosaurs."},
		"bone": {"name": "Bone", "rarity": 1, "price": 0, "unlock_m": 0, "from": "Bonking wild dinosaurs."},
		"resin": {"name": "Resin", "rarity": 2, "price": 0, "unlock_m": 0, "from": "Deep reward spots and chests."},
		"dino_scale": {"name": "Dino Scale", "rarity": 2, "price": 0, "unlock_m": 0, "from": "A rare drop from wild dinosaurs."},
		"obsidian": {"name": "Obsidian", "rarity": 2, "price": 0, "unlock_m": 0, "from": "Volcanic rocks and meteors."},
		"shell": {"name": "Shell", "rarity": 3, "price": 0, "unlock_m": 0, "from": "Ultra rare and legendary chests."},
		"fossil_shard": {"name": "Fossil Shard", "rarity": 3, "price": 0, "unlock_m": 0, "from": "Rare fossils."},
		"primal_crystal": {"name": "Primal Crystal", "rarity": 4, "price": 0, "unlock_m": 0, "from": "Ultra rare and legendary chests."},
	},
	"unlock": {"bench_m": 500},
	"market": {"bundle": 5},
	"recipes": {
		"club": {"wood": 6, "fiber": 2},
		"stone_axe": {"wood": 4, "stone": 4, "fiber": 3},
		"flint_spear": {"wood": 6, "flint": 5, "fiber": 3},
		"torch": {"wood": 5, "fiber": 3, "resin": 3},
		"bone_hammer": {"bone": 6, "stone": 4, "hide": 3},
		"sling": {"hide": 6, "fiber": 4, "stone": 4},
		"bow": {"wood": 6, "fiber": 6, "flint": 4, "dino_scale": 2},
		"hide_vest": {"hide": 6, "fiber": 3},
		"bone_guards": {"bone": 6, "hide": 4},
		"scale_mail": {"dino_scale": 8, "hide": 4},
		"shell_plate": {"shell": 2, "hide": 4, "bone": 4},
	},
	"rarity": {
		"names": ["Common", "Uncommon", "Rare", "Epic", "Legendary"],
		"chances": [60, 25, 10, 4, 1],
		"bonus_mult": [1.0, 1.2, 1.45, 1.75, 2.1],
		"durability_mult": [1.0, 1.25, 1.5, 2.0, 2.5],
	},
	"catalysts": {
		"resin": [45, 32, 15, 6, 2],
		"obsidian": [35, 35, 19, 8, 3],
		"fossil_shard": [15, 35, 30, 15, 5],
		"primal_crystal": [0, 15, 40, 30, 15],
	},
	"salvage": {"share": 0.5, "bonus": ["", "", "resin", "fossil_shard", "primal_crystal"]},
	"repair": {"meat": [20, 35, 60, 100, 160]},
	"drop_rarity": {"weights": [1.0, 0.45, 0.15, 0.05, 0.015]},
	"break_drops": {"chance": 0.15, "count": [1, 2],
		"wood": {"wood": 3, "fiber": 1}, "fiber": {"fiber": 3, "wood": 1},
		"rock_forest": {"stone": 4, "flint": 1}, "rock_desert": {"stone": 2, "flint": 3},
		"rock_volcanic": {"stone": 2, "obsidian": 2}, "meteor": {"obsidian": 1}},
	"wild_drops": {"chance": 0.3, "count": [1, 2],
		"land": {"hide": 6, "bone": 4, "dino_scale": 1.5, "shell": 0.3},
		"flyer": {"bone": 3, "hide": 2, "dino_scale": 1.5}},
	"spots": {"chance": 0.05, "count": [1, 3],
		"forest": {"wood": 3, "fiber": 3, "stone": 1}, "desert": {"flint": 3, "bone": 2, "stone": 1},
		"volcanic": {"obsidian": 2, "stone": 2, "flint": 1},
		"deep_from_m": 2500, "deep_full_m": 6000, "deep_max": 0.5,
		"deep": {"resin": 3, "dino_scale": 3, "fossil_shard": 0.6, "primal_crystal": 0.15}},
	"chests": {"common_count": 4, "common": {"wood": 1, "stone": 1, "fiber": 1, "flint": 1, "hide": 1},
		"rare_count": 3, "rare": {"bone": 1, "resin": 1, "dino_scale": 1, "obsidian": 1},
		"ultra_rare_count": 2, "ultra_rare": {"shell": 1, "fossil_shard": 1, "dino_scale": 1, "primal_crystal": 0.3},
		"legendary_count": 3, "legendary": {"fossil_shard": 1, "primal_crystal": 0.6, "shell": 0.5}},
	"fossils": {"shards": 1},
}
## Rarity frame colours: grey, green, blue, purple, gold.
const RARITY_COLOR := [Color(0.72, 0.72, 0.7), Color(0.45, 0.85, 0.4), Color(0.4, 0.65, 1.0),
		Color(0.78, 0.45, 1.0), Color(1.0, 0.78, 0.25)]
## Market ids for material bundles: "mat_<id>" (a node-name-safe id: Market cards are named by it).
const MAT_PREFIX := "mat_"
## Pickup kinds for materials on the course: "m_<id>".
const PICKUP_PREFIX := "m_"

static var _v := {}
static var bank: Dictionary = {}   # material id -> how many (main.materials)


static func _load() -> void:
	if not _v.is_empty():
		return
	_v = DEFAULTS.duplicate(true)
	var c := ConfigFile.new()
	if c.load(PATH) != OK:
		return
	for sec in c.get_sections():
		if sec == "materials" or sec == "recipes" or sec == "catalysts":
			_v[sec] = {}   # the file's list replaces the defaults (so ids can be removed)
		elif not _v.has(sec):
			_v[sec] = {}
		for key in c.get_section_keys(sec):
			_v[sec][key] = c.get_value(sec, key)


## Is this key set in the config (or its defaults)?
static func has_key(section: String, key: String) -> bool:
	_load()
	return _v.get(section, {}).has(key) or DEFAULTS.get(section, {}).has(key)


## A value from the config: Crafting.num("spots", "chance").
static func num(section: String, key: String) -> Variant:
	_load()
	return _v.get(section, {}).get(key, DEFAULTS.get(section, {}).get(key, 0))


## Test hook: forget the loaded values, or set one.
static func forget() -> void:
	_v = {}


static func set_value(section: String, key: String, value: Variant) -> void:
	_load()
	if not _v.has(section):
		_v[section] = {}
	_v[section][key] = value


# ------------------------------------------------------------ materials

static func materials() -> Array:
	_load()
	return _v.materials.keys()


static func is_material(id: String) -> bool:
	_load()
	return _v.materials.has(id)


static func mat(id: String) -> Dictionary:
	_load()
	return _v.materials.get(id, {"name": id, "rarity": 0, "price": 0, "unlock_m": 0, "from": ""})


static func mat_name(id: String) -> String:
	return String(mat(id).name)


static func mat_rarity(id: String) -> int:
	return int(mat(id).rarity)


static func have(id: String) -> int:
	return int(bank.get(id, 0))


## "6 Wood, 2 Fiber".
static func cost_text(cost: Dictionary) -> String:
	var parts: Array = []
	for m in cost:
		parts.append("%d %s" % [int(cost[m]), mat_name(m)])
	return ", ".join(parts)


static func can_afford(cost: Dictionary) -> bool:
	for m in cost:
		if have(m) < int(cost[m]):
			return false
	return true


## Materials the Market sells (price > 0), as "mat_<id>".
static func market_ids() -> Array:
	return materials().filter(func(m): return int(mat(m).price) > 0).map(func(m): return MAT_PREFIX + m)


## The best distance that opens the Crafting Bench ([unlock] bench_m).
static func bench_m() -> int:
	return int(num("unlock", "bench_m"))


static func bundle() -> int:
	return int(num("market", "bundle"))


# ------------------------------------------------------------ recipes and rarity

static func recipe(item: String) -> Dictionary:
	_load()
	return _v.recipes.get(Gear.base(item), {})


static func recipes() -> Array:
	_load()
	return _v.recipes.keys().filter(func(k): return Gear.ITEMS.has(k))


## The best distance that teaches a recipe ([market_unlocks] in progression.cfg).
static func learn_m(item: String) -> int:
	return maxi(bench_m(), int(Progression.MARKET_UNLOCK_M.get(item, Gear.ITEMS[item].unlock_m))) if Gear.ITEMS.has(item) else 0


static func rarity_names() -> Array:
	return num("rarity", "names")


static func rarity_name(r: int) -> String:
	var n: Array = rarity_names()
	return String(n[clampi(r, 0, n.size() - 1)])


static func bonus_mult(r: int) -> float:
	var a: Array = num("rarity", "bonus_mult")
	return float(a[clampi(r, 0, a.size() - 1)])


static func durability_mult(r: int) -> float:
	var a: Array = num("rarity", "durability_mult")
	return float(a[clampi(r, 0, a.size() - 1)])


static func catalysts() -> Array:
	_load()
	return _v.catalysts.keys()


## The chance weights of each rarity, with an optional catalyst.
static func weights(catalyst := "") -> Array:
	_load()
	if catalyst != "" and _v.catalysts.has(catalyst):
		return _v.catalysts[catalyst]
	return num("rarity", "chances")


## Each rarity's chance (0-1) with a catalyst.
static func odds(catalyst := "") -> Array:
	var w := weights(catalyst)
	var total := 0.0
	for x in w:
		total += float(x)
	return w.map(func(x): return float(x) / maxf(total, 0.0001))


## The rarity a roll (0-1) lands on.
static func roll_rarity(roll: float, catalyst := "") -> int:
	var o := odds(catalyst)
	for i in o.size():
		roll -= float(o[i])
		if roll < 0.0:
			return i
	return o.size() - 1


## What salvaging an item returns.
static func salvage_return(item: String, rarity: int) -> Dictionary:
	var out := {}
	var share := float(num("salvage", "share"))
	var r := recipe(item)
	for m in r:
		var n := int(floor(float(r[m]) * share))
		if n > 0:
			out[m] = n
	var bonus: Array = num("salvage", "bonus")
	var b := String(bonus[clampi(rarity, 0, bonus.size() - 1)]) if not bonus.is_empty() else ""
	if b != "":
		out[b] = int(out.get(b, 0)) + 1
	return out


## Meat to repair a piece of rarity `r` with `worn` of `mx` runs used up:
## [repair] meat (by rarity) x the worn share, at least 1.
static func repair_meat(r: int, worn: int, mx: int) -> int:
	if worn <= 0 or mx <= 0:
		return 0
	var by: Array = num("repair", "meat")
	var full := float(by[clampi(r, 0, by.size() - 1)])
	return maxi(1, int(ceil(full * float(worn) / float(mx) - 0.001)))


# ------------------------------------------------------------ drops

## A drop table weighted by drop rarity ([drop_rarity] weights by each
## material's rarity): what run drops actually roll.
static func rarity_weighted(table: Dictionary) -> Dictionary:
	var w: Array = num("drop_rarity", "weights")
	var out := {}
	for m in table:
		out[m] = float(table[m]) * (float(w[clampi(mat_rarity(m), 0, w.size() - 1)]) if not w.is_empty() else 1.0)
	return out


## A wild dinosaur's drop table: land or flyer, plus its species' extras.
static func wild_table(species: String, flyer: bool) -> Dictionary:
	var t: Dictionary = (num("wild_drops", "flyer" if flyer else "land") as Dictionary).duplicate()
	var extra: Dictionary = (num("wild_drops", "species") as Dictionary).get(species, {}) if num("wild_drops", "species") is Dictionary else {}
	for m in extra:
		t[m] = float(t.get(m, 0.0)) + float(extra[m])
	return t


## The trophy a hunter's escaped charge can drop ("" = none).
static func trophy(hunter: String) -> String:
	var v: Variant = num("trophies", hunter)
	return String(v) if v is String else ""


## Pick a material a run drops from a table (drop rarity applied).
static func drop_pick(table: Dictionary, roll := -1.0) -> String:
	return pick(rarity_weighted(table), roll)


## Pick from a weights table {id: weight}.
static func pick(table: Dictionary, roll := -1.0) -> String:
	var total := 0.0
	for k in table:
		total += float(table[k])
	if total <= 0.0:
		return ""
	var r := (randf() if roll < 0.0 else roll) * total
	for k in table:
		r -= float(table[k])
		if r < 0.0:
			return String(k)
	return String(table.keys()[-1])


static func count_of(section: String) -> int:
	var c: Array = num(section, "count")
	return randi_range(int(c[0]), int(c[1]))


## The break-drop table for a broken obstacle: "wood", "fiber",
## "rock_<zone>" or "meteor" ("" = drops no material, e.g. a mushroom).
static func break_table(o: Obstacle, zone: String) -> String:
	var t := ""
	if o.mushroom:
		t = "mushroom"
	elif o.get_meta("meteor", false):
		return "meteor"
	elif o.vine or o.kind == "thorns":
		t = "fiber"
	elif o.kind in ["wood", "fence"]:
		t = "wood"
	else:
		t = "rock"
	var zoned := "%s_%s" % [t, zone]   # a zone's own table when there is one (fiber_desert: cactus spines)
	var v: Variant = num("break_drops", zoned)
	if v is Dictionary and not (v as Dictionary).is_empty():
		return zoned
	if t == "rock":   # a zone without its own rock table (rocks have no plain one): its kin's, else the Forest's
		var kin := "rock_" + Zones.kin(zone)
		return kin if num("break_drops", kin) is Dictionary else "rock_forest"
	return t


## The table a material reward spot rolls at `metres` in `zone`.
static func spot_table(zone: String, metres: float, roll := -1.0, specials := []) -> Dictionary:
	# an event or lap twist running: its own materials ([spots] special_chance)
	for sp in specials:
		var st: Variant = num("spots", String(sp)) if String(sp) != "" else null
		if st is Dictionary and not (st as Dictionary).is_empty() and randf() < float(num("spots", "special_chance")):
			return st
	var from := float(num("spots", "deep_from_m"))
	var full := float(num("spots", "deep_full_m"))
	var deep := float(num("spots", "deep_max")) * clampf(inverse_lerp(from, full, metres), 0.0, 1.0)
	if (randf() if roll < 0.0 else roll) < deep:
		return num("spots", "deep")
	for z in [zone, Zones.kin(zone), "forest"]:
		var t: Variant = num("spots", z)
		if t is Dictionary and not (t as Dictionary).is_empty():
			return t
	return {}


# ------------------------------------------------------------ icons

static var _icons := {}
const MAT_COLOR := {"wood": Color(0.55, 0.33, 0.15), "stone": Color(0.62, 0.6, 0.58), "fiber": Color(0.45, 0.62, 0.25),
		"flint": Color(0.35, 0.38, 0.45), "hide": Color(0.72, 0.5, 0.3), "bone": Color(0.95, 0.9, 0.78),
		"resin": Color(1.0, 0.65, 0.15), "dino_scale": Color(0.3, 0.65, 0.5), "obsidian": Color(0.18, 0.12, 0.22),
		"shell": Color(0.85, 0.7, 0.5), "fossil_shard": Color(0.8, 0.72, 0.55), "primal_crystal": Color(0.55, 0.9, 1.0),
		"fern_frond": Color(0.3, 0.6, 0.25), "mushroom_cap": Color(0.8, 0.3, 0.25), "moss": Color(0.35, 0.5, 0.2),
		"sandstone": Color(0.85, 0.65, 0.4), "cactus_spine": Color(0.5, 0.65, 0.35), "basalt": Color(0.25, 0.25, 0.28),
		"ash": Color(0.55, 0.55, 0.55), "feather": Color(0.95, 0.85, 0.7), "clay": Color(0.7, 0.45, 0.3),
		"wild_berries": Color(0.6, 0.15, 0.4), "ochre": Color(0.8, 0.45, 0.15), "sulfur": Color(0.95, 0.9, 0.25),
		"ember_coal": Color(0.75, 0.25, 0.1), "sinew": Color(0.8, 0.6, 0.5), "claw": Color(0.9, 0.88, 0.8),
		"eggshell": Color(0.95, 0.93, 0.85), "stampede_dust": Color(0.75, 0.6, 0.45), "bleached_skull": Color(0.98, 0.96, 0.9),
		"horn": Color(0.85, 0.78, 0.6), "back_plate": Color(0.55, 0.45, 0.3), "tail_club_knob": Color(0.5, 0.42, 0.35),
		"wing_membrane": Color(0.85, 0.55, 0.4), "golden_dust": Color(1.0, 0.85, 0.3), "storm_glass": Color(0.5, 0.6, 0.85),
		"fog_pearl": Color(0.85, 0.88, 0.92), "fire_opal": Color(1.0, 0.45, 0.2), "t_rex_tooth": Color(0.95, 0.92, 0.82),
		"carnotaurus_horn": Color(0.7, 0.35, 0.25), "allosaurus_claw": Color(0.85, 0.8, 0.7), "meteorite_iron": Color(0.4, 0.38, 0.42),
		"eclipse_shard": Color(0.35, 0.2, 0.55), "insect_in_amber": Color(1.0, 0.6, 0.1), "star_metal": Color(0.75, 0.85, 1.0)}


## A material's icon: the user's art (assets/materials/<id>.png) once it
## exists, else a placeholder drawn in code (a lump in the material's colour
## with a dark outline, on a ring of its rarity's colour).
static func icon(id: String) -> Texture2D:
	var path := "res://assets/materials/%s.png" % id
	if ResourceLoader.exists(path):
		return SpriteLib.tex(path)
	if _icons.has(id):
		return _icons[id]
	var img := Image.create(96, 96, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var col: Color = MAT_COLOR.get(id, Color(0.6, 0.5, 0.4))
	var ring: Color = RARITY_COLOR[clampi(mat_rarity(id), 0, 4)]
	var dark := col.darkened(0.6)
	var seed := hash(id)
	for y in 96:
		for x in 96:
			var d := Vector2(x - 48, y - 48)
			var ang := d.angle()
			var wob := 30.0 + 5.0 * sin(ang * 3.0 + float(seed % 7)) + 3.0 * sin(ang * 5.0 + float(seed % 11))
			var l := d.length()
			if l > 44.0 and l < 47.0:
				img.set_pixel(x, y, ring)
			elif l < wob - 3.0:
				var shade := 0.25 * (d.y - d.x) / 60.0
				img.set_pixel(x, y, col.darkened(clampf(shade, -0.3, 0.4)) if shade > 0.0 else col.lightened(-shade))
			elif l < wob:
				img.set_pixel(x, y, dark)
	var tex := ImageTexture.create_from_image(img)
	_icons[id] = tex
	return tex
