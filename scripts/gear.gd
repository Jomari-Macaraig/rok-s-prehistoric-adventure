class_name Gear
## Hero gear (the user's design): each hero (Rok, Nira, Boro) has a Weapon
## slot and an Armor slot. Weapons and armor are CRAFTED at the Crafting
## Bench from materials (Crafting; recipes in config/crafting.cfg, learned at
## the item's [market_unlocks] distance) and add attributes to the hero
## wearing them (`bonus`, used by Dinos.stat, so levels, perks and form_data
## all see them). A weapon also sets how far ATTACK reaches (`reach`).
## Every crafted item is its own COPY with a rarity (0 Common .. 4
## Legendary) that multiplies its bonuses and durability: its id is the
## item id plus "#<n>" ("stone_axe#3"); `base(id)` gives the item id. Gear
## from old saves has no "#" and is Common.
## Dinosaur CARDS aren't equipped (the user's rule, 2026-11-23): they're
## SLOTTED into a weapon. Each weapon has a card slot or not
## (config/crafting.cfg [card_slots], `card_slots`), and a slot can stay empty.
## One card per dinosaur (the playable four and the 28 expansion species),
## dropped by wild dinosaurs and found in milestone chests. A slotted card adds
## CARD_BONUS (by the dinosaur's tier) to its category's lean attribute (Runner
## Speed, Smasher Power, Tank Armor, Flyer Jump) on top of the weapon's own
## bonuses, while the weapon is equipped and not broken. `sockets` (main.
## gear_sockets, saved) maps a weapon copy to its card's dinosaur; a card in a
## weapon is used up until it's taken out (`free_cards`).
## State lives in main (`gear_owned`, `gear_equipped`, `cards`), saved by
## SaveData.load/save_gear; main keeps these static vars pointing at it.
## Art: icons are drawn in code until the user supplies them (tools/CLAUDE.md).

## id -> name, slot, attribute bonuses, reach (weapons), default price and
## on-sale distance, and a line of text.
const ITEMS := {
	"club": {"name": "Wooden Club", "slot": "weapon", "bonus": {"power": 1.0}, "reach": 165.0, "durability": 30,
		"price": 240, "unlock_m": 0, "desc": "A sturdy branch. Whacks small hazards a little harder."},
	"stone_axe": {"name": "Stone Axe", "slot": "weapon", "bonus": {"power": 2.0}, "reach": 175.0, "durability": 40,
		"price": 600, "unlock_m": 1200, "desc": "Chops through logs and thorn bushes."},
	"flint_spear": {"name": "Flint Spear", "slot": "weapon", "bonus": {"power": 1.5, "speed": 1.0}, "reach": 250.0, "durability": 50,
		"price": 1000, "unlock_m": 2600, "desc": "Long reach, and a little faster on your feet."},
	"bone_hammer": {"name": "Bone Hammer", "slot": "weapon", "bonus": {"power": 3.5, "speed": -0.5}, "reach": 170.0, "durability": 60,
		"price": 1600, "unlock_m": 4200, "desc": "Heavy enough to smash fences and boulders."},
	"sling": {"name": "Sling", "slot": "weapon", "bonus": {"power": 1.0, "jump": 1.0}, "reach": 340.0, "durability": 80,
		"price": 2200, "unlock_m": 6000, "desc": "Hits from far away, and you travel light."},
	"torch": {"name": "Torch", "slot": "weapon", "bonus": {"power": 1.0}, "reach": 185.0, "durability": 45, "burns": true,
		"price": 1300, "unlock_m": 3400, "desc": "Burns through logs, fences, thorns and vines, whatever your Power."},
	"bow": {"name": "Bow", "slot": "weapon", "bonus": {"power": 2.0}, "reach": 460.0, "durability": 70, "ranged": true,
		"price": 2800, "unlock_m": 7400, "desc": "Shoots flint arrows at things far ahead: the longest reach."},
	"hide_vest": {"name": "Hide Vest", "slot": "armor", "bonus": {"armor": 1.0},
		"price": 240, "unlock_m": 0, "desc": "Softens trips and bumps."},
	"bone_guards": {"name": "Bone Guards", "slot": "armor", "bonus": {"armor": 2.0},
		"price": 700, "unlock_m": 1800, "desc": "Arm and shin guards of carved bone."},
	"scale_mail": {"name": "Scale Mail", "slot": "armor", "bonus": {"armor": 2.5, "stamina": 0.5},
		"price": 1300, "unlock_m": 3600, "desc": "Overlapping dinosaur scales: tough and light."},
	"shell_plate": {"name": "Shell Plate", "slot": "armor", "bonus": {"armor": 3.5, "speed": -0.5},
		"price": 2000, "unlock_m": 5400, "desc": "A great shell on your back. Crashes barely hurt."},
}
## The Market's Card Pack: a random dinosaur card (can be bought again and again).
## A weapon's attack style (config/crafting.cfg [weapon_styles]): "swing",
## "thrust", "throw", "shoot", "fist", or "" for anything else.
static func style(id: String) -> String:
	var v: Variant = Crafting.num("weapon_styles", base(id))
	return v if v is String else ""


