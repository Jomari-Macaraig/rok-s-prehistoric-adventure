class_name Economy
## What things are worth and what the Market pays for them (the user's
## economy: selling pays 80% of an item's value). Numbers in
## config/economy.cfg. Sellable things are "sell ids":
##   "sell:gear:<copy id>"   a crafted weapon or armor copy (not equipped)
##   "sell:mat:<material>"   one piece of a material
##   "sell:card:<dino id>"   one spare dinosaur card (not slotted in a weapon)

const PATH := "res://config/economy.cfg"
const DEFAULTS := {
	"sell": {"share": 0.8},
	"value": {"material_by_rarity": [8, 20, 45, 110, 280], "gear_min_share": 0.3, "card_by_tier": [60, 80, 140, 260, 500]},
}
const PREFIX := "sell:"
static var _v := {}


static func num(section: String, key: String) -> Variant:
	if _v.is_empty():
		_v = DEFAULTS.duplicate(true)
		var c := ConfigFile.new()
		if c.load(PATH) == OK:
			for sec in c.get_sections():
				if not _v.has(sec):
					_v[sec] = {}
				for k in c.get_section_keys(sec):
					_v[sec][k] = c.get_value(sec, k)
	return _v.get(section, {}).get(key, DEFAULTS.get(section, {}).get(key, 0))


## Test hook.
static func set_value(section: String, key: String, value: Variant) -> void:
	num(section, key)
	_v[section][key] = value


## One piece of a material.
static func material_value(m: String) -> float:
	var price := int(Crafting.mat(m).price)
	if price > 0 and Crafting.bundle() > 0:
		return float(price) / float(Crafting.bundle())
	var t: Array = num("value", "material_by_rarity")
	return float(t[clampi(Crafting.mat_rarity(m), 0, t.size() - 1)])


## A gear copy: its recipe's materials x its rarity's multiplier x the
## durability it has left (never below gear_min_share).
static func gear_value(copy: String) -> float:
	var v := 0.0
	var r := Crafting.recipe(Gear.base(copy))
	for m in r:
		v += material_value(String(m)) * float(r[m])
	v *= Crafting.bonus_mult(Gear.rarity_of(copy))
	var mx := Gear.max_durability(copy)
	if mx > 0:
		v *= maxf(float(Gear.durability(copy)) / float(mx), float(num("value", "gear_min_share")))
	return v


static func card_value(d: String) -> float:
	var t: Array = num("value", "card_by_tier")
	return float(t[clampi(Dinos.tier(d), 0, t.size() - 1)])


## The full value of a sell id.
static func value(sid: String) -> float:
	var kind := sid.get_slice(":", 1)
	var what := sid.substr(PREFIX.length() + kind.length() + 1)
	match kind:
		"gear": return gear_value(what)
		"mat": return material_value(what)
		"card": return card_value(what)
	return 0.0


## What the Market pays: `share` (80%) of the value, at least 1 meat.
static func sell_price(sid: String) -> int:
	return maxi(1, int(round(value(sid) * float(num("sell", "share")))))


## Everything the player can sell now, in shelf order: gear, cards, materials.
static func sellables(owned: Array, equipped: Dictionary, materials: Dictionary) -> Array:
	var out: Array = []
	var worn_now: Array = []
	for h in equipped:
		worn_now.append_array((equipped[h] as Dictionary).values())
	for c in owned:
		if Gear.has(String(c)) and not worn_now.has(c):
			out.append(PREFIX + "gear:" + String(c))
	var ds: Array = Gear.cards.keys().filter(func(d): return Gear.free_cards(String(d)) > 0)
	ds.sort()
	for d in ds:
		out.append(PREFIX + "card:" + String(d))
	for m in Crafting.materials():
		if int(materials.get(m, 0)) > 0:
			out.append(PREFIX + "mat:" + String(m))
	return out


## Its name, icon and how many there are, for the shelf.
static func name_of(sid: String) -> String:
	var kind := sid.get_slice(":", 1)
	var what := sid.substr(PREFIX.length() + kind.length() + 1)
	match kind:
		"gear": return Gear.full_name(what)
		"mat": return Crafting.mat_name(what)
		"card": return Herd.name_of(what) + " Card"
	return sid


static func icon_of(sid: String) -> Texture2D:
	var kind := sid.get_slice(":", 1)
	var what := sid.substr(PREFIX.length() + kind.length() + 1)
	match kind:
		"gear": return Gear.icon(what)
		"mat": return Crafting.icon(what)
		"card": return Gear.icon(Gear.CARD_PREFIX + what)
	return null
