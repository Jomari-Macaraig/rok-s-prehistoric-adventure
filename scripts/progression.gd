class_name Progression
## The run's curriculum, measured in metres travelled.
##
## Each obstacle / terrain feature is introduced on its own at a set distance
## ("NEW" banner + hint, extra space around it for its first few appearances),
## then mixed with familiar ones; combos only use things the player has
## already met, and harder combos come later. Dinosaurs unlock permanently the
## first time a run reaches their distance.

## Text for each introduction: key -> [banner title, hint, tip form, tip].
## Empty title = no banner. The tip is added to the hint only once that
## dinosaur is unlocked. WHEN each one appears is set in
## config/progression.cfg ([introductions]).
const INTRO_TEXT := {
	"small": ["Rocks & Mushrooms", "Tap JUMP to leap over them. Hit a rock and you trip (the T-rex gains); a mushroom makes you dizzy", -1, ""],
	"pepper": ["Blaze Peppers", "Grab it! It goes in a booster slot: tap the slot for a burst of speed. You start with 1 booster slot; reach %d m for a second, and a third comes from the Market", -1, ""],
	"hill": ["", "", -1, ""],
	"log": ["Logs", "Jump over them. Hold JUMP for a higher leap", -1, ""],
	"thorn_bush": ["Thorn Bushes", "Jump them! Stumbling lets the T-rex catch up", Forms.SPINOSAURUS, "or trample them as Spinosaurus"],
	"boulder": ["Boulders", "Give it a big jump", Forms.TRICERATOPS, "or smash it as Triceratops"],
	"gate_raptor": ["Crumbling Bridge", "Too flimsy for heavy feet. Only a light Raptor gets across!", -1, ""],
	"slope": ["", "", -1, ""],
	"large_hill": ["Big Hills", "Climbing slows you and the T-rex gains. SLIDE down the far side to pull away!", -1, ""],
	"fence": ["Fences", "Time your jump", Forms.SPINOSAURUS, "or trample it as Spinosaurus"],
	"pit": ["Pits", "Jump across. Don't fall in!", Forms.PTERANODON, "or fly over as Pteranodon"],
	"bridge": ["Log Bridges", "Sturdy bridges hold anyone", -1, ""],
	"gate_tri": ["Barricade", "Too tall to jump. Smash through as Triceratops!", -1, ""],
	"ledge": ["Low Ledges", "Tap SLIDE to get under them. A vine only snags you, but solid ledges stop you dead", -1, ""],
	"quicksand": ["Quicksand", "Don't stop on it! Jump across, or dash over as the Raptor", -1, ""],
	"wall": ["Rock Walls", "Jump again in mid-air to double-jump", Forms.TRICERATOPS, "or smash it as Triceratops"],
	"drop": ["", "", -1, ""],
	"tall_fence": ["Tall Fences", "Double-jump over", Forms.SPINOSAURUS, "or trample as Spinosaurus"],
	"gate_spino": ["Bramble Wall", "A wall of thorns. Only Spinosaurus can trample through!", -1, ""],
	"gate_water": ["Flooded Crossing", "Too wide to jump. Swim across as Spinosaurus!", -1, ""],
	"sky_trail": ["", "", -1, ""],
	"combo": ["Combos!", "Hazards you know, now back to back", -1, ""],
	"hard_combo": ["Tougher Combos", "You've got this. Read ahead", -1, ""],
	"steam": ["Steam Vents", "They puff before they blast. A blast makes you stumble", -1, ""],
	"gate_ptera": ["Wide Canyon", "Too wide to jump. Fly over as Pteranodon!", -1, ""],
	"gate_lava": ["Lava Channel", "Too wide to jump. Fly over as Pteranodon!", -1, ""],
	"rolling_boulder": ["Rolling Boulders", "They roll at you! Jump them, or smash as Triceratops", -1, ""],
	"stampede": ["Stampede!", "Wild dinosaurs dash your way. Jump over them! Behind you, the T-rex snaps them up", -1, ""],
	"swooper": ["Swoopers", "Flyers swoop at head height. Slide under them! The T-rex grabs them behind you", -1, ""],
	"diver": ["Diving Flyers", "Some flyers come in high, screech and dive at you. SLIDE as it swoops down, or ATTACK it once it's low", -1, ""],
}

