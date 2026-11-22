class_name Loot
## The rules and odds for amber, meat, hearts, power-ups and fossils: what a
## reward spot holds, how many, where spots are placed, what a broken
## obstacle drops and which power-up turns up. Every number is read from
## config/pickups.cfg (the one file to edit; the user's request), falling
## back to the Tuning default for anything missing. Course and main read the
## values through here (Loot.num / Loot.weights), never the Tuning constants.

const PATH := "res://config/pickups.cfg"

## section -> key -> default (the Tuning constants, so tests and fallbacks agree)
const DEFAULTS := {
	"spots": {
		"heart": Tuning.HEART_SPOT_CHANCE,
		"power": Tuning.POWER_SPOT_CHANCE,
		"meat": Tuning.MEAT_SPOT_CHANCE,
		"mixed": Tuning.MIXED_SPOT_CHANCE,
		"meat_due_m": Tuning.MEAT_DUE_M,
	},
	"counts": {
		"weights": Tuning.SPOT_COUNT_WEIGHTS,
		"island_max": 3,
	},
	"placement": {
		"sky_trail": Tuning.SKY_TRAIL_CHANCE,
		"islands": Tuning.PLATFORM_CHANCE,
		"staircase": 0.45,
		"staircase_from_m": 300.0,
		"arc": Tuning.PICKUP_CHANCE,
		"arc_height": 200.0,
		"trail_height": 290.0,
		"island_min_lift": 160.0,
		"island_max_lift": 240.0,
	},
	"escalation": {
		"big_meat_from_m": Tuning.BIG_MEAT_FROM_M,
		"big_meat_full_m": Tuning.BIG_MEAT_FULL_M,
		"big_meat_max": Tuning.BIG_MEAT_MAX_CHANCE,
		"fossil_from_m": Tuning.FOSSIL_FROM_M,
		"fossil_full_m": Tuning.FOSSIL_FULL_M,
		"fossil_min": Tuning.FOSSIL_MIN_CHANCE,
		"fossil_max": Tuning.FOSSIL_MAX_CHANCE,
	},
	"break_loot": {
		"chance": Tuning.LOOT_CHANCE,
		"heart": Tuning.LOOT_HEART_SHARE,
		"power": Tuning.LOOT_POWER_SHARE,
		"amber_count": Tuning.LOOT_AMBER,
		"in_frenzy": false,
	},
	"power_ups": {
		"egg_share": 0.5,
	},
}

static var _v := {}


static func _load() -> void:
	if not _v.is_empty():
		return
	_v = DEFAULTS.duplicate(true)
	var c := ConfigFile.new()
	if c.load(PATH) != OK:
		return
	for sec in c.get_sections():
		if not _v.has(sec):
			_v[sec] = {}
		for key in c.get_section_keys(sec):
			_v[sec][key] = c.get_value(sec, key)


## A number (or bool) from the config: Loot.num("spots", "heart").
static func num(section: String, key: String) -> Variant:
	_load()
	return _v.get(section, {}).get(key, DEFAULTS.get(section, {}).get(key, 0.0))


## Per-power-up weights from [power_ups] (power-ups not listed weigh 1).
static func booster_weight(kind: String) -> float:
	_load()
	return float(_v.get("power_ups", {}).get(kind, 1.0))


## Test hook: forget the loaded values (the next read loads the file again),
## or set one value for a check.
static func reload() -> void:
	_v = {}


static func set_value(section: String, key: String, value: Variant) -> void:
	_load()
	if not _v.has(section):
		_v[section] = {}
	_v[section][key] = value
