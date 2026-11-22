class_name Badges
## Badges: long-term goals with Bronze, Silver and Gold tiers. Each tracks one
## stat, and every stat needs the course: something you can't farm by
## mashing a button (no "slide N times" or "transform N times"). "total" stats add up over every run (rocks smashed, meat collected...),
## "best" stats are the best single run (distance, distance without a
## stumble...) or a current count (dinosaurs owned). Reaching a tier pays
## TIER_REWARD meat straight into the bank (main._award_badges).
##
## main owns the numbers: main.badge_stats (stat -> value, saved) and
## main.badge_tiers (badge id -> tiers earned 0-3, saved). Events come in
## through main.badge_event(stat, amount) and main.badge_best(stat, value).
##
## Art: icon(id, tier) uses assets/badges/<id>_<tier>.png when it exists
## (tier 1-3 = bronze, silver, gold; 0 = not earned yet), otherwise a medal
## drawn in code in the tier's colour.

const TIERS := ["Bronze", "Silver", "Gold"]
const TIER_COLORS := [Color(0.8, 0.5, 0.25), Color(0.78, 0.8, 0.86), Color(1.0, 0.8, 0.2)]
const TIER_REWARD := [20, 50, 120]    # meat for reaching bronze, silver, gold (kept small: runs are the main income)

## id -> name, what to do ("%d" = the target), stat, kind and tier targets.
## Targets are long-term: Bronze takes a few runs of doing that thing on
## purpose, Silver tens of runs, Gold is mastery. (At the first targets a
## couple of casual runs earned most Bronzes and several Silvers.)
const DATA := {
	# category badges (Dinos.CATEGORY_BADGE): playing a category unlocks its higher tiers
	# perk badges (PERKS): each tier earned gives a permanent bonus
	"scorer": {"name": "Point Hunter", "desc": "Score %d points in total", "stat": "points", "kind": "total", "tiers": [25000, 150000, 600000]},
	"veteran": {"name": "Seasoned", "desc": "Earn %d dinosaur XP in total", "stat": "xp", "kind": "total", "tiers": [2000, 12000, 50000]},
	"swift": {"name": "Swift Feet", "desc": "Run %d m as a Runner", "stat": "runner_m", "kind": "total", "tiers": [1000, 5000, 15000]},
	"ironhide": {"name": "Iron Hide", "desc": "Travel %d m as a Tank", "stat": "tank_m", "kind": "total", "tiers": [600, 3000, 10000]},
	"smasher": {"name": "Rock Breaker", "desc": "Smash %d obstacles", "stat": "smashed", "kind": "total", "tiers": [40, 200, 600]},
	"meat": {"name": "Meat Collector", "desc": "Collect %d meat", "stat": "meat", "kind": "total", "tiers": [60, 300, 1000]},
	"amber": {"name": "Amber Hoarder", "desc": "Collect %d amber", "stat": "amber", "kind": "total", "tiers": [250, 1500, 5000]},
	"gates": {"name": "Gate Crasher", "desc": "Get through %d dino gates", "stat": "gates", "kind": "total", "tiers": [10, 50, 150]},
	"limbo": {"name": "Limbo Master", "desc": "Slide under %d low ledges", "stat": "ledges", "kind": "total", "tiers": [30, 120, 400]},
	"flyer": {"name": "Sky Rider", "desc": "Fly %d m in total", "stat": "flown_m", "kind": "total", "tiers": [500, 3000, 10000]},
	"bait": {"name": "Bait", "desc": "Lead %d wild dinosaurs to the T-rex", "stat": "snacks", "kind": "total", "tiers": [15, 80, 250]},
	"escape": {"name": "Escape Artist", "desc": "Escape %d T-rex charges", "stat": "charges", "kind": "total", "tiers": [3, 15, 50]},
	"marathon": {"name": "Marathon", "desc": "Run %d m in one run", "stat": "run_m", "kind": "best", "tiers": [2000, 4000, 7000]},
	"clean": {"name": "Untouchable", "desc": "Run %d m in one go without stumbling", "stat": "clean_m", "kind": "best", "tiers": [800, 2000, 4000]},
	"primal": {"name": "Primal Spirit", "desc": "Spend %d m as a dino in one run", "stat": "dino_m", "kind": "best", "tiers": [800, 2000, 4000]},
	"herd": {"name": "Herd Keeper", "desc": "Own %d new dinosaurs", "stat": "herd", "kind": "best", "tiers": [1, 10, 28]},
	"explorer": {"name": "Explorer", "desc": "Reach %d zones in one run", "stat": "zones", "kind": "best", "tiers": [3, 5, 9]},
}


