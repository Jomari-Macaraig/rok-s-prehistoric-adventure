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
		"text": "The DINOSAUR CAMP: level up your heroes and\ndinosaurs and equip gear. Tap it!",
		"inside": "Pick one to compare and level it up.\nTap Back when you're done."},
	{"button": "codex", "screen": "codex",
		"text": "The ENCYCLOPEDIA: everything you meet,\nexplained. Tap it!",
		"inside": "Dinosaurs, hazards, items and badges.\nTap Back to finish the tour."},
]
## The Crafting tour (the user's request): back on the main menu after the
## run that opened the Crafting Bench, the coach shows the way in: the main
## menu's Crafting button and CRAFT on the bench, then the Camp's equipment.
## A step's "target" is the control inside its screen the note points at
## (default Back) and "advance_on" the screen whose opening moves on (default:
## closing its own screen); a step without a "button" starts inside.
const CRAFT_STEPS := [
	{"button": "crafting", "screen": "bench",
		"text": "The CRAFTING BENCH is open! Kora makes gear\nfrom the materials you find. Tap Crafting!",
		"target": "Craft",
		"inside": "Pick a recipe on the shelf. With its materials,\ntap CRAFT twice: every craft rolls a rarity.\nItems (top right) holds your materials and cards.\nThen tap Back."},
	# then the Camp: the weapon, armor and card slot systems (the user's request)
	{"button": "herd", "screen": "herd",
		"text": "Now put your gear on: tap the Dinosaur Camp!",
		"target": "EquipmentHead",
		"inside": "EQUIPMENT: Change puts a weapon or armor on\nyour hero. Weapons wear with each hit you land,\narmor with each hit you take: Repair them here.\nA weapon's Card slot takes a dinosaur card\nfor a bonus. The Encyclopedia's Items tab\nexplains it all. Tap Back when done."},
]
const SKIP_TIME := 3.0   # s a second stray tap has to skip the tour

var game                 # main.gd
var steps: Array = STEPS
var i := 0
var phase := "point"     # point (ring on the menu button), inside (note on Back), done
var _skip_t := 0.0
var _shown := ""         # what the coach shows now (so it's only set once)


func _init(main_node, p_steps: Array = STEPS) -> void:
	game = main_node
	steps = p_steps
	if String(steps[0].button) == "":
		phase = "inside"


func step_data() -> Dictionary:
	return steps[i]


## The menu button the tour wants tapped now ("" while inside a screen).
func want() -> String:
	return String(step_data().button) if phase == "point" else ""


func _screen() -> CanvasLayer:
	return _named_screen(String(step_data().screen))


func _named_screen(n: String) -> CanvasLayer:
	return {"market": game.market, "herd": game.herd, "codex": game.codex, "bench": game.bench, "items": game.items}[n]


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
			var nxt: String = s.get("advance_on", "")
			if (nxt != "" and _named_screen(nxt).visible) or (nxt == "" and not open):
				# its screen closed (Back), or the screen it leads to opened: the next step
				game.hud.hide_coach()
				i += 1
				_shown = ""
				if i >= steps.size():
					finish(false)
				else:
					phase = "point" if String(steps[i].button) != "" else "inside"
			elif _shown != "inside%d" % i and open:
				var back: Control = _screen().find_child(String(s.get("target", "Back")), true, false)
				if back != null:
					_scroll_to(back)   # a target down a scrolling panel comes into view first
				if back != null and back.is_visible_in_tree() and game.hud.coach_control(back, String(s.inside), true):
					_shown = "inside%d" % i


func _scroll_to(c: Control) -> void:
	var p := c.get_parent()
	while p != null:
		if p is ScrollContainer:
			(p as ScrollContainer).ensure_control_visible(c)
			return
		p = p.get_parent()


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
	game.end_menu_tour()
	if skipped:
		game._show_menu_text()   # the title panel back
		return
	game.hud.show_banner("YOU'RE ALL SET!", "Tap anywhere to start running." if steps == STEPS else "Happy crafting! Tap anywhere to run.", Color(1.0, 0.85, 0.45), 3.0)
	# the title panel comes back once the banner has gone (it sat on top of it)
	game.get_tree().create_timer(3.2).timeout.connect(game._show_menu_text)
