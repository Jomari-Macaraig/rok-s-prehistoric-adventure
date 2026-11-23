class_name Requires
## The dependency tree (the user's request): things that only happen once
## something else has happened, all set in config/requirements.cfg. A thing
## with no entry has no requirement.
##
## Things (the left side), checked where they happen:
##   pickup.<kind>    a pickup spawning (Course._pickup): amber, meat, heart, fossil, pepper, any power-up id
##   intro.<key>      a hazard / terrain feature / gate appearing (Progression.available)
##   event.<id>       a mid-run event (RunEvents.pool): golden_hour, meteor_shower, amber_storm, stampede_rush
##   power.<id>       a power-up turning up in a reward spot or a drop (Course._booster)
##   market.<id>      a Market item going on sale (Market.on_sale)
## Requirements (the right side, all must hold):
##   dino             at least one dinosaur unlocked
##   form:<id>        that dinosaur unlocked (raptor, triceratops, spinosaurus, pteranodon)
##   seen:<key>       that lesson / banner already shown (main.seen)
##   best_m:<n>       a best distance of at least n metres
##   owns:<id>        owns that item (power-up, gear, dinosaur, hero)
##   slots:<n>        at least n booster slots open
## main binds itself (Requires.game) so the checks read the live state; with
## no game bound (unit tests of other classes) everything is allowed.

const PATH := "res://config/requirements.cfg"

static var game                 # main.gd, set by main._ready
static var _rules := {}         # thing -> [requirement strings]
static var _loaded := false


static func _load() -> void:
	if _loaded:
		return
	_loaded = true
	_rules = {}
	var c := ConfigFile.new()
	if c.load(PATH) != OK:
		return
	if c.has_section("requires"):
		for key in c.get_section_keys("requires"):
			var v: Variant = c.get_value("requires", key)
			_rules[String(key)] = v if v is Array else [v]


## The requirements listed for a thing ([] = none).
static func of(thing: String) -> Array:
	_load()
	return _rules.get(thing, [])


## May this thing happen now?
static func ok(thing: String) -> bool:
	_load()
	if game == null or not _rules.has(thing):
		return true
	for r in _rules[thing]:
		if not met(String(r)):
			return false
	return true


## Is one requirement met?
static func met(r: String) -> bool:
	if game == null:
		return true
	var kind := r.get_slice(":", 0)
	var arg := r.get_slice(":", 1) if r.contains(":") else ""
	match kind:
		"dino":
			return game.unlocked.any(func(f): return f != Forms.ROK)
		"form":
			for f in game.unlocked:
				if String(Forms.DATA[f].id) == arg:
					return true
			return false
		"seen":
			return game.seen.has(arg)
		"best_m":
			return game.best_m >= float(arg)
		"owns":
			return game.boosters_owned.has(arg) or game.gear_owned.has(arg) or game.dinos_owned.has(arg)
		"slots":
			return game.slot_count >= int(arg)
	push_warning("requirements.cfg: unknown requirement '%s'" % r)
	return true


## A requirement in plain words, e.g. "unlock a dinosaur" (Market lock text).
static func describe(r: String) -> String:
	var kind := r.get_slice(":", 0)
	var arg := r.get_slice(":", 1) if r.contains(":") else ""
	match kind:
		"dino":
			return "unlock a dinosaur"
		"form":
			return "unlock the " + arg.capitalize()
		"seen":
			return "meet the " + arg.replace("_", " ")
		"best_m":
			return "reach %s m in one run" % arg
		"owns":
			return "own the " + Market.item_name(arg)
		"slots":
			return "open %s booster slots" % arg
	return r


## The requirements of a thing that aren't met yet, in plain words.
static func missing(thing: String) -> Array:
	return of(thing).filter(func(r): return not met(String(r))).map(func(r): return describe(String(r)))


## Test hook: set (or with [] clear) one thing's requirements, or reload the file.
static func set_rule(thing: String, reqs: Array) -> void:
	_load()
	if reqs.is_empty():
		_rules.erase(thing)
	else:
		_rules[thing] = reqs


static func reload() -> void:
	_loaded = false
	_load()
