class_name MenuTour
extends RefCounted
## The menu tour (the user's request): right after a finished training run,
## on the main menu, the coach walks the player through the Marketplace, the
## Camp and the Encyclopedia. For each: a ring on its button ("tap it"), then
## inside the screen a note on its Back button about what's there; Back moves
## on to the next. Only the highlighted button works meanwhile; a tap
## anywhere else asks, and a second within SKIP_TIME skips the tour.
## main owns it (main.menu_tour) and calls step() every frame.

const STEPS := [
	{"button": "market", "screen": "market",
		"text": "The MARKETPLACE: spend meat on power-ups,\ngear and new dinosaurs. Tap to look inside!",
		"inside": "Tap an item to see what it does,\nthen Buy (tap twice). Tap Back when done."},
	{"button": "herd", "screen": "herd",
		"text": "The CAMP: level up your heroes and\ndinosaurs and equip gear. Tap it!",
		"inside": "Pick one to compare and level it up.\nTap Back when you're done."},
	{"button": "codex", "screen": "codex",
		"text": "The ENCYCLOPEDIA: everything you meet,\nexplained. Tap it!",
		"inside": "Dinosaurs, hazards, items and badges.\nTap Back to finish the tour."},
]
const SKIP_TIME := 3.0   # s a second stray tap has to skip the tour

var game                 # main.gd
var i := 0
var phase := "point"     # point (ring on the menu button), inside (note on Back), done
var _skip_t := 0.0
var _shown := ""         # what the coach shows now (so it's only set once)


func _init(main_node) -> void:
	game = main_node


func step_data() -> Dictionary:
	return STEPS[i]


## The menu button the tour wants tapped now ("" while inside a screen).
func want() -> String:
	return String(step_data().button) if phase == "point" else ""


func _screen() -> CanvasLayer:
	return {"market": game.market, "herd": game.herd, "codex": game.codex}[String(step_data().screen)]


func step(delta: float) -> void:
	_skip_t = maxf(_skip_t - delta, 0.0)
	if phase == "done":
		return
	var s := step_data()
	var open: bool = _screen().visible
	if game.state == game.State.TITLE:
		game.hud.center_panel.visible = false   # the title panel would sit under the bubbles
	match phase:
		"point":
			if open:
				phase = "inside"
				_shown = ""
			elif game.state == game.State.TITLE and _shown != "point%d" % i:
				if game.hud.coach(String(s.button), String(s.text)):
					_shown = "point%d" % i
		"inside":
			if not open:   # Back: on to the next screen
				game.hud.hide_coach()
				i += 1
				_shown = ""
				if i >= STEPS.size():
					finish(false)
				else:
					phase = "point"
			elif _shown != "inside%d" % i:
				var back: Control = _screen().find_child("Back", true, false)
				if back != null and back.is_visible_in_tree() and game.hud.coach_control(back, String(s.inside), true):
					_shown = "inside%d" % i


## A tap on the menu that isn't the highlighted button: the first asks, a
## second soon after skips the tour.
func stray_tap() -> void:
	if _skip_t > 0.0:
		finish(true)
		return
	_skip_t = SKIP_TIME
	game.hud.show_banner("TAP THE GLOWING BUTTON", "Or tap again to skip the tour.", Color(1.0, 0.8, 0.45), SKIP_TIME)


func finish(skipped: bool) -> void:
	phase = "done"
	game.hud.hide_coach()
	game.hud.clear_banner()
	if not skipped:
		game.hud.show_banner("YOU'RE ALL SET!", "Tap anywhere to start running.", Color(1.0, 0.85, 0.45), 3.0)
	game.end_menu_tour()
	game._show_menu_text()   # the title panel back
