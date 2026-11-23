class_name Critters
## Wild dinosaurs coming Rok's way: a land one (a "stampede", jump it) and a
## flyer (a "swooper" at head height, slide under it). Each zone has its own
## pair, each with its own attributes. Running into one isn't the end: it
## bumps Rok (a stumble, the T-rex gains). Once one gets past Rok it runs into
## the T-rex, which eats it (main._eat_critters): a bite, a "CHOMP!", and the
## T-rex stops to eat, giving back `snack` px of the gap.
##
## The first stampede and the first swooper are lessons (config
## [introductions] stampede / swooper); after that the zone decides which
## species comes, and a species met for the first time gets a NEW banner.
## Art: the expansion species' playable sheets (assets/characters/<id>/) and
## the Pteranodon's own flight sheet, mirrored to face Rok.

## id -> zone, kind ("stampede" or "swooper"), name and attributes:
##   speed  - extra px/s it closes in, on top of the world scrolling
##   scale  - size against its playable art
##   bump   - chase gap the T-rex gains if Rok runs into it
##   snack  - gap Rok wins back while the T-rex eats it
##   height - swoopers: how high its underside flies (px above the ground)
##   bob    - swoopers: how far it bobs up and down (px)
const DATA := {
	"pachycephalosaurus": {"zone": "forest", "kind": "stampede", "name": "Pachycephalosaurus",
		"speed": 150.0, "scale": 1.1, "bump": 95.0, "snack": 50.0, "blurb": "charges head-down"},
	"dimorphodon": {"zone": "forest", "kind": "swooper", "name": "Dimorphodon",
		"speed": 130.0, "scale": 0.85, "bump": 70.0, "snack": 35.0, "height": 102.0, "bob": 14.0, "blurb": "small and quick"},
	"gallimimus": {"zone": "desert", "kind": "stampede", "name": "Gallimimus",
		"speed": 270.0, "scale": 1.3, "bump": 75.0, "snack": 40.0, "blurb": "very fast, but light"},
	"pteranodon": {"zone": "desert", "kind": "swooper", "name": "Pteranodon",
		"speed": 170.0, "scale": 0.95, "bump": 90.0, "snack": 55.0, "height": 98.0, "bob": 24.0, "blurb": "swoops up and down"},
	"kentrosaurus": {"zone": "volcanic", "kind": "stampede", "name": "Kentrosaurus",
		"speed": 200.0, "scale": 1.1, "bump": 130.0, "snack": 80.0, "blurb": "spiky, fast and hits hard"},
	"quetzalcoatlus": {"zone": "volcanic", "kind": "swooper", "name": "Quetzalcoatlus",
		"speed": 90.0, "scale": 1.05, "bump": 120.0, "snack": 90.0, "height": 96.0, "bob": 8.0, "blurb": "a slow giant"},
}


## The species of a kind that lives in a zone.
static func for_zone(zid: String, kind: String) -> String:
	for z in [zid, Zones.kin(zid)]:   # none of its own: its kin zone's
		for id in DATA:
			if DATA[id].zone == z and DATA[id].kind == kind:
				return id
	return ""


static var _frames := {}
static var _bounds := {}


## Its running (or flying) loop, from the species' playable sheet.
static func frames(id: String) -> SpriteFrames:
	if _frames.has(id):
		return _frames[id]
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	var anim := "fly" if DATA[id].kind == "swooper" else "run"
	var tex: Texture2D = load("res://assets/characters/%s/%s.png" % [id, anim])
	var fs := frame_size(id)
	var times: Array = [80, 80, 80, 80, 80, 80, 80, 80]
	if Dinos.playable(id):
		times = Dinos._data[id].play.times[anim]
	elif id == "pteranodon":
		times = Forms.DATA[Forms.PTERANODON].extra_anims.fly
	sf.add_animation("a")
	sf.set_animation_loop("a", true)
	sf.set_animation_speed("a", 1000.0)
	for i in 8:
		var at := AtlasTexture.new()
		at.atlas = tex
		at.region = Rect2(Vector2(i % 4, i / 4) * fs, fs)
		sf.add_frame("a", at, float(times[i]))
	_frames[id] = sf
	return sf


static func frame_size(id: String) -> Vector2:
	if id == "pteranodon":
		return Forms.DATA[Forms.PTERANODON].frame
	Dinos._load()
	return Vector2(Dinos._data[id].play.frame[0], Dinos._data[id].play.frame[1])


static func pivot(id: String) -> Vector2:
	if id == "pteranodon":
		return Forms.DATA[Forms.PTERANODON].pivot
	Dinos._load()
	return Vector2(Dinos._data[id].play.pivot[0], Dinos._data[id].play.pivot[1])


## The art's opaque bounds relative to the feet (pivot), from frame 0,
## measured once: what its hitbox is built from.
static func art_bounds(id: String) -> Rect2:
	if not _bounds.has(id):
		var sf := frames(id)
		var img := (sf.get_frame_texture("a", 0) as AtlasTexture).atlas.get_image()
		var fs := frame_size(id)
		var r := img.get_region(Rect2i(0, 0, int(fs.x), int(fs.y))).get_used_rect()
		_bounds[id] = Rect2(Vector2(r.position) - pivot(id), Vector2(r.size))
	return _bounds[id]
