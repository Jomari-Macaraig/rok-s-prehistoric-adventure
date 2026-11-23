class_name Hunters
## The predator chasing Rok changes with the zone, so the chase doesn't get
## samey. Each hunter has its own way of hunting:
##   charge_rate  - extra px/s it gains while charging (main._charge_step)
##   charge_time  - how long its charges last (s)
##   tint         - placeholder look until its own art exists
## main.hunter_id is the current one; main._hunter_step swaps it at zone
## borders (a roar and a banner) and Trex.set_hunter changes the art.
##
## Art: assets/hunters/<id>/{idle,run,roar,bite}.png + assets/hunters/hunters.json
## (frame, pivot, snout) when the user's sheets are imported; until then every
## hunter uses the T-rex's sheets, tinted. See tools/CLAUDE.md for the spec.

const DATA := {
	"trex": {"zone": "forest", "name": "T-rex", "charge_rate": 45.0, "charge_time": 4.0,
		"tint": Color(1, 1, 1), "blurb": "the king of the forest: steady, with long charges"},
	"carnotaurus": {"zone": "desert", "name": "Carnotaurus", "charge_rate": 65.0, "charge_time": 3.0,
		"tint": Color(1.3, 0.72, 0.62), "blurb": "a desert sprinter: short, fierce charges"},
	"allosaurus": {"zone": "volcanic", "name": "Allosaurus", "charge_rate": 40.0, "charge_time": 5.0,
		"tint": Color(1.18, 0.95, 0.62), "blurb": "relentless: the longest charges of all"},
}


static func for_zone(zid: String) -> String:
	for z in [zid, Zones.kin(zid)]:   # a zone without its own hunter: its kin's (the Canyon: the Desert's)
		for id in DATA:
			if DATA[id].zone == z:
				return id
	return "trex"


static func has_art(id: String) -> bool:
	return id == "trex" or ResourceLoader.exists("res://assets/hunters/%s/run.png" % id)


static var _meta := {}
static var _frames := {}


static func _hunter_meta(id: String) -> Dictionary:
	if _meta.is_empty() and FileAccess.file_exists("res://assets/hunters/hunters.json"):
		_meta = JSON.parse_string(FileAccess.get_file_as_string("res://assets/hunters/hunters.json"))
	return _meta.get(id, {})


## Its idle/run/roar/bite frames (the T-rex's until it has its own art).
static func frames(id: String) -> SpriteFrames:
	if id == "trex" or not has_art(id) or _hunter_meta(id).is_empty():
		return SpriteLib.trex()
	if _frames.has(id):
		return _frames[id]
	var m := _hunter_meta(id)
	var fs := Vector2(m.frame[0], m.frame[1])
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	for anim in ["idle", "run", "roar", "bite"]:
		var tex: Texture2D = load("res://assets/hunters/%s/%s.png" % [id, anim])
		SpriteLib._sheet_frames(sf, anim, tex, fs, m.times[anim], anim == "idle" or anim == "run")
	_frames[id] = sf
	return sf


static func pivot(id: String) -> Vector2:
	var m := _hunter_meta(id)
	return Trex.PIVOT if m.is_empty() or not has_art(id) else Vector2(m.pivot[0], m.pivot[1])


## Snout x relative to the feet, in game px (where the chase gap is measured from).
static func snout(id: String) -> float:
	var m := _hunter_meta(id)
	return Trex.SNOUT if m.is_empty() or not has_art(id) else float(m.snout)


## The tint while it borrows the T-rex's art.
static func tint(id: String) -> Color:
	return Color.WHITE if id == "trex" or (has_art(id) and not _hunter_meta(id).is_empty()) else DATA[id].tint
