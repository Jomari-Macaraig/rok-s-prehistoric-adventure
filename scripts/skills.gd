class_name Skills
## Hero skill trees (config/skills.cfg; docs/systems/heroes.md#skill-trees).
## Each hero level from 2 up gives one skill point; a hero has three branches
## of five skills (costs 1, 1, 2, 2, 3), each needing the one below; reset is
## free. `learned` (hero -> [skill ids]) is main.skills_learned
## (SaveData.load/save_skills). has(id) answers for the hero being played.

const PATH := "res://config/skills.cfg"
const DEFAULT_COSTS := [1, 1, 2, 2, 3]

static var learned: Dictionary = {}
static var costs: Array = DEFAULT_COSTS
static var trees: Dictionary = {}      # hero -> [branch ids]
static var branches: Dictionary = {}   # branch id -> {name, color, skills}
static var info: Dictionary = {}       # skill id -> {name, text, value}
static var _loaded := false


static func _load() -> void:
	if _loaded:
		return
	_loaded = true
	var c := ConfigFile.new()
	if c.load(PATH) != OK:
		push_warning("Skills: %s missing" % PATH)
		return
	costs = c.get_value("general", "costs", DEFAULT_COSTS)
	for s in c.get_sections():
		var parts := s.split(".")
		if parts.size() != 2:
			continue
		match parts[0]:
			"tree":
				trees[parts[1]] = c.get_value(s, "branches", [])
			"branch":
				branches[parts[1]] = {"name": c.get_value(s, "name", parts[1]), "color": Color(c.get_value(s, "color", "#888888")),
						"skills": c.get_value(s, "skills", [])}
			"skill":
				info[parts[1]] = {"name": c.get_value(s, "name", parts[1]), "text": c.get_value(s, "text", ""),
						"value": c.get_value(s, "value", 1)}


## The hero's branches (ids), [] if it has no tree yet.
static func tree(hero: String) -> Array:
	_load()
	return trees.get(hero, [])


static func has_tree(hero: String) -> bool:
	return not tree(hero).is_empty()


## The branch a skill is in and its place there (0 = bottom), or ["", -1].
static func place(hero: String, sid: String) -> Array:
	for b in tree(hero):
		var i: int = (branches[b].skills as Array).find(sid)
		if i >= 0:
			return [b, i]
	return ["", -1]


static func cost(hero: String, sid: String) -> int:
	var p := place(hero, sid)
	return int(costs[p[1]]) if p[1] >= 0 and p[1] < costs.size() else 0


static func learned_by(hero: String) -> Array:
	return learned.get(hero, [])


static func knows(hero: String, sid: String) -> bool:
	return learned_by(hero).has(sid)


## Points earned: one per level from 2 up.
static func points(hero: String) -> int:
	return Dinos.level(hero) - 1


static func spent(hero: String) -> int:
	var t := 0
	for sid in learned_by(hero):
		t += cost(hero, sid)
	return t


static func free_points(hero: String) -> int:
	return points(hero) - spent(hero)


## Learnable now: in its tree, not learned, the one below learned, enough points.
static func can_learn(hero: String, sid: String) -> bool:
	var p := place(hero, sid)
	if p[1] < 0 or knows(hero, sid):
		return false
	if p[1] > 0 and not knows(hero, String(branches[p[0]].skills[p[1] - 1])):
		return false
	return free_points(hero) >= cost(hero, sid)


## Learn it (the caller saves). Returns true if learned.
static func learn(hero: String, sid: String) -> bool:
	if not can_learn(hero, sid):
		return false
	var a: Array = learned_by(hero).duplicate()
	a.append(sid)
	learned[hero] = a
	return true


## Free reset: every point back.
static func reset(hero: String) -> void:
	learned.erase(hero)


## The hero being played (Rok unless Nira or Boro is on his button).
static func hero() -> String:
	var h: String = Forms.equipped.get(Forms.ROK, "")
	return h if h != "" else "rok"


## Does the hero being played know this skill?
static func has(sid: String) -> bool:
	return knows(hero(), sid)


## A skill's number from the config.
static func value(sid: String, default: Variant = 1.0) -> Variant:
	_load()
	return info.get(sid, {}).get("value", default)


static func name_of(sid: String) -> String:
	_load()
	return String(info.get(sid, {}).get("name", sid))


static func text_of(sid: String) -> String:
	_load()
	return String(info.get(sid, {}).get("text", ""))


## Skills that change the hero's form data (so Forms builds it).
static func changes_form(hero_id: String) -> bool:
	return knows(hero_id, "air_step")