## Built-in defaults, used for anything missing from the config file.
const DEFAULT_INTRO_M := {
	"small": 0,
	"hill": 240,
	"pepper": 600,
	"log": 160,
	"ledge": 300,
	"pit": 1150,
	"quicksand": 1750,
	"slope": 1400,
	"gate_raptor": 450,
	"steam": 3150,
	"combo": 2480,
	"gate_tri": 1000,
	"boulder": 1900,
	"drop": 4450,
	"gate_spino": 1600,
	"rolling_boulder": 3900,
	"sky_trail": 5300,
	"large_hill": 5680,
	"gate_water": 5000,
	"gate_ptera": 2200,
	"thorn_bush": 6680,
	"stampede": 2340,
	"swooper": 2740,
	"diver": 4100,
	"fence": 7800,
	"gate_lava": 8000,
	"wall": 8200,
	"tall_fence": 8600,
	"bridge": 9000,
	"hard_combo": 9400,
}
const DEFAULT_UNLOCK_M := {"raptor": 450, "triceratops": 1000, "spinosaurus": 1600, "pteranodon": 2200}
const CONFIG_PATH := "res://config/progression.cfg"

## Loaded from the config (see _load). [metres, key, title, hint, tip form, tip],
## sorted by distance.
static var INTROS: Array = []
## Dinosaur unlocks by best distance (metres).
static var UNLOCKS: Dictionary = {}
## Distance where the pressure ramp (gaps, pit width) begins and reaches max.
static var RAMP_START_M := 4000.0
static var RAMP_FULL_M := 12000.0
## A newly introduced key appears this many times alone, with extra space.
static var INTRO_SOLO_SPAWNS := 3
## Combos may only use keys introduced at least this many metres ago.
static var FAMILIAR_AFTER_M := 300.0
## Metres after something new before the next new hazard may come.
static var MARINATE_M := 130.0
## No new hazard this close before a big moment (dino, first zone visit, slot).
static var BIG_CLEARANCE_M := 100.0
static var GATE_SPACING_M := Vector2(200.0, 340.0)
static var ZONE_SHOWCASE_M := 120.0
## [early]: the first stretch before the Raptor (see config/progression.cfg).
static var STARTER_CHEST_M := 870.0
static var STAMPEDE_PREVIEW_M := 720.0
static var STAMPEDE_PREVIEW_SPEED := 0.5
## T-rex charges: where they happen, then every TREX_CHARGE_EVERY_M after the last.
static var TREX_CHARGE_M: Array = [5400.0, 7800.0]
static var TREX_CHARGE_EVERY_M := 2400.0
## Best distance that unlocks the second booster slot (config [boosters] slot_2).
static var SLOT_UNLOCK_M := 3760.0
## Market prices in meat (config [market]); "booster_slot_3" is the third slot.
const DEFAULT_PRICES := {"amber_shield": 300, "fossil_magnet": 600, "time_crystal": 900,
		"primal_berry": 1200, "golden_fossil": 1650, "booster_slot_3": 2100,
		# dinosaurs (scripts/dinos.gd), in the order they go on sale
		"gallimimus": 450,
		"oviraptor": 500,
		"coelophysis": 600,
		"dilophosaurus": 750,
		"pachycephalosaurus": 800,
		"centrosaurus": 900,
		"deinonychus": 1000,
		"styracosaurus": 1050,
		"stegosaurus": 1100,
		"parasaurolophus": 1200,
		"carnotaurus": 1300,
		"iguanodon": 1350,
		"kentrosaurus": 1400,
		"baryonyx": 1500,
		"allosaurus": 1500,
		"tapejara": 1600,
		"euoplocephalus": 1700,
		"tupandactylus": 1800,
		"rhamphorhynchus": 1900,
		"utahraptor": 1950,
		"therizinosaurus": 2100,
		"nyctosaurus": 2200,
		"diplodocus": 2250,
		"dimorphodon": 2300,
		"ankylosaurus": 2400,
		"dsungaripterus": 2550,
		"brachiosaurus": 2700,
		"quetzalcoatlus": 2850,
		# heroes (scripts/heroes.gd)
		"nira": 1200,
		"boro": 1800,
		# Heart Containers (on sale by best score: DEFAULT_MARKET_SCORE)
		"heart_1": 900,
		"heart_2": 1800,
		"heart_3": 3200}
