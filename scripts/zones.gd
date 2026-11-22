class_name Zones
## Distance-based zones and the day/night cycle.
##
## Zones repeat every ZONE_LEN_M * 3 metres: Forest (grass, dirt, trees and
## ferns) -> Desert (sandstone, dunes and mesas) -> Volcanic badlands (basalt,
## lava fissures, ash-filled sky) -> Forest again. Each has its own background
## layers, ground style, terrain mix and ambient effect; looks cross-fade over
## BLEND_M around each border.
##
## Day and night run on their own cycle (DAY_CYCLE_M), so each zone is seen at
## different times of day: daylight() is 1 by day and 0 at night, with
## sunset() peaking at dusk and dawn.

## Metres per zone (config/progression.cfg [zones] length_m; was 1000, the
## user found the zones changed too fast). A lap is ZONE_LEN_M * 3.
static var ZONE_LEN_M := 1500.0
const BLEND_M := 120.0
const DAY_CYCLE_M := 3600.0

const ZONES := [
	{
		"id": "forest", "name": "Forest", "ground": "forest",
		"blurb": "Grass, dirt, trees and ferns. Where every run begins.",
		"sky_day": [Color(0.5, 0.74, 0.9), Color(0.93, 0.88, 0.74), Color(0.62, 0.7, 0.5)],
		"sky_night": [Color(0.03, 0.05, 0.14), Color(0.1, 0.16, 0.32), Color(0.08, 0.16, 0.2)],
		"light_day": Color(1, 1, 1), "light_night": Color(0.56, 0.62, 0.86),
		"ambient_day": "", "ambient_night": "fireflies",
		"pit": 1.0, "hill": 1.0, "big_hill": 1.0, "drop": 1.0,
	},
	{
		"id": "desert", "name": "Desert", "ground": "desert",
		"blurb": "Sandstone, dunes and mesas. Rolling hills, fewer pits.",
		"sky_day": [Color(0.4, 0.64, 0.88), Color(0.98, 0.9, 0.74), Color(0.98, 0.84, 0.62)],
		"sky_night": [Color(0.04, 0.05, 0.16), Color(0.18, 0.18, 0.36), Color(0.3, 0.22, 0.32)],
		"light_day": Color(1.0, 0.98, 0.94), "light_night": Color(0.6, 0.62, 0.86),
		"ambient_day": "dust", "ambient_night": "",
		"pit": 0.7, "hill": 1.7, "big_hill": 1.5, "drop": 0.6,
	},
	{
		"id": "volcanic", "name": "Volcanic Badlands", "ground": "volcanic",
		"blurb": "Basalt, lava fissures and an ash-filled sky. Pits and drops everywhere.",
		"sky_day": [Color(0.3, 0.2, 0.24), Color(0.74, 0.4, 0.28), Color(0.46, 0.22, 0.17)],
		"sky_night": [Color(0.06, 0.02, 0.05), Color(0.36, 0.08, 0.06), Color(0.26, 0.06, 0.04)],
		"light_day": Color(1.0, 0.9, 0.84), "light_night": Color(0.78, 0.56, 0.54),
		"ambient_day": "embers", "ambient_night": "embers",
		"pit": 1.6, "hill": 0.7, "big_hill": 0.8, "drop": 1.7,
	},
]


static func index_at(metres: float) -> int:
	return int(floor(maxf(metres, 0.0) / ZONE_LEN_M)) % ZONES.size()


static func zone_at(metres: float) -> Dictionary:
	return ZONES[index_at(metres)]


## How many full Forest-Desert-Volcanic laps came before (0 on the first).
static func lap_at(metres: float) -> int:
	return int(floor(maxf(metres, 0.0) / (ZONE_LEN_M * ZONES.size())))


## Blend weights of every zone at this distance (they sum to 1).
static func weights(metres: float) -> Array:
	var w := [0.0, 0.0, 0.0]
	var i := index_at(metres)
	var t := fmod(maxf(metres, 0.0), ZONE_LEN_M)
	var k := 0.0
	if t > ZONE_LEN_M - BLEND_M * 0.5:
		k = (t - (ZONE_LEN_M - BLEND_M * 0.5)) / BLEND_M
		w[i] = 1.0 - k
		w[(i + 1) % 3] = k
	elif t < BLEND_M * 0.5 and metres >= ZONE_LEN_M:
		k = 0.5 + t / BLEND_M
		w[i] = k
		w[(i + 2) % 3] = 1.0 - k
	else:
		w[i] = 1.0
	return w


static func _blend3(colors: Array, w: Array) -> Color:
	var c := Color(0, 0, 0, 0)
	for i in 3:
		c += colors[i] * w[i]
	return c


# ------------------------------------------------------------ day / night

## 1 = full day, 0 = full night. Runs start in the morning.
static func daylight(metres: float) -> float:
	var p := fmod(maxf(metres, 0.0) / DAY_CYCLE_M, 1.0)
	# day 0-0.42, dusk 0.42-0.52, night 0.52-0.9, dawn 0.9-1
	if p < 0.42:
		return 1.0
	if p < 0.52:
		return smoothstep(0.52, 0.42, p)
	if p < 0.9:
		return 0.0
	return smoothstep(0.9, 1.0, p)


static func is_night(metres: float) -> bool:
	return daylight(metres) < 0.5


## Peaks at dusk and dawn (for warm sunset colours).
static func sunset(metres: float) -> float:
	var d := daylight(metres)
	return 4.0 * d * (1.0 - d)


static func sky(metres: float) -> Array:
	var w := weights(metres)
	var d := daylight(metres)
	var s := sunset(metres)
	var out := []
	for k in 3:
		var day := _blend3(ZONES.map(func(z): return z.sky_day[k]), w)
		var night := _blend3(ZONES.map(func(z): return z.sky_night[k]), w)
		var c := night.lerp(day, d)
		if k > 0:
			c = c.lerp(Color(1.0, 0.55, 0.32) if k == 1 else Color(0.85, 0.4, 0.3), s * 0.55)
		out.append(c)
	return out


## World lighting (CanvasModulate colour).
static func light(metres: float) -> Color:
	var w := weights(metres)
	var day := _blend3(ZONES.map(func(z): return z.light_day), w)
	var night := _blend3(ZONES.map(func(z): return z.light_night), w)
	var c := night.lerp(day, daylight(metres))
	return c.lerp(Color(1.0, 0.82, 0.7), sunset(metres) * 0.35)


## Strength (0..1) of each ambient effect right now.
static func ambient(metres: float) -> Dictionary:
	var w := weights(metres)
	var d := daylight(metres)
	var out := {"fireflies": 0.0, "dust": 0.0, "embers": 0.0}
	for i in 3:
		var z: Dictionary = ZONES[i]
		if z.ambient_day != "":
			out[z.ambient_day] += w[i] * d
		if z.ambient_night != "":
			out[z.ambient_night] += w[i] * (1.0 - d)
	return out
