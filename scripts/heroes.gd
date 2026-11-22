class_name Heroes
## The heroes: Rok and the two you can buy in the Market, Nira (a quick scout)
## and Boro (a sturdy guardian). The hero is Rok's human form: whichever is
## equipped (main.equip, saved as "hero") runs on the ROK button and turns into
## the dinosaurs. Each has the same 17-point attribute budget as an original
## dinosaur (Dinos.HERO_STATS), its own levels and XP. Nira's and Boro's art and
## measured bounds come from assets/heroes/heroes.json (tools/prepare_heroes.gd);
## Rok keeps his own sheets (Forms.DATA[ROK]).

const IDS := ["rok", "nira", "boro"]
const DIR := "res://assets/heroes"
const INFO := {
	"rok": {"name": "Rok", "role": "All-rounder", "blurb": "The hero: steady at everything."},
	"nira": {"name": "Nira", "role": "Scout", "blurb": "A quick scout: fast and springy, but fragile."},
	"boro": {"name": "Boro", "role": "Guardian", "blurb": "A sturdy guardian: slow, but strong and tough."},
}

static var _data := {}


static func _load() -> void:
	if not _data.is_empty():
		return
	var path := DIR + "/heroes.json"
	if FileAccess.file_exists(path):
		_data = JSON.parse_string(FileAccess.get_file_as_string(path))


static func is_hero(id: String) -> bool:
	return INFO.has(id)


## A hero you buy (Nira, Boro) whose art is imported. Rok isn't one: he's free.
static func has(id: String) -> bool:
	_load()
	return id != "rok" and _data.has(id)


## Imported art and bounds for Nira or Boro (frame, pivot, times, stand, slide).
static func play(id: String) -> Dictionary:
	_load()
	return _data[id]


static func name_of(id: String) -> String:
	return String(INFO[id].name)


static func role_of(id: String) -> String:
	return String(INFO[id].role)
