extends Node2D
## Game controller: states, input, world speed, collisions, scoring.

enum State { TITLE, INTRO, PLAYING, DYING, OVER, PAUSED, INFO }

var state := State.TITLE
var _menu_t := 0.0             # main menu: taps wait this long after the summary card (MENU_GRACE)
var played_once := false       # a run has ended this session (the menu says "run again")
var tutorial: Tutorial         # coach hints (tutorial.gd, _coach_step)
var tutorial_run: TutorialRun  # the training run while it plays (tutorial_run.gd), else null
var menu_tour: MenuTour     # the menu tour after a finished training run (menu_tour.gd), else null
var tutorial_run_done := true  # the training run has been played (or skipped); it plays once, on a fresh save
var lent_raptor := false       # the training run lent the Raptor (end_tutorial takes it back)
var _slot_wait := 0.0          # seconds a ready power-up has sat in a slot unused (the booster lesson)
var _ground_jump_t := -1.0     # seconds since the last ground jump while JUMP is still held (-1: none)
var speed := 0.0
var distance := 0.0
var score := 0.0
var best := 0
var best_m := 0
var unlocked: Array = [Forms.ROK]
var seen: Array = []          # intro banners already shown once
var guide_viewed: Array = []  # Field Guide entries already looked at
var boosters_owned: Array = ["egg"]   # power-ups unlocked (market later); only these appear
var badge_stats := {}        # Badges stat -> value (saved)
var badge_tiers := {}:       # badge id -> tiers earned 0-3 (saved)
	set(v):
		badge_tiers = v
		Badges.earned = v      # the Market reads badge requirements from here
var new_badges: Array = []   # tiers earned this run, for the game-over news
var _clean_from := 0.0       # metres of the last stumble this run (Untouchable)
var _dino_m := 0.0           # metres spent as a dino this run (Primal Spirit)
var hunter_id := "trex"      # the predator chasing Rok now (Hunters), changes with the zone
var charge_state := ""      # T-rex charge: "", "warn" or "charge"
var charge_t := 0.0          # seconds left in that phase
var _next_charge := 0.0      # metres of the next charge this run
var best_flag: BestFlag      # the flag at the best distance (null if no record yet)
var _run_best := 0.0         # best distance when this run began
var dizzy_t := 0.0   # seconds left of mushroom dizziness (lower jumps, wobble)
var dinos_owned: Array = []    # expansion dinosaurs bought in the Market (Dinos ids)
var dino_levels: Dictionary = {}   # id -> {"lv", "pts"} from levelling (Dinos.levels points here)
var dino_xp: Dictionary = {}       # id -> XP, 1 per metre run as it (Dinos.xp points here)
var run_dino_m: Dictionary = {}    # this run: id -> metres run as it (the summary card)
var run_rank: Array = Tuning.RUN_RANKS[0]   # this run's rank (RunSummary.rank_for): its multiplier boosts meat and XP
var run_bonus_meat := 0
var _ranked := false
var codex: Codex
var market: Market
var herd: Herd       # choose and compare the dinosaur on each button
var loader: Preloader   # the loading screen while art preloads (normal launches only)
var bench: Workshop  # the Crafting Bench (workshop.gd, mode "bench")
var items: Workshop  # the Items screen (workshop.gd, mode "items")
var summary: RunSummary   # the end-of-run summary card
## Tests fix the Power roll with this (0 = always breaks through, 0.999 = never); -1 = random.
var roll_override := -1.0
var trex: Trex
var chase_gap := Tuning.CHASE_GAP_MAX   # px between the T-rex's snout and Rok
var _intro_t := 0.0
var _intro_flags := {}
var _bitten := false
var lighting: CanvasModulate     # zone + day/night lighting of the world
var zone_index := 0
var pause_for_info := true      # new unlocks / hazards / zones pause on an info card (tests turn it off)
var _info_queue: Array = []     # [title, body, icon, colour]
var _info_t := 0.0
var last_new_m := -INF          # metres where the last new thing was shown (marination)
var _was_night := false
var speed_mod := 1.0   # hills: <1 climbing, >1 sliding downhill
var boost_t := 0.0     # egg speed boost time left
var power_t := {}      # Market power-up -> seconds left (fossil_magnet, time_crystal, primal_berry, golden_fossil)
var run_meat := 0     # meat collected this run, banked for the Market when it ends
var meat_bank := 0    # Market currency (saved)
var last_run_meat := 0
var _market_announced := {}   # Market items that went on sale this run
var new_this_run: Array = []  # names of everything new met this run (game-over summary)
var new_market: Array = []    # Market item ids that went on sale this run
var market_seen: Array = []   # on-sale Market items already looked at (NEW tags / badge)
var slots: Array = ["", "", ""]   # booster slots (Boosters): one each, different types
var slot_count := Boosters.START_SLOTS   # slots open (distance unlocks the 2nd, Market the 3rd)
var heart_containers := 0   # Heart Containers bought in the Market: each adds a heart
var sink := 0.0        # quicksand: 0 standing .. 1 swallowed
var _was_airborne := false   # quicksand: a landing on it plunges Rok in
var combo := Combo.new()     # combo streak + Primal Frenzy (combo.gd)
var frenzies := 0            # Primal Frenzies this run
var _frenzy_meat := 0.0      # countdown to the next meat drop in a frenzy
var next_chest_m := 0.0      # the next milestone chest (metres)
var preview_done := false    # this run's wild-dinosaur preview has come (Progression.STAMPEDE_PREVIEW_M)
var chests_opened := 0       # milestone chests opened this run
var fossils_found := 0       # rare fossils picked up this run
var events := RunEvents.new()   # mid-run events (run_events.gd)
var attack_cd := 0.0         # seconds until the next attack (main._attack)
var attack_cd_max := 1.0     # its full length (the button's cooldown sweep)
var stop_armed := 0.0        # seconds the Stop button waits for its second tap
var attack_marker: AttackMarker   # brackets over what ATTACK would hit
var bonus_t := 0.0           # seconds left in a bonus zone
var bonus_zones := 0         # bonus zones entered this run
var next_bonus_m := 0.0      # where the next bonus portal may appear (metres)
var portal: BonusPortal      # the portal ahead, if one is out
var _bonus_drop := 0.0
var _bonus_wave := 0.0
var bonus_tint: ColorRect    # the golden-violet wash over the world in a bonus zone
var weather: Weather         # lap twists: storm, fog, eclipse (weather.gd)
var lap := 1                 # which lap of the zones Rok is on
var missions := Missions.new()   # daily missions (missions.gd)
var gear_owned: Array = []         # crafted weapon and armor copies (gear.gd: "stone_axe#3")
var gear_wear: Dictionary = {}     # weapon copy -> uses left (missing = new; Gear.wear)
var gear_rarity: Dictionary = {}   # copy -> rarity 0-4 (missing = Common; Gear.rarity)
var gear_next := 1                 # the next copy number
var materials: Dictionary = {}     # crafting material -> how many (crafting.gd)
var run_materials: Dictionary = {} # materials found this run (for the summary's news)
var gear_equipped: Dictionary = {} # hero -> {"weapon": id or "card:<dino>", "armor": id}
var cards: Dictionary = {}         # dino id -> dinosaur cards owned
var last_card := ""                # the card a wild dinosaur or chest just gave
var _lap_banner_t := 0.0
var energy := Tuning.ENERGY_START
var health := Tuning.MAX_HEARTS * Hearts.QUARTERS   # in quarter hearts (Hearts); every hit costs some, 0 ends the run (max: max_health())
var dino_time := 0.0   # seconds spent as a dino since last being Rok (drives the drain)
var elapsed := 0.0
var shift_cd := 0.0
var _dying_t := 0.0
var death_cause := ""   # for tests/debugging

var world: Node2D
var bg: Background
var terrain: Terrain
var course: Course
var player: Player
var fx: Fx
var hud: Hud
var audio: Audio
var _slide_dust := 0.0
var _bridge := {}   # bridge under the player this frame
var _touches := {}   # touch index -> action it started


func _ready() -> void:
	randomize()
	_setup_input()
	best = SaveData.load_best()
	best_m = SaveData.load_best_m()
	Requires.game = self   # the dependency tree reads the live state (requires.gd)
	tutorial = Tutorial.new(SaveData.load_tutorial())
	tutorial.enabled = SaveData.load_tips()
	if tutorial.progress.is_empty() and best_m >= Tuning.COACH_SKIP_BASICS_M:
		tutorial.skip_basics()   # a returning player already knows the moves
	# the training run plays once, at the very beginning (an existing save has played)
	tutorial_run_done = SaveData.load_tutorial_run_done() or best_m > 0.0
	unlocked = SaveData.load_unlocked()
	seen = SaveData.load_seen()
	missions.from_dict(SaveData.load_missions())
	var g := SaveData.load_gear()
	gear_owned = Array(g.get("owned", []))
	gear_equipped = Dictionary(g.get("equipped", {}))
	cards = Dictionary(g.get("cards", {}))
	gear_wear = Dictionary(g.get("wear", {}))
	gear_rarity = Dictionary(g.get("rarity", {}))
	gear_next = int(g.get("next", 1))
	materials = Dictionary(g.get("materials", {}))
	_sync_gear()
	guide_viewed = SaveData.load_viewed()
	boosters_owned = SaveData.load_unlocked_boosters()
	dinos_owned = SaveData.load_dinos_owned()
	var bl: Array = SaveData.load_badges()
	badge_stats = bl[0]
	badge_tiers = bl[1]
	Codex.species_owned = dinos_owned
	dino_levels = SaveData.load_dino_levels()
	Dinos.levels = dino_levels
	dino_xp = SaveData.load_dino_xp()
	Dinos.xp = dino_xp
	Forms.clear_cache()
	var eq: Dictionary = SaveData.load_equipped()
	Forms.equipped.clear()
	for cat in eq:
		if Dinos.CATEGORIES.has(cat) and dinos_owned.has(eq[cat]):
			Forms.equip(Dinos.slot_of(cat), eq[cat])
		elif cat == "hero" and Heroes.has(eq[cat]) and dinos_owned.has(eq[cat]):
			Forms.equip(Forms.ROK, eq[cat])
	slot_count = SaveData.load_booster_slots()
	heart_containers = SaveData.load_heart_containers()
	Market.hearts_owned = heart_containers
	Market.best_score = best
	meat_bank = SaveData.load_meat()
	market_seen = SaveData.load_market_seen()
	if best_m >= Progression.SLOT_UNLOCK_M and slot_count < 2:
		slot_count = 2   # already earned on an older save
		SaveData.save_booster_slots(slot_count)
	world = Node2D.new()
	add_child(world)
	lighting = CanvasModulate.new()
	add_child(lighting)
	bg = Background.new()
	world.add_child(bg)
	terrain = Terrain.new()
	world.add_child(terrain)
	course = Course.new()
	course.terrain = terrain
	world.add_child(course)
	trex = Trex.new()
	world.add_child(trex)
	trex.position = Vector2(-900, Tuning.GROUND_Y)
	trex.stomped.connect(func(close: float): audio.play("stomp", 0.08, 1.0, -16.0 + 14.0 * close))
	course.introduce_ok = _can_introduce
	terrain.introduce_ok = _can_introduce
	course.introduced.connect(_on_introduced)
	terrain.introduced.connect(_on_introduced)
	terrain.gate_built.connect(course.terrain_gate)
	terrain.deep_sand_built.connect(course.deep_sand)
	fx = Fx.new()
	world.add_child(fx)
	world.add_child(bg.foreground)
	fx.shake_target = world
	audio = Audio.new()
	add_child(audio)
	var tint_layer := CanvasLayer.new()   # under the HUD
	add_child(tint_layer)
	bonus_tint = ColorRect.new()
	bonus_tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bonus_tint.set_anchors_preset(Control.PRESET_FULL_RECT)
	bonus_tint.color = Color(0.75, 0.45, 1.0, 0.0)
	tint_layer.add_child(bonus_tint)
	weather = Weather.new()
	add_child(weather)
	hud = Hud.new()
	add_child(hud)
	hud.combo_meter.combo = combo
	combo.tier_up.connect(_on_combo_tier)
	combo.broken.connect(_on_combo_broken)
	combo.frenzy_started.connect(_on_frenzy_started)
	combo.frenzy_ended.connect(_on_frenzy_ended)
	hud.set_sound_icon(audio.muted)
	codex = Codex.new()
	add_child(codex)
	codex.closed.connect(func(): audio.play("click", 0.0))
	market = Market.new()
	market.game = self
	add_child(market)
	market.closed.connect(func():
		audio.play("click", 0.0)
		_show_menu_text())
	summary = RunSummary.new()
	add_child(summary)
	herd = Herd.new()
	herd.game = self
	add_child(herd)
	herd.closed.connect(func():
		audio.play("click", 0.0)
		_show_menu_text())
	for m in ["bench", "items"]:
		var w := Workshop.new()
		w.mode = m
		w.game = self
		add_child(w)
		w.closed.connect(func():
			audio.play("click", 0.0)
			if herd.visible:
				herd.refresh()   # back on the Camp: gear may have changed
			else:
				_show_menu_text())
		if m == "bench":
			bench = w
		else:
			items = w
	audio.start_music()
	_spawn_player()
	_to_title()
	if get_tree().current_scene == self:   # a normal launch (test and screenshot scripts skip it)
		loader = Preloader.new()
		loader.game = self
		add_child(loader)


func _spawn_player() -> void:
	if player:
		player.queue_free()
	player = Player.new()
	player.position = Vector2(Tuning.PLAYER_X, Tuning.GROUND_Y)
	world.add_child(player)
	world.move_child(player, trex.get_index() + 1)   # in front of the T-rex
	player.headroom_clear = _headroom_clear
	player.flapped.connect(func(): audio.play("flap", 0.1))
	player.slid.connect(func():
		audio.play("slide", 0.08)
		fx.dust(player.position, true))
	player.stepped.connect(_on_step)
	player.landed.connect(func(hard):
		fx.dust(player.position, hard)
		if _heavy():
			audio.play("land_heavy", 0.08)
			fx.add_shake(4.0 if hard else 2.0)
		elif hard:
			audio.play("land")
		_surface_step())
	player.jumped.connect(func(air):
		if air:
			_coach_done("double_jump")
		else:
			_ground_jump_t = 0.0
		fx.dust(player.position, false)
		audio.play("double_jump" if air else JUMP_SOUND.get(player.form, "jump"), 0.06)
		if air:
			fx.sparkle(player.position + Vector2(0, -40), player.data().color))


func _setup_input() -> void:
	var map := {
		"jump": [KEY_SPACE, KEY_UP, KEY_W],
		"slide": [KEY_DOWN, KEY_S],
		"attack": [KEY_F],
		"stop": [KEY_X],
		"form_1": [KEY_1], "form_2": [KEY_2], "form_3": [KEY_3], "form_4": [KEY_4], "form_5": [KEY_5],
		"form_prev": [KEY_Q], "form_next": [KEY_E, KEY_SHIFT],
		"pause": [KEY_P, KEY_ESCAPE],
		"restart": [KEY_R],
		"tips": [KEY_T],
		"codex": [KEY_C],
		"market": [KEY_M, KEY_K],
		"herd": [KEY_H],
		"tutorial": [KEY_U],
		"note_back": [KEY_LEFT, KEY_BACKSPACE],
		"booster_1": [KEY_B],
		"booster_2": [KEY_N],
		"booster_3": [KEY_COMMA],
	}
	for action in map:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for k in map[action]:
			var e := InputEventKey.new()
			e.physical_keycode = k
			InputMap.action_add_event(action, e)


# ------------------------------------------------------------------ states

## The main menu (the title screen): run, or go to the Field Guide, Camp or
## Market. A run's summary card leads here (the user's flow), so a tap right
## after the card can't start a run by accident (MENU_GRACE).
func _to_title() -> void:
	var after_run := state == State.OVER
	hud.refresh_form_icons()   # an equipped hero/dinosaur from the save
	summary.hide_run()
	state = State.TITLE
	_menu_t = Tuning.MENU_GRACE if after_run else 0.0
	speed = 0.0
	player.idle()
	hud.show_title(best, best_m, unlocked, meat_bank, played_once)
	_show_missions()
	_refresh_hud()


## Starts a run. With intro (the default) the T-rex charges in and roars
## first; tests pass false to start running straight away.
func start_run(intro := true) -> void:
	Preloader.warm_forms()   # a dinosaur equipped since loading is ready before the run moves
	if menu_tour != null:
		menu_tour = null
		hud.hide_coach()
	summary.hide_run()
	if player:   # no power-up effects carried into a new run
		player.pfx_aura.visible = false
		player.pfx_once.visible = false
	course.reset()
	terrain.reset()
	if player.dead or player.form != Forms.ROK or not player.visible:
		_spawn_player()
	player.position = Vector2(Tuning.PLAYER_X, Tuning.GROUND_Y)
	_bitten = false
	_freeze_world(false)
	_info_queue.clear()
	hud.hide_info()
	last_new_m = -INF
	speed_mod = 1.0
	dizzy_t = 0.0
	dino_time = 0.0
	player.react_stop()
	player.reset_actions()   # no slide, cooldown or attack clip carried over
	tutorial.new_run()
	hud.hide_coach()
	_slot_wait = 0.0
	_ground_jump_t = -1.0
	charge_state = ""
	charge_t = 0.0
	hunter_id = Hunters.for_zone(Zones.zone_at(0.0).id)
	trex.set_hunter(hunter_id)
	# every run starts in the first zone, so coming back to it a lap later
	# isn't a first visit (it used to show a NEW ZONE card and hold lessons)
	if not seen.has("zone_" + Zones.ZONES[0].id):
		seen.append("zone_" + Zones.ZONES[0].id)
	new_badges.clear()
	_clean_from = 0.0
	_dino_m = 0.0
	_next_charge = Progression.next_charge_m(1.0)
	_run_best = best_m
	if best_flag:
		best_flag.queue_free()
		best_flag = null
	if best_m >= 50:
		best_flag = BestFlag.new().setup(int(best_m))
		world.add_child(best_flag)
		world.move_child(best_flag, player.get_index())   # behind Rok
	player.jump_mult = 1.0
	player.sprite.rotation = 0.0
	slots = ["", "", ""]
	last_run_meat = 0
	run_materials.clear()
	_market_announced.clear()
	new_this_run.clear()
	run_dino_m.clear()
	_ranked = false
	run_bonus_meat = 0
	run_rank = Tuning.RUN_RANKS[0]
	new_market.clear()
	course.boosters_owned = boosters_owned
	_roar_t = 8.0
	_growled = false
	boost_t = 0.0
	power_t.clear()
	_bank_meat()
	sink = 0.0
	_was_airborne = false
	player.sand_grip = 1.0
	player.reset_celebration()
	combo.reset()
	attack_cd = 0.0
	frenzies = 0
	_frenzy_meat = 0.0
	chests_opened = 0
	fossils_found = 0
	# a starter chest before the first milestone ([early] starter_chest_m)
	next_chest_m = Progression.STARTER_CHEST_M if Progression.STARTER_CHEST_M > 0.0 else Tuning.CHEST_EVERY_M
	preview_done = false
	events.reset(0.0)
	course.force_meat = false
	hud.set_event("")
	_end_bonus(false)
	bonus_zones = 0
	lap = 1
	_lap_banner_t = 0.0
	hud.set_missions([])
	if missions.refresh(Time.get_date_string_from_system(), best_m, unlocked):
		SaveData.save_missions(missions.to_dict())
	weather.set_twist("", "")
	next_bonus_m = Tuning.BONUS_FROM_M + randf_range(0.0, 500.0)
	zone_index = 0
	_was_night = false
	_intro_flags.clear()
	if intro:
		state = State.INTRO
		_intro_t = 0.0
		speed = 0.0
		player.idle()
		player.position.x = Tuning.INTRO_PLAYER_X   # room to see the whole T-rex
		chase_gap = 1100.0
		trex.run()
	else:
		state = State.PLAYING
		speed = Tuning.START_SPEED
		player.sprite.play("run")
		chase_gap = Tuning.CHASE_GAP_START
		trex.run()
	trex.follow(player.position.x, chase_gap, terrain, 1.0)
	distance = 0.0
	score = 0.0
	elapsed = 0.0
	energy = Tuning.ENERGY_START
	health = max_health()
	hud.hide_center()
	audio.start_music()