static var PRICES: Dictionary = DEFAULT_PRICES.duplicate()
## Best distance that puts each Market item on sale (config [market_unlocks]).
const DEFAULT_MARKET_UNLOCK_M := {"amber_shield": 0, "fossil_magnet": 1800, "time_crystal": 3000,
		"primal_berry": 5000, "golden_fossil": 6600, "booster_slot_3": 6000,
		# dinosaurs: Starters just after their button unlocks, by category
		"gallimimus": 600,
		"oviraptor": 2000,
		"coelophysis": 2400,
		"dilophosaurus": 2800,
		"deinonychus": 4000,
		"carnotaurus": 5200,
		"utahraptor": 7200,
		"pachycephalosaurus": 3300,
		"centrosaurus": 3700,
		"styracosaurus": 4200,
		"stegosaurus": 4600,
		"kentrosaurus": 5600,
		"euoplocephalus": 6800,
		"ankylosaurus": 8800,
		"parasaurolophus": 4900,
		"iguanodon": 5300,
		"baryonyx": 5800,
		"allosaurus": 6200,
		"therizinosaurus": 7400,
		"diplodocus": 8000,
		"brachiosaurus": 9600,
		"tapejara": 6500,
		"tupandactylus": 6900,
		"rhamphorhynchus": 7100,
		"nyctosaurus": 7600,
		"dimorphodon": 8200,
		"dsungaripterus": 9200,
		"quetzalcoatlus": 10400,
		# heroes
		"nira": 2500,
		"boro": 4500}
static var MARKET_UNLOCK_M: Dictionary = DEFAULT_MARKET_UNLOCK_M.duplicate()
## Badge an item also needs before it goes on sale (config [market_badges]):
## id -> [badge id, tier 1-3].
const DEFAULT_MARKET_BADGES := {
	# power-ups that match a badge
	"fossil_magnet": "amber:1",
	"primal_berry": "primal:1",
	"golden_fossil": "clean:2",
	# dinosaur tiers: Skilled / Expert / Legend need their category badge at
	# Bronze / Silver / Gold (Dinos.CATEGORY_BADGE)
	"coelophysis": "swift:1",
	"dilophosaurus": "swift:1",
	"deinonychus": "swift:2",
	"carnotaurus": "swift:2",
	"utahraptor": "swift:3",
	"styracosaurus": "smasher:1",
	"stegosaurus": "smasher:1",
	"kentrosaurus": "smasher:2",
	"euoplocephalus": "smasher:2",
	"ankylosaurus": "smasher:3",
	"baryonyx": "ironhide:1",
	"allosaurus": "ironhide:1",
	"therizinosaurus": "ironhide:2",
	"diplodocus": "ironhide:2",
	"brachiosaurus": "ironhide:3",
	"rhamphorhynchus": "flyer:1",
	"nyctosaurus": "flyer:1",
	"dimorphodon": "flyer:2",
	"dsungaripterus": "flyer:2",
	"quetzalcoatlus": "flyer:3",
}
## Best score (one run) that puts each Heart Container on sale (config [market_score]).
const DEFAULT_MARKET_SCORE := {"heart_1": 6000, "heart_2": 15000, "heart_3": 35000}
static var MARKET_SCORE: Dictionary = DEFAULT_MARKET_SCORE.duplicate()
static var MARKET_BADGES: Dictionary = {}
static var _loaded: bool = _load()


