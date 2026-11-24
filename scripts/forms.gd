class_name Forms
## Shapeshift form definitions. Rok can turn into any dinosaur at will while
## he has primal energy; each form clears different obstacles.

enum { ROK, RAPTOR, TRICERATOPS, SPINOSAURUS, PTERANODON }

const ORDER := [ROK, RAPTOR, TRICERATOPS, SPINOSAURUS, PTERANODON]

const DATA := {
	ROK: {
		"id": "rok", "name": "Rok",
		"desc": "Double jump",
		"frame": Vector2(168, 224), "pivot": Vector2(84, 213.5),
		"scale": 1.0, "hitbox": Vector2(56, 140),
		"slide_box": Vector2(76, 92), "duck_box": Vector2(64, 100), "low_squash": 0.82,
		"jump": 1020.0, "air_jumps": 1, "breaks": [],
		"drain": 0.0, "score_mult": 1.0, "armor": 0,
		"speed": 4, "speed_label": "Steady", "chase_rate": 0.0,
		"color": Color(0.95, 0.72, 0.42),
	},
	RAPTOR: {
		"id": "raptor", "name": "Raptor",
		"desc": "Fast: outruns the T-rex, huge leaps, x2 score",
		"frame": Vector2(224, 168), "pivot": Vector2(112, 157.5),
		"scale": 0.92, "hitbox": Vector2(110, 84),
		"slide_box": Vector2(120, 62), "duck_box": Vector2(112, 74), "low_squash": 0.95,
		"jump": 1180.0, "air_jumps": 1, "breaks": [], "light": true, "fast": true,
		"drain": 6.0, "score_mult": 2.0, "armor": 0,
		"speed": 5, "speed_label": "Quick", "chase_rate": 40.0,
		"color": Color(0.55, 0.85, 0.4),
	},
	TRICERATOPS: {
		"id": "triceratops", "name": "Triceratops",
		"desc": "Smashes rocks & logs, but slow",
		"frame": Vector2(224, 168), "pivot": Vector2(112, 157.5),
		"scale": 1.1, "hitbox": Vector2(130, 92),
		"slide_box": Vector2(130, 72), "duck_box": Vector2(130, 80), "low_squash": 0.95,
		"jump": 860.0, "air_jumps": 0, "breaks": ["rock", "wood"],   # small hazards: a Power roll (Dinos.break_chance)
		"drain": 9.0, "score_mult": 1.0, "armor": 0,
		"speed": 3, "speed_label": "Steady", "chase_rate": -8.0,
		"color": Color(0.95, 0.5, 0.25),
	},
	SPINOSAURUS: {
		"id": "spinosaurus", "name": "Spinosaurus",
		"desc": "Tramples fences & thorns, swims, 1 shield, very slow",
		"frame": Vector2(224, 168), "pivot": Vector2(112, 157.5),
		"scale": 1.25, "hitbox": Vector2(130, 92),
		"slide_box": Vector2(130, 64), "duck_box": Vector2(130, 74), "low_squash": 0.9,
		"jump": 920.0, "air_jumps": 0, "breaks": ["fence", "wood", "thorns"],
		"drain": 10.0, "score_mult": 1.0, "armor": 1,
		"speed": 1, "speed_label": "Slow", "chase_rate": -14.0, "swims": true,
		"extra_anims": {"swim": [120, 120, 120, 120, 120, 120, 120, 120]},
		"color": Color(0.35, 0.7, 0.85),
	},
	PTERANODON: {
		"id": "pteranodon", "name": "Pteranodon",
		"desc": "Hold JUMP to fly, fast but hungry",
		"frame": Vector2(224, 224), "pivot": Vector2(112, 213.5),
		"scale": 1.0, "hitbox": Vector2(110, 100), "box_offset_x": 12.0,
		"slide_box": Vector2(120, 56), "duck_box": Vector2(110, 74), "low_squash": 1.0,
		# in flight the art floats above the origin; collide with the torso only
		"fly_box": Vector2(100, 60), "fly_box_bottom": 64.0, "fly_offset_x": 26.0,
		"jump": 780.0, "air_jumps": 0, "breaks": [], "light": true,
		"drain": 13.0, "score_mult": 1.5, "armor": 0, "flies": true,
		"speed": 5, "speed_label": "Quick", "chase_rate": 25.0,
		"extra_anims": {
			"fly": [80, 80, 80, 80, 80, 80, 80, 80],
			"glide": [160, 160, 160, 160, 160, 160, 160, 160],
			"takeoff": [140, 100, 100, 100, 100, 100, 100, 160],
			"land": [140, 100, 100, 100, 100, 100, 100, 180],
		},
		"color": Color(0.92, 0.42, 0.3),
	},
}


## Which species each dino button uses (form -> Dinos id), set from the save
## by main (main.equip). Missing = the button's original dinosaur.
static var equipped: Dictionary = {}
static var _species_cache: Dictionary = {}


## Longest time in the air from flat ground: a full jump, then every air jump
## (0.92x, see Player._do_jump) taken just before touching down.
static func air_time(d: Dictionary, grip := 1.0) -> float:
	var t := 2.0 * float(d.jump) * grip / Tuning.GRAVITY
	if grip >= 1.0:
		t += int(d.air_jumps) * 2.0 * float(d.jump) * 0.92 / Tuning.GRAVITY
	return t


static func get_data(form: int) -> Dictionary:
	var id: String = equipped.get(form, "")
	if id == "" or not Dinos.playable(id):
		id = DATA[form].id
	if id == DATA[form].id and not Dinos.has_levels(id) and not Gear.has_any(id) and not Skills.changes_form(id):
		return DATA[form]   # an unlevelled original plays exactly as written here
	if not _species_cache.has(id):
		_species_cache[id] = Dinos.form_data(form, id)
	return _species_cache[id]


## Forget built form data (after a level-up changes attributes).
static func clear_cache() -> void:
	_species_cache.clear()


## Put a species on a button ("" = back to the original dinosaur).
static func equip(form: int, id: String) -> void:
	if id == "" or id == DATA[form].id:
		equipped.erase(form)
	else:
		equipped[form] = id