## The bare-hands attack: the hero's Fist style clip, or "" without one (or
## with styles off): then a code-drawn lunge and slash.
static func fist_clip(hero: String) -> String:
	if not bool(Crafting.num("weapon_styles", "use_styles")):
		return ""
	return "style_fist" if SpriteLib.attack_meta(hero).has("style_fist") else ""


## How big a weapon draws in a style clip ([weapon_styles] scale, or
## "<id>_scale" for that weapon).
static func style_scale(id: String) -> float:
	var v: Variant = Crafting.num("weapon_styles", base(id) + "_scale")
	if not (v is float or v is int) or float(v) <= 0.0:
		v = Crafting.num("weapon_styles", "scale")
	return float(v) if (v is float or v is int) and float(v) > 0.0 else 1.0


## The style clip a hero swings this weapon with ("style_swing"), or "" if
## styles are off or the hero has no clip for it yet (then the old clip
## with the weapon drawn in plays).
static func style_clip(hero: String, id: String) -> String:
	if not bool(Crafting.num("weapon_styles", "use_styles")):
		return ""
	var s := style(id)
	return ("style_" + s) if s != "" and SpriteLib.attack_meta(hero).has("style_" + s) else ""


const CARD_PACK := "card_pack"
const CARD_PACK_PRICE := 350
## Card bonus to the lean attribute, by the dinosaur's tier (0 original, 1-4 Starter..Legend).
const CARD_BONUS := [1.0, 1.0, 1.5, 2.0, 3.0]
const CARD_PREFIX := "card:"

static var owned: Array = []          # gear copy ids (main.gear_owned)
static var rarity: Dictionary = {}    # copy id -> rarity 0-4 (missing = 0 Common; main.gear_rarity)
static var equipped: Dictionary = {}  # hero id -> {"weapon": id or "card:<dino>", "armor": id}
static var cards: Dictionary = {}     # dino id -> how many (main.cards)
static var sockets: Dictionary = {}   # weapon copy id -> the dino id of the card slotted in it (main.gear_sockets)
## Weapon durability (the user's design): every ATTACK that connects costs 1;
## at 0 the weapon is broken (no bonus, no reach, not drawn) until repaired
## at the Camp for meat. id -> uses left (missing = new). main.gear_wear.
static var wear: Dictionary = {}
## A weapon warns when this many uses are left (repairs cost materials:
## Crafting.repair_cost, config/crafting.cfg [repair]).
const WEAR_WARN := 5


## The item id of a copy ("stone_axe#3" -> "stone_axe"); cards unchanged.
static func base(id: String) -> String:
	if id.begins_with(CARD_PREFIX):
		return id
	var i := id.find("#")
	return id if i < 0 else id.substr(0, i)


static func has(id: String) -> bool:
	return ITEMS.has(base(id))


static func slot_of(id: String) -> String:
	if id.begins_with(CARD_PREFIX):
		return "weapon"
	return String(ITEMS[base(id)].slot)


static func name_of(id: String) -> String:
	if id.begins_with(CARD_PREFIX):
		return Herd.name_of(id.substr(CARD_PREFIX.length())) + " Card"
	return String(ITEMS[base(id)].name) if ITEMS.has(base(id)) else id


## A copy's rarity, 0 Common .. 4 Legendary (cards: 0).
static func rarity_of(id: String) -> int:
	return int(rarity.get(id, 0))


## "Epic Stone Axe" (just "Stone Axe" for Common and for cards).
static func full_name(id: String) -> String:
	var r := rarity_of(id)
	return name_of(id) if r == 0 or not has(id) else "%s %s" % [Crafting.rarity_name(r), name_of(id)]