func _game_over() -> void:
	if tutorial_run != null:
		start_tutorial(tutorial_run.i)   # the training run can't be lost: that step again
		return
	state = State.DYING
	_bank_meat()
	_dying_t = 0.0
	speed = 0.0
	player.die()
	fx.add_shake(8.0)
	audio.play("hit", 0.0)
	_freeze_world(true)
	audio.play("death_jingle", 0.0)


## Mario-style: when Rok dies, everyone else stops in place (scrolling,
## the T-rex, obstacles, plants, particles) and the music ducks. Only Rok
## (and screen-shake / popups) keep moving.
func _freeze_world(on: bool) -> void:
	for c in world.get_children():
		if c == player or c == fx:
			continue
		c.process_mode = Node.PROCESS_MODE_DISABLED if on else Node.PROCESS_MODE_INHERIT
	audio.duck_music(on)


## The T-rex closed the gap: it freezes mid-bite along with everything else.
func _caught() -> void:
	if tutorial_run != null:
		start_tutorial(tutorial_run.i)   # the training run can't be lost: that step again
		return
	death_cause = "caught"
	trex.bite()
	trex.sprite.frame = 4
	audio.play("bite", 0.0)
	_bitten = true
	_game_over()


func _bite() -> void:
	if _bitten:
		return
	_bitten = true
	trex.bite()
	audio.play("bite", 0.0)
	fx.add_shake(10.0)


func _fell_in_pit() -> void:
	if tutorial_run != null:
		start_tutorial(tutorial_run.i)   # the training run can't be lost: that step again
		return
	speed = 0.0
	var liquid := terrain.liquid_at(player.position.x)
	death_cause = liquid if liquid != "" else "pit"
	if liquid != "":
		fx.splash(Vector2(player.position.x, terrain.liquid_surface(player.position.x)),
				Color(1.0, 0.5, 0.1) if liquid == "lava" else Color(0.5, 0.75, 1.0))
	_bank_meat()
	state = State.DYING
	_dying_t = 0.4
	player.dead = true
	player.visible = false
	fx.add_shake(10.0)
	audio.play("fall", 0.0)
	_freeze_world(true)
	audio.play("death_jingle", 0.0)


func metres() -> float:
	return distance / Tuning.PX_PER_M


func _finish_game_over() -> void:
	state = State.OVER
	played_once = true
	_save_tutorial()
	var s := int(score)
	var new_best := s > best
	if new_best:
		# Heart Containers go on sale by best score: crossing a threshold is news
		for hid in Market.HEART_IDS:
			var need := Market.unlock_score(hid)
			if best < need and s >= need and not new_market.has(hid):
				new_market.append(hid)
		best = s
		SaveData.save_best(best)
		Market.best_score = best
	var m := int(metres())
	var record := m > best_m
	if m > best_m:
		best_m = m
		SaveData.save_best_m(best_m)
	var highlights: Array = []
	if chests_opened > 0 or fossils_found > 0:
		var parts: Array = []
		if chests_opened > 0:
			parts.append("%d chest%s opened" % [chests_opened, "" if chests_opened == 1 else "s"])
		if fossils_found > 0:
			parts.append("%d rare fossil%s" % [fossils_found, "" if fossils_found == 1 else "s"])
		highlights.append(", ".join(parts))
	if combo.best >= int(Tuning.COMBO_TIERS[1][0]):
		highlights.append("Best combo: %d" % combo.best + (", %d Primal Frenz%s" % [frenzies, "y" if frenzies == 1 else "ies"] if frenzies > 0 else ""))
	var news: Array = highlights + new_this_run + new_market.map(func(id): return "Market: " + Market.item_name(id)) + new_badges
	hud.show_game_over(s, best, new_best, m, best_m, unlocked, death_cause == "caught", last_run_meat, meat_bank, news)
	# the summary card replaces the plain game-over text
	# Rok first (he levels too), then the dinosaurs played, most metres first
	var played := run_dino_m.keys().filter(func(id): return float(run_dino_m[id]) >= 1.0)
	played.sort_custom(func(a, b): return Heroes.is_hero(a) or (not Heroes.is_hero(b) and float(run_dino_m[a]) > float(run_dino_m[b])))
	summary.show_run({"caught": death_cause == "caught", "cause": death_cause, "metres": m, "score": s, "best_m": best_m,
			"new_best": new_best, "new_best_m": record, "meat": last_run_meat, "banked": meat_bank,
			"rank": run_rank, "bonus_meat": run_bonus_meat, "xp_mult": xp_mult(),
			"zones": int(floorf(float(m) / Zones.ZONE_LEN_M)) + 1, "dinos": played.map(func(id): return [id, run_dino_m[id]]), "news": news})
	hud.center_panel.visible = false


## First appearance of a hazard: banner with a hint, unless it has already
## been taught (banner seen before, or the best run went past it).
func _on_introduced(key: String) -> void:
	if tutorial_run != null:
		return   # the training run teaches its own way
	var e := Progression.intro_entry(key)
	if e.is_empty() or e[2] == "" or (state != State.PLAYING and state != State.INFO):
		return
	if Progression.taught(key, best_m, seen):
		return
	seen.append(key)
	if key == "stampede" or key == "swooper":   # the lesson's card covers its first species
		seen.append("critter_" + Critters.for_zone(Zones.zone_at(metres()).id, key))
	SaveData.save_seen(seen)
	last_new_m = metres()
	new_this_run.append(e[2])
	audio.play("intro", 0.0)
	if pause_for_info:
		queue_info("NEW: " + e[2], Progression.hint(key, unlocked), _intro_icon(key), Color(1.0, 0.7, 0.25))
	else:
		hud.show_banner("NEW: " + e[2], Progression.hint(key, unlocked), Color(1.0, 0.85, 0.4))


# ------------------------------------------------------------------ info cards

## Something new: pause on an info card (queued if one is already showing).
func queue_info(title: String, body: String, icon: Texture2D, color: Color) -> void:
	_info_queue.append([title, body, icon, color])
	if state == State.PLAYING:
		_next_info()


func _next_info() -> void:
	if _info_queue.is_empty():
		hud.hide_info()
		state = State.PLAYING
		return
	var c: Array = _info_queue.pop_front()
	state = State.INFO
	_info_t = 0.0
	player.release_jump()
	player.release_slide()
	hud.show_info(c[0], c[1], c[2], c[3])


func _info_step(delta: float) -> void:
	var was := _info_t
	_info_t += delta
	if was < Tuning.INFO_MIN_TIME and _info_t >= Tuning.INFO_MIN_TIME:
		hud.show_info_ready()


func _dismiss_info() -> void:
	if state == State.INFO and _info_t >= Tuning.INFO_MIN_TIME:
		audio.play("click", 0.0)
		_next_info()


## Picture for a hazard's info card: its look in the zone Rok is in
## (HazardIcons, shared with the Field Guide).
func _intro_icon(key: String) -> Texture2D:
	return HazardIcons.icon(key, Zones.zone_at(metres()).id)


## Marination: a hazard nobody has been taught yet is only introduced once
## the last new thing has had MARINATE_M metres to sink in, and never within
## BIG_CLEARANCE_M before a big moment (a dino unlock, the first visit to a
## zone, a booster slot). Things without a card, and things already taught,
## are never held back.
func _can_introduce(key: String) -> bool:
	var e := Progression.intro_entry(key)
	if e.is_empty() or e[2] == "" or seen.has(key) or Progression.taught(key, best_m, seen):
		return true
	var m := metres()
	if m - last_new_m < Progression.MARINATE_M:
		return false
	if next_big_m(m) - m < Progression.BIG_CLEARANCE_M:
		return false
	# a zone's own lesson goes first while you're in that zone
	var zid: String = Zones.zone_at(m).id
	if Progression.ZONE_LESSONS.get(key, "") != zid:
		for k in Progression.ZONE_LESSONS:
			if Progression.ZONE_LESSONS[k] == zid and Progression.available(k, m) \
					and not seen.has(k) and not Progression.taught(k, best_m, seen):
				return false
	return true


## Where the next big moment of this run is: a dino unlock, the first-ever
## visit to a zone, the second booster slot or the first T-rex charge. INF if
## none is left.
func next_big_m(m: float) -> float:
	var nxt := INF
	for f in Progression.UNLOCKS:
		if not unlocked.has(f) and Progression.UNLOCKS[f] > m:
			nxt = minf(nxt, Progression.UNLOCKS[f])
	if slot_count < 2 and Progression.SLOT_UNLOCK_M > m:
		nxt = minf(nxt, Progression.SLOT_UNLOCK_M)
	for i in Zones.ZONES.size():
		var start: float = i * Zones.ZONE_LEN_M
		if start > m and not seen.has("zone_" + Zones.ZONES[i].id):
			nxt = minf(nxt, start)
	# the first T-rex charge ever (it has its own card)
	if not seen.has("trex_charge") and not Progression.TREX_CHARGE_M.is_empty() and Progression.TREX_CHARGE_M[0] > m:
		nxt = minf(nxt, Progression.TREX_CHARGE_M[0])
	return nxt


## Dinosaurs unlock permanently when a run first reaches their distance.
func _check_unlocks() -> void:
	var m := metres()
	for f in Progression.UNLOCKS:
		if not unlocked.has(f) and m >= Progression.UNLOCKS[f]:
			unlocked.append(f)
			SaveData.save_unlocked(unlocked)
			# announce the button's own dinosaur (an equipped species just
			# takes over its button once it's unlocked)
			var d: Dictionary = Forms.DATA[f]
			last_new_m = metres()
			new_this_run.append(d.name)
			if pause_for_info:
				queue_info("NEW DINO: " + d.name.to_upper() + "!",
						"%s.\nTap its button to transform.%s\n\nDid you know? %s" % [d.desc,
							"\nDinos tire fast: the longer you stay one, the faster energy drains. Change back to Rok to recharge with amber." if unlocked.size() == 2 else "",
							DinoFacts.for_id(d.id).get("quiz", "")],
						SpriteLib.tex("res://assets/portraits/%s.png" % d.id), d.color)
			else:
				hud.show_banner("NEW DINO: " + d.name.to_upper() + "!",
						"%s. Tap its button to transform" % d.desc, d.color.lightened(0.3), 3.2)
			hud.celebrate(f)
			audio.play("unlock", 0.0)
			energy = maxf(energy, 60.0)   # enough amber to try it right away
			course.force_gate(Progression.gate_for_form(f))   # ...and its gate comes next
			fx.transform_puff(player.position + Vector2(0, -90), d.color)
	# the second booster slot unlocks by distance (the third comes from the Market)
	if slot_count < 2 and m >= Progression.SLOT_UNLOCK_M:
		slot_count = 2
		SaveData.save_booster_slots(slot_count)
		last_new_m = m
		new_this_run.append("2nd booster slot")
		var body := "You can now carry 2 different boosters at once. A third slot will be sold in the Market."
		if pause_for_info:
			queue_info("NEW BOOSTER SLOT!", body, Boosters.icon("egg"), Color(1.0, 0.8, 0.35))
		else:
			hud.show_banner("NEW BOOSTER SLOT!", body, Color(1.0, 0.85, 0.5), 3.2)
		hud.pulse_slot(1)
		audio.play("unlock", 0.0)
	# Market items go on sale by best distance. They're announced on the
	# game-over screen (not mid-run, so they never pile onto a lesson card).
	for id in Market.items():
		var at := Market.unlock_m(id)
		if at > 0 and best_m < at and m >= at and not _market_announced.has(id):
			_market_announced[id] = true
			new_market.append(id)


# ------------------------------------------------------------------ input

## Keyboard (desktop / testing).
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.echo:
		return
	if is_instance_valid(loader):
		return   # still loading
	if codex.visible:
		if event.is_action_pressed("pause") or event.is_action_pressed("codex"):
			codex.close_guide()
		return
	if market.visible:
		if event.is_action_pressed("pause") or event.is_action_pressed("market"):
			market.close_market()
		return
	for w in [bench, items]:
		if w.visible:
			if event.is_action_pressed("pause"):
				w.close_screen()
			return
	if herd.visible:
		if event.is_action_pressed("pause") or event.is_action_pressed("herd"):
			herd.close_herd()
		return
	if menu_tour != null and state == State.TITLE:
		# the menu tour: only its highlighted button's key works
		var wanted := menu_tour.want()
		if not (wanted != "" and event.is_action_pressed(wanted)):
			for act in ["jump", "restart", "tutorial", "codex", "market", "herd"]:
				if event.is_action_pressed(act):
					menu_tour.stray_tap()
					return
	if event.is_action_pressed("herd") and (state == State.TITLE or state == State.OVER):
		open_herd()
		return
	if event.is_action_pressed("tutorial") and state == State.TITLE and not (_overlay_open()):
		replay_tutorial()
		return
	if event.is_action_pressed("market") and (state == State.TITLE or state == State.OVER):
		open_market()
		return
	if event.is_action_pressed("codex") and state != State.PLAYING and state != State.DYING:
		open_guide()
		return
	match state:
		State.INFO:
			if event.is_action_pressed("jump") or event.is_action_pressed("pause"):
				_dismiss_info()
		State.TITLE:
			if (event.is_action_pressed("jump") or event.is_action_pressed("restart")) and _menu_t <= 0.0:
				_start_from_menu()
		State.OVER:   # the summary card: on to the main menu (R still restarts straight away)
			if event.is_action_pressed("restart"):
				start_run()
			elif event.is_action_pressed("jump"):
				_to_title()
		State.INTRO:
			pass   # the roar plays out (about 1.7 s)
		State.PLAYING:
			if tutorial_run != null and tutorial_run.frozen:
				# only a real key press counts (mouse motion, drags and key
				# releases used to skip the training run's notes)
				var pressed_key: bool = (event is InputEventKey or event is InputEventJoypadButton) and event.is_pressed() and not event.is_echo()
				if not pressed_key or not _tutorial_allows(_key_action(event)):
					return
			if event.is_action_pressed("jump"):
				player.press_jump()
			elif event.is_action_released("jump"):
				_release_jump()
			elif event.is_action_pressed("booster_1"):
				use_slot(0)
			elif event.is_action_pressed("booster_2"):
				use_slot(1)
			elif event.is_action_pressed("booster_3"):
				use_slot(2)
			elif event.is_action_pressed("slide"):
				player.press_slide()
			elif event.is_action_released("slide"):
				player.release_slide()
			elif event.is_action_pressed("attack"):
				_attack()
			elif event.is_action_pressed("stop"):
				_press_stop()
			elif event.is_action_pressed("pause"):
				_pause()
			else:
				for i in Forms.ORDER.size():
					if event.is_action_pressed("form_%d" % (i + 1)):
						_request_form(Forms.ORDER[i])
				if event.is_action_pressed("form_next"):
					_request_form(Forms.ORDER[(Forms.ORDER.find(player.form) + 1) % Forms.ORDER.size()])
				elif event.is_action_pressed("form_prev"):
					_request_form(Forms.ORDER[(Forms.ORDER.find(player.form) + Forms.ORDER.size() - 1) % Forms.ORDER.size()])
		State.PAUSED:
			if event.is_action_pressed("pause"):
				_resume()
			elif event.is_action_pressed("tips"):
				_toggle_tips()


## Touch (mobile). The mouse is turned into touches by the project setting
## input_devices/pointing/emulate_touch_from_mouse, so desktop clicks work too.
## Each finger is tracked separately, so you can hold JUMP and tap a form.
func _input(event: InputEvent) -> void:
	if is_instance_valid(loader):
		get_viewport().set_input_as_handled()   # still loading: taps wait
		return
	var t := event as InputEventScreenTouch
	if t == null or _overlay_open():
		return   # the Field Guide is ordinary GUI: let its buttons and scrolling have the touch
	get_viewport().set_input_as_handled()
	if t.pressed:
		var a := hud.action_at(t.position)
		_touches[t.index] = a
		hud.set_held(a, true)
		_touch_pressed(a)
	else:
		var a: String = _touches.get(t.index, "")
		_touches.erase(t.index)
		hud.set_held(a, false)
		if state == State.PLAYING and (a == "jump" or a == ""):
			_release_jump()
		elif a == "slide":
			player.release_slide()


func _touch_pressed(a: String) -> void:
	if state == State.INFO:
		_dismiss_info()
		return
	if state == State.OVER:
		if a != "sound":
			audio.play("click", 0.0)
			_to_title()   # the summary card leads to the main menu
			return
	if menu_tour != null and state == State.TITLE and a != "sound" and a != menu_tour.want():
		menu_tour.stray_tap()   # only the highlighted button works during the tour
		return
	if a == "codex":
		if state != State.PLAYING and state != State.DYING:
			audio.play("click", 0.0)
			open_guide()
		return
	if a == "market":
		if state == State.TITLE:
			audio.play("click", 0.0)
			open_market()
		return
	if a == "herd":
		if state == State.TITLE:
			audio.play("click", 0.0)
			open_herd()
		return
	if a == "tutorial":
		if state == State.TITLE:
			replay_tutorial()
		return
	if a == "stop":
		_press_stop()
		return
	if a == "tips":
		if state == State.PAUSED:
			_toggle_tips()
		return
	if a == "sound":
		audio.set_muted(not audio.muted)
		hud.set_sound_icon(audio.muted)
		audio.play("click", 0.0)
		return
	match state:
		State.TITLE:
			if a != "pause" and _menu_t <= 0.0:
				_start_from_menu()
		State.PLAYING:
			if a == "" and tutorial_run != null and tutorial_run.tap_grace > 0.0:
				return   # the tap right after closing a note isn't a jump
			if a != "pause" and not _tutorial_allows("jump" if a == "" else a):
				return
			if a == "pause":
				audio.play("click", 0.0)
				_pause()
			elif a.begins_with("form_"):
				_request_form(int(a.substr(5)))
			elif a == "slide":
				player.press_slide()
			elif a == "attack":
				_attack()
			elif a.begins_with("slot_"):
				use_slot(int(a.substr(5)))
			else:
				player.press_jump()   # JUMP button or anywhere else on screen
		State.PAUSED:
			audio.play("click", 0.0)
			_resume()


func open_market() -> void:
	_coach_done("market")
	_save_tutorial()
	market.open_market()
	# everything on sale has now been seen: the NEW tags go next time
	for id in Market.items():
		if Market.on_sale(id, best_m) and not market_seen.has(id):
			market_seen.append(id)
	SaveData.save_market_seen(market_seen)


## The Herd: choose and compare the dinosaur on each button.
func open_herd(cat := "") -> void:
	_coach_done("camp")
	_save_tutorial()
	herd.open_herd(cat)


## The Crafting Bench opens at a best distance (config/crafting.cfg [unlock]).
func bench_open() -> bool:
	return best_m >= Crafting.bench_m()


## The Crafting Bench and the Items screen (opened from the Camp's header).
func open_bench(t := "") -> void:
	if not bench_open():
		audio.play("denied", 0.0)
		return
	bench.open_screen(t)


func open_items(t := "") -> void:
	items.open_screen(t)


