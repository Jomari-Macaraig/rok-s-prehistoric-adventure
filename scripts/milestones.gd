class_name Milestones
## Dinosaur milestones and evolution (config/milestones.cfg;
## docs/systems/dinosaurs.md#milestones). At set levels a dinosaur learns a
## Trick or a Trait for its own form; at the evolution levels it evolves.
## Everything comes from its level, so nothing extra is saved.

const PATH := "res://config/milestones.cfg"
const DEFAULT_LEVELS := [3, 5, 8, 13, 15, 18]
const DEFAULT_EVOLUTIONS := [10, 20]

static var levels: Array = DEFAULT_LEVELS
static var evolutions: Array = DEFAULT_EVOLUTIONS
static var species: Dictionary = {}   # species id -> {level: milestone id}
static var info: Dictionary = {}      # milestone id -> {name, kind, text, value}
static var _loaded := false


static func _load() -> void:
	if _loaded:
		return
	_loaded = true
	var c := ConfigFile.new()
	if c.load(PATH) != OK:
		push_warning("Milestones: %s missing" % PATH)
		return
	levels = c.get_value("levels", "milestones", DEFAULT_LEVELS)
	evolutions = c.get_value("levels", "evolutions", DEFAULT_EVOLUTIONS)
	for s in c.get_sections():
		var parts := s.split(".")
		if parts.size() != 2:
			continue
		if parts[0] == "species":
			var m := {}
			for k in c.get_section_keys(s):
				m[int(k)] = String(c.get_value(s, k))
			species[parts[1]] = m
		elif parts[0] == "milestone":
			info[parts[1]] = {"name": c.get_value(s, "name", parts[1]), "kind": c.get_value(s, "kind", "trait"),
					"text": c.get_value(s, "text", ""), "value": c.get_value(s, "value", 1)}


## {level: milestone id} for a species ({} if it has none yet).
static func of(id: String) -> Dictionary:
	_load()
	return species.get(id, {})


## Has this dinosaur reached the milestone?
static func knows(id: String, mid: String) -> bool:
	var m := of(id)
	var lv := Dinos.level(id)
	for l in m:
		if m[l] == mid and lv >= int(l):
			return true
	return false


## Milestones it gained going from level `from` (excluded) to `to` (included).
static func gained(id: String, from: int, to: int) -> Array:
	var m := of(id)
	var out: Array = []
	for l in m:
		if int(l) > from and int(l) <= to:
			out.append(m[l])
	return out


## How many times it has evolved (0, 1 or 2) at level `l`.
static func stage_at(id: String, l: int) -> int:
	_load()
	if Heroes.is_hero(id):
		return 0
	return evolutions.filter(func(e): return l >= int(e)).size()


static func stage(id: String) -> int:
	return stage_at(id, Dinos.level(id))


static func value(mid: String, default: Variant = 1.0) -> Variant:
	_load()
	return info.get(mid, {}).get("value", default)


static func name_of(mid: String) -> String:
	_load()
	return String(info.get(mid, {}).get("name", mid))


static func kind_of(mid: String) -> String:
	_load()
	return String(info.get(mid, {}).get("kind", "trait"))


static func text_of(mid: String) -> String:
	_load()
	return String(info.get(mid, {}).get("text", ""))
