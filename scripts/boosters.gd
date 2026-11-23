class_name Boosters
## Power-ups (boosters) Rok can carry. Like a kart racer: up to MAX_SLOTS (3)
## slots, each holding one booster, all of different types. Rok starts with
## one slot (START_SLOTS); the second unlocks by best distance
## (Progression.SLOT_UNLOCK_M) and the third will come from the Market
## (SaveData.load_booster_slots). A booster picked up goes into any free open
## slot, even if another slot holds the same type; when every open slot is
## full it just gives its points. Tap a slot's button to use it.
##
## Only UNLOCKED boosters exist in a run: they're the only ones that spawn or
## can be picked up. The rest are shown locked in the Field Guide's
## Power-Ups tab; a market (planned) will unlock them, the same way distance
## unlocks dinosaurs. Unlocks are saved (SaveData.load_unlocked_boosters).
##
## Adding / enabling a booster:
##   1. its entry here (art id, name, effect text, points; "starter" = owned
##      from the start),
##   2. what it does in main.activate_booster() (and booster_ready() if it
##      can't always be used),
##   3. a price in config/progression.cfg [market] (it's then sold in the
##      Market; Course._booster() spawns owned ones in runs).

const MAX_SLOTS := 3
const START_SLOTS := 1
## Slot index bought in the Market (not earned by distance).
const MARKET_SLOT := 2

## id -> data. "art" names the sprites in assets/powerups (<art>_idle.png
## animated loop, <art>.png icon). Order = Field Guide order.
const DATA := {
	"pepper": {
		# The speed boost (the user's change, 2026-11-23: it replaced the Dino
		# Egg, whose art waits in assets/powerups for another idea). One still
		# picture until it has an idle loop (tools/prepare_assets.py blaze_pepper).
		"art": "blaze_pepper", "name": "Blaze Pepper", "score": 250, "starter": true,
		"desc": "A fiery 2.5-second burst of speed that pulls away from the T-rex.",
	},
	# Primal Amber (id kept from the old Amber Shield, so saves and prices carry
	# over; the user's change): a usable amber that refills PRIMAL energy. Its
	# picture is the amber pickup itself ("still") until it has its own art.
	"amber_shield": {
		"art": "", "still": "res://assets/props/Other_07.png", "name": "Primal Amber", "score": 250,
		"desc": "Refills your PRIMAL energy to full, so you can stay a dinosaur longer.",
	},
	"fossil_magnet": {
		"art": "fossil_magnet", "name": "Fossil Magnet", "score": 250,
		"desc": "For 7 seconds, nearby amber, meat and power-ups fly straight to you.",
	},
	"time_crystal": {
		"art": "time_crystal", "name": "Time Crystal", "score": 250,
		"desc": "For 4 seconds the world slows down and the T-rex falls behind.",
	},
	"primal_berry": {
		"art": "primal_berry", "name": "Primal Berry", "score": 250,
		"desc": "For 8 seconds, shapeshifting is free: no energy cost and no cooldown.",
	},
	"golden_fossil": {
		"art": "golden_fossil", "name": "Golden Fossil", "score": 250,
		"desc": "For 10 seconds, every point you earn counts double.",
	},
}


static func is_booster(kind: String) -> bool:
	return DATA.has(kind)


static func icon(kind: String) -> Texture2D:
	if DATA[kind].get("still", "") != "":
		return load(DATA[kind].still)
	return load("res://assets/powerups/%s.png" % DATA[kind].art)


## Animated pickup (idle loop, 4x2 sheet of 128 px frames at 160 ms).
static func frames(kind: String) -> SpriteFrames:
	var f := SpriteFrames.new()
	f.remove_animation("default")
	f.add_animation("idle")
	f.set_animation_loop("idle", true)
	f.set_animation_speed("idle", 6.25)
	if DATA[kind].get("still", "") != "":   # no idle loop yet: its one picture, scaled like the loops
		var still: Texture2D = load(DATA[kind].still)
		var img := still.get_image()
		var k := 96.0 / maxf(img.get_width(), img.get_height())
		img.resize(maxi(1, int(img.get_width() * k)), maxi(1, int(img.get_height() * k)), Image.INTERPOLATE_LANCZOS)
		var canvas := Image.create(128, 128, false, Image.FORMAT_RGBA8)
		canvas.blit_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), (Vector2i(128, 128) - img.get_size()) / 2)
		f.add_frame("idle", ImageTexture.create_from_image(canvas))
		return f
	var tex: Texture2D = load("res://assets/powerups/%s_idle.png" % DATA[kind].art)
	for i in 8:
		var at := AtlasTexture.new()
		at.atlas = tex
		at.region = Rect2(Vector2(i % 4, i / 4) * 128.0, Vector2(128, 128))
		f.add_frame("idle", at)
	return f


## Boosters owned from the start (before any market purchase).
static func starters() -> Array:
	return DATA.keys().filter(func(k): return DATA[k].get("starter", false))