## A full screen (Field Guide, Market, Camp, Crafting Bench, Items) is open.
func _overlay_open() -> bool:
	return codex.visible or market.visible or herd.visible or (bench != null and bench.visible) or (items != null and items.visible)


## Market items on sale that haven't been looked at yet.
func market_new() -> Array:
	return Market.items().filter(func(id): return Market.on_sale(id, best_m) and not market.owns(id) and not market_seen.has(id))


## Heroes and dinosaurs you own that can level up right now (enough XP and
## meat, not maxed): the Camp button and their rows show a red dot.
func level_ready() -> Array:
	var out: Array = []
	var ids: Array = Heroes.IDS.filter(func(h): return h == "rok" or dinos_owned.has(h))
	for f in Forms.ORDER:
		if f != Forms.ROK and unlocked.has(f):
			ids.append(Forms.DATA[f].id)
	ids.append_array(dinos_owned.filter(func(d): return Dinos.has(d)))
	for id in ids:
		if Dinos.can_level(id) and Dinos.xp_ok(id) and meat_bank >= Dinos.level_cost(id):
			out.append(id)
	return out


## Something to equip: an owned hero with an empty slot it has gear or cards for.
func gear_ready() -> bool:
	for h in Heroes.IDS.filter(func(x): return x == "rok" or dinos_owned.has(x)):
		for slot in ["weapon", "armor"]:
			if Gear.slot_item(h, slot) == "" and not Gear.choices(slot).is_empty():
				return true
	return false


## Red dot on the Market button: something new on sale, or something you can afford.
func market_badge() -> bool:
	return not market_new().is_empty() or Market.items().any(func(id):
		return not market.owns(id) and meat_bank >= Market.price(id) and Market.on_sale(id, best_m))


## Owned: the originals and Rok always; bought dinosaurs and heroes once bought.
func owns_form(id: String) -> bool:
	return dinos_owned.has(id) or (not Dinos.has(id) and not Heroes.has(id))


## Put an owned expansion dinosaur on its category's button (saved). It's
## used once that button is unlocked by distance. Returns true if equipped.
## A bought hero (Nira, Boro) goes on the ROK button; "rok" puts Rok back.
func equip(id: String) -> bool:
	if Heroes.is_hero(id):
		if not owns_form(id):
			return false
		Forms.equip(Forms.ROK, "" if id == "rok" else id)
		_save_equipped()
		if not player.dead and player.form == Forms.ROK:
			player.refresh_form()   # show the new hero's sprite right away
		return true
	if not Dinos.ROSTER.has(id) or not Dinos.playable(id) or not dinos_owned.has(id):
		return false
	Forms.equip(Dinos.slot_of(Dinos.category_of(id)), id)
	_save_equipped()
	return true


## Level up an owned dinosaur (the originals count as owned): +1 to `attr`,
## paid in meat (Dinos.level_cost). Returns true if it levelled.
func level_up(id: String, attr: String) -> bool:
	if not Dinos.known(id) or not owns_form(id):
		return false
	if not Dinos.can_raise(id, attr) or not Dinos.xp_ok(id):
		return false   # at its cap, or not enough XP yet (run more as it)
	var cost := Dinos.level_cost(id)
	if meat_bank < cost:
		return false
	meat_bank -= cost
	SaveData.save_meat(meat_bank)
	Dinos.levels = dino_levels
	var g := Dinos.gain(id, attr)
	var e := Dinos.level_entry(id)
	e.pts[attr] = snappedf(float(e.pts.get(attr, 0.0)) + g, 0.01)
	e.lv = int(e.lv) + 1
	SaveData.save_dino_levels(dino_levels)
	Forms.clear_cache()
	hud.refresh_form_icons()
	audio.play("unlock", 0.0)
	return true


## Back to the button's original dinosaur.
func unequip(cat: String) -> void:
	if cat == "hero" or cat == "rok":
		Forms.equip(Forms.ROK, "")
		_save_equipped()
		return
	Forms.equip(Dinos.slot_of(cat), "")
	_save_equipped()


## The species a category's button uses now.
func equipped_in(cat: String) -> String:
	if cat == "hero" or cat == "rok":
		return Forms.get_data(Forms.ROK).id
	return Forms.get_data(Dinos.slot_of(cat)).id


func _save_equipped() -> void:
	var eq := {}
	if Forms.equipped.has(Forms.ROK):
		eq["hero"] = Forms.equipped[Forms.ROK]
	for cat in Dinos.CATEGORIES:
		var f := Dinos.slot_of(cat)
		if Forms.equipped.has(f):
			eq[cat] = Forms.equipped[f]
	SaveData.save_equipped(eq)
	hud.refresh_form_icons()
	if player.form != Forms.ROK and not player.dead:
		player.shift_to(Forms.ROK)


## Buy a Market item with banked amber. Returns true if it was bought.
func buy(id: String) -> bool:
	var cost := Market.price(id)
	if market.owns(id) or meat_bank < cost or not Market.on_sale(id, best_m):
		audio.play("denied", 0.0)
		return false
	meat_bank -= cost
	SaveData.save_meat(meat_bank)
	if id == Market.SLOT_ID:
		slot_count = Boosters.MAX_SLOTS
		SaveData.save_booster_slots(slot_count)
	elif Market.is_heart(id):
		heart_containers = Market.heart_index(id)
		Market.hearts_owned = heart_containers
		SaveData.save_heart_containers(heart_containers)
	elif id.begins_with(Crafting.MAT_PREFIX):   # a bundle of a basic material
		grant_materials({id.substr(Crafting.MAT_PREFIX.length()): Crafting.bundle()}, false)
	elif id == Gear.CARD_PACK:
		grant_card(Gear.random_card(false))
	elif Dinos.has(id) or Heroes.has(id):   # bought dinosaurs and heroes live in dinos_owned
		dinos_owned.append(id)
		SaveData.save_dinos_owned(dinos_owned)
		Codex.species_owned = dinos_owned
		badge_best("herd", dinos_owned.filter(func(k): return Dinos.has(k)).size())
	else:
		boosters_owned.append(id)
		SaveData.save_unlocked_boosters(boosters_owned)
	audio.play("unlock", 0.0)
	return true


## Title / game-over text again (after the Market changes the amber total).
func _show_menu_text() -> void:
	if state == State.TITLE:
		hud.show_title(best, best_m, unlocked, meat_bank, played_once)
	elif state == State.OVER:
		hud.show_game_over(int(score), best, false, int(metres()), best_m, unlocked, death_cause == "caught", last_run_meat, meat_bank,
				new_this_run + new_market.map(func(id): return "Market: " + Market.item_name(id)) + new_badges)


func open_guide() -> void:
	codex.boosters_owned = boosters_owned
	Codex.badge_stats = badge_stats
	Codex.badge_tiers = badge_tiers
	codex.open_guide(unlocked, best_m, seen, guide_viewed)
	guide_viewed = codex.viewed_after_open()
	SaveData.save_viewed(guide_viewed)


## The Stop button: the first tap asks (a banner, the button lights up), a
## second tap within STOP_CONFIRM_TIME ends the run: meat and progress are
## kept and the run summary shows ("RUN OVER", cause "stopped").
func _press_stop() -> void:
	if state != State.PLAYING and state != State.PAUSED:
		return
	audio.play("click", 0.0)
	if stop_armed <= 0.0:
		stop_armed = Tuning.STOP_CONFIRM_TIME
		if tutorial_run != null:
			hud.show_banner("SKIP THE TUTORIAL?", "Tap Skip again to skip it. Tips will still help along the way, and the Tutorial button replays it.", Color(1.0, 0.55, 0.45), Tuning.STOP_CONFIRM_TIME)
		else:
			hud.show_banner("STOP THIS RUN?", "Tap the stop button again to end it. Your meat and progress are kept.", Color(1.0, 0.55, 0.45), Tuning.STOP_CONFIRM_TIME)
		return
	stop_run()


## End the run now (from the Stop button): no death, straight to the summary.
func stop_run() -> void:
	if state != State.PLAYING and state != State.PAUSED:
		return
	stop_armed = 0.0
	if state == State.PAUSED:
		_resume()
	if tutorial_run != null:
		end_tutorial(true)
		return
	death_cause = "stopped"
	speed = 0.0
	_freeze_world(true)
	hud.clear_banner()
	_bank_meat()
	_finish_game_over()


func _pause() -> void:
	state = State.PAUSED
	player.release_jump()
	player.release_slide()
	hud.show_pause()


func _resume() -> void:
	state = State.PLAYING
	hud.hide_center()


func _notification(what: int) -> void:
	# auto-pause when the app is backgrounded on mobile
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and state == State.PLAYING:
		_pause()


func _request_form(f: int) -> void:
	if state != State.PLAYING or f == player.form or shift_cd > 0.0:
		return
	if not unlocked.has(f):
		fx.float_text(player.position + Vector2(-60, -200), "Reach %d m to unlock" % Progression.unlock_m(f), Color(1, 0.6, 0.4))
		audio.play("denied", 0.0)
		return
	if f != Forms.ROK and energy < Tuning.SHIFT_MIN_ENERGY and not power_on("primal_berry"):
		fx.float_text(player.position + Vector2(-20, -200), "Need amber!", Color(1, 0.45, 0.35))
		audio.play("denied", 0.0)
		return
	_shift(f)


func _shift(f: int) -> void:
	if f == Forms.ROK and player.form != Forms.ROK and energy < Tuning.COACH_LOW_ENERGY * 1.6:
		_coach_done("energy")
	elif f != Forms.ROK:
		_coach_done("shift")
	var from: Dictionary = player.data()
	player.shift_to(f)
	shift_cd = 0.0 if power_on("primal_berry") else Tuning.SHIFT_COOLDOWN
	var c: Color = Forms.get_data(f).color
	if player.play_transform(from):   # the user's burst hides the change
		fx.add_shake(4.0)
	else:
		fx.transform_puff(player.position + Vector2(0, -70), c)
	audio.play("shift", 0.05)
	audio.play("form_" + Forms.get_data(f).get("sound_id", Forms.get_data(f).id), 0.05)
	fx.float_text(player.position + Vector2(-50, -215), Forms.get_data(f).name.to_upper(), c, 38)


# ------------------------------------------------------------------ loop

func _process(delta: float) -> void:
	delta = minf(delta, 1.0 / 30.0)
	stop_armed = maxf(stop_armed - delta, 0.0)
	_menu_t = maxf(_menu_t - delta, 0.0)
	if player:
		player.set_carry(carry_weapon())   # a run sheet with the weapon drawn in, when there is one
	if menu_tour != null:
		menu_tour.step(delta)
	else:
		_coach_step(delta)
	match state:
		State.TITLE:
			bg.scroll(60.0, delta)  # gentle drift behind the title
			terrain.scroll(0.0)
		State.INTRO:
			_intro_step(delta)
		State.INFO:
			_info_step(delta)
		State.PLAYING:
			if tutorial_run == null or not tutorial_run.frozen:
				_play_step(delta)
			if tutorial_run != null:
				tutorial_run.step(delta)
		State.DYING:
			# everything is frozen (see _freeze_world); only Rok's death plays
			_dying_t += delta
			player.step(delta, Terrain.PIT, 0.0)
			if _dying_t > Tuning.DEATH_FREEZE + 1.7:   # let the death jingle finish
				_finish_game_over()
	_refresh_hud()


## The chase gap. Rok runs at exactly the hunter's pace, so on flat ground as
## Rok the gap never shrinks on its own, and a lead is never faded back: only
## stumbles (trips, snags, dizziness, bumps...), subtracted where they happen,
## climbing (UPHILL_LOSS, except the `fast` Raptor) and hunter charges take
## distance. Each form adds its speed (Forms `chase_rate`): the Raptor and
## Pteranodon pull away, while the heavy Triceratops and Spinosaurus let the
## hunter gain. Sliding downhill, an egg boost and the Time Crystal pull away.
## Any lead you build is kept (up to CHASE_GAP_FAR).
func _update_chase(delta: float, slope: float) -> void:
	var d := player.data()
	var fast: bool = d.get("fast", false)
	var rate: float = Tuning.CHASE_RECOVER + d.get("chase_rate", 0.0)
	if slope < -0.05 and not fast:
		rate -= Tuning.UPHILL_LOSS   # climbing costs ground (the user's call: it makes sense), except for the fast Raptor
	if slope > 0.05 and player.is_low():
		rate += Tuning.SLIDE_DOWNHILL_GAIN
	if boost_t > 0.0:
		rate += Tuning.EGG_CHASE_GAIN
	if power_on("time_crystal"):
		rate += Tuning.SLOW_CHASE_GAIN
	if charge_state == "charge":
		rate -= Hunters.DATA[hunter_id].charge_rate   # it's charging
	if rate > 0.0:
		chase_gap = minf(chase_gap + rate * delta, Tuning.CHASE_GAP_FAR)
	else:
		chase_gap += rate * delta   # a lead is kept: nothing fades it back


var _roar_t := 8.0
var _growled := false


## The T-rex makes itself heard: a roar every so often (louder the closer it
## is) and a growl the moment it gets dangerously close.
func _trex_voice(delta: float) -> void:
	var close := clampf(1.0 - chase_gap / Tuning.CHASE_GAP_MAX, 0.0, 1.0)
	_roar_t -= delta * (1.0 + close * 1.5)
	if _roar_t <= 0.0:
		_roar_t = randf_range(Tuning.TREX_ROAR_EVERY.x, Tuning.TREX_ROAR_EVERY.y)
		audio.play("trex_roar", 0.08, randf_range(0.9, 1.1), -14.0 + 12.0 * close)
		if close > 0.4:
			fx.add_shake(3.0 + 4.0 * close)
	var danger := chase_gap < Tuning.CHASE_DANGER
	if danger and not _growled:
		_growled = true
		audio.play("trex_growl", 0.05)
	elif chase_gap > Tuning.CHASE_DANGER + 40.0:
		_growled = false


## Run start: the T-rex charges in from the left and roars, Rok startles
## and takes off.
func _intro_step(delta: float) -> void:
	_intro_t += delta
	var t := _intro_t
	# 0-0.55 s: the T-rex charges in, fully on screen behind Rok
	if t < 0.55:
		chase_gap = lerpf(1100.0, Tuning.INTRO_ROAR_GAP, ease(t / 0.55, 0.5))
	elif not _intro_flags.has("roar"):
		_intro_flags["roar"] = true
		trex.roar()
		audio.play("trex_roar", 0.0)
	if t > 0.6 and t < 1.2:
		fx.add_shake(7.0)
	# 1.1 s: Rok startles and sprints; he slides back to his running spot while
	# the T-rex settles in behind, mostly off-screen
	if t >= 1.1 and not _intro_flags.has("go"):
		_intro_flags["go"] = true
		player.sprite.play("run")
		fx.float_text(player.position + Vector2(-10, -210), "!", Color(1, 0.9, 0.4), 52)
		audio.play("start", 0.0)
		audio.play("rok_alarm", 0.0)   # Rok shouts: time to run
	if t >= 1.25 and not _intro_flags.has("chase"):
		_intro_flags["chase"] = true
		trex.run()
	if t >= 1.1:
		var k := clampf((t - 1.1) / (Tuning.INTRO_TIME - 1.1), 0.0, 1.0)
		speed = lerpf(0.0, Tuning.START_SPEED, k)
		player.position.x = lerpf(Tuning.INTRO_PLAYER_X, Tuning.PLAYER_X, ease(k, -1.6))
		chase_gap = lerpf(Tuning.INTRO_ROAR_GAP, Tuning.CHASE_GAP_START, k)
	bg.scroll(speed, delta)
	terrain.scroll(speed * delta)
	course.scroll(speed, delta)
	distance += speed * delta
	player.step(delta, _support_y(), maxf(speed, 1.0))
	if speed < 1.0:
		player.sprite.play("idle" if t < 1.1 else "run")
	trex.follow(player.position.x, chase_gap, terrain, delta, maxf(speed, 200.0) / Tuning.START_SPEED)
	if t >= Tuning.INTRO_TIME:
		state = State.PLAYING
		speed = Tuning.START_SPEED
		player.position.x = Tuning.PLAYER_X


func _play_step(delta: float) -> void:
	elapsed += delta
	shift_cd = maxf(shift_cd - delta, 0.0)
	attack_cd = maxf(attack_cd - delta, 0.0)
	# cooldown sweeps on the hero's action buttons (the user's rule: every action shows its wait)
	hud.attack_button.cooldown = attack_cd / maxf(attack_cd_max, 0.01)
	hud.slide_button.cooldown = player.slide_cd / maxf(player.slide_cd_max, 0.01)
	hud.jump_button.cooldown = player.jump_cd / maxf(player.jump_cd_max, 0.01) if player.on_ground else 0.0
	hud.attack_button.cooldown_left = attack_cd
	hud.slide_button.cooldown_left = player.slide_cd
	hud.jump_button.cooldown_left = player.jump_cd if player.on_ground else 0.0
	speed = minf(speed + Tuning.SPEED_RAMP * delta, Tuning.MAX_SPEED)
	course.metres = metres()
	course.specials = [events.current, weather.twist]   # an event or lap twist turns up its own materials
	course.unlocked = unlocked
	terrain.metres = metres()
	terrain.speed = speed
	terrain.runner_ready = unlocked.has(Forms.RAPTOR)
	course.difficulty = Progression.pressure(metres())
	var d := player.data()

	# hills change Rok's pace: slower climbing, faster sliding downhill
	var slope := terrain.slope_at(player.position.x) if player.on_ground else 0.0
	var pace := 1.0
	if slope < -0.05 and not d.get("fast", false):
		pace = Tuning.UPHILL_PACE
	elif slope > 0.05 and player.is_low():
		pace = Tuning.DOWNHILL_SLIDE_PACE
	if boost_t > 0.0:
		boost_t = maxf(boost_t - delta, 0.0)
		pace *= Tuning.EGG_BOOST_PACE
		_boost_fx(delta)
	if power_on("time_crystal"):
		pace *= Tuning.SLOW_PACE
	speed_mod = lerpf(speed_mod, pace, minf(delta * 6.0, 1.0))
	var eff := speed * speed_mod
	bg.scroll(eff, delta)
	terrain.difficulty = course.difficulty
	terrain.scroll(eff * delta)
	course.scroll(eff, delta)
	distance += eff * delta
	score += eff * delta * Tuning.SCORE_PER_PX * d.score_mult * points_mult()
	_power_step(delta)
	_dizzy_step(delta)
	_charge_step(delta)
	_best_flag_step()
	_eat_critters()
	_hunter_step()
	_badge_run_step(eff * delta / Tuning.PX_PER_M)

	# energy drain; revert to Rok when empty (free while a Primal Berry lasts)
	if player.form == Forms.ROK:
		dino_time = 0.0
	elif not power_on("primal_berry"):
		dino_time += delta
		energy -= d.drain * drain_mult() * delta
		if energy <= 0.0:
			energy = 0.0
			_shift(Forms.ROK)

	_check_unlocks()
	_update_chase(delta, slope)
	_trex_voice(delta)
	trex.follow(Tuning.PLAYER_X, chase_gap, terrain, delta, speed / Tuning.START_SPEED)
	if chase_gap <= 0.0:
		_caught()
		return
	player.step(delta, _support_y(), speed)
	_check_bridge()
	player.set_swimming(player.on_ground and player.data().get("swims", false)
			and terrain.liquid_at(player.position.x) == "water")
	if _check_quicksand(delta):
		return
	if player.low == Player.Low.GLIDE:
		_slide_dust -= delta
		if _slide_dust <= 0.0:
			_slide_dust = 0.09
			fx.dust(player.position + Vector2(30, 0), false)
	if player.position.y > Tuning.VIEW_H + 120.0:
		_fell_in_pit()
		return
	_collide()
	_attack_marker_step()
	if state == State.PLAYING:
		_combo_step(delta)
		_chest_step()
		_preview_step()
		_first_sight_step()
		_event_step(delta)
		_bonus_step(delta)
		_lap_step(delta)