## The attribute bonuses an item gives.
static func item_bonus(id: String) -> Dictionary:
	if id.begins_with(CARD_PREFIX):
		var d := id.substr(CARD_PREFIX.length())
		var lean: String = String(Dinos.CATEGORIES[Dinos.category_of(d)].lean)
		return {lean: float(CARD_BONUS[clampi(Dinos.tier(d), 0, CARD_BONUS.size() - 1)])}
	if not ITEMS.has(base(id)):
		return {}
	var k := Crafting.bonus_mult(rarity_of(id))
	var out := {}
	var b: Dictionary = ITEMS[base(id)].bonus
	for a in b:
		out[a] = snappedf(float(b[a]) * k, 0.1) if float(b[a]) > 0.0 else float(b[a])   # rarity boosts the good, not the drawbacks
	return out


## "+2 Power, +1 Speed".
static func bonus_text(id: String) -> String:
	var parts: Array = []
	var b := item_bonus(id)
	for a in Dinos.ATTRS:
		if b.has(a):
			parts.append("%s%s %s" % ["+" if float(b[a]) > 0.0 else "", Dinos.fmt(float(b[a])), Dinos.ATTR_NAMES[a]])
	return ", ".join(parts)


## How many hits a weapon takes in all (0 = it doesn't wear: armor, cards).
static func max_durability(id: String) -> int:
	if not ITEMS.has(base(id)):
		return 0
	return int(round(float(ITEMS[base(id)].get("durability", 0)) * Crafting.durability_mult(rarity_of(id))))


static func durability(id: String) -> int:
	return int(wear.get(id, max_durability(id)))


static func broken(id: String) -> bool:
	return max_durability(id) > 0 and durability(id) <= 0


## Materials to repair it to full ({} if it isn't worn).
static func repair_cost(id: String) -> Dictionary:
	var mx := max_durability(id)
	if mx <= 0 or durability(id) >= mx:
		return {}
	return Crafting.repair_cost(base(id), mx - durability(id), mx)


## A working (not broken) weapon with this property ("burns", "ranged"), or "".
static func weapon_with(hero: String, prop: String) -> String:
	var w := slot_item(hero, "weapon")
	return w if ITEMS.has(base(w)) and ITEMS[base(w)].get(prop, false) and not broken(w) else ""


static func slot_item(hero: String, slot: String) -> String:
	return String(equipped.get(hero, {}).get(slot, ""))


static func has_any(hero: String) -> bool:
	return slot_item(hero, "weapon") != "" or slot_item(hero, "armor") != ""


## Everything a hero's gear adds to one attribute (a weapon's slotted card included).
static func bonus(hero: String, attr: String) -> float:
	var t := 0.0
	for slot in ["weapon", "armor"]:
		var id := slot_item(hero, slot)
		if id != "" and not broken(id):
			t += float(item_bonus(id).get(attr, 0.0))
			if socketed(id) != "":
				t += float(item_bonus(CARD_PREFIX + socketed(id)).get(attr, 0.0))
	return t


## How many card slots a weapon has (config/crafting.cfg [card_slots]; 0 = none).
static func card_slots(id: String) -> int:
	if not ITEMS.has(base(id)) or ITEMS[base(id)].slot != "weapon":
		return 0
	var key := base(id) if Crafting.has_key("card_slots", base(id)) else "default"
	return int(Crafting.num("card_slots", key)) if Crafting.has_key("card_slots", key) else 1


## The dinosaur whose card is slotted in this weapon copy, or "".
static func socketed(id: String) -> String:
	return String(sockets.get(id, ""))


## Cards of a dinosaur not slotted in any weapon.
static func free_cards(dino: String) -> int:
	return int(cards.get(dino, 0)) - sockets.values().count(dino)


## Dinosaurs with a free card, sorted.
static func card_choices() -> Array:
	var ids: Array = cards.keys().filter(func(d): return free_cards(String(d)) > 0)
	ids.sort()
	return ids


## How far ahead the hero's ATTACK reaches (bare hands without a weapon).
static func reach(hero: String) -> float:
	var w := slot_item(hero, "weapon")
	return float(ITEMS[base(w)].reach) if ITEMS.has(base(w)) and not broken(w) else Tuning.ATTACK_REACH_HAND


