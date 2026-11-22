class_name SaveData

const PATH := "user://rok_runner.cfg"
static var path := PATH   # tests point this at their own file


static func _read(section: String, key: String, default: Variant) -> Variant:
	var c := ConfigFile.new()
	if c.load(path) != OK:
		return default
	return c.get_value(section, key, default)


static func _write(section: String, key: String, v: Variant) -> void:
	var c := ConfigFile.new()
	c.load(path)
	c.set_value(section, key, v)
	c.save(path)


static func load_best() -> int:
	return int(_read("score", "best", 0))


static func save_best(v: int) -> void:
	_write("score", "best", v)


static func load_muted() -> bool:
	return bool(_read("settings", "muted", false))


static func save_muted(m: bool) -> void:
	_write("settings", "muted", m)


static func load_best_m() -> int:
	return int(_read("score", "best_m", 0))


static func save_best_m(v: int) -> void:
	_write("score", "best_m", v)


static func load_unlocked() -> Array:
	var a: Array = _read("progress", "unlocked", [Forms.ROK])
	if not a.has(Forms.ROK):
		a.append(Forms.ROK)
	return a


static func save_unlocked(a: Array) -> void:
	_write("progress", "unlocked", a)


## Banner keys already shown once (so intro banners don't repeat every run).
static func load_seen() -> Array:
	return _read("progress", "seen", [])


static func save_seen(a: Array) -> void:
	_write("progress", "seen", a)


## Field Guide entries already viewed (for the NEW tags / button badge).
static func load_viewed() -> Array:
	return _read("progress", "guide_viewed", [])


static func save_viewed(a: Array) -> void:
	_write("progress", "guide_viewed", a)


## Power-ups the player owns (only these spawn in a run). Starts with the
## starter boosters; the planned market adds to it.
static func load_unlocked_boosters() -> Array:
	var a: Array = _read("progress", "boosters", Boosters.starters())
	for k in Boosters.starters():
		if not a.has(k):
			a.append(k)
	return a


static func save_unlocked_boosters(a: Array) -> void:
	_write("progress", "boosters", a)


## Expansion dinosaurs bought in the Market (Dinos ids).
static func load_dinos_owned() -> Array:
	return _read("progress", "dinos_owned", [])


static func save_dinos_owned(a: Array) -> void:
	_write("progress", "dinos_owned", a)


## Badges: stat -> value and badge id -> tiers earned (0-3).
static func load_badges() -> Array:
	return [_read("progress", "badge_stats", {}), _read("progress", "badge_tiers", {})]


static func save_badges(stats: Dictionary, tiers: Dictionary) -> void:
	_write("progress", "badge_stats", stats)
	_write("progress", "badge_tiers", tiers)


## Which species each category's button uses: category id -> Dinos id.
## Dinosaur levels: id -> {attribute: points added by levelling}.
static func load_dino_levels() -> Dictionary:
	return _read("progress", "dino_levels", {})


static func save_dino_levels(d: Dictionary) -> void:
	_write("progress", "dino_levels", d)


## Dinosaur experience: id -> metres run as it.
static func load_dino_xp() -> Dictionary:
	return _read("progress", "dino_xp", {})


static func save_dino_xp(d: Dictionary) -> void:
	_write("progress", "dino_xp", d)


static func load_equipped() -> Dictionary:
	return _read("progress", "equipped", {})


static func save_equipped(d: Dictionary) -> void:
	_write("progress", "equipped", d)


## Meat banked for the Market (collected in runs, spent on power-ups).
static func load_meat() -> int:
	return int(_read("progress", "meat", 0))


static func save_meat(n: int) -> void:
	_write("progress", "meat", n)


## Market items already looked at while on sale (for the NEW tags).
static func load_market_seen() -> Array:
	return _read("progress", "market_seen", [])


static func save_market_seen(a: Array) -> void:
	_write("progress", "market_seen", a)


## How many booster slots are open (1 to Boosters.MAX_SLOTS).
## Heart Containers bought (each adds a heart), 0-Tuning.HEART_CONTAINERS.
static func load_heart_containers() -> int:
	return clampi(int(_read("progress", "heart_containers", 0)), 0, Tuning.HEART_CONTAINERS)


static func save_heart_containers(n: int) -> void:
	_write("progress", "heart_containers", n)


static func load_booster_slots() -> int:
	return clampi(int(_read("progress", "booster_slots", Boosters.START_SLOTS)), Boosters.START_SLOTS, Boosters.MAX_SLOTS)


static func save_booster_slots(n: int) -> void:
	_write("progress", "booster_slots", n)


## Daily missions (Missions.to_dict / from_dict).
static func load_missions() -> Dictionary:
	var d: Variant = _read("missions", "state", {})
	return d if d is Dictionary else {}


static func save_missions(d: Dictionary) -> void:
	_write("missions", "state", d)


## Hero gear: {"owned": [gear ids], "equipped": {hero: {"weapon", "armor"}}, "cards": {dino: count}}.
static func load_gear() -> Dictionary:
	var d: Variant = _read("gear", "state", {})
	return d if d is Dictionary else {}


static func save_gear(d: Dictionary) -> void:
	_write("gear", "state", d)


## Coach-hint progress (Tutorial.progress: lesson id -> {done, shown}).
static func load_tutorial() -> Dictionary:
	var d: Variant = _read("progress", "tutorial", {})
	return d if d is Dictionary else {}


static func save_tutorial(d: Dictionary) -> void:
	_write("progress", "tutorial", d)


## Whether coach hints are on (the player can switch them off).
static func load_tips() -> bool:
	return bool(_read("settings", "tips", true))


static func save_tips(on: bool) -> void:
	_write("settings", "tips", on)


## The training run (tutorial_run.gd) has been played or skipped: it plays once.
static func load_tutorial_run_done() -> bool:
	return bool(_read("progress", "tutorial_run_done", false))


static func save_tutorial_run_done(done: bool) -> void:
	_write("progress", "tutorial_run_done", done)