## Each form sounds different: footsteps, jumps and landings.
const STEP_SOUND := {Forms.ROK: "step_rok", Forms.RAPTOR: "step_raptor", Forms.TRICERATOPS: "step_heavy",
		Forms.SPINOSAURUS: "step_heavy", Forms.PTERANODON: "step_raptor"}
const JUMP_SOUND := {Forms.ROK: "jump", Forms.RAPTOR: "jump_raptor", Forms.TRICERATOPS: "jump_heavy",
		Forms.SPINOSAURUS: "jump_heavy", Forms.PTERANODON: "flap"}
## ...and so does the ground in each zone.
const SURFACE_SOUND := {"forest": "step_grass", "desert": "step_sand", "volcanic": "step_rock"}


func _heavy() -> bool:
	return player.form == Forms.TRICERATOPS or player.form == Forms.SPINOSAURUS


func _on_step() -> void:
	if state != State.PLAYING and state != State.INTRO or player.swimming:
		return
	audio.play(STEP_SOUND.get(player.form, "step_rok"), 0.12)
	_surface_step()
	if _heavy():
		fx.add_shake(1.5)


func _surface_step() -> void:
	var liquid := terrain.liquid_at(player.position.x)
	var key: String = "step_sand" if liquid == "quicksand" else SURFACE_SOUND[Zones.zone_at(metres()).id]
	audio.play(key, 0.15)


## True when Rok could stand up without his standing hitbox hitting a ledge.
func _headroom_clear() -> bool:
	var hb := player.standing_hitbox()
	for o in course.obstacles:
		if o.kind == "overhead" and hb.intersects(o.hitbox()):
			return false
	return true


## Highest surface under the player: a platform he is above, else the ground.
## If he has already sunk below the terrain (fell into a pit and the far
## wall arrived) he keeps falling instead of popping up onto it.
func _support_y() -> float:
	var y := terrain.height_at(player.position.x)
	if player.position.y > y + Tuning.GROUND_SNAP and not player.on_ground:
		y = Terrain.PIT
	var hb := player.hitbox()
	for p in course.platforms:
		if p.covers(player.position.x, hb.size.x) and player.position.y <= p.top() + 6.0:
			y = minf(y, p.top())
	# the Spinosaurus swims across water instead of sinking
	if player.data().get("swims", false) and terrain.liquid_at(player.position.x) == "water":
		y = minf(y, terrain.liquid_surface(player.position.x))
	_bridge = terrain.bridge_at(player.position.x, hb.size.x * 0.5)
	if not _bridge.is_empty() and player.position.y <= _bridge.y + 6.0:
		y = minf(y, _bridge.y)
	else:
		_bridge = {}
	return y


## Heavy forms break crumbling bridges (Raptor and Pteranodon are light).
func _check_bridge() -> void:
	if _bridge.is_empty() or _bridge.sturdy or not player.on_ground:
		return
	if absf(player.position.y - _bridge.y) > 2.0 or player.data().get("light", false):
		return
	terrain.crumble(_bridge)
	audio.play("break_wood", 0.1, 0.85)
	fx.float_text(player.position + Vector2(-60, -200), "Too heavy!", Color(1, 0.55, 0.4))
	fx.add_shake(6.0)


func _collide() -> void:
	var hb := player.hitbox()
	var d := player.data()
	for o in course.obstacles.duplicate():
		if state != State.PLAYING:
			return   # a hit just took the last heart
		if not hb.intersects(o.hitbox()):
			continue
		if o.bumped:
			continue
		if combo.in_frenzy():
			_frenzy_smash(o)
			continue
		if o.kind == "steam":
			if player.invuln <= 0.0:
				_stumble(Tuning.STUMBLE_STEAM, "Steam!")
				_hurt("steam", "steam")
			continue
		if o.kind in d.breaks:
			_smash(o, player.data().color)
		elif _small_hazard(o) and player.invuln <= 0.0 and _roll() < Dinos.break_chance(String(d.id), player.form):
			_power_break(o)   # Power won the roll: straight through, no trip/dizzy/snag
		elif o.mushroom:
			_mushroom(o)
		elif player.invuln > 0.0:
			continue
		elif o.kind == "small" and o.gate_form == -1:
			_trip()
		elif o.critter != "":
			_bump(o)
		elif o.vine:
			_snag(o)
		elif o.kind == "thorns" and o.gate_form == -1:
			_prick()
		elif player.armor > 0 and o.gate_form == -1:
			player.armor -= 1
			player.invuln = 0.8
			_smash(o, Color(0.6, 0.9, 1.0))
			audio.play("shield", 0.0)
			chase_gap -= Tuning.STUMBLE_SHIELD
			fx.float_text(player.position + Vector2(-40, -220), "SHIELD!", Color(0.45, 0.8, 1.0))
		elif o.gate_form == -1:
			if _crash(o):
				return
		else:
			death_cause = "gate %s (%s, ground=%s)" % [o.kind, Forms.get_data(player.form).id, player.on_ground]
			_game_over()
			return
	for k in course.pickups.duplicate():
		if k.kind == "chest":
			if not k.opened and hb.grow(12.0).intersects(Rect2(k.position + Vector2(-44, -74), Vector2(88, 74))):
				_open_chest(k)
			continue
		if hb.grow(10.0).has_point(k.position) or hb.grow(k.radius * 0.6).has_point(k.position):
			if k.kind == "amber":
				var amber_e: float = (Tuning.AMBER_ENERGY if player.form == Forms.ROK else Tuning.AMBER_ENERGY_DINO) * float(player.data().get("amber_mult", 1.0))
				energy = minf(energy + amber_e, Tuning.ENERGY_MAX)
				score += Tuning.AMBER_SCORE * points_mult()
				fx.sparkle(k.position, Color(1.0, 0.7, 0.2))
				audio.play("amber", 0.08)
				badge_event("amber")
			elif k.kind == "meat" or k.kind == "big_meat":
				var worth := Tuning.BIG_MEAT_VALUE if k.kind == "big_meat" else 1
				if events.active("golden_hour"):
					worth *= Tuning.GOLDEN_HOUR_MEAT
				var got := worth * combo.meat_per_pickup()
				run_meat += got
				score += Tuning.MEAT_SCORE * worth * points_mult()
				fx.sparkle(k.position, Color(1.0, 0.8, 0.25) if k.kind == "big_meat" else Color(1.0, 0.5, 0.35))
				audio.play("amber", 0.05, 0.75 if worth == 1 else 0.95)
				if got > 1:
					fx.float_text(k.position + Vector2(-30, -50), "+%d meat" % got, Color(1.0, 0.8, 0.3), 26)
				badge_event("meat", got)
			elif k.kind == "fossil":
				var fm := Tuning.FOSSIL_MEAT * combo.meat_per_pickup()
				run_meat += fm
				fossils_found += 1
				score += Tuning.FOSSIL_SCORE * points_mult()
				badge_event("meat", fm)
				fx.sparkle(k.position, Color(0.7, 0.9, 1.0))
				fx.sparkle(k.position + Vector2(0, -30), Color(1.0, 0.9, 0.6))
				fx.float_text(k.position + Vector2(-80, -60), "RARE FOSSIL! +%d meat" % fm, Color(0.7, 0.9, 1.0), 30)
				grant_materials({"fossil_shard": int(Crafting.num("fossils", "shards"))})
				audio.play("unlock", 0.0, 1.3)
			elif k.kind.begins_with(Crafting.PICKUP_PREFIX):   # a crafting material
				var mid: String = String(k.kind).substr(Crafting.PICKUP_PREFIX.length())
				grant_materials({mid: 1})
				fx.sparkle(k.position, Crafting.RARITY_COLOR[Crafting.mat_rarity(mid)])
				fx.float_text(k.position + Vector2(-30, -50), "+1 " + Crafting.mat_name(mid), Crafting.RARITY_COLOR[Crafting.mat_rarity(mid)], 22)
				audio.play("click", 0.08, 1.4)
			elif k.kind == "chest":
				continue   # chests open by touch below (they sit on the ground)
			elif k.kind == "heart":
				_heal(k.position)
			elif Boosters.is_booster(k.kind):
				collect_booster(k.kind, k.position)
			combo.keep_alive()
			course.remove_pickup(k)


## Quicksand: standing on it sinks Rok (slowly for the fast Raptor, quickly
## for the heavy dinos). Deep sand (built once the Raptor is unlocked, see
## Terrain.quicksand_width) also plunges him in when he lands on it
## (QUICKSAND_PLUNGE) and grips his feet: a jump off it is weak with no air
## jump (QUICKSAND_GRIP), so he can't hop-chain across. The sink only drains
## once he's clear of the sand. Sinking all the way ends the run.
## Returns true if it did.
func _check_quicksand(delta: float) -> bool:
	var over_sand := terrain.liquid_at(player.position.x) == "quicksand"
	var on_sand := player.on_ground and over_sand
	var rate := Tuning.SINK_RATE
	if player.data().get("fast", false):
		rate = Tuning.SINK_RATE_FAST
	elif player.form == Forms.TRICERATOPS or player.form == Forms.SPINOSAURUS:
		rate = Tuning.SINK_RATE_HEAVY
	var deep := on_sand and terrain.deep_sand_at(player.position.x)
	if on_sand:
		if _was_airborne and deep:
			sink += Tuning.QUICKSAND_PLUNGE * rate / Tuning.SINK_RATE
		sink += rate * delta
	elif not over_sand:
		sink = maxf(sink - Tuning.SINK_RECOVER * delta, 0.0)
	player.sand_grip = Tuning.QUICKSAND_GRIP if deep and rate >= Tuning.SINK_RATE else 1.0
	_was_airborne = not player.on_ground
	player.body.position.y = sink * 70.0
	if sink >= 1.0:
		death_cause = "quicksand"
		player.visible = false
		fx.splash(player.position, Color(0.9, 0.75, 0.4))
		_game_over()
		return true
	return false



## Crashing into a solid obstacle (log, boulder, wall, fence, a hard ledge):
## it costs hearts (Hearts.damage "crash", by the form's Armor) instead of ending
## the run, the hunter gains, Rok gets a moment of invulnerability and the
## obstacle breaks (no smash points). Out of hearts, the run ends. Returns
## true if it did.
func _crash(o: Obstacle) -> bool:
	var cost := Hearts.damage("crash", Hearts.armor_of(player.data()))
	if _hurt("crash", "%s (%s, ground=%s)" % [o.kind, Forms.get_data(player.form).id, player.on_ground]):
		return true
	var pos := o.position + Vector2(0, -o.size.y * 0.5)
	fx.smash(pos, Color(0.55, 0.5, 0.45) if o.kind == "rock" else Color(0.6, 0.38, 0.2))
	course.shatter_obstacle(o)
	audio.play("hit", 0.0)
	break_sound(o)
	_stumble(Tuning.STUMBLE_CRASH, "Ouch! -" + Hearts.text(cost).replace(" hearts", "♥").replace(" heart", "♥"), Color(1.0, 0.35, 0.35))
	player.invuln = maxf(player.invuln, Tuning.CRASH_INVULN)
	if player.on_ground and player.form == Forms.ROK:
		player.react_play("trip")
	hud.hearts_hit()
	return false


## Full health in quarter hearts: the 3 starting hearts plus Heart Containers.
func max_health() -> int:
	return (Tuning.MAX_HEARTS + heart_containers) * Hearts.QUARTERS


## Any hit costs quarter hearts by its kind and the form's Armor (Hearts.damage).
## Out of hearts, the run ends with `cause`. Returns true if it did.
func _hurt(kind: String, cause: String) -> bool:
	if state != State.PLAYING:
		return false
	health = maxi(health - Hearts.damage(kind, Hearts.armor_of(player.data())), 0)
	if kind != "crash":
		hud.hearts_hit()
	if health <= 0:
		death_cause = cause
		_game_over()
		return true
	return false


## A heart pickup heals one heart (or is just points at full health).
func _heal(pos: Vector2) -> void:
	var full := max_health()
	if health < full:
		health = mini(health + Hearts.QUARTERS, full)
		fx.float_text(pos + Vector2(-30, -40), "+1 ♥", Color(1.0, 0.45, 0.5))
	else:
		score += Tuning.HEART_SCORE * points_mult()
		fx.float_text(pos + Vector2(-30, -40), "+%d" % int(Tuning.HEART_SCORE * points_mult()))
	fx.sparkle(pos, Color(1.0, 0.4, 0.45))
	audio.play("amber", 0.05, 1.3)


## A small thorn bush trips Rok up instead of killing him: the T-rex gains
## ground, with a moment of invulnerability so one bush can't hit twice.
func _prick() -> void:
	_stumble(Tuning.STUMBLE_THORN, "Stumble!")
	_hurt("thorns", "thorns")


## A small rock, a mushroom or a vine: the hazards a Power roll can break.
func _small_hazard(o: Obstacle) -> bool:
	return o.gate_form == -1 and (o.mushroom or o.vine or o.kind == "small")


## The dice for a Power roll (tests pin it with roll_override).
func _roll() -> float:
	return roll_override if roll_override >= 0.0 else randf()


## Power broke through a small hazard: rocks and mushrooms shatter, a vine
## snaps and scrolls on harmlessly.
func _power_break(o: Obstacle) -> void:
	if o.vine:
		course.obstacles.erase(o)
		course.debris.append(o)
		fx.float_text(player.position + Vector2(-40, -210), "SNAP!", Color(0.6, 0.95, 0.45))
		audio.play("break_wood", 0.1, 1.2)
	else:
		_smash(o, player.data().color)
		fx.float_text(player.position + Vector2(-40, -210), "SMASH!", Color(1.0, 0.75, 0.35))


## Small rocks (and twigs) trip Rok up instead of ending the run: he
## stumbles and the T-rex gains. Big hazards (boulders, walls...) still kill.
func _trip() -> void:
	_stumble(Tuning.STUMBLE_ROCK, "Trip!")
	player.react_play("trip")
	_hurt("trip", "small")


# ------------------------------------------------------------------ badges

## A "total" badge stat goes up (rocks smashed, meat collected...).
func badge_event(stat: String, amount := 1.0) -> void:
	badge_stats[stat] = float(badge_stats.get(stat, 0.0)) + amount
	_award_badges(stat)
	mission_event(stat, amount)


## A "best" badge stat: keep the highest value (one run's distance, owned dinos).
func badge_best(stat: String, value: float) -> void:
	_missions_done(missions.best(stat, value))
	if value > float(badge_stats.get(stat, 0.0)):
		badge_stats[stat] = value
		_award_badges(stat)


## Earn every tier the stat has reached: meat straight into the bank, a
## banner during a run, and a line in the game-over news.
func _award_badges(stat: String) -> void:
	var v := float(badge_stats.get(stat, 0.0))
	var earned := false
	for id in Badges.for_stat(stat):
		var t := int(badge_tiers.get(id, 0))
		var tiers: Array = Badges.DATA[id].tiers
		while t < tiers.size() and v >= tiers[t]:
			var reward: int = Badges.TIER_REWARD[t]
			t += 1
			badge_tiers[id] = t
			meat_bank += reward
			earned = true
			# a dinosaur this badge was holding back may now go on sale
			for u in Badges.unlocks(id):
				if u[1] == t and Market.on_sale(u[0], best_m) and not new_market.has(u[0]):
					new_market.append(u[0])
			var label := "%s %s" % [Badges.TIERS[t - 1], Badges.DATA[id].name]
			new_badges.append("Badge: " + label)
			Codex.badges_new = true
			if state == State.PLAYING:
				var perk := Badges.perk_text(id, t)
				hud.show_banner("BADGE: " + label.to_upper() + "!", "+%d meat" % reward + ("  ·  now %s for good" % perk if perk != "" else ""), Badges.TIER_COLORS[t - 1], 2.6)
				audio.play("unlock", 0.0, 1.2)
	if earned:
		SaveData.save_meat(meat_bank)
		SaveData.save_badges(badge_stats, badge_tiers)


## Per-run badge stats, every frame: distance, metres flown, metres as a
## dino, distance since the last stumble, and zones reached.
func _badge_run_step(dm: float) -> void:
	run_dino_m[player.data().id] = float(run_dino_m.get(player.data().id, 0.0)) + dm
	if player.form != Forms.ROK:
		_dino_m += dm
	if true:   # XP for whoever is running: the equipped species, the original, or Rok himself
		var did: String = player.data().id
		var was_ready := Dinos.xp_ok(did)
		var gx := dm * xp_mult()
		dino_xp[did] = float(dino_xp.get(did, 0.0)) + gx
		badge_stats["xp"] = float(badge_stats.get("xp", 0.0)) + gx
		if not was_ready and Dinos.xp_ok(did) and Dinos.can_level(did) and owns_form(did):
			new_this_run.append("%s ready for Lv %d" % [Herd.name_of(did), Dinos.level(did) + 1])
		if player.flies() and not player.on_ground:
			badge_stats["flown_m"] = float(badge_stats.get("flown_m", 0.0)) + dm
		if player.form == Forms.RAPTOR:
			badge_stats["runner_m"] = float(badge_stats.get("runner_m", 0.0)) + dm
		elif player.form == Forms.SPINOSAURUS:
			badge_stats["tank_m"] = float(badge_stats.get("tank_m", 0.0)) + dm
	_course_badges()
	var m := metres()
	_badge_tick += 1
	if _badge_tick % 15 != 0:
		return   # checking a few times a second is plenty
	_award_badges("flown_m")
	_award_badges("runner_m")
	_award_badges("xp")
	_award_badges("tank_m")
	badge_best("run_m", m)
	badge_best("clean_m", m - _clean_from)
	badge_best("dino_m", _dino_m)
	badge_best("zones", floorf(m / Zones.ZONE_LEN_M) + 1.0)


var _badge_tick := 0


## Badge events that need the course: a low ledge counts once it's behind Rok
## if he was sliding while it was over him (walking under it standing or a
## snag doesn't count); a dino gate counts once its start is GATE_CLEAR px
## behind him and he's still running.
const GATE_CLEAR := 1300.0


func _course_badges() -> void:
	if state != State.PLAYING:
		return
	var px := player.position.x
	for o in course.obstacles:
		if o.kind != "overhead" or o.passed:
			continue
		var half := o.size.x * 0.5
		if absf(o.position.x - px) < half and player.is_low():
			o.set_meta("slid", true)
		elif o.position.x + half < px - 40.0:
			o.passed = true
			if o.get_meta("slid", false):
				badge_event("ledges")
				_coach_done("slide")
	for mk in course.markers:
		if not mk.get_meta("counted", false) and not mk.get_meta("sand", false) and Course.gate_x0(mk) < px - GATE_CLEAR:
			mk.set_meta("counted", true)
			badge_event("gates")
			combo.feat(Tuning.COMBO_GATE_WEIGHT)



