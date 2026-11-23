class_name Chest
## Milestone chests (the user's pick for long runs): every CHEST_EVERY_M of a
## run a chest sits on flat ground ahead (main._chest_step places it, a
## Pickup of kind "chest"); running into it opens it (main._open_chest).
## Its rarity is rolled here when it is placed (so its art shows the tier
## before Rok reaches it), better the further the run has got, and the
## reward depends on the rarity. Numbers: config/pickups.cfg [chests]
## (Loot.num), defaults in tuning.gd (CHEST_*). Art: one chest per tier,
## tools/prepare_chest.py.

const RARITY := ["common", "rare", "ultra_rare", "legendary"]
const RARITY_NAME := {"common": "CHEST", "rare": "RARE CHEST", "ultra_rare": "ULTRA RARE CHEST", "legendary": "LEGENDARY CHEST"}
const RARITY_COLOR := {"common": Color(0.95, 0.8, 0.5), "rare": Color(0.45, 0.85, 1.0),
		"ultra_rare": Color(0.85, 0.5, 1.0), "legendary": Color(1.0, 0.78, 0.25)}


## Tier index 0..3 (common .. legendary).
static func tier(r: String) -> int:
	return maxi(RARITY.find(r), 0)


## What a rarity can hold (picked evenly; see main._open_chest).
static func rewards(r: String) -> Array:
	return Loot.num("chests", "rewards_" + r) as Array


## A reward from a rarity's list, by [chests] reward_weights (cards are kept rare).
static func pick_reward(r: String) -> String:
	var opts := rewards(r)
	var w: Dictionary = Loot.num("chests", "reward_weights") if Loot.num("chests", "reward_weights") is Dictionary else {}
	var total := 0.0
	for o in opts:
		total += float(w.get(o, 1.0))
	var roll := randf() * total
	for o in opts:
		roll -= float(w.get(o, 1.0))
		if roll < 0.0:
			return o
	return opts[-1]


## Chance of each rarer tier at milestone n (1 = the first, at
## CHEST_EVERY_M): each grows with every milestone, up to its cap.
static func chances(n: int) -> Dictionary:
	var k := maxi(n - 1, 0)
	var out := {}
	for r in ["rare", "ultra_rare", "legendary"]:
		var o: Array = Loot.num("chests", r)
		out[r] = minf(float(o[0]) + float(o[1]) * k, float(o[2]))
	return out


## Rarity for milestone n, given a roll in 0..1 (rarest checked first).
static func rarity(n: int, roll: float) -> String:
	var c := chances(n)
	var acc := 0.0
	for r in ["legendary", "ultra_rare", "rare"]:
		acc += float(c[r])
		if roll < acc:
			return r
	return "common"


## Meat in a meat reward: the rarity's base plus a little per milestone.
static func meat(r: String, n: int) -> int:
	return int((Loot.num("chests", "meat") as Array)[tier(r)]) + maxi(n - 1, 0)


## XP in an XP reward (for the form Rok is in).
static func xp(r: String, n: int) -> int:
	return int((Loot.num("chests", "xp") as Array)[tier(r)]) * (1 + maxi(n - 1, 0) / 3)


static func score() -> int:
	return int(Loot.num("chests", "score"))


static func combo_weight() -> int:
	return int(Loot.num("chests", "combo_weight"))