## Reads config/progression.cfg (falling back to the defaults above).
static func _load() -> bool:
	var c := ConfigFile.new()
	var ok := c.load(CONFIG_PATH) == OK
	if not ok:
		push_warning("Progression: %s not found, using defaults" % CONFIG_PATH)
	INTROS = []
	for key in INTRO_TEXT:
		var m: float = float(c.get_value("introductions", key, DEFAULT_INTRO_M.get(key, 0))) if ok else float(DEFAULT_INTRO_M.get(key, 0))
		var t: Array = INTRO_TEXT[key]
		INTROS.append([m, key, t[0], t[1], t[2], t[3]])
	INTROS.sort_custom(func(a, b): return a[0] < b[0])
	UNLOCKS = {}
	for f in [Forms.RAPTOR, Forms.TRICERATOPS, Forms.SPINOSAURUS, Forms.PTERANODON]:
		var id: String = Forms.get_data(f).id
		UNLOCKS[f] = int(c.get_value("dinos", id, DEFAULT_UNLOCK_M[id])) if ok else DEFAULT_UNLOCK_M[id]
	if ok:
		MARINATE_M = float(c.get_value("pacing", "marinate_m", MARINATE_M))
		BIG_CLEARANCE_M = float(c.get_value("pacing", "big_clearance_m", BIG_CLEARANCE_M))
		INTRO_SOLO_SPAWNS = int(c.get_value("pacing", "intro_solo_spawns", INTRO_SOLO_SPAWNS))
		FAMILIAR_AFTER_M = float(c.get_value("pacing", "familiar_after_m", FAMILIAR_AFTER_M))
		GATE_SPACING_M = Vector2(float(c.get_value("pacing", "gate_spacing_min", GATE_SPACING_M.x)),
				float(c.get_value("pacing", "gate_spacing_max", GATE_SPACING_M.y)))
		ZONE_SHOWCASE_M = float(c.get_value("pacing", "zone_showcase_m", ZONE_SHOWCASE_M))
		Zones.ZONE_LEN_M = float(c.get_value("zones", "length_m", Zones.ZONE_LEN_M))
		STARTER_CHEST_M = float(c.get_value("early", "starter_chest_m", STARTER_CHEST_M))
		STAMPEDE_PREVIEW_M = float(c.get_value("early", "stampede_preview_m", STAMPEDE_PREVIEW_M))
		STAMPEDE_PREVIEW_SPEED = float(c.get_value("early", "stampede_preview_speed", STAMPEDE_PREVIEW_SPEED))
		SLOT_UNLOCK_M = float(c.get_value("boosters", "slot_2", SLOT_UNLOCK_M))
		TREX_CHARGE_M = (c.get_value("trex", "charge_m", TREX_CHARGE_M) as Array).map(func(v): return float(v))
		TREX_CHARGE_EVERY_M = float(c.get_value("trex", "charge_every_m", TREX_CHARGE_EVERY_M))
		for k in DEFAULT_PRICES:
			PRICES[k] = int(c.get_value("market", k, DEFAULT_PRICES[k]))
		for k in Gear.ITEMS.keys() + [Gear.CARD_PACK]:   # hero gear (defaults in gear.gd)
			if c.has_section_key("market", k):
				PRICES[k] = int(c.get_value("market", k))
		var mb: Dictionary = DEFAULT_MARKET_BADGES.duplicate()
		if c.has_section("market_badges"):
			mb = {}
			for k in c.get_section_keys("market_badges"):
				mb[k] = String(c.get_value("market_badges", k))
		MARKET_BADGES = {}
		for k in mb:
			var parts: PackedStringArray = String(mb[k]).split(":")
			MARKET_BADGES[k] = [parts[0], int(parts[1]) if parts.size() > 1 else 1]
		for k in DEFAULT_MARKET_SCORE:
			MARKET_SCORE[k] = int(c.get_value("market_score", k, DEFAULT_MARKET_SCORE[k]))
		for k in DEFAULT_MARKET_UNLOCK_M:
			MARKET_UNLOCK_M[k] = int(c.get_value("market_unlocks", k, DEFAULT_MARKET_UNLOCK_M[k]))
		for k in Gear.ITEMS.keys() + [Gear.CARD_PACK]:
			if c.has_section_key("market_unlocks", k):
				MARKET_UNLOCK_M[k] = int(c.get_value("market_unlocks", k))
		RAMP_START_M = float(c.get_value("pacing", "ramp_start_m", RAMP_START_M))
		RAMP_FULL_M = float(c.get_value("pacing", "ramp_full_m", RAMP_FULL_M))
	return true


const PATTERN_KEYS := ["small", "thorn_bush", "log", "boulder", "fence", "ledge", "wall", "tall_fence",
		"steam", "rolling_boulder", "stampede", "swooper"]