## T-rex charges at set distances (config [trex]): a roar and a warning, then
## for the hunter's charge_time it gains its charge_rate extra per second
## (Hunters.DATA, see _update_chase).
## A Runner roughly holds it off; an egg boost or a downhill slide escapes.
## The first one ever pauses on a card explaining how to survive it.
func _charge_step(delta: float) -> void:
	if charge_state == "" and metres() >= _next_charge and bonus_t <= 0.0 and portal == null:
		charge_state = "warn"
		charge_t = Tuning.CHARGE_WARN
		_next_charge = Progression.next_charge_m(metres() + 1.0)
		trex.roar()
		audio.play("trex_roar", 0.0, 0.85, 4.0)
		fx.add_shake(10.0)
		# Rok's shout once the roar has hit: run! (a paused timer, so it
		# waits behind the first charge's info card)
		get_tree().create_timer(Tuning.CHARGE_ALARM_DELAY, false).timeout.connect(func():
			if charge_state == "warn":
				audio.play("rok_alarm", 0.0))
		var hint := "Run as a Runner, use an egg or slide downhill to escape!"
		var title := "THE %s CHARGES!" % String(Hunters.DATA[hunter_id].name).to_upper()
		if pause_for_info and not seen.has("trex_charge"):
			queue_info(title, "Every so often the hunter behind you roars and charges, gaining on you fast for a few seconds.\n" + hint,
					SpriteLib.tex("res://assets/portraits/trex.png"), Color(0.95, 0.35, 0.25))
		else:
			hud.show_banner(title, hint, Color(1.0, 0.45, 0.35), 3.0)
		if not seen.has("trex_charge"):
			seen.append("trex_charge")
			SaveData.save_seen(seen)
			last_new_m = metres()   # a new thing: the next lesson waits a little
		return
	if charge_state == "":
		return
	charge_t -= delta
	if charge_t > 0.0:
		return
	if charge_state == "warn":
		charge_state = "charge"
		charge_t = Hunters.DATA[hunter_id].charge_time
		trex.run()
		audio.play("stomp", 0.05, 0.8, 4.0)
	else:
		charge_state = ""
		fx.float_text(player.position + Vector2(-60, -230), "Escaped!", Color(0.6, 1.0, 0.5))
		badge_event("charges")
		_charge_trophy()


## The flag at the best distance scrolls in with the world; running past it
## celebrates the new record (once per run).
func _best_flag_step() -> void:
	if best_flag == null:
		return
	var x: float = Tuning.PLAYER_X + (best_flag.metres - metres()) * Tuning.PX_PER_M
	best_flag.visible = x > -200.0 and x < hud.get_viewport().get_visible_rect().size.x + 400.0
	var gy: float = terrain.height_at(x)
	best_flag.position = Vector2(x, gy if gy < Terrain.PIT else Tuning.GROUND_Y)
	if not best_flag.passed and metres() >= best_flag.metres:
		best_flag.passed = true
		player.celebrate_t = Tuning.CELEBRATE_WINDOW   # the hero's next jump is a celebration
		hud.show_banner("NEW BEST!", "You passed your record of %d m. Keep going!" % best_flag.metres, Color(0.55, 1.0, 0.5), 2.4)
		audio.play("unlock", 0.0)
		for i in 6:
			fx.sparkle(player.position + Vector2(randf_range(-80, 120), randf_range(-200, -40)), Color(1.0, 0.85, 0.3))
		fx.add_shake(4.0)


## "a desert sprinter" -> "A desert sprinter" (String.capitalize would
## capitalise every word).
static func _sentence(t: String) -> String:
	return t.substr(0, 1).to_upper() + t.substr(1) if t != "" else t


## Each zone has its own hunter (Hunters): at the border the new one takes
## over with a roar and a banner (NEW HUNTER the first time ever).
func _hunter_step() -> void:
	var want := Hunters.for_zone(Zones.zone_at(metres()).id)
	if want == hunter_id:
		return
	hunter_id = want
	trex.set_hunter(want)
	if charge_state == "":
		trex.roar()
	audio.play("trex_roar", 0.05, 0.95, 2.0)
	fx.add_shake(6.0)
	var d: Dictionary = Hunters.DATA[want]
	var key := "hunter_" + want
	if not seen.has(key):
		seen.append(key)
		SaveData.save_seen(seen)
		hud.show_banner("NEW HUNTER: " + String(d.name).to_upper() + "!", _sentence(d.blurb), Color(1.0, 0.5, 0.4), 3.2)
	else:
		hud.show_banner("THE %s TAKES UP THE HUNT!" % String(d.name).to_upper(), "", Color(1.0, 0.55, 0.45), 2.4)


## Running into a wild dinosaur bumps Rok (its own bump strength) instead of
## ending the run; it carries on toward the T-rex.
func _bump(o: Obstacle) -> void:
	o.bumped = true
	_stumble(Critters.DATA[o.critter].bump, "Bonk!")
	player.react_play("trip")
	_hurt("bump", "critter " + o.critter)


## Wild dinosaurs that get past Rok run into the T-rex, which eats them: a
## bite, a "CHOMP!", and it stops to eat (Rok wins back `snack` of the gap).
## A species met for the first time (after the lesson) gets a NEW banner.
func _eat_critters() -> void:
	var snout_x: float = Tuning.PLAYER_X - chase_gap
	var view_w := get_viewport().get_visible_rect().size.x
	for o in course.obstacles.duplicate():
		if o.critter == "":
			continue
		if o.dive_started and not o.get_meta("screeched", false):
			o.set_meta("screeched", true)
			audio.play("form_pteranodon", 0.08, 1.35, -3.0)   # the dive's warning screech
		var key: String = "critter_" + o.critter
		if not seen.has(key) and o.position.x < view_w and seen.has(o.kind):
			seen.append(key)
			SaveData.save_seen(seen)
			var d: Dictionary = Critters.DATA[o.critter]
			hud.show_banner("NEW: " + d.name.to_upper(), "A %s %s. %s" % [
					"stampeding" if o.kind == "stampede" else "swooping", d.name, _sentence(d.blurb)], Color(1.0, 0.8, 0.45))
		elif not seen.has(key) and o.position.x < view_w:
			seen.append(key)
			SaveData.save_seen(seen)
		if o.position.x < snout_x + Tuning.CRITTER_EAT_X:
			course.remove_obstacle(o)
			trex.eat()
			chase_gap += Critters.DATA[o.critter].snack
			audio.play("bite", 0.05)
			audio.play("trex_growl", 0.1, 1.1, -6.0)
			fx.smash(o.position + Vector2(0, -40), Color(0.75, 0.55, 0.4))
			fx.float_text(Vector2(snout_x - 40.0, o.position.y - 160.0), "CHOMP!", Color(1.0, 0.55, 0.3))
			badge_event("snacks")
			combo.feat(Tuning.COMBO_SNACK_WEIGHT)


## A Forest vine branch snags Rok instead of ending the run: he stumbles (the
## T-rex gains) and pushes through, so the branch stops being an obstacle and
## can't snag him twice. The Desert arch and Volcanic rock are solid and kill.
func _snag(o: Obstacle) -> void:
	course.obstacles.erase(o)
	course.debris.append(o)   # still drawn and scrolling, no longer collides
	_stumble(Tuning.STUMBLE_VINE, "Snagged!", Color(0.45, 0.85, 0.35))
	player.react_play("snag", Tuning.SNAG_HOLD)
	_hurt("snag", "overhead vine")


## Running into a mushroom squashes it: no death, but its spores make Rok
## dizzy for DIZZY_TIME (lower jumps, a wobble) and he stumbles a little.
func _mushroom(o: Obstacle) -> void:
	course.remove_obstacle(o)
	fx.sparkle(o.position + Vector2(0, -30), Color(0.75, 0.5, 1.0))
	fx.dust(o.position)
	audio.play("land", 0.1, 1.3)
	if player.invuln > 0.0:
		return
	dizzy_t = Tuning.DIZZY_TIME
	_stumble(Tuning.STUMBLE_MUSHROOM, "Dizzy!", Color(0.62, 0.3, 1.0))
	player.react_play("dizzy", Tuning.DIZZY_TIME - 0.4)
	player.invuln = maxf(player.invuln, 0.5)
	_hurt("dizzy", "small mushroom")


func _dizzy_step(delta: float) -> void:
	if dizzy_t <= 0.0:
		return
	dizzy_t = maxf(dizzy_t - delta, 0.0)
	player.jump_mult = Tuning.DIZZY_JUMP if dizzy_t > 0.0 else 1.0
	# the dizzy animation (back on landing after a jump); a wobble while airborne
	if player.react_kind == "" and dizzy_t > 0.6:
		player.react_play("dizzy", dizzy_t - 0.4, true)
	var wobble := player.react_kind != "dizzy"
	player.sprite.rotation = sin(dizzy_t * 11.0) * 0.09 * minf(dizzy_t, 1.0) if wobble else 0.0


func _stumble(amount: float, text: String, color := Color(1, 0.5, 0.4)) -> void:
	combo.hit()
	chase_gap -= amount * player.data().get("stumble_mult", 1.0)   # armor softens stumbles
	_clean_from = metres()   # Untouchable counts from the last stumble
	player.invuln = maxf(player.invuln, 0.9)
	player.sprite.modulate = Color(color.r * 1.6, color.g * 1.2, color.b * 1.25)   # flash in the text colour
	create_tween().tween_property(player.sprite, "modulate", Color.WHITE, 0.4)
	fx.float_text(player.position + Vector2(-50, -200), text, color)
	fx.add_shake(5.0)
	audio.play("denied", 0.0)
	audio.play("stomp", 0.05, 0.9, -2.0)


# ------------------------------------------------------------------ boosters

## Picking up a booster: it goes into a free open slot (any type, even one
## you already hold; the user's rule) unless every open slot is full; either
## way it's worth its points. Returns true if it was stored.
func collect_booster(kind: String, at: Vector2) -> bool:
	if not boosters_owned.has(kind):
		return false   # locked power-ups don't exist in a run yet
	var pts: int = int(Boosters.DATA[kind].score * points_mult())
	score += pts
	fx.sparkle(at, Color(1.0, 0.95, 0.8))
	audio.play("powerup_pickup", 0.0)
	fx.float_text(at + Vector2(-20, -30), "+%d" % pts)
	var i := slots.find("")
	if i == -1 or i >= slot_count:
		return false
	slots[i] = kind
	hud.pulse_slot(i)
	player.powerup_fx("pickup")
	return true


## Use the booster in slot i (its button; B / N / M on a keyboard for testing).
func use_slot(i: int) -> void:
	if state == State.PLAYING and i >= slot_count and i < slots.size():
		var msg := "Coming to the Market" if i == Boosters.MARKET_SLOT else "Reach %d m to unlock" % int(Progression.SLOT_UNLOCK_M)
		fx.float_text(player.position + Vector2(-60, -200), msg, Color(1, 0.6, 0.4))
		audio.play("denied", 0.0)
		return
	if state != State.PLAYING or i < 0 or i >= slots.size() or slots[i] == "":
		return
	var kind: String = slots[i]
	if not booster_ready(kind):
		return
	slots[i] = ""
	activate_booster(kind)
	_coach_done("booster")


## Can this booster be used right now? (e.g. one egg boost at a time)
func booster_ready(kind: String) -> bool:
	match kind:
		"egg":
			return boost_t <= 0.0
		"amber_shield":
			return energy < Tuning.ENERGY_MAX - 0.5   # Primal Amber: only when there's energy to refill
	return not power_on(kind)   # timed power-ups don't stack


## What each booster does. Add new booster ids here.
func activate_booster(kind: String) -> void:
	var at := player.position + Vector2(-90, -240)
	player.powerup_fx("activation")
	audio.play("powerup_activate", 0.0, Tuning.POWERUP_SOUND_PITCH.get(kind, 1.0))
	match kind:
		"egg":
			_egg_boost()
		"amber_shield":   # Primal Amber: PRIMAL energy back to full
			energy = Tuning.ENERGY_MAX
			fx.float_text(at, "PRIMAL AMBER!", Color(1.0, 0.75, 0.3), 36)
			fx.sparkle(player.position + Vector2(0, -80), Color(1.0, 0.75, 0.3))
		"fossil_magnet":
			power_t[kind] = Tuning.MAGNET_TIME
			fx.float_text(at, "MAGNET!", Color(0.6, 0.85, 1.0), 36)
		"time_crystal":
			power_t[kind] = Tuning.SLOW_TIME
			fx.float_text(at, "TIME SLOWS!", Color(0.75, 0.6, 1.0), 36)
		"primal_berry":
			power_t[kind] = Tuning.BERRY_TIME
			energy = maxf(energy, Tuning.SHIFT_MIN_ENERGY)
			fx.float_text(at, "FREE SHIFTING!", Color(0.95, 0.4, 0.6), 36)
		"golden_fossil":
			power_t[kind] = Tuning.GOLD_TIME
			fx.float_text(at, "DOUBLE POINTS!", Color(1.0, 0.85, 0.2), 36)


func power_on(kind: String) -> bool:
	return power_t.get(kind, 0.0) > 0.0


func points_mult() -> float:
	var m := Tuning.GOLD_MULT if power_on("golden_fossil") else 1.0
	m *= combo.mult()   # the combo streak's tier
	m *= 1.0 + Tuning.LAP_BONUS * (lap - 1)   # each lap past the first pays more
	return m * (1.0 + Badges.perk_bonus("points"))   # Point Hunter's permanent bonus


## XP a dinosaur earns per metre: 1, plus Seasoned's permanent bonus.
func xp_mult() -> float:
	return 1.0 + Badges.perk_bonus("xp")


## Timed Market power-ups count down; the magnet pulls pickups in.
func _power_step(delta: float) -> void:
	for k in power_t.keys():
		power_t[k] = maxf(power_t[k] - delta, 0.0)
		if power_t[k] <= 0.0:
			power_t.erase(k)
	var had_aura := player.pfx_aura.visible
	player.set_power_aura(boost_t > 0.0 or not power_t.is_empty())   # the aura while one runs, expire when the last ends
	if had_aura and not player.pfx_aura.visible:
		audio.play("powerup_expire", 0.0)
	if power_on("fossil_magnet"):
		var target := player.position + Vector2(10.0, -70.0)
		for p in course.pickups:
			if p.position.distance_to(target) < Tuning.MAGNET_RADIUS and p.position.x > player.position.x - 80.0:
				p.pull_toward(target, Tuning.MAGNET_PULL * delta)
	# a soft tint shows a power-up is running
	if boost_t <= 0.0:
		var tint := Color.WHITE
		if dizzy_t > 0.0:
			tint = Color(1.05, 0.85, 1.3)   # spore-purple while dizzy
		elif power_on("golden_fossil"):
			tint = Color(1.25, 1.15, 0.7)
		elif power_on("time_crystal"):
			tint = Color(0.9, 0.85, 1.25)
		player.sprite.self_modulate = tint


## Meat collected in a run goes into the Market bank when the run ends.
func _bank_meat() -> void:
	if bench_open() and not seen.has("bench_open"):   # the Crafting Bench just opened
		seen.append("bench_open")
		SaveData.save_seen(seen)
		new_this_run.append("Crafting Bench open: craft gear at the Dinosaur Camp")
	if not run_materials.is_empty():   # (already in the bank; just the news)
		new_this_run.append("Found " + Crafting.cost_text(run_materials))
		run_materials.clear()
	SaveData.save_badges(badge_stats, badge_tiers)   # running totals, once per run
	SaveData.save_missions(missions.to_dict())   # today's progress
	_apply_rank()
	SaveData.save_dino_xp(dino_xp)
	if run_meat <= 0:
		return
	meat_bank += run_meat
	last_run_meat = run_meat
	run_meat = 0
	SaveData.save_meat(meat_bank)


## Once per run, when it ends: the score sets the run's rank, and the rank's
## multiplier (Tuning.RUN_RANKS, very steep) adds bonus meat and bonus XP for
## every dinosaur played (the extra on top of what the run earned).
func _apply_rank() -> void:
	if _ranked or score <= 0.0:
		return
	_ranked = true
	badge_event("points", floorf(score))   # Point Hunter counts every run's score
	run_rank = RunSummary.rank_for(score)
	var extra: float = float(run_rank[2]) - 1.0
	if extra <= 0.0:
		return
	run_bonus_meat = int(roundf(run_meat * extra))
	run_meat += run_bonus_meat
	for id in run_dino_m:   # Rok included: he levels too
		var bx := float(run_dino_m[id]) * xp_mult() * extra
		dino_xp[id] = float(dino_xp.get(id, 0.0)) + bx
		badge_stats["xp"] = float(badge_stats.get("xp", 0.0)) + bx


# ------------------------------------------------------------ combo and frenzy

## Clean feats the course itself provides: an obstacle that scrolled past Rok
## without hitting him, a pit or quicksand patch he got across. (Smashes,
## dino gates and wild dinosaurs fed to the hunter are counted where they
## happen.) Also runs the Primal Frenzy: pulling away, meat rain, the glow.
func _combo_step(delta: float) -> void:
	combo.step(delta)
	var hb := player.hitbox()
	for o in course.obstacles:
		if not o.get_meta("combo", false) and not o.bumped and o.hitbox().end.x < hb.position.x:
			o.set_meta("combo", true)
			if player.invuln <= 0.0 or combo.in_frenzy():   # not one he stumbled through
				combo.feat()
				if o.kind != "overhead" and o.gate_form == -1 and not player.on_ground:
					_coach_done("jump")   # jumped clean over it
	var lx: float = player.position.x - terrain.position.x
	for f in terrain.features:
		if f.x1 >= lx:
			break
		if not f.get("combo", false) and (f.type == "pit" or f.get("liquid", "") != ""):
			f.combo = true
			if f.x1 > lx - 400.0:   # crossed just now (not ground generated behind a fresh run)
				combo.feat()
	if combo.in_frenzy():
		chase_gap = minf(chase_gap + Tuning.FRENZY_CHASE_GAIN * delta, Tuning.CHASE_GAP_FAR)
		_frenzy_meat -= delta
		if _frenzy_meat <= 0.0:
			_frenzy_meat = Tuning.FRENZY_MEAT_EVERY
			var x := Tuning.PLAYER_X + randf_range(520.0, 760.0)
			var gy := terrain.height_at(x)
			if gy < Terrain.PIT:
				course._pickup("meat", Vector2(x, gy - randf_range(50.0, 170.0)))
		_boost_trail -= delta
		if _boost_trail <= 0.0:
			_boost_trail = 0.06
			fx.speed_line(player.position + Vector2(-40.0, -randf_range(20.0, 140.0)))
		var glow := 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.025)
		player.sprite.self_modulate = Color(1.15, 1.05, 0.75).lerp(Color(1.7, 1.35, 0.6), glow)


## New things are introduced before they can be picked up or used (the
## user's rule): the first time ever a big meat, a rare fossil, a milestone
## chest, a bonus portal or a power-up other than the starter egg comes on
## screen, an info card (or a banner while cards are off) explains it, and
## the Field Guide reveals it (`seen` key).
const FIRST_SIGHT := {
	"big_meat": ["BIG MEAT", "Long runs get richer: big meat is worth %d meat." % Tuning.BIG_MEAT_VALUE, Color(1.0, 0.75, 0.4)],
	"fossil": ["RARE FOSSIL", "Found only deep into long runs: %d meat and %d points." % [Tuning.FOSSIL_MEAT, Tuning.FOSSIL_SCORE], Color(0.7, 0.9, 1.0)],
	"chest": ["MILESTONE CHEST", "Every %d m of a run a chest waits on the ground. Run into it! The further you get, the better they are." % int(Tuning.CHEST_EVERY_M), Color(0.95, 0.8, 0.5)],
	"bonus": ["BONUS ZONE", "Run through the glowing portal: a safe stretch full of treasure waits on the other side.", Color(1.0, 0.85, 0.45)],
}


func _first_sight_step() -> void:
	if tutorial_run != null:
		return   # the training run explains its own things
	var view_w := get_viewport().get_visible_rect().size.x
	for k in course.pickups:
		if k.position.x > view_w - 30.0:
			continue
		if FIRST_SIGHT.has(k.kind):
			_introduce_thing(k.kind, k.kind)
		elif Boosters.is_booster(k.kind) and k.kind != "egg":
			_introduce_thing("power_" + k.kind, k.kind)
	if portal != null and is_instance_valid(portal) and portal.position.x < view_w - 30.0:
		_introduce_thing("bonus", "bonus")


