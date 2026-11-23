class_name ObstacleLooks
## The looks a hazard comes in (a rock, a mushroom, a raptor skull...), each
## with its own NEW banner the first time it's on screen (main._looks_step).
## Read from config/obstacle_looks.cfg: per look its art names, banner name
## and hint, and optionally the lesson whose banner already teaches it.

const PATH := "res://config/obstacle_looks.cfg"

static var _looks := {}     # look id -> {name, hint, lesson}
static var _by_art := {}    # art name -> look id


static func _load() -> void:
	if not _looks.is_empty():
		return
	var c := ConfigFile.new()
	if c.load(PATH) != OK:
		_looks["_"] = {}   # nothing configured: no look banners
		return
	for id in c.get_sections():
		_looks[id] = {"name": String(c.get_value(id, "name", id.capitalize())),
				"hint": String(c.get_value(id, "hint", "")), "lesson": String(c.get_value(id, "lesson", ""))}
		for art in c.get_value(id, "art", []):
			_by_art[String(art)] = id


## The look id for an art name ("Mushrooms_02" -> "mushroom"), or "".
static func for_art(art: String) -> String:
	_load()
	return String(_by_art.get(art, ""))


## A look's data: {name, hint, lesson} ({} if unknown).
static func get_look(id: String) -> Dictionary:
	_load()
	return _looks.get(id, {})


## Every look id, in config order.
static func ids() -> Array:
	_load()
	return _looks.keys().filter(func(k): return k != "_")
