class_name Hearts
## Rok's health: Tuning.MAX_HEARTS hearts, each split into QUARTERS
## (main.health counts quarters). Every hit costs quarters (main._hurt) by
## the obstacle's DAMAGE TIER (config/damage.cfg, the user's design: light,
## medium, heavy, severe, deadly) times (1 - Armor / armor_divisor), rounded
## up, never below one quarter, using the Armor of the form Rok is in (Rok
## has attributes too). A shield (armor 10 on a non-Tank, the Spinosaurus's)
## blocks a crash first. Out of quarters, the run ends. Pits, water, lava,
## quicksand, dino gates and being caught stay instant (the user's rule).
## Rare heart pickups heal one heart (course.gd; odds in config/pickups.cfg [spots] heart).
##
## Art: assets/items/heart_<full|three|half|quarter|empty>.png when the user
## supplies it, otherwise hearts drawn in code.

const QUARTERS := 4
const PATH := "res://config/damage.cfg"
## Fallbacks for anything config/damage.cfg leaves out.
const DEFAULT_TIERS := {"light": 1, "medium": 2, "heavy": 4}
const DEFAULT_OBSTACLES := {
	"small": "light", "mushroom": "light", "thorns": "light", "steam": "light",
	"vine": "medium", "log": "medium", "fence": "medium", "stampede": "medium", "swooper": "medium",
	"boulder": "heavy", "tall_fence": "heavy", "wall": "heavy", "ledge": "heavy", "rolling_boulder": "heavy",
}
## The order tiers are listed in (lightest first).
const TIER_ORDER := ["light", "medium", "heavy"]
const RED := Color(0.9, 0.18, 0.2)
const OUTLINE := Color(0.32, 0.08, 0.06)
const EMPTY := Color(0.2, 0.1, 0.08, 0.55)
const ART := ["empty", "quarter", "half", "three", "full"]

static var _icons := {}
static var _cfg := {}


static func _load() -> void:
	if not _cfg.is_empty():
		return
	_cfg = {"tiers": DEFAULT_TIERS.duplicate(), "obstacles": DEFAULT_OBSTACLES.duplicate(),
			"armor_divisor": 20.0}
	var c := ConfigFile.new()
	if c.load(PATH) != OK:
		return
	for k in c.get_section_keys("tiers") if c.has_section("tiers") else []:
		_cfg.tiers[k] = int(c.get_value("tiers", k))
	for k in c.get_section_keys("obstacles") if c.has_section("obstacles") else []:
		_cfg.obstacles[k] = String(c.get_value("obstacles", k))
	_cfg.armor_divisor = float(c.get_value("armor", "armor_divisor", 20.0))


## An obstacle's damage tier ("light" ... "deadly"; unknown ones are light).
static func tier(obstacle: String) -> String:
	_load()
	return String(_cfg.obstacles.get(obstacle, "light"))


## Base cost of an obstacle in quarter hearts (its tier's, before Armor).
static func base(obstacle: String) -> int:
	_load()
	return int(_cfg.tiers.get(tier(obstacle), 1))


## Every obstacle of a tier, in config order.
static func in_tier(t: String) -> Array:
	_load()
	return (_cfg.obstacles as Dictionary).keys().filter(func(k): return _cfg.obstacles[k] == t)


## Quarter hearts hitting `obstacle` costs at this Armor (1-10).
static func damage(obstacle: String, armor: float) -> int:
	_load()
	return maxi(1, ceili(base(obstacle) * (1.0 - armor / float(_cfg.armor_divisor)) - 0.001))


## The Armor of a form's data (Rok or a dinosaur, levels included).
static func armor_of(d: Dictionary) -> float:
	var id: String = d.get("id", "rok")
	return Dinos.stat(id, "armor") if Dinos.known(id) else 1.0


## "¼ heart", "½ heart", "¾ heart", "1 heart", "1¼ hearts"...
static func text(quarters: int) -> String:
	var whole := quarters / QUARTERS
	var frac: String = ["", "¼", "½", "¾"][quarters % QUARTERS]
	if whole == 0:
		return frac + " heart"
	return "%d%s heart%s" % [whole, frac, "" if quarters == QUARTERS else "s"]


## A heart icon: fill 0 (empty) to 4 (full), filled left to right in quarters.
static var _drain := []      # the drain frames (AtlasTextures), full -> empty
static var _drain_shares := []


## The stone heart's drain frames and each one's red share (tools/prepare_hearts.py),
## [] without the art. The HUD steps through them when a heart loses quarters.
static func drain_frames() -> Array:
	if _drain.is_empty() and FileAccess.file_exists("res://assets/items/heart_drain.json"):
		var m: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/items/heart_drain.json"))
		var tex := SpriteLib.tex("res://assets/items/heart_drain.png")
		var sz := float(m.size)
		_drain_shares = m.shares
		for i in (m.shares as Array).size():
			var at := AtlasTexture.new()
			at.atlas = tex
			at.region = Rect2(i * sz, 0, sz, sz)
			_drain.append(at)
	return _drain


## Drain frames (in order) passing from a heart filled `from` quarters down to `to`.
static func drain_steps(from: int, to: int) -> Array:
	var out := []
	var frames := drain_frames()
	var hi := float(from) / QUARTERS
	var lo := float(to) / QUARTERS
	for i in frames.size():
		var sh := float(_drain_shares[i])
		if sh < hi - 0.02 and sh > lo + 0.02:
			out.append(frames[i])
	return out


static func icon(fill: int) -> Texture2D:
	fill = clampi(fill, 0, QUARTERS)
	var path := "res://assets/items/heart_%s.png" % ART[fill]
	if ResourceLoader.exists(path):
		return SpriteLib.tex(path)   # the user's stone heart (sharp @2x twin)
	if not _icons.has(fill):
		_icons[fill] = _draw(fill)
	return _icons[fill]


## Placeholder heart: the classic implicit heart curve, outlined, with a
## shine; the left `fill` quarters of its width are red.
static func _draw(fill: int) -> Texture2D:
	var n := 64
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var x0 := 5.0
	var x1 := 59.0
	for y in n:
		for x in n:
			var u := (x + 0.5 - 32.0) / 26.0
			var v := (34.0 - (y + 0.5)) / 26.0 + 0.1
			var f := pow(u * u + v * v - 1.0, 3.0) - u * u * v * v * v
			if f > 0.0:
				continue
			var edge := f > -0.06
			var lit := x + 0.5 < x0 + (x1 - x0) * fill / float(QUARTERS)
			var c := OUTLINE if edge else (RED if lit else EMPTY)
			if lit and not edge and u < -0.25 and v > 0.35 and v < 0.75 and u > -0.65:
				c = RED.lightened(0.45)   # shine
			img.set_pixel(x, y, c)
	return ImageTexture.create_from_image(img)
