class_name Chest
## Milestone chests (the user's pick for long runs): every CHEST_EVERY_M of a
## run a chest sits on flat ground ahead (main._chest_step places it, a
## Pickup of kind "chest"); running into it opens it (main._open_chest).
## Its rarity is rolled here, better the further the run has got, and the
## reward depends on the rarity. Numbers live in tuning.gd (CHEST_*).

const RARITY := ["common", "rare", "epic"]
const RARITY_NAME := {"common": "CHEST", "rare": "RARE CHEST", "epic": "EPIC CHEST"}
const RARITY_COLOR := {"common": Color(0.95, 0.8, 0.5), "rare": Color(0.45, 0.85, 1.0), "epic": Color(1.0, 0.5, 1.0)}
## What each rarity can hold (picked evenly; see main._open_chest).
## "materials" is a handful of crafting materials (config/crafting.cfg [chests]).
const REWARDS := {
	"common": ["meat", "xp", "materials"],
	"rare": ["meat", "xp", "booster", "heart", "card", "materials"],
	"epic": ["meat", "xp", "frenzy", "full_heal", "card", "materials"],
}


## Chance of a rare and of an epic chest at milestone n (1 = the first, at
## CHEST_EVERY_M): both grow with every milestone, up to a cap.
static func chances(n: int) -> Vector2:
	var k := maxi(n - 1, 0)
	var epic := minf(Tuning.CHEST_EPIC_BASE + Tuning.CHEST_EPIC_STEP * k, Tuning.CHEST_EPIC_MAX)
	var rare := minf(Tuning.CHEST_RARE_BASE + Tuning.CHEST_RARE_STEP * k, Tuning.CHEST_RARE_MAX)
	return Vector2(rare, epic)


## Rarity for milestone n, given a roll in 0..1.
static func rarity(n: int, roll: float) -> String:
	var c := chances(n)
	if roll < c.y:
		return "epic"
	if roll < c.y + c.x:
		return "rare"
	return "common"


## Meat in a meat reward: the rarity's base plus a little per milestone.
static func meat(r: String, n: int) -> int:
	return int(Tuning.CHEST_MEAT[RARITY.find(r)]) + maxi(n - 1, 0)


## XP in an XP reward (for the form Rok is in).
static func xp(r: String, n: int) -> int:
	return int(Tuning.CHEST_XP[RARITY.find(r)]) * (1 + maxi(n - 1, 0) / 3)