## A random dinosaur card for a chest or Card Pack: rare chests the lower
## tiers, epic ones any tier (the higher tiers more often).
static func random_card(epic: bool) -> String:
	var pool: Array = []
	for f in Forms.ORDER:
		if f != Forms.ROK:
			pool.append(Forms.DATA[f].id)
	for d in Dinos.ids():
		var t := Dinos.tier(d)
		if epic or t <= 2:
			for i in (1 + t if epic else 1):
				pool.append(d)
	return pool.pick_random()


## Gear a hero could put in a slot: owned weapons or armor (cards go in a
## weapon's card slot instead: card_choices).
static func choices(slot: String) -> Array:
	var out: Array = owned.filter(func(id): return ITEMS.has(base(id)) and ITEMS[base(id)].slot == slot)
	out.sort_custom(func(a, b): return [ITEMS.keys().find(base(a)), -rarity_of(a)] < [ITEMS.keys().find(base(b)), -rarity_of(b)])
	return out



static var _icons := {}


## An icon drawn in code (until the user's gear art exists:
## assets/gear/<id>.png): a weapon on a round badge, armor on a shield, a
## card shows its dinosaur, a Card Pack a fan of cards.
static func icon(id: String) -> Texture2D:
	id = base(id)
	var path := "res://assets/gear/%s.png" % id
	if ResourceLoader.exists(path):
		return SpriteLib.tex(path)   # uses its sharper @2x twin when there is one
	if id.begins_with(CARD_PREFIX):   # the user's card art, else the dinosaur's portrait
		var card := CardView.art(id.substr(CARD_PREFIX.length()))
		return card if card else Herd.icon_of(id.substr(CARD_PREFIX.length()))
	if _icons.has(id):
		return _icons[id]
	var img := Image.create(96, 96, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var wood := Color(0.55, 0.33, 0.15)
	var stone := Color(0.62, 0.6, 0.58)
	var bone := Color(0.95, 0.9, 0.78)
	var dark := Color(0.3, 0.17, 0.07)
	if id == CARD_PACK:
		for k in 3:
			var r := Rect2i(18 + k * 10, 14 + k * 6, 44, 62)
			img.fill_rect(r.grow(2), dark)
			img.fill_rect(r, [Color(0.85, 0.75, 0.55), Color(0.95, 0.85, 0.6), Color(1.0, 0.92, 0.7)][k])
		img.fill_rect(Rect2i(48, 44, 16, 16), Color(0.8, 0.35, 0.15))
	elif ITEMS.has(id) and ITEMS[id].slot == "armor":
		var col: Color = {"hide_vest": Color(0.7, 0.48, 0.28), "bone_guards": bone, "scale_mail": Color(0.4, 0.6, 0.45), "shell_plate": Color(0.55, 0.45, 0.35)}.get(id, wood)
		for y in 80:
			var half := int(36.0 * (1.0 - pow(maxf(0.0, (y - 40.0) / 40.0), 2.0)))
			img.fill_rect(Rect2i(48 - half - 3, 8 + y, half * 2 + 6, 1), dark)
			img.fill_rect(Rect2i(48 - half, 8 + y, half * 2, 1), col)
		img.fill_rect(Rect2i(44, 16, 8, 64), col.darkened(0.25))
	else:
		# a handle, and a head that says which weapon
		for i in 64:
			img.fill_rect(Rect2i(20 + i, 78 - i, 7, 7), dark)
			img.fill_rect(Rect2i(21 + i, 79 - i, 5, 5), wood)
		match id:
			"stone_axe":
				img.fill_rect(Rect2i(56, 10, 30, 26), dark)
				img.fill_rect(Rect2i(58, 12, 26, 22), stone)
			"flint_spear":
				for i in 20:
					img.fill_rect(Rect2i(72 + i / 2, 4 + i, 14 - i * 2 / 3, 2), stone.darkened(0.2))
			"bone_hammer":
				img.fill_rect(Rect2i(54, 8, 36, 28), dark)
				img.fill_rect(Rect2i(56, 10, 32, 24), bone)
			"sling":
				for a in 24:
					var p := Vector2(66, 26) + Vector2.from_angle(TAU * a / 24.0) * 16.0
					img.fill_rect(Rect2i(int(p.x), int(p.y), 4, 4), dark)
				img.fill_rect(Rect2i(60, 20, 12, 12), stone)
			_:   # club: a thick end
				img.fill_rect(Rect2i(60, 6, 28, 28), dark)
				img.fill_rect(Rect2i(62, 8, 24, 24), wood.lightened(0.15))
	var tex := ImageTexture.create_from_image(img)
	_icons[id] = tex
	return tex