func _introduce_thing(key: String, kind: String) -> void:
	if seen.has(key):
		return
	seen.append(key)
	SaveData.save_seen(seen)
	var title: String
	var text: String
	var col: Color
	var icon: Texture2D
	if FIRST_SIGHT.has(key):
		title = FIRST_SIGHT[key][0]
		text = FIRST_SIGHT[key][1]
		col = FIRST_SIGHT[key][2]
		icon = load(Hud.MEAT_ICON) if kind == "big_meat" else SpriteLib.tex("res://assets/props/Other_07.png")
	else:
		title = String(Boosters.DATA[kind].name).to_upper()
		text = String(Boosters.DATA[kind].desc) + " Grab it to put it in a booster slot."
		col = Color(1.0, 0.85, 0.4)
		icon = Boosters.icon(kind)
	if pause_for_info:
		queue_info("NEW: " + title, text, icon, col)
	else:
		hud.show_banner("NEW: " + title, text, col, 3.0)


## Mid-run events (run_events.gd): start one when it's due (not during a
## frenzy, a hunter charge or a bonus zone), run its spawns, end it.
func _event_step(delta: float) -> void:
	if events.current == "" and metres() >= events.next_m:
		if combo.in_frenzy() or charge_state != "" or bonus_t > 0.0 or portal != null:
			events.next_m = metres() + 60.0
		else:
			_start_event(RunEvents.pool(seen.has("stampede") and Progression.available("stampede", metres())).pick_random())
	if events.current == "":
		return
	var d: Dictionary = RunEvents.DATA[events.current]
	hud.set_event("%s  %ds" % [d.name, ceili(events.time_left)], d.color)
	if events.tick <= 0.0:
		_event_spawn(events.current)
	if events.step(delta):
		course.force_meat = false
		hud.set_event("")
		fx.float_text(player.position + Vector2(-80, -260), d.name + " OVER", Color(0.9, 0.85, 0.8), 24)


func _start_event(id: String) -> void:
	events.start(id, metres())
	var d: Dictionary = RunEvents.DATA[id]
	course.force_meat = id == "golden_hour"
	hud.show_banner(d.name, d.hint, d.color, 2.6)
	audio.play("intro", 0.0, 1.1)
	fx.add_shake(3.0)


## One spawn of the running event; sets the time to the next.
func _event_spawn(id: String) -> void:
	if course.holding and (id == "meteor_shower" or id == "stampede_rush"):
		events.tick = 0.5   # a dino unlock's gate (or a bonus zone) comes first: no new hazards
		return
	var x := Tuning.PLAYER_X + randf_range(450.0, 800.0)
	var gy := terrain.flat_y(x - 40.0, x + 40.0)
	match id:
		"golden_hour":
			events.tick = 999.0   # nothing to spawn: the meat itself is worth more
		"meteor_shower":
			events.tick = Tuning.METEOR_EVERY
			var mx := Tuning.PLAYER_X + randf_range(650.0, 900.0)   # far enough ahead to see the shadow
			var mg := terrain.flat_y(mx - 40.0, mx + 40.0)
			if mg >= 0.0:
				_meteor(mx, mg)
		"amber_storm":
			events.tick = Tuning.AMBER_STORM_EVERY
			var g2 := terrain.height_at(x)
			if g2 < Terrain.PIT:
				course._pickup("amber", Vector2(x, g2 - randf_range(60.0, 230.0)))
		"stampede_rush":
			events.tick = Tuning.STAMPEDE_RUSH_EVERY
			course._spawn_key("stampede", get_viewport().get_visible_rect().size.x + 150.0)


## A falling rock: a growing shadow on the ground, then a small rock drops
## onto it (it can hit Rok while falling) and lands with a thud.
func _meteor(x: float, gy: float) -> void:
	var shadow := Polygon2D.new()
	var pts := PackedVector2Array()
	for i in 16:
		pts.append(Vector2.from_angle(TAU * i / 16.0) * Vector2(34.0, 8.0))
	shadow.polygon = pts
	shadow.color = Color(0.1, 0.03, 0.0, 0.45)
	shadow.position = Vector2(x, gy)
	shadow.scale = Vector2(0.3, 0.3)
	course.add_child(shadow)
	course.debris.append(shadow)
	var st := shadow.create_tween()   # (tweens live on their nodes: a new run frees them safely)
	st.tween_property(shadow, "scale", Vector2.ONE, Tuning.METEOR_FALL)
	st.tween_callback(shadow.hide)
	var o := course.small(x)
	if o.mushroom:   # Forest small hazards include mushrooms: meteors are rocks
		course.remove_obstacle(o)
		return
	o.position.y = gy - 720.0
	o.rotation = randf_range(-1.0, 1.0)
	o.set_meta("meteor", true)   # ATTACK can smash it at any height, even mid-fall
	o.set_meta("ground", gy)
	var t := o.create_tween()
	o.set_meta("fall", t)
	t.tween_property(o, "position:y", gy, Tuning.METEOR_FALL).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	t.parallel().tween_property(o, "rotation", 0.0, Tuning.METEOR_FALL)
	t.tween_callback(_meteor_landed.bind(o))


func _meteor_landed(o: Obstacle) -> void:
	fx.dust(o.position)
	fx.add_shake(2.5)
	audio.play("stomp", 0.1, 1.2, -4.0)


# ------------------------------------------------------------ lap twists

## Every lap of the zones past the first brings a twist (Weather.TWISTS, in
## turn) and pays LAP_BONUS more points; a banner says so a moment after the
## zone banner.
func _lap_step(delta: float) -> void:
	var n := int(metres() / (Zones.ZONE_LEN_M * Zones.ZONES.size())) + 1
	if n != lap:
		lap = n
		_lap_banner_t = Tuning.LAP_BANNER_DELAY if n >= 2 else 0.0
	weather.set_twist(Weather.twist_for_lap(lap), Zones.zone_at(metres()).id)
	if _lap_banner_t > 0.0:
		_lap_banner_t -= delta
		if _lap_banner_t <= 0.0:
			var t := Weather.twist_for_lap(lap)
			hud.show_banner("LAP %d: %s!" % [lap, Weather.NAMES[t]], "%s Points x%s for this lap." % [
					Weather.HINTS[t], str(snappedf(1.0 + Tuning.LAP_BONUS * (lap - 1), 0.01))], Color(0.75, 0.85, 1.0), 3.0)
			audio.play("intro", 0.0, 0.8)


# ------------------------------------------------------------ bonus zones

## Bonus zones: when one is due (and nothing big is going on) a portal is
## placed on flat ground just off-screen; the ground behind it is trimmed
## back and only flat ground follows (`Terrain.calm`), and no hazards spawn
## (`Course.holding`), so it's safe. Rok runs through the portal (any height)
## and for BONUS_TIME the world glows and treasure rains down in waves.
func _bonus_step(delta: float) -> void:
	if not Tuning.BONUS_ENABLED and bonus_t <= 0.0 and portal == null:
		bonus_tint.color.a = 0.0
		return   # bonus zones are switched off for now (the user's call)
	if bonus_t > 0.0:
		bonus_t -= delta
		bonus_tint.color.a = lerpf(bonus_tint.color.a, 0.16, minf(delta * 4.0, 1.0))
		_bonus_drop -= delta
		_bonus_wave += delta
		if _bonus_drop <= 0.0:
			_bonus_drop = Tuning.BONUS_DROP_EVERY
			var x := get_viewport().get_visible_rect().size.x + 60.0
			var gy := terrain.height_at(x)
			if gy < Terrain.PIT:
				var r := randf()
				var kind := "big_meat" if r < 0.15 else ("meat" if r < 0.45 else "amber")
				course._pickup(kind, Vector2(x, gy - 70.0 - 150.0 * absf(sin(_bonus_wave * 1.6))))
		if bonus_t <= 0.0:
			_end_bonus(true)
		return
	bonus_tint.color.a = lerpf(bonus_tint.color.a, 0.0, minf(delta * 3.0, 1.0))
	if portal != null:
		if not is_instance_valid(portal):
			portal = null
		elif portal.position.x <= player.position.x:
			_enter_bonus()
		return
	if metres() < next_bonus_m:
		return
	if combo.in_frenzy() or charge_state != "" or events.current != "" or course.holding or course.markers.size() > 0:
		next_bonus_m = metres() + 40.0
		return
	var x := get_viewport().get_visible_rect().size.x + 150.0
	var gy := terrain.flat_y(x - 90.0, x + 90.0)
	if gy < 0.0 or terrain.liquid_at(x) != "":
		next_bonus_m = metres() + 5.0
		return
	_place_portal(x, gy)


func _place_portal(x: float, gy: float) -> void:
	portal = BonusPortal.new()
	portal.position = Vector2(x, gy)
	course.add_child(portal)
	course.debris.append(portal)   # scrolls with the world
	terrain.calm_from(x + 90.0)
	course.holding = true
	for o in course.obstacles.duplicate():
		if o.position.x > x - 260.0:
			course.remove_obstacle(o)   # nothing in the way, unseen (off-screen)


func _enter_bonus() -> void:
	portal.entered = true
	portal = null
	bonus_t = Tuning.BONUS_TIME
	bonus_zones += 1
	_bonus_drop = 0.0
	_bonus_wave = 0.0
	combo.feat(Tuning.CHEST_COMBO_WEIGHT)
	fx.add_shake(5.0)
	for i in 10:
		fx.sparkle(player.position + Vector2(randf_range(-60, 120), randf_range(-200, -20)), Color(1.0, 0.85, 0.45))
	audio.play("unlock", 0.0, 0.9)
	fx.float_text(player.position + Vector2(-90, -260), "BONUS ZONE!", Color(1.0, 0.85, 0.45), 42)


## Leave (or cancel) a bonus zone: hazards and normal ground come back.
func _end_bonus(announce: bool) -> void:
	bonus_t = 0.0
	terrain.calm = false
	if course._hold_marker == null:   # (a dino unlock mid-bonus keeps its own hold)
		course.holding = false
	if portal != null and is_instance_valid(portal):
		portal.queue_free()
	portal = null
	next_bonus_m = metres() + randf_range(Tuning.BONUS_GAP_MIN, Tuning.BONUS_GAP_MAX)
	if announce:
		fx.float_text(player.position + Vector2(-80, -260), "Back to the chase!", Color(1.0, 0.9, 0.7), 28)
		audio.play("shift", 0.0, 0.9)


# ------------------------------------------------------------ gear and cards

## Gear's static state points at main's (like Badges.earned).
func _sync_gear() -> void:
	Gear.owned = gear_owned
	Gear.equipped = gear_equipped
	Gear.cards = cards
	Gear.wear = gear_wear
	Gear.rarity = gear_rarity
	Crafting.bank = materials
	Forms.clear_cache()


func _save_gear() -> void:
	_sync_gear()
	SaveData.save_gear({"owned": gear_owned, "equipped": gear_equipped, "cards": cards, "wear": gear_wear,
			"rarity": gear_rarity, "next": gear_next, "materials": materials})


## Dinosaur cards are dropped by wild dinosaurs (the user's rule, not sold in
## the Market): one Rok bonks with ATTACK or bowls over in a frenzy drops its own
## species' card, always the first time ever for that species, then with
## CARD_DROP_CHANCE. The card pops out and is collected at once. Tests pin it
## with card_drop_override (-1 = roll).
var card_drop_override := -1.0


