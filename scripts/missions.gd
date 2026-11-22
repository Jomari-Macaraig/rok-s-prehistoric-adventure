class_name Missions
extends RefCounted
## Daily missions (the user's pick for long runs): three small goals a day,
## picked from POOL by the date (the same three all day), only from what the
## player can already do. Progress counts across every run that day ("total")
## or within one run ("best"); each one done pays MISSION_MEAT into the bank,
## and finishing all three pays MISSION_ALL_MEAT plus a streak bonus for
## consecutive days (MISSION_STREAK_MEAT per day, up to MISSION_STREAK_MAX).
## main owns one (`main.missions`), feeds it through `add`/`best` (from
## badge_event / badge_best and a few direct hooks) and saves it with
## SaveData.save_missions. The title and game-over screens list them
## (Hud.set_missions).

## id -> text (with %d), how it counts, the stat main reports, targets
## [easy, harder] (harder once the player is further along) and what the
## player must have reached first (best distance in metres, or a form).
const POOL := {
	"run_m": {"text": "Run %d m in one run", "kind": "best", "stat": "run_m", "need_m": 0},
	"meat": {"text": "Collect %d meat", "kind": "total", "stat": "meat", "targets": [15, 30], "need_m": 0},
	"amber": {"text": "Collect %d amber", "kind": "total", "stat": "amber", "targets": [40, 80], "need_m": 0},
	"ledges": {"text": "Slide under %d low ledges", "kind": "total", "stat": "ledges", "targets": [4, 8], "need_m": 300},
	"combo": {"text": "Reach a x%d combo", "kind": "best", "stat": "combo", "targets": [2, 3], "need_m": 300},
	"chests": {"text": "Open %d milestone chests", "kind": "total", "stat": "chests", "targets": [1, 2], "need_m": 1000},
	"smashed": {"text": "Smash %d obstacles", "kind": "total", "stat": "smashed", "targets": [6, 12], "need_form": Forms.TRICERATOPS},
	"gates": {"text": "Get through %d dino gates", "kind": "total", "stat": "gates", "targets": [2, 4], "need_form": Forms.RAPTOR},
	"snacks": {"text": "Lead %d wild dinosaurs to the hunter", "kind": "total", "stat": "snacks", "targets": [2, 4], "need_m": 3600},
	"frenzy": {"text": "Start %d Primal Frenzy", "kind": "total", "stat": "frenzy", "targets": [1, 2], "need_m": 1500},
}
const PER_DAY := 3

var date := ""
var ids: Array = []
var targets: Array = []
var progress: Array = []
var done: Array = []
var streak := 0           # days in a row with all three done
var last_full := ""       # the last date all three were done


## Missions the player can do now (best distance and unlocked forms).
static func eligible(best_m: float, unlocked: Array) -> Array:
	var out: Array = []
	for id in POOL:
		var p: Dictionary = POOL[id]
		if p.has("need_form") and not unlocked.has(int(p.need_form)):
			continue
		if best_m < float(p.get("need_m", 0)):
			continue
		out.append(id)
	return out


## The target for a mission: harder once the player is further along.
static func target_for(id: String, best_m: float) -> int:
	if id == "run_m":
		return int(clampf(roundf(best_m * 0.6 / 100.0) * 100.0, 300.0, 6000.0))
	var t: Array = POOL[id].targets
	return int(t[1] if best_m >= 4000.0 else t[0])


## Today's three (keeps the saved ones if they're from today).
func refresh(today: String, best_m: float, unlocked: Array) -> bool:
	if date == today and ids.size() == PER_DAY:
		return false
	date = today
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(today)
	var pool := eligible(best_m, unlocked)
	pool.sort()
	ids.clear()
	while ids.size() < PER_DAY and not pool.is_empty():
		ids.append(pool.pop_at(rng.randi() % pool.size()))
	targets = ids.map(func(id): return target_for(id, best_m))
	progress = ids.map(func(_id): return 0.0)
	done = ids.map(func(_id): return false)
	return true


## A "total" stat went up. Returns the indices of missions it completed.
func add(stat: String, amount: float) -> Array:
	return _update(stat, amount, false)


## A "best" stat reached `value` this run. Returns completed indices.
func best(stat: String, value: float) -> Array:
	return _update(stat, value, true)


func _update(stat: String, v: float, is_best: bool) -> Array:
	var finished: Array = []
	for i in ids.size():
		var p: Dictionary = POOL[ids[i]]
		if done[i] or p.stat != stat or (p.kind == "best") != is_best:
			continue
		progress[i] = maxf(progress[i], v) if is_best else progress[i] + v
		if progress[i] >= targets[i]:
			progress[i] = float(targets[i])
			done[i] = true
			finished.append(i)
	return finished


func all_done() -> bool:
	return ids.size() == PER_DAY and done.all(func(d): return d)


## All three done today: count the streak (consecutive days) and return the
## bonus meat. `yesterday` is the date before `date`.
func complete_day(yesterday: String) -> int:
	streak = streak + 1 if last_full == yesterday else 1
	last_full = date
	return Tuning.MISSION_ALL_MEAT + Tuning.MISSION_STREAK_MEAT * mini(streak - 1, Tuning.MISSION_STREAK_MAX)


func text(i: int) -> String:
	return POOL[ids[i]].text % targets[i]


## One line per mission for the HUD: a tick when done, else progress.
func lines() -> Array:
	var out: Array = []
	for i in ids.size():
		if done[i]:
			out.append("✓ " + text(i))
		else:
			out.append("• %s  (%d/%d)" % [text(i), int(progress[i]), targets[i]])
	return out


func to_dict() -> Dictionary:
	return {"date": date, "ids": ids, "targets": targets, "progress": progress, "done": done,
			"streak": streak, "last_full": last_full}


func from_dict(d: Dictionary) -> void:
	date = String(d.get("date", ""))
	ids = Array(d.get("ids", []))
	targets = Array(d.get("targets", []))
	progress = Array(d.get("progress", []))
	done = Array(d.get("done", []))
	streak = int(d.get("streak", 0))
	last_full = String(d.get("last_full", ""))
	if not (ids.size() == targets.size() and ids.size() == progress.size() and ids.size() == done.size()) \
			or ids.any(func(id): return not POOL.has(id)):
		date = ""   # damaged: pick fresh ones
		ids.clear()