## Perk badges: badge id -> [what it boosts, bonus at Bronze, Silver, Gold].
## Point Hunter boosts every point scored (main.points_mult), Seasoned the XP
## dinosaurs earn (main._badge_run_step and the rank bonus).
const PERKS := {"scorer": ["points", 0.05, 0.10, 0.20], "veteran": ["xp", 0.10, 0.20, 0.35]}


## The permanent bonus (0.0 = none) the perk badges give to "points" or "xp".
static func perk_bonus(kind: String) -> float:
	var b := 0.0
	for id in PERKS:
		var p: Array = PERKS[id]
		var t := int(earned.get(id, 0))
		if p[0] == kind and t > 0:
			b += float(p[t])
	return b


## "+10% points" for a perk badge's tier (1-3), "" for other badges.
static func perk_text(id: String, tier: int) -> String:
	if not PERKS.has(id) or tier < 1:
		return ""
	var p: Array = PERKS[id]
	return "+%d%% %s" % [roundi(float(p[tier]) * 100.0), "points" if p[0] == "points" else "XP"]


## Badges that track a stat.
static func for_stat(stat: String) -> Array:
	return DATA.keys().filter(func(id): return DATA[id].stat == stat)


## The target of the next tier (or the gold one if all are earned).
static func target(id: String, tiers_earned: int) -> int:
	var t: Array = DATA[id].tiers
	return t[mini(tiers_earned, t.size() - 1)]


static func goal_text(id: String, tiers_earned: int) -> String:
	return String(DATA[id].desc) % target(id, tiers_earned)


## Tiers earned (badge id -> 0-3): main keeps this pointing at main.badge_tiers,
## so things like the Market can ask without a reference to main.
static var earned: Dictionary = {}


static func has_tier(id: String, tier: int) -> bool:
	return int(earned.get(id, 0)) >= tier


## "Rock Breaker (Silver)"
static func tier_name(id: String, tier: int) -> String:
	return "%s (%s)" % [DATA[id].name, TIERS[tier - 1]]


## Market items a badge's tier helps unlock: [item id, tier needed].
static func unlocks(id: String) -> Array:
	var out := []
	for item in Progression.MARKET_BADGES:
		var r: Array = Progression.MARKET_BADGES[item]
		if r[0] == id:
			out.append([item, r[1]])
	return out


static var _icons := {}


## The medal for a badge at a tier (0 = not earned: a dim outline).
static func icon(id: String, tier: int) -> Texture2D:
	var path := "res://assets/badges/%s_%d.png" % [id, tier]
	if ResourceLoader.exists(path):
		return load(path)
	var key := "%s_%d" % [id, tier]
	if not _icons.has(key):
		_icons[key] = _draw_medal(tier)
	return _icons[key]


## Placeholder medal: a ribbon and a disc in the tier colour with a small
## three-dot emblem (no font needed). Replaced by the user's art when it exists.
static func _draw_medal(tier: int) -> Texture2D:
	var n := 96
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var c: Color = TIER_COLORS[tier - 1] if tier > 0 else Color(0.55, 0.47, 0.38)
	var ribbon := Color(0.75, 0.2, 0.18) if tier > 0 else Color(0.5, 0.42, 0.34)
	img.fill_rect(Rect2i(30, 4, 14, 36), ribbon)
	img.fill_rect(Rect2i(52, 4, 14, 36), ribbon.darkened(0.2))
	var ctr := Vector2(48, 58)
	for y in n:
		for x in n:
			var r := Vector2(x + 0.5, y + 0.5).distance_to(ctr)
			if r < 34.0:
				var col := c.darkened(0.35) if r > 29.0 else (c.lightened(0.25) if r < 20.0 and x + y < 100 else c)
				img.set_pixel(x, y, col if tier > 0 else Color(col, 0.55))
	var star := [Vector2i(0, -10), Vector2i(-9, 8), Vector2i(9, 8)]
	for p in star:
		img.fill_rect(Rect2i(ctr.x + p.x - 4, ctr.y + p.y - 4, 8, 8), c.darkened(0.5) if tier > 0 else Color(0.3, 0.25, 0.2, 0.6))
	return ImageTexture.create_from_image(img)