## Hazards that only belong in one zone.
const ZONE_ONLY := {"steam": "volcanic", "rolling_boulder": "volcanic"}
## Lessons that can only happen in one zone (zone-only hazards plus desert
## quicksand). While you're in that zone they go first, so they don't miss it.
const ZONE_LESSONS := {"quicksand": "desert", "steam": "volcanic", "rolling_boulder": "volcanic"}

## Dino gates: only this form gets through. Obstacle gates are spawned by
## Course; canyon and bridge gates are terrain built by Terrain on request.
const GATE_FORM := {
	"gate_raptor": Forms.RAPTOR,
	"gate_tri": Forms.TRICERATOPS,
	"gate_spino": Forms.SPINOSAURUS,
	"gate_ptera": Forms.PTERANODON,
}
const TERRAIN_GATES := ["gate_raptor", "gate_ptera"]


static func gate_for_form(f: int) -> String:
	for k in GATE_FORM:
		if GATE_FORM[k] == f:
			return k
	return ""
## Each zone's signature dino traps (they have that zone's art) are favoured
## there, and one comes up shortly after entering the zone.
const ZONE_GATES := {
	"forest": ["gate_spino", "gate_tri"],          # flooded crossing, log barricade
	"desert": ["gate_raptor", "gate_tri"],         # sandstone bridge, sandstone wall
	"canyon": ["gate_raptor", "gate_tri"],         # crumbling sandstone bridge over a gap, sandstone wall
	"volcanic": ["gate_ptera", "gate_tri"],        # lava channel, basalt barricade
}


## Gates the player can meet now: introduced by distance and dino unlocked.
static func eligible_gates(metres: float, unlocked: Array) -> Array:
	var out := []
	for k in GATE_FORM:
		if available(k, metres) and unlocked.has(GATE_FORM[k]):
			out.append(k)
	return out
const TERRAIN_KEYS := ["hill", "slope", "drop", "pit"]


## The first T-rex charge at or after m (metres).
static func next_charge_m(m: float) -> float:
	for c in TREX_CHARGE_M:
		if c >= m:
			return c
	var last: float = TREX_CHARGE_M[-1] if not TREX_CHARGE_M.is_empty() else 0.0
	return last + ceilf((m - last) / TREX_CHARGE_EVERY_M) * TREX_CHARGE_EVERY_M if m > last else last


static func intro_m(key: String) -> float:
	for e in INTROS:
		if e[1] == key:
			return e[0]
	return INF


static func available(key: String, metres: float) -> bool:
	return metres >= intro_m(key) and Requires.ok("intro." + key)   # (config/requirements.cfg)


static func familiar(key: String, metres: float) -> bool:
	return metres >= intro_m(key) + FAMILIAR_AFTER_M


## Banner hint for a key, with the dino tip if that dino is unlocked.
static func hint(key: String, unlocked: Array) -> String:
	var e := intro_entry(key)
	if e.is_empty():
		return ""
	var h: String = e[3]
	if key == "pepper":
		h = h % int(SLOT_UNLOCK_M)
	if e[4] != -1 and unlocked.has(e[4]):
		h += ", " + e[5]
	return h


## A run has to get this far past an intro for it to count as taught.
const TAUGHT_MARGIN_M := 60.0


## Already taught: its banner was shown, or the player's best run went well
## past where it is introduced. Taught hazards get no hint banner and are
## revealed in the Field Guide.
static func taught(key: String, best_m: float, seen: Array) -> bool:
	return seen.has(key) or best_m >= intro_m(key) + TAUGHT_MARGIN_M


static func intro_entry(key: String) -> Array:
	for e in INTROS:
		if e[1] == key:
			return e
	return []


## 0 while learning, rising to 1 once everything has been introduced and
## familiar; drives gap shrinking and pit width.
static func pressure(metres: float) -> float:
	return clampf((metres - RAMP_START_M) / (RAMP_FULL_M - RAMP_START_M), 0.0, 1.0)


static func unlock_m(form: int) -> int:
	return UNLOCKS.get(form, 0)


## The next locked form (by distance) or -1.
static func next_unlock(unlocked: Array) -> int:
	var best := -1
	for f in UNLOCKS:
		if not unlocked.has(f) and (best == -1 or UNLOCKS[f] < UNLOCKS[best]):
			best = f
	return best