func _drop_card(o: Obstacle) -> void:
	var d := String(o.critter)
	if d == "" or not Dinos.known(d):
		return
	var first := not seen.has("card_" + d)
	var roll := card_drop_override if card_drop_override >= 0.0 else randf()
	if not first and roll >= Tuning.CARD_DROP_CHANCE:
		return
	seen.append("card_" + d)
	SaveData.save_seen(seen)
	grant_card(d)
	var pic := Sprite2D.new()
	pic.texture = Gear.icon(Gear.CARD_PREFIX + d)
	pic.scale = Vector2.ONE * (64.0 / maxf(pic.texture.get_width(), pic.texture.get_height()))
	pic.z_index = 60
	world.add_child(pic)
	pic.global_position = o.global_position + Vector2(0, -o.size.y * 0.6)
	var t := pic.create_tween()
	t.tween_property(pic, "global_position", pic.global_position + Vector2(-30, -140), 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(pic, "scale", pic.scale * 1.4, 0.45)
	t.tween_property(pic, "modulate:a", 0.0, 0.35)
	t.tween_callback(pic.queue_free)
	fx.sparkle(pic.global_position, Color(1.0, 0.9, 0.5))
	audio.play("unlock", 0.05, 1.3, -4.0)
	hud.show_banner(Herd.name_of(d).to_upper() + " CARD!", "It dropped its card. Put it in a hero's weapon slot at the Dinosaur Camp.", Color(1.0, 0.85, 0.45), 2.4)
	new_this_run.append(Herd.name_of(d) + " Card")


## A dinosaur card (from a wild dinosaur or a chest).
func grant_card(dino: String) -> void:
	cards[dino] = int(cards.get(dino, 0)) + 1
	last_card = dino
	_save_gear()


## Put an item (an owned weapon or armor, a card you hold, or "" to empty
## it) in one of a hero's slots. Returns true if it changed.
func equip_gear(hero: String, slot: String, id: String) -> bool:
	if not Heroes.is_hero(hero) or not (slot == "weapon" or slot == "armor"):
		return false
	if id != "":
		if Gear.slot_of(id) != slot:
			return false
		if id.begins_with(Gear.CARD_PREFIX):
			if int(cards.get(id.substr(Gear.CARD_PREFIX.length()), 0)) <= 0:
				return false
		elif not gear_owned.has(id):
			return false
	var e: Dictionary = gear_equipped.get(hero, {}).duplicate()
	e[slot] = id
	gear_equipped[hero] = e
	_save_gear()
	if player.form == Forms.ROK:
		player.refresh_form()
	return true


## One hit's wear on a weapon: at Gear.WEAR_WARN uses left a warning, at 0 it
## breaks (snap sound, a banner; no bonus or reach until repaired at the Dinosaur Camp).
func wear_weapon(id: String) -> void:
	var left := Gear.durability(id) - 1
	gear_wear[id] = left
	if left == Gear.WEAR_WARN:
		hud.show_banner(Gear.name_of(id).to_upper() + " IS WEARING OUT", "%d hits left. Repair it at the Dinosaur Camp." % left, Color(1.0, 0.75, 0.4), 2.2)
	elif left <= 0:
		if player.form == Forms.ROK:
			player.attack_stop()   # back to the body sprite so the shatter shows
			player.gear.play_break(Gear.base(id))   # its shatter plays in his hand
		audio.play("weapon_break", 0.05)
		fx.float_text(player.position + Vector2(-50, -230), "SNAP!", Color(1.0, 0.55, 0.4), 30)
		fx.add_shake(4.0)
		hud.show_banner(Gear.name_of(id).to_upper() + " BROKE!", "Repair it at the Dinosaur Camp to use it again.", Color(1.0, 0.5, 0.4), 2.8)
		new_this_run.append(Gear.name_of(id) + " broke")
	_save_gear()
	if left <= 0 and player.form == Forms.ROK:
		player.refresh_form()   # its bonus is gone


## Repair a worn or broken weapon to full for materials (Gear.repair_cost).
## Returns true if repaired.
func repair_gear(id: String) -> bool:
	var cost := Gear.repair_cost(id)
	if cost.is_empty() or not Crafting.can_afford(cost) or not gear_owned.has(id):
		audio.play("denied", 0.0)
		return false
	_spend(cost)
	gear_wear.erase(id)
	_save_gear()
	audio.play("unlock", 0.0)
	if player.form == Forms.ROK:
		player.refresh_form()
	return true


# ------------------------------------------------------------ crafting

## Add materials to the bank (from a run, a chest, the Market or salvage).
## `found` marks them as this run's (the summary's news).
func grant_materials(got: Dictionary, found := true) -> void:
	for m in got:
		if int(got[m]) <= 0:
			continue
		materials[m] = int(materials.get(m, 0)) + int(got[m])
		if found:
			run_materials[m] = int(run_materials.get(m, 0)) + int(got[m])
	_save_gear()


func _spend(cost: Dictionary) -> void:
	for m in cost:
		materials[m] = int(materials.get(m, 0)) - int(cost[m])
		if int(materials[m]) <= 0:
			materials.erase(m)


## Can this recipe be crafted now (learned, and with a catalyst you hold)?
func can_craft(item: String, catalyst := "") -> bool:
	if not bench_open() or not Gear.ITEMS.has(item) or Crafting.recipe(item).is_empty() or best_m < Crafting.learn_m(item):
		return false
	var cost := Crafting.recipe(item).duplicate()
	if catalyst != "":
		if not Crafting.catalysts().has(catalyst):
			return false
		cost[catalyst] = int(cost.get(catalyst, 0)) + 1
	return Crafting.can_afford(cost)


## Craft an item at the Bench: spend its recipe (and the catalyst), roll its
## rarity (tests pass `roll`) and add a new copy. Returns the copy id ("" if
## it can't be crafted).
func craft(item: String, catalyst := "", roll := -1.0) -> String:
	if not can_craft(item, catalyst):
		audio.play("denied", 0.0)
		return ""
	var cost := Crafting.recipe(item).duplicate()
	if catalyst != "":
		cost[catalyst] = int(cost.get(catalyst, 0)) + 1
	_spend(cost)
	var r := Crafting.roll_rarity(randf() if roll < 0.0 else roll, catalyst)
	var copy := "%s#%d" % [item, gear_next]
	gear_next += 1
	gear_owned.append(copy)
	if r > 0:
		gear_rarity[copy] = r
	_save_gear()
	return copy


## Break an unequipped copy down for part of its recipe (Crafting.salvage_return).
func salvage(copy: String) -> bool:
	if not gear_owned.has(copy):
		return false
	for h in gear_equipped:
		if gear_equipped[h].values().has(copy):
			audio.play("denied", 0.0)
			return false
	var back := Crafting.salvage_return(Gear.base(copy), Gear.rarity_of(copy))
	gear_owned.erase(copy)
	gear_wear.erase(copy)
	gear_rarity.erase(copy)
	grant_materials(back, false)
	audio.play("break_wood", 0.05)
	return true


## Materials pop out of something in a run and are collected at once (a
## broken obstacle, a bonked wild dinosaur), with a little icon flying up.
func _drop_materials(table: Dictionary, n: int, at: Vector2) -> Dictionary:
	var got := {}
	for i in n:
		var m := Crafting.drop_pick(table)
		if m != "":
			got[m] = int(got.get(m, 0)) + 1
	if got.is_empty():
		return got
	grant_materials(got)
	var i := 0
	for m in got:
		var pic := Sprite2D.new()
		pic.texture = Crafting.icon(m)
		pic.scale = Vector2.ONE * (40.0 / maxf(pic.texture.get_width(), pic.texture.get_height()))
		pic.z_index = 60
		world.add_child(pic)
		pic.global_position = at + Vector2(i * 34.0, 0)
		var t := pic.create_tween()
		t.tween_property(pic, "global_position", pic.global_position + Vector2(-20, -110), 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		t.tween_property(pic, "modulate:a", 0.0, 0.3)
		t.tween_callback(pic.queue_free)
		fx.float_text(at + Vector2(-20 + i * 34.0, -60), "+%d %s" % [int(got[m]), Crafting.mat_name(m)], Crafting.RARITY_COLOR[Crafting.mat_rarity(m)], 20)
		i += 1
	return got


## Dice for material drops (tests pin it; -1 = roll).
var mat_drop_override := -1.0


## Escaping a hunter's charge sometimes drops its trophy (config/crafting.cfg [trophies]).
func _charge_trophy() -> Dictionary:
	var t := Crafting.trophy(hunter_id)
	var r := mat_drop_override if mat_drop_override >= 0.0 else randf()
	if t == "" or r >= float(Crafting.num("trophies", "chance")):
		return {}
	return _drop_materials({t: 1}, 1, player.position + Vector2(-40, -160))


## A broken obstacle sometimes drops materials (config/crafting.cfg [break_drops]).
func _break_materials(o: Obstacle, at: Vector2) -> Dictionary:
	var table := Crafting.break_table(o, String(course.zone_at_x(o.position.x).id))
	var r := mat_drop_override if mat_drop_override >= 0.0 else randf()
	if table == "" or r >= float(Crafting.num("break_drops", "chance")):
		return {}
	return _drop_materials(Crafting.num("break_drops", table), Crafting.count_of("break_drops"), at)


## A bonked wild dinosaur drops materials (config/crafting.cfg [wild_drops]).
func _wild_materials(o: Obstacle) -> Dictionary:
	var r := mat_drop_override if mat_drop_override >= 0.0 else randf()
	if r >= float(Crafting.num("wild_drops", "chance")):
		return {}
	var table := Crafting.wild_table(String(o.critter), o.kind == "swooper")
	return _drop_materials(table, Crafting.count_of("wild_drops"), o.global_position + Vector2(0, -o.size.y * 0.6))


# ------------------------------------------------------------ attack

## How far ahead the current form reaches: a hero by its weapon (Gear), a
## dinosaur by ATTACK_REACH_DINO.
func attack_reach() -> float:
	var id := String(player.data().id)
	if player.form == Forms.ROK:
		return Gear.reach(id)
	return Tuning.ATTACK_REACH_DINO


## Attack Power: the form's Power attribute (a hero's includes its gear).
func attack_power() -> float:
	var id := String(player.data().id)
	return Dinos.stat(id, "power") if Dinos.known(id) else 3.0


## Can an attack with this Power break obstacle o? Wild dinosaurs and small
## hazards always; logs, thorns, fences and rocks by Power (or if the form
## smashes that kind anyway); dino gates, ledges and steam never.
func attack_breaks(o: Obstacle, power: float) -> bool:
	if o.gate_form != -1 or o.kind == "overhead" or o.kind == "steam":
		return false
	if o.critter != "" or o.kind == "small" or o.mushroom or o.vine:
		return true
	if o.kind in player.data().breaks:
		return true
	if player.form == Forms.ROK and Gear.weapon_with(String(player.data().id), "burns") != "" \
			and (o.vine or o.kind in ["wood", "fence", "thorns"]):
		return true   # the Torch burns wood, whatever the Power
	match o.kind:
		"wood", "thorns":
			return power >= Tuning.ATTACK_POWER_WOOD
		"fence":
			return power >= Tuning.ATTACK_POWER_FENCE
		"rock":
			return power >= Tuning.ATTACK_POWER_ROCK
	return false


## ATTACK at the nearest obstacle or wild dinosaur within reach ahead: the
## form's attack clip plays (attack_clip; a code-drawn lunge and slash for
## bare hands and forms without one). It breaks the target if the Power is
## enough (attack_breaks), else "CLANG!"; the hit lands at once, the clip is
## cosmetic. ATTACK_COOLDOWN between. Returns the obstacle it broke, or null.
func _attack() -> Obstacle:
	if state != State.PLAYING or attack_cd > 0.0 or player.dead:
		return null
	attack_cd = Tuning.ATTACK_COOLDOWN * Dinos.cooldown_mult(String(player.data().id), "power")   # Power attacks faster
	attack_cd_max = attack_cd
	var target := attack_target()
	var clip := attack_clip()
	# running on the ground with a seamless running attack for this weapon:
	# that (it joins the run cycle); otherwise the standing clip
	var w := clip.trim_prefix("attack_") if player.form == Forms.ROK and clip.begins_with("attack_") else ""
	if not (w != "" and player.run_attack_play(w)) and not player.attack_play(clip):
		var lunge := player.create_tween()
		lunge.tween_property(player.body, "position:x", 34.0, 0.08)
		lunge.tween_property(player.body, "position:x", 0.0, 0.16)
		_slash(player.position + Vector2(60.0, -player.data().hitbox.y * 0.55), attack_reach())
	audio.play("slide", 0.1, 1.6, -4.0)
	if target == null:
		return null
	if clip == "attack_bow" or clip == "attack_sling":
		# the arrow / stone leaves on the clip's release frame
		var to := target.global_position + Vector2(0, -target.size.y * 0.5)
		var m: Dictionary = SpriteLib.attack_meta(String(player.data().id)).get(clip, {})
		var wait := 0.0
		if player.attack_clip == clip:
			for i in int(m.get("release", 4)):
				wait += float(m.times[i]) / 1000.0
		elif player.run_attack_phase >= 0:
			wait = player.run_attack_wait(4)   # the running attack releases on frame 4
		get_tree().create_timer(wait, false).timeout.connect(_shoot_arrow.bind(to, clip == "attack_sling"))
	return _attack_hit(target)


## The whole weapon the hero holds (for the run that carries it), or "".
func carry_weapon() -> String:
	if player.form != Forms.ROK:
		return ""
	var w := Gear.slot_item(String(player.data().id), "weapon")
	if w == "" or not Gear.ITEMS.has(Gear.base(w)) or Gear.slot_of(w) != "weapon" or Gear.broken(w):
		return ""
	return Gear.base(w)


## The attack clip for the current form: a hero's "attack_<weapon>" while the
## weapon is whole (bare hands, a dinosaur card or a broken weapon: ""), a
## dinosaur's "attack".
func attack_clip() -> String:
	if player.form != Forms.ROK:
		return "attack"
	var w := Gear.slot_item(String(player.data().id), "weapon")
	if w == "" or not Gear.ITEMS.has(Gear.base(w)) or Gear.slot_of(w) != "weapon" or Gear.broken(w):
		return ""
	return "attack_" + Gear.base(w)


## The Bow's arrow (or the Sling's stone), from the hero's hand to where the
## target was (the hit itself is instant).
func _shoot_arrow(to: Vector2, stone := false) -> void:
	if player.dead or state != State.PLAYING:
		return
	var a: Node2D
	if stone:
		var p := Polygon2D.new()
		var pts := PackedVector2Array()
		for i in 10:
			pts.append(Vector2(cos(TAU * i / 10.0) * 7.0, sin(TAU * i / 10.0) * 6.0))
		p.polygon = pts
		p.color = Color(0.55, 0.52, 0.48)
		a = p
	elif ResourceLoader.exists("res://assets/gear/arrow.png"):
		var sp := Sprite2D.new()
		sp.texture = SpriteLib.tex("res://assets/gear/arrow.png")
		sp.scale = Vector2.ONE * (70.0 / sp.texture.get_width())
		a = sp
	else:
		return
	a.z_index = 50
	world.add_child(a)
	a.global_position = player.global_position + Vector2(40, -player.data().hitbox.y * 0.6)
	a.rotation = (to - a.global_position).angle()
	var t := a.create_tween()
	t.tween_property(a, "global_position", to, clampf(a.global_position.distance_to(to) / 1800.0, 0.06, 0.25))
	t.tween_callback(a.queue_free)


## What ATTACK would hit right now: the nearest obstacle or wild dinosaur
## within reach ahead at Rok's height (a falling meteor at any height, with
## extra reach), or null. The target marker shows it.
func attack_target() -> Obstacle:
	var hb := player.hitbox()
	var reach := attack_reach()
	var target: Obstacle = null
	for o in course.obstacles:
		var ob := o.hitbox()
		var far := reach + (Tuning.ATTACK_METEOR_REACH if o.get_meta("meteor", false) else 0.0)
		if ob.size == Vector2.ZERO or ob.end.x < hb.position.x or ob.position.x - hb.end.x > far:
			continue
		var meteor: bool = o.get_meta("meteor", false)
		if meteor:
			if ob.position.x - hb.end.x > reach + Tuning.ATTACK_METEOR_REACH:
				continue
		elif ob.end.y < hb.position.y - 40.0 or ob.position.y > hb.end.y + 10.0:
			continue   # not at Rok's height
		if target == null or ob.position.x < target.hitbox().position.x:
			target = o
	return target


func _attack_hit(target: Obstacle) -> Obstacle:
	var power := attack_power()
	if player.form == Forms.ROK:   # the hit wears the hero's weapon (after its Power counted)
		var w := Gear.slot_item(String(player.data().id), "weapon")
		if Gear.max_durability(w) > 0 and not Gear.broken(w):
			wear_weapon(w)
	if not attack_breaks(target, power):
		fx.float_text(target.position + Vector2(-40, -target.size.y - 30.0), "CLANG!", Color(0.85, 0.85, 0.9), 26)
		audio.play("shield", 0.05, 0.7, -2.0)
		return null
	_coach_done("attack")
	if target.get_meta("meteor", false):
		var fall: Tween = target.get_meta("fall", null)
		if fall and fall.is_valid():
			fall.kill()   # smashed in the air: the rubble drops while it crumbles
		_smash(target, Color(1.0, 0.6, 0.3))
		var drop := target.create_tween()
		drop.tween_property(target, "position:y", float(target.get_meta("ground", target.position.y)), 0.3).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		drop.parallel().tween_property(target, "rotation", 0.0, 0.3)
		fx.float_text(target.position + Vector2(-50, -80), "SMASHED!", Color(1.0, 0.7, 0.35), 30)
		fx.add_shake(3.0)
		return target
	if target.critter != "":
		target.bumped = true
		course.remove_obstacle(target)
		fx.smash(target.position + Vector2(0, -40), Color(0.75, 0.55, 0.4))
		fx.float_text(target.position + Vector2(-40, -150), "BONK!", Color(1.0, 0.75, 0.35), 30)
		score += Tuning.SMASH_SCORE * points_mult()
		audio.play("smash", 0.1, 0.8)
		combo.feat()
		_drop_card(target)
		_wild_materials(target)
	elif _small_hazard(target):
		_power_break(target)
	else:
		_smash(target, Color(1.0, 0.6, 0.45))
		fx.float_text(target.position + Vector2(-40, -target.size.y - 30.0), "WHACK!", Color(1.0, 0.75, 0.35), 28)
	fx.add_shake(3.0)
	return target


## A quick claw/club arc in front of Rok that fades (placeholder attack art).
## The target marker: corner brackets and an arrow over what ATTACK would hit
## (attack_target), green if it would break, red if it would clang; faded
## while the attack cools down. Hidden when nothing is in reach.
func _attack_marker_step() -> void:
	if attack_marker == null:
		attack_marker = AttackMarker.new()
		world.add_child(attack_marker)
	var t := attack_target() if state == State.PLAYING and not player.dead else null
	if t == null:
		attack_marker.visible = false
		return
	attack_marker.visible = true
	attack_marker.box = t.hitbox()
	attack_marker.breaks = attack_breaks(t, attack_power())
	attack_marker.ready_now = attack_cd <= 0.0


func _slash(at: Vector2, reach: float) -> void:
	var l := Line2D.new()
	var pts := PackedVector2Array()
	for i in 9:
		var a := lerpf(-1.1, 0.9, i / 8.0)
		pts.append(at + Vector2(cos(a), sin(a)) * minf(reach * 0.55, 110.0))
	l.points = pts
	l.width = 10.0
	l.default_color = Color(1.0, 0.95, 0.8, 0.9)
	l.begin_cap_mode = Line2D.LINE_CAP_ROUND
	l.end_cap_mode = Line2D.LINE_CAP_ROUND
	world.add_child(l)
	var t := l.create_tween()
	t.tween_property(l, "modulate:a", 0.0, 0.2)
	t.tween_callback(l.queue_free)


# ------------------------------------------------------------ daily missions

## A "total" stat went up (also every badge_event): mission progress.
func mission_event(stat: String, amount := 1.0) -> void:
	if state == State.PLAYING:
		_missions_done(missions.add(stat, amount))


## Missions just completed: meat straight into the bank, a banner, a line in
## the run's news; all three done pays the day's bonus (plus the streak).
func _missions_done(idx: Array) -> void:
	if idx.is_empty() or state != State.PLAYING:
		return
	for i in idx:
		meat_bank += Tuning.MISSION_MEAT
		new_this_run.append("Mission: " + missions.text(i))
		hud.show_banner("MISSION COMPLETE!", "%s  +%d meat" % [missions.text(i), Tuning.MISSION_MEAT], Color(0.55, 1.0, 0.6), 2.6)
	audio.play("unlock", 0.0, 1.1)
	if missions.all_done() and missions.last_full != missions.date:
		var yesterday := Time.get_date_string_from_unix_time(int(Time.get_unix_time_from_system()) - 86400)
		var bonus := missions.complete_day(yesterday)
		meat_bank += bonus
		new_this_run.append("All missions done: +%d meat" % bonus)
		hud.show_banner("ALL MISSIONS DONE!", "+%d meat%s" % [bonus, " · %d-day streak!" % missions.streak if missions.streak > 1 else ""], Color(0.55, 1.0, 0.6), 3.0)
	SaveData.save_meat(meat_bank)
	SaveData.save_missions(missions.to_dict())


func _show_missions() -> void:
	if missions.refresh(Time.get_date_string_from_system(), best_m, unlocked):
		SaveData.save_missions(missions.to_dict())
	var head := "DAILY MISSIONS"
	if missions.streak > 1 and missions.last_full >= Time.get_date_string_from_unix_time(int(Time.get_unix_time_from_system()) - 86400):
		head += "  ·  %d-day streak" % missions.streak
	hud.set_missions(missions.lines(), head)


## Milestone chests: when the next milestone (every CHEST_EVERY_M) comes
## into view, a chest is placed on flat ground there (a little later if the
## ground isn't flat, never over a pit or liquid).
func _chest_step() -> void:
	var view_w := get_viewport().get_visible_rect().size.x
	var x := Tuning.PLAYER_X + (next_chest_m - metres()) * Tuning.PX_PER_M
	while x < Tuning.PLAYER_X + 200.0:
		# no room left for this one (or the run started past it): the next milestone
		next_chest_m = (floorf(next_chest_m / Tuning.CHEST_EVERY_M) + 1.0) * Tuning.CHEST_EVERY_M
		x = Tuning.PLAYER_X + (next_chest_m - metres()) * Tuning.PX_PER_M
	if x > view_w + 150.0:
		return
	var gy := terrain.flat_y(x - 60.0, x + 60.0)
	if gy < 0.0 or terrain.liquid_at(x) != "":
		next_chest_m += 2.0   # try a little further on
		return
	course._pickup("chest", Vector2(x, gy))
	course.pickups[-1].set_meta("milestone", maxi(1, int(roundf(next_chest_m / Tuning.CHEST_EVERY_M))))
	next_chest_m = (floorf(next_chest_m / Tuning.CHEST_EVERY_M) + 1.0) * Tuning.CHEST_EVERY_M


## The wild-dinosaur preview ([early] stampede_preview_m): until the Stampede
## lesson is taught, one slow wild dinosaur of the zone runs at Rok in every
## run, with a banner (not a card, so lessons aren't held back). Jump it and
## the hunter eats it behind him (main._eat_critters).
func _preview_step() -> void:
	if preview_done or tutorial_run != null or Progression.STAMPEDE_PREVIEW_M <= 0.0:
		return
	var m := metres()
	if m < Progression.STAMPEDE_PREVIEW_M:
		return
	if Progression.taught("stampede", best_m, seen) or m > Progression.STAMPEDE_PREVIEW_M + 200.0:
		preview_done = true   # already met the real thing, or no flat ground came
		return
	if course.wild_preview(Progression.STAMPEDE_PREVIEW_SPEED) == null:
		return   # no flat ground yet: try again next frame
	preview_done = true
	hud.show_banner("WILD DINOSAUR!", "Jump over it, then look behind you!", Color(1.0, 0.8, 0.45), 3.0)


## Running into a chest opens it: its rarity (better at later milestones,
## Chest.rarity) and a reward from that rarity's list (Chest.REWARDS).
func _open_chest(k: Pickup, roll := -1.0, pick := "") -> void:
	var n: int = k.get_meta("milestone", 1)
	var r := Chest.rarity(n, randf() if roll < 0.0 else roll)
	var reward: String = pick if pick != "" else Chest.REWARDS[r].pick_random()
	var col: Color = Chest.RARITY_COLOR[r]
	var text := ""
	match reward:
		"meat":
			var mt := Chest.meat(r, n)
			run_meat += mt
			badge_event("meat", mt)
			text = "+%d meat" % mt
		"xp":
			var did: String = player.data().id
			var gx := float(Chest.xp(r, n)) * xp_mult()
			dino_xp[did] = float(dino_xp.get(did, 0.0)) + gx
			badge_stats["xp"] = float(badge_stats.get("xp", 0.0)) + gx
			text = "+%d XP for %s" % [int(gx), Herd.name_of(did)]
		"booster":
			var owned := boosters_owned.duplicate()
			var kind: String = owned.pick_random() if not owned.is_empty() else "egg"
			if collect_booster(kind, k.position):
				text = Boosters.DATA[kind].name + "!"
			else:   # no free slot: meat instead
				var mt := Chest.meat(r, n)
				run_meat += mt
				badge_event("meat", mt)
				text = "+%d meat" % mt
		"heart":
			if health < max_health():
				health = mini(health + Hearts.QUARTERS, max_health())
				text = "+1 ♥"
			else:
				score += Tuning.HEART_SCORE * points_mult()
				text = "+%d" % int(Tuning.HEART_SCORE * points_mult())
		"full_heal":
			health = max_health()
			text = "Hearts refilled!"
		"materials":
			var got := {}
			for i in int(Crafting.num("chests", r + "_count")):
				var m := Crafting.drop_pick(Crafting.num("chests", r))
				if m != "":
					got[m] = int(got.get(m, 0)) + 1
			grant_materials(got)
			text = Crafting.cost_text(got)
		"card":
			var d := Gear.random_card(r == "epic")
			grant_card(d)
			new_this_run.append("Card: " + Herd.name_of(d))
			text = "%s Card!" % Herd.name_of(d)
		"frenzy":
			combo.meter = 1.0
			combo.frenzy_t = Tuning.FRENZY_TIME
			combo.frenzy_started.emit()
			text = "PRIMAL FRENZY!"
	score += Tuning.CHEST_SCORE * points_mult()
	chests_opened += 1
	mission_event("chests")
	combo.feat(Tuning.CHEST_COMBO_WEIGHT)
	k.open(r)
	course.pickups.erase(k)
	course.debris.append(k)   # stays, open, scrolling away
	fx.float_text(k.position + Vector2(-90, -150), Chest.RARITY_NAME[r] + "!", col, 34 if r == "common" else 40)
	fx.float_text(k.position + Vector2(-80, -110), text, Color(1, 0.95, 0.8), 28)
	for i in (4 if r == "common" else 8):
		fx.sparkle(k.position + Vector2(randf_range(-50, 50), randf_range(-110, -30)), col)
	fx.add_shake(3.0 if r == "common" else 6.0)
	audio.play("unlock", 0.0, 1.0 if r == "common" else 1.2)
	if r != "common":
		audio.play("amber", 0.0, 1.5, 2.0)


## Primal Frenzy: whatever Rok runs into breaks (dino gate walls too) and wild
## dinosaurs are bowled over. Steam just blows past him.
func _frenzy_smash(o: Obstacle) -> void:
	if o.kind == "steam":
		return
	if o.critter != "":
		o.bumped = true
		course.remove_obstacle(o)
		fx.smash(o.position + Vector2(0, -40), Color(0.75, 0.55, 0.4))
		fx.float_text(player.position + Vector2(-40, -210), "BOWLED OVER!", Color(1.0, 0.8, 0.3))
		score += Tuning.SMASH_SCORE * points_mult()
		audio.play("smash", 0.1, 0.8)
		combo.feat()
		_drop_card(o)
		_wild_materials(o)
		return
	_smash(o, Color(1.0, 0.8, 0.3))
	fx.add_shake(3.0)


func _on_combo_tier(t: int) -> void:
	_missions_done(missions.best("combo", combo.mult()))
	var col := hud.combo_meter.tier_color(t)
	hud.combo_meter.pop()
	fx.float_text(player.position + Vector2(-70, -250), "x%s COMBO!" % hud.combo_meter._mult_text(combo.mult()), col, 30 + t * 3)
	audio.play("amber", 0.0, 1.0 + 0.15 * t, 2.0)
	if not seen.has("combo"):
		seen.append("combo")
		SaveData.save_seen(seen)
		hud.show_banner("COMBO!", "Clear hazards without a stumble to raise your points multiplier. A stumble or a long gap ends the streak.", col, 3.5)


func _on_combo_broken(n: int) -> void:
	if n >= int(Tuning.COMBO_TIERS[1][0]) and state == State.PLAYING:
		fx.float_text(player.position + Vector2(-60, -290), "Combo %d lost" % n, Color(0.85, 0.8, 0.75), 22)


func _on_frenzy_started() -> void:
	frenzies += 1
	mission_event("frenzy")
	_frenzy_meat = 0.3
	hud.combo_meter.pop()
	fx.float_text(player.position + Vector2(-110, -260), "PRIMAL FRENZY!", Color(1.0, 0.8, 0.25), 44)
	fx.add_shake(8.0)
	for i in 8:
		fx.sparkle(player.position + Vector2(randf_range(-80, 80), randf_range(-180, -20)), Color(1.0, 0.8, 0.3))
	audio.play("trex_roar", 0.0, 1.7, -4.0)
	audio.play("unlock", 0.0, 1.2)
	if not seen.has("frenzy"):
		seen.append("frenzy")
		SaveData.save_seen(seen)
		hud.show_banner("PRIMAL FRENZY!", "Your streak filled the gold meter: for a few seconds Rok smashes through anything and pulls away. Pits still bite!", Color(1.0, 0.8, 0.25), 3.5)


func _on_frenzy_ended() -> void:
	player.invuln = maxf(player.invuln, Tuning.FRENZY_END_INVULN)
	player.sprite.self_modulate = Color.WHITE
	audio.play("shift", 0.0, 0.8)


## Eating an egg: a short burst of speed that pulls away from the T-rex.
func _egg_boost() -> void:
	boost_t = Tuning.EGG_BOOST_TIME
	fx.float_text(player.position + Vector2(-80, -240), "SPEED BOOST!", Color(1.0, 0.85, 0.3), 36)
	audio.play("shift", 0.0, 1.4)


var _boost_trail := 0.0


func _boost_fx(delta: float) -> void:
	_boost_trail -= delta
	if _boost_trail <= 0.0:
		_boost_trail = 0.05
		fx.speed_line(player.position + Vector2(-40.0, -randf_range(20.0, 120.0)))
	var glow := 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.02)
	player.sprite.self_modulate = Color(1.0, 1.0, 1.0).lerp(Color(1.4, 1.25, 0.8), glow * minf(boost_t, 1.0))
	if boost_t <= 0.0:
		player.sprite.self_modulate = Color.WHITE


## The break sound for what an obstacle is made of: wood (logs, fences,
## thorns, vines), stone (rocks, boulders, walls, meteors), else the old smash.
func break_sound(o: Obstacle) -> void:
	if o.mushroom:
		audio.play("smash", 0.1)
	elif o.vine or o.kind in ["wood", "fence", "thorns"]:
		audio.play("break_wood", 0.08)
	elif o.kind in ["rock", "small"] or o.get_meta("meteor", false):
		audio.play("break_rock", 0.08)
	else:
		audio.play("smash", 0.1)


func _smash(o: Obstacle, color: Color) -> void:
	var pos := o.position + Vector2(0, -o.size.y * 0.5)
	var debris := Color(0.55, 0.5, 0.45) if o.kind == "rock" else Color(0.6, 0.38, 0.2)
	fx.smash(pos, debris)
	badge_event("smashed")
	combo.feat()
	break_sound(o)
	fx.sparkle(pos, color)
	score += Tuning.SMASH_SCORE * points_mult()
	fx.float_text(pos + Vector2(-20, -40), "+%d" % int(Tuning.SMASH_SCORE * points_mult()))
	_break_loot(pos)
	_break_materials(o, pos)
	course.shatter_obstacle(o)


## Dice for break loot (tests pin it; -1 = roll).
var loot_override := -1.0


## A broken obstacle sometimes drops something (the user's rule;
## config/pickups.cfg [break_loot]): a few amber, or rarer a heart (amber at
## full health) or a power-up the player owns. Not during a frenzy unless
## in_frenzy (it rains meat already). Returns what dropped ("" for nothing).
func _break_loot(at: Vector2) -> String:
	if combo.in_frenzy() and not Loot.num("break_loot", "in_frenzy"):
		return ""
	var chance: float = Loot.num("break_loot", "chance")
	var r := loot_override if loot_override >= 0.0 else randf()
	if r >= chance:
		return ""
	r /= chance   # which: 0-1 within the drop
	var heart: float = Loot.num("break_loot", "heart")
	var kind := "amber"
	if r < heart and health < max_health():
		kind = "heart"
	elif r >= heart and r < heart + float(Loot.num("break_loot", "power")):
		kind = course._booster()
	if not Requires.ok("pickup." + kind):
		return ""   # not yet (config/requirements.cfg: amber needs a dinosaur)
	var n := int(Loot.num("break_loot", "amber_count")) if kind == "amber" else 1
	for i in n:
		course._pickup(kind, at + Vector2(30.0 + 38.0 * i, -50.0 - 26.0 * (i % 2)))
	return kind


## Which form button should glow: strongly for an upcoming dino gate, softly
## for a big hazard an unlocked dino handles well (if there is energy for it).
func _glow_hint() -> Vector2i:
	if state != State.PLAYING:
		return Vector2i(-1, 0)
	var px := player.position.x
	for m in course.markers:
		var gx: float = Course.gate_x0(m)
		var f: int = m.get_meta("form")
		if gx > px - 20.0 and gx - px < 1300.0:
			if f != player.form and unlocked.has(f):
				return Vector2i(f, 2)
			return Vector2i(-1, 0)
	if energy < Tuning.SHIFT_MIN_ENERGY:
		return Vector2i(-1, 0)
	var next: Obstacle = null
	for o in course.obstacles:
		if o.position.x > px + 60.0 and o.position.x - px < 750.0 and (next == null or o.position.x < next.position.x):
			next = o
	if next == null:
		return Vector2i(-1, 0)
	var big := next.size.y * next.shrink.y > 150.0
	if big:
		for f in [Forms.TRICERATOPS, Forms.SPINOSAURUS]:
			if next.kind in Forms.get_data(f).breaks and unlocked.has(f) and f != player.form:
				return Vector2i(f, 1)
	return Vector2i(-1, 0)


## Zones and the day/night cycle follow the distance travelled.
func _update_environment() -> void:
	var m := metres()
	bg.apply_environment(m)
	var lc := Zones.light(m)
	var lm := weather.light_mult()
	lighting.color = Color(lc.r * lm, lc.g * lm, lc.b * lm, lc.a)
	audio.set_music_weights(Zones.weights(m))
	if state != State.PLAYING:
		return
	var zi := int(floor(m / Zones.ZONE_LEN_M))
	if zi != zone_index:
		zone_index = zi
		var z := Zones.zone_at(m)
		var lap := Zones.lap_at(m)
		audio.play("intro", 0.0, 0.8)
		if not seen.has("zone_" + z.id):
			seen.append("zone_" + z.id)
			SaveData.save_seen(seen)
			last_new_m = m
			new_this_run.append(z.name)
			if pause_for_info:
				var icons := {"forest": "res://assets/bg/bg_2.png", "desert": "res://assets/bg/desert_far.png", "volcanic": "res://assets/bg/volcanic_far.png"}
				queue_info("NEW ZONE: " + z.name.to_upper(), z.blurb, load(icons[z.id]), Color(1.0, 0.75, 0.35))
				return
		hud.show_banner(("ZONE: " if lap == 0 else "ZONE (lap %d): " % (lap + 1)) + z.name.to_upper(), z.blurb, Color(1.0, 0.86, 0.5), 2.8)
	var night := Zones.is_night(m)
	if night != _was_night:
		_was_night = night
		hud.show_banner("NIGHT FALLS" if night else "DAYBREAK", "", Color(0.7, 0.8, 1.0) if night else Color(1.0, 0.85, 0.5), 1.6)


## What the HUD's meat counter shows: this run's meat while it lasts, the
## run's total once he dies and on the game-over screen (it's banked by
## then), and nothing on
## the title screen (which shows the bank).
func _meat_count() -> int:
	match state:
		State.TITLE:
			return -1
		State.DYING, State.OVER:
			return last_run_meat   # already banked when Rok died
	return run_meat


## How much faster than its base rate a dino form drains energy right now.
func drain_mult() -> float:
	return 1.0 + dino_time / Tuning.DRAIN_DOUBLE_TIME


func _refresh_hud() -> void:
	_update_environment()
	var danger := 0.0
	if state == State.PLAYING:
		danger = clampf(1.0 - chase_gap / Tuning.CHASE_DANGER, 0.0, 1.0)
	hud.set_danger(danger)
	hud.set_chase(chase_gap, state == State.PLAYING or state == State.INTRO or state == State.DYING or state == State.PAUSED)
	var g := _glow_hint()
	hud.set_glow(g.x, g.y)
	# the summary card (OVER) has the screen to itself; the main menu (TITLE)
	# brings back the Field Guide, Camp and Market buttons
	var menu := state == State.TITLE or state == State.PAUSED
	var overlay: bool = _overlay_open()
	hud.combo_meter.shown = state == State.PLAYING or state == State.INFO or state == State.PAUSED
	hud.set_tips(state == State.PAUSED and not overlay, tutorial.enabled)
	var in_run := (state == State.PLAYING or state == State.PAUSED) and not overlay
	hud.set_stop(in_run and tutorial_run == null, stop_armed > 0.0)
	hud.set_tutorial_bar(in_run and tutorial_run != null, stop_armed > 0.0)
	hud.set_codex(menu and not overlay, menu and Codex.has_new(unlocked, best_m, seen, guide_viewed))
	hud.set_market(state == State.TITLE and not overlay, market_badge())
	hud.set_herd(state == State.TITLE and not overlay, not level_ready().is_empty() or gear_ready())
	hud.set_tutorial(state == State.TITLE and not overlay and menu_tour == null)   # (the tour's bubble sits there)
	hud.set_hearts(health, max_health())
	hud.update_play(int(score), int(metres()), energy, player.form, player.armor, state == State.PLAYING, unlocked,
			Zones.zone_at(metres()).name, _meat_count())
	hud.set_drain_heat(0.0 if player.form == Forms.ROK else clampf((drain_mult() - 1.0) / 2.0, 0.0, 1.0))
	hud.set_slots(slots, slots.map(func(k): return k != "" and booster_ready(k)), slot_count)


# ------------------------------------------------------------ coach hints (tutorial.gd)

## The player did a lesson's action: count it, and end its hint if it's up.
func _coach_done(id: String) -> void:
	if tutorial and tutorial.done(id):
		hud.hide_coach()


## The pause screen's Tips button: coach hints on or off (saved).
func _toggle_tips() -> void:
	tutorial.enabled = not tutorial.enabled
	SaveData.save_tips(tutorial.enabled)
	if not tutorial.enabled:
		tutorial.hide()
		hud.hide_coach()
	audio.play("click", 0.0)


func _save_tutorial() -> void:
	SaveData.save_tutorial(tutorial.progress)


## Every frame: end a hint whose moment has passed (or that timed out), else
## show the first lesson whose moment has come. Never outside a run or the
## main menu, nor while an overlay screen is open.
func _coach_step(delta: float) -> void:
	if tutorial == null or tutorial_run != null:
		return
	if _ground_jump_t >= 0.0:
		if not player.on_ground and player._jump_held:
			_ground_jump_t += delta
			if _ground_jump_t >= Tuning.COACH_HOLD_JUMP:
				_coach_done("high_jump")   # held JUMP for a higher leap
				_ground_jump_t = -1.0
		elif player.on_ground or not player._jump_held:
			_ground_jump_t = -1.0
	var overlay: bool = _overlay_open()
	var where := "run" if state == State.PLAYING else ("menu" if state == State.TITLE and not overlay and _menu_t <= 0.0 else "")
	var timed_out := tutorial.step(delta)
	if tutorial.current != "":
		if where == "" or timed_out or _coach_target(tutorial.current, where) == "":
			tutorial.hide()
			hud.hide_coach()
		return
	if where == "":
		return
	for id in Tutorial.LESSONS:
		if not tutorial.can_show(id):
			continue
		var target := _coach_target(id, where)
		if target != "" and hud.coach(target, tutorial.show(id), where == "menu"):
			return


## The button a lesson points at if its moment has come now, else "".
func _coach_target(id: String, where: String) -> String:
	var lesson: Dictionary = Tutorial.LESSONS[id]
	if lesson.get("menu", false) != (where == "menu"):
		return ""
	match id:
		"market":
			return "market" if played_once and market_badge() else ""
		"camp":
			return "herd" if played_once and not level_ready().is_empty() else ""
		"booster":
			_slot_wait = _slot_wait + get_process_delta_time() if slots.slice(0, slot_count).any(func(k): return k != "" and booster_ready(k)) else 0.0
			if _slot_wait < Tuning.COACH_SLOT_WAIT:
				return ""
			for i in slot_count:
				if slots[i] != "" and booster_ready(slots[i]):
					return "slot_%d" % i
			return ""
		"shift":
			var g := _glow_hint()
			return "form_%d" % g.x if g.x > 0 and energy >= Tuning.SHIFT_MIN_ENERGY else ""
		"energy":
			return "form_%d" % Forms.ROK if player.form != Forms.ROK and energy < Tuning.COACH_LOW_ENERGY else ""
		"attack":
			var t := attack_target()
			if t == null or attack_cd > 0.0 or not attack_breaks(t, attack_power()):
				return ""
			if t.critter == "" and not tutorial.learned("jump"):
				return ""   # the first rocks teach jumping; ATTACK comes once that's learned
			return "attack"
	# jump lessons and slide: the next obstacle coming up
	if not player.on_ground or player.is_low():
		return ""
	var o := _coach_obstacle()
	if o == null:
		return ""
	var tall := o.hitbox().size.y
	match id:
		"slide":
			return "slide" if (o.kind == "overhead" or o.kind == "swooper") and player.standing_hitbox().size.y > Tuning.LEDGE_CLEARANCE else ""
		"jump":
			return "jump" if o.kind != "overhead" and not o.kind == "swooper" else ""
		"high_jump":
			return "jump" if tutorial.learned("jump") and o.kind in ["wood", "rock", "fence", "thorns"] and tall >= Tuning.COACH_TALL else ""
		"double_jump":
			return "jump" if tutorial.learned("jump") and o.kind != "overhead" and tall >= Tuning.COACH_WALL else ""
	return ""


## The nearest obstacle ahead within the coach's look-ahead window (not a
## dino gate: those have their glowing button and marker).
func _coach_obstacle() -> Obstacle:
	var hb := player.hitbox()
	var best: Obstacle = null
	for o in course.obstacles:
		if o.gate_form != -1:
			continue
		var d := o.hitbox().position.x - hb.end.x
		if d >= Tuning.COACH_NEAR and d <= Tuning.COACH_FAR and (best == null or o.hitbox().position.x < best.hitbox().position.x):
			best = o
	return best


# ------------------------------------------------------------ the training run (tutorial_run.gd)

## A tap or key on the main menu: the training run the very first time, else a run.
func _start_from_menu() -> void:
	if not tutorial_run_done:
		start_tutorial()
	else:
		start_run()


## The main menu's Tutorial button: play the training run again, any time.
## (It plays by itself only once, on a fresh save; a replay changes nothing
## but what it teaches, which is already known.)
func replay_tutorial() -> void:
	if _menu_t > 0.0:
		return
	audio.play("click", 0.0)
	start_tutorial()


## Start (or restart at `step`) the training run: a normal run with the
## intro, then TutorialRun drives it.
func start_tutorial(step := 0) -> void:
	start_run(step == 0)
	tutorial_run = TutorialRun.new(self, step)
	next_chest_m = INF      # no starter chest (it came mid-lesson with its own card)
	preview_done = true     # nor the wild-dinosaur preview
	course.holding = true
	course.starter_egg = false
	terrain.calm = true
	hud.hide_coach()


## While the training run is frozen on a hint, only the button it asks for
## (and pause / stop) does anything. True if `action` may go ahead.
func _tutorial_allows(action: String) -> bool:
	if tutorial_run == null or not tutorial_run.frozen:
		return true
	if action in ["pause", "stop", "sound"]:
		return true
	if tutorial_run.phase == "note":
		if action == "note_back":
			tutorial_run.note_back()
		else:
			tutorial_run.note_tap()   # a note: Next, or any other tap, moves on
		return false
	if action == "":
		return false
	return tutorial_run.pressed(action)


## The HUD action a key press stands for (for the training run's freeze).
func _key_action(event: InputEvent) -> String:
	for pair in [["note_back", "note_back"], ["jump", "jump"], ["slide", "slide"], ["attack", "attack"], ["booster_1", "slot_0"],
			["booster_2", "slot_1"], ["booster_3", "slot_2"], ["pause", "pause"], ["stop", "stop"]]:
		if event.is_action_pressed(pair[0]):
			return pair[1]
	for i in Forms.ORDER.size():
		if event.is_action_pressed("form_%d" % (i + 1)):
			return "form_%d" % Forms.ORDER[i]
	return ""


## The training run is over (finished, or skipped with Stop): it never plays
## again. What it taught is marked learned for the coach hints, its hazards
## count as taught, the lent Raptor goes back, and it's the main menu.
func end_tutorial(skipped: bool) -> void:
	if tutorial_run == null:
		return
	if tutorial_run.frozen:
		tutorial_run._unfreeze()
	for id in tutorial_run.taught():
		if Tutorial.LESSONS.has(id):
			tutorial.learn(id)
	if not skipped:
		for key in ["small", "log", "wall", "ledge", "egg"]:
			if not seen.has(key):
				seen.append(key)
		SaveData.save_seen(seen)
	tutorial_run = null
	tutorial_run_done = true
	SaveData.save_tutorial_run_done(true)
	_save_tutorial()
	if lent_raptor:
		unlocked.erase(Forms.RAPTOR)
		lent_raptor = false
	if player.form != Forms.ROK:
		player.shift_to(Forms.ROK)
	course.holding = false
	terrain.calm = false
	hud.hide_coach()
	hud.clear_banner()
	speed = 0.0
	slots = ["", "", ""]
	_to_title()
	if not skipped:
		_menu_t = 0.0
		menu_tour = MenuTour.new(self)   # and now the Marketplace, Camp and Encyclopedia


## The menu tour is over (finished or skipped): back to a normal main menu.
func end_menu_tour() -> void:
	menu_tour = null
	hud.hide_coach()


## A JUMP release. In the training run a jump counts as held for at least
## TutorialRun.MIN_HOLD, so a quick first-time tap still clears the lesson's
## obstacle (a very short tap is a tiny hop).
func _release_jump() -> void:
	if tutorial_run != null and tutorial_run.hold_left > 0.0:
		tutorial_run.release_pending = true
	else:
		player.release_jump()
