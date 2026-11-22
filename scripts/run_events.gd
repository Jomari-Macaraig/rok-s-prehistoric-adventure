class_name RunEvents
extends RefCounted
## Mid-run events (the user's pick for long runs): from EVENT_FROM_M, every
## EVENT_GAP_MIN..MAX metres a random event takes over for its duration,
## announced with a banner and shown on the HUD with a countdown. main owns
## one (`main.events`) and does the effects in `_event_step`.
##   golden_hour   - every meat counts double and reward spots are all meat
##   meteor_shower - rocks fall from the sky just ahead (they land as small
##                   rocks: dodge them while they fall, jump them after)
##   amber_storm   - amber rains down ahead (energy for dinosaur play)
##   stampede_rush - wild dinosaurs keep charging at Rok (only once the
##                   stampede has been met; the hunter eats the ones he dodges)
## An event never starts during a frenzy, a hunter charge or a bonus zone; it
## waits a little and tries again.

const DATA := {
	"golden_hour": {"name": "GOLDEN HOUR", "hint": "Every meat counts double!", "time": 20.0, "color": Color(1.0, 0.82, 0.3)},
	"meteor_shower": {"name": "METEOR SHOWER", "hint": "Rocks are falling: watch the shadows, or tap ATTACK to smash them!", "time": 15.0, "color": Color(1.0, 0.5, 0.3)},
	"amber_storm": {"name": "AMBER STORM", "hint": "Amber rains down: time to be a dinosaur!", "time": 15.0, "color": Color(1.0, 0.7, 0.2)},
	"stampede_rush": {"name": "STAMPEDE!", "hint": "Wild dinosaurs keep coming: jump them and the hunter eats them.", "time": 15.0, "color": Color(0.9, 0.65, 0.4)},
}

var current := ""        # the event running now, or ""
var time_left := 0.0
var next_m := 0.0        # where the next event may start (metres)
var tick := 0.0          # countdown to the event's next spawn
var count := 0           # events this run


func reset(start_m: float) -> void:
	current = ""
	time_left = 0.0
	tick = 0.0
	count = 0
	next_m = maxf(Tuning.EVENT_FROM_M, start_m + Tuning.EVENT_GAP_MIN)


func active(id: String) -> bool:
	return current == id


## Which events can happen now (stampede_rush needs the stampede taught).
static func pool(stampede_ok: bool) -> Array:
	var ids := DATA.keys()
	if not stampede_ok:
		ids.erase("stampede_rush")
	return ids.filter(func(id): return Requires.ok("event." + id))   # (config/requirements.cfg)


## Start an event (main calls this when it's due and allowed).
func start(id: String, m: float) -> void:
	current = id
	time_left = float(DATA[id].time)
	tick = 0.5
	count += 1
	next_m = m + randf_range(Tuning.EVENT_GAP_MIN, Tuning.EVENT_GAP_MAX)


## Counts down; returns true on the frame the event ends.
func step(delta: float) -> bool:
	if current == "":
		return false
	time_left -= delta
	tick -= delta
	if time_left <= 0.0:
		current = ""
		time_left = 0.0
		return true
	return false
