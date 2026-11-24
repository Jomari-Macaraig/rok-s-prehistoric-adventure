class_name Missions
extends RefCounted
## Daily and weekly missions (config/missions.cfg; a Missions instance is one
## period, "daily" or "weekly": main.missions and main.missions_week). The
## weekly set is keyed by the week's Monday (`week_key`), has bigger targets
## (`target_mult`, `run_m_share`, `combo_plus`) and pays more, without a streak.
## Daily missions (the user's pick for long runs): three small goals a day,
## picked from POOL by the date (the same three all day), only from what the
## player can already do. Progress counts across every run that day ("total")
## or within one run ("best"); each one done is CLAIMED in the Missions scene
## for its meat (`claim`), and finishing all three adds the all-done bonus
## plus a streak bonus for consecutive days, paid with the last claim
## (`bonus_due`). Rewards a new day replaces unclaimed are paid then
## (`unclaimed_meat`, main._refresh_missions).
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
const PATH := "res://config/missions.cfg"
const DEFAULTS := {
	"daily": {"count": 3, "meat": 25, "all_meat": 50, "streak_meat": 15, "streak_max": 6, "target_mult": 1.0, "run_m_share": 0.6, "combo_plus": 0},
	"weekly": {"count": 3, "meat": 120, "all_meat": 300, "streak_meat": 0, "streak_max": 0, "target_mult": 6.0, "run_m_share": 0.9, "combo_plus": 1},
}
static var _cfg := {}

var period := "daily"     # "daily" or "weekly"
var date := ""            # the day (daily) or the week's Monday (weekly) these are for
var ids: Array = []
var targets: Array = []
var progress: Array = []
var done: Array = []
var claimed: Array = []   # done and its meat taken (the CLAIM button)
var bonus_due := 0        # the all-done (and streak) bonus, paid with the last claim
var streak := 0           # days in a row with all three done
var last_full := ""       # the last date all three were done


func _init(p := "daily") -> void:
	period = p


## A setting for a period from config/missions.cfg (DEFAULTS when missing).
static func num(p: String, key: String) -> Variant:
	if _cfg.is_empty():
		_cfg = DEFAULTS.duplicate(true)
		var c := ConfigFile.new()
		if c.load(PATH) == OK:
			for sec in c.get_sections():
				for k in c.get_section_keys(sec):
					_cfg[sec][k] = c.get_value(sec, k)
	return _cfg.get(p, {}).get(key, DEFAULTS.get(p, {}).get(key, 0))


func per() -> int:
	return int(num(period, "count"))


func meat() -> int:
	return int(num(period, "meat"))


## The week a date (YYYY-MM-DD) falls in, as its Monday's date.
static func week_key(day: String) -> String:
	var unix := Time.get_unix_time_from_datetime_string(day + "T00:00:00")
	var wd := int(Time.get_datetime_dict_from_unix_time(unix).weekday)   # 0 Sunday .. 6 Saturday
	return Time.get_date_string_from_unix_time(unix - ((wd + 6) % 7) * 86400)


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


## The target for a mission: harder once the player is further along, and
## bigger for the weekly set (config/missions.cfg).
static func target_for(id: String, best_m: float, p := "daily") -> int:
	if id == "run_m":
		return int(clampf(roundf(best_m * float(num(p, "run_m_share")) / 100.0) * 100.0, 300.0, 9000.0))
	var t: Array = POOL[id].targets
	var base := int(t[1] if best_m >= 4000.0 else t[0])
	if POOL[id].kind == "best":
		return base + int(num(p, "combo_plus")) if id == "combo" else base
	return int(ceil(base * float(num(p, "target_mult"))))


## This period's missions (keeps the saved ones if they're from today, or
## this week for the weekly set).
func refresh(today: String, best_m: float, unlocked: Array) -> bool:
	var key := week_key(today) if period == "weekly" else today
	if date == key and ids.size() == per():
		return false
	date = key
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(period + key)
	var pool := eligible(best_m, unlocked)
	pool.sort()
	ids.clear()
	while ids.size() < per() and not pool.is_empty():
		ids.append(pool.pop_at(rng.randi() % pool.size()))
	targets = ids.map(func(id): return target_for(id, best_m, period))
	progress = ids.map(func(_id): return 0.0)
	done = ids.map(func(_id): return false)
	claimed = ids.map(func(_id): return false)
	bonus_due = 0
	return true


## Done, and its meat not taken yet.
func claimable(i: int) -> bool:
	return i < ids.size() and done[i] and not claimed[i]


func any_claimable() -> bool:
	return range(ids.size()).any(func(i): return claimable(i))


## Take mission i's meat (and the all-done bonus with the last one).
## Returns the meat (0 if it couldn't be claimed).
func claim(i: int) -> int:
	if not claimable(i):
		return 0
	claimed[i] = true
	var paid := meat()
	if bonus_due > 0 and claimed.all(func(c): return c):
		paid += bonus_due
		bonus_due = 0
	return paid


## Meat still waiting to be claimed (rewards and any bonus).
func unclaimed_meat() -> int:
	var t := bonus_due
	for i in ids.size():
		if claimable(i):
			t += meat()
	return t


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
	return ids.size() == per() and done.all(func(d): return d)


## All of them done: count the streak (consecutive days; weeks have none)
## and return the bonus meat. `yesterday` is the date before `date`.
func complete_day(yesterday: String) -> int:
	streak = streak + 1 if last_full == yesterday else 1
	last_full = date
	return int(num(period, "all_meat")) + int(num(period, "streak_meat")) * mini(streak - 1, int(num(period, "streak_max")))


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
			"claimed": claimed, "bonus_due": bonus_due, "streak": streak, "last_full": last_full}


func from_dict(d: Dictionary) -> void:
	date = String(d.get("date", ""))
	ids = Array(d.get("ids", []))
	targets = Array(d.get("targets", []))
	progress = Array(d.get("progress", []))
	done = Array(d.get("done", []))
	claimed = Array(d.get("claimed", done.duplicate()))   # older saves paid on completion
	bonus_due = int(d.get("bonus_due", 0))
	if claimed.size() != done.size():
		claimed = done.duplicate()
	streak = int(d.get("streak", 0))
	last_full = String(d.get("last_full", ""))
	if not (ids.size() == targets.size() and ids.size() == progress.size() and ids.size() == done.size()) \
			or ids.any(func(id): return not POOL.has(id)):
		date = ""   # damaged: pick fresh ones
		ids.clear()
