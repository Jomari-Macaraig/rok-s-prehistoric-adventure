class_name Tutorial
extends RefCounted
## Coach hints: the tutorial (the user's request: teach gradually, never be
## annoying). A hint is a pulsing ring on the button to press plus a few words
## (Hud.coach), shown only at the moment it's useful, and it never pauses.
##
## Rules that keep it quiet:
## - one hint at a time, at least GAP seconds after the last one ended;
## - a hint stays up while its moment lasts, at most SHOW_TIME seconds;
## - a lesson is LEARNED once the player has done the thing `need` times
##   (done() is called from gameplay, whether a hint was showing or not), and
##   a learned lesson never shows again;
## - a lesson shows at most MAX_SHOWS times in all and once per run, so a
##   player who ignores it isn't nagged;
## - nothing in the first START_QUIET seconds of a run, during info cards or
##   while paused.
## Progress is saved (SaveData.load/save_tutorial). main decides when each
## lesson's moment has come (main._coach_step) and reports actions (done).

const GAP := 6.0
const SHOW_TIME := 4.5
const MAX_SHOWS := 3
const START_QUIET := 1.5

## id -> text, the HUD action the ring sits on ("" = the button main passes),
## how many times the player must do it, and where it's taught ("run" / "menu").
const LESSONS := {
	"jump": {"text": "Tap to jump!", "target": "jump", "need": 2},
	"high_jump": {"text": "Hold to jump higher", "target": "jump", "need": 2},
	"double_jump": {"text": "Tap again in mid-air!", "target": "jump", "need": 2},
	"slide": {"text": "Slide under!", "target": "slide", "need": 2},
	"attack": {"text": "Smash it!", "target": "attack", "need": 2},
	"booster": {"text": "Use your power-up", "target": "", "need": 1},
	"shift": {"text": "Change into this dinosaur", "target": "", "need": 2},
	"energy": {"text": "Low energy: back to Rok", "target": "form_0", "need": 1},
	"market": {"text": "Spend your\nmeat here", "target": "market", "need": 1, "menu": true},
	"camp": {"text": "Level up\nat the Camp", "target": "herd", "need": 1, "menu": true},
}

var progress := {}       # id -> {"done": n, "shown": n}
var enabled := true
var current := ""        # the lesson showing now ("" = none)
var _t := 0.0            # time the current hint has been up
var _quiet := 0.0        # time left before another hint may show
var _this_run: Array = []


func _init(saved: Dictionary = {}) -> void:
	progress = saved.duplicate(true)


func _entry(id: String) -> Dictionary:
	if not progress.has(id):
		progress[id] = {"done": 0, "shown": 0}
	return progress[id]


func learned(id: String) -> bool:
	return int(_entry(id).done) >= int(LESSONS[id].need)


## Could this lesson show right now (ignoring whether its moment has come)?
func can_show(id: String) -> bool:
	if not enabled or current != "" or _quiet > 0.0 or learned(id):
		return false
	if int(_entry(id).shown) >= MAX_SHOWS or _this_run.has(id):
		return false
	return true


## Show a lesson's hint (main checked can_show and that its moment has come).
## Returns the hint text.
func show(id: String) -> String:
	current = id
	_t = 0.0
	_entry(id).shown = int(_entry(id).shown) + 1
	_this_run.append(id)
	return String(LESSONS[id].text)


## The player did the thing (whether a hint was up or not). Returns true if
## this ended the hint that was showing.
func done(id: String) -> bool:
	var e := _entry(id)
	e.done = int(e.done) + 1
	if current == id:
		hide()
		return true
	return false


## End the hint (its moment passed, it timed out, or it was done).
func hide() -> void:
	if current != "":
		_quiet = GAP
	current = ""


## Advance the timers; true if the current hint has been up too long.
func step(delta: float) -> bool:
	_quiet = maxf(_quiet - delta, 0.0)
	if current == "":
		return false
	_t += delta
	return _t >= SHOW_TIME


## A new run: every lesson may show once again, after a quiet start.
func new_run() -> void:
	hide()
	_this_run.clear()
	_quiet = START_QUIET


## Mark a lesson learned (the training run taught it).
func learn(id: String) -> void:
	_entry(id).done = maxi(int(_entry(id).done), int(LESSONS[id].need))


## An existing save with a long best run already knows the basic moves:
## mark them learned so returning players aren't taught what they do daily.
func skip_basics() -> void:
	for id in ["jump", "high_jump", "double_jump", "slide"]:
		_entry(id).done = int(LESSONS[id].need)
