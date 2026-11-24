class_name Codex
extends CanvasLayer
## The Field Guide: an encyclopedia of what the player has unlocked or been
## taught. Dinosaurs appear once unlocked; hazards and terrain once taught
## (Progression.taught). Everything else shows as a silhouette with the
## distance where it is discovered. Entries discovered since the guide was
## last opened carry a NEW tag.

signal closed

const INK := Color(0.32, 0.17, 0.06)
const PAPER := Color(0.97, 0.9, 0.74)
const CARD := Color(0.93, 0.83, 0.62)
const P := "res://assets/props/%s.png"

## Hazards and terrain, in the order they are taught.
const HAZARDS := [
	{"key": "trex", "name": "The T-rex", "icon": "res://assets/portraits/trex.png", "always": true, "facts": "trex",
		"text": "Always on Rok's tail, running at exactly his pace. Only stumbles (trips, snags, dizziness, thorns, shield hits), climbing hills and its charges let it close in; on flat ground as Rok you never lose ground. If it reaches him, it's over.", "counter": "Pull away with a fast dino (Raptor, Pteranodon), by sliding downhill, or with a pepper booster. Any lead you build is yours to keep."},
	{"key": "small", "name": "Rocks & Mushrooms", "icon": "Stones_03",
		"text": "Low and easy. A single jump clears them. They won't end your run: Rok trips over a rock and the T-rex gains on him, and a mushroom squashes, its spores making him dizzy for a few seconds (lower jumps).", "counter": "Every form can jump them. Triceratops and Spinosaurus smash them."},
	{"key": "thorn_bush", "name": "Thorn Bushes", "icon": "Grasses_16",
		"text": "A prickly bush. Brushing it won't end your run, but Rok stumbles and the T-rex gains on him.", "counter": "Spinosaurus tramples thorns."},
	{"key": "log", "name": "Logs & Stumps", "icon": "Logs_03",
		"text": "Long and low. Jump early, and hold JUMP for a longer leap.", "counter": "Triceratops and Spinosaurus smash them."},
	{"key": "boulder", "name": "Boulders", "icon": "Stones_04",
		"text": "Tall and heavy. Needs a full jump.", "counter": "Triceratops smashes them."},
	{"key": "gate_raptor", "name": "Crumbling Bridge", "icon": "Logs_05", "gate": true,
		"text": "Thin twigs over a gap too wide to jump. They snap under heavy feet.", "counter": "DINO GATE: cross as the light Raptor (or fly over)."},
	{"key": "gate_tri", "name": "Barricades", "icon": "res://assets/props/Tile-3_09.png", "gate": true,
		"text": "Log barricades (forest), cracked sandstone (desert) and basalt (volcanic), stacked to the sky. Too tall to jump or fly over.", "counter": "DINO GATE: charge through as Triceratops."},
	{"key": "quicksand", "name": "Quicksand", "icon": "res://assets/props/Other_08.png",
		"text": "Desert sand that swallows anyone who lingers. Rok sinks in under a second; heavy dinos even faster. Once the Raptor joins you, the sand runs deep: too wide to jump as the world speeds up, and it grabs anyone who lands in it.", "counter": "Jump across while it's narrow. Deep sand: dash over as the Raptor (it barely sinks) or fly."},
	{"key": "large_hill", "name": "Big Hills", "icon": "res://assets/terrain/slope_up.png",
		"text": "A long climb and a long descent. Climbing slows Rok and the T-rex gains.", "counter": "SLIDE down the far side to pull away. The fast Raptor isn't slowed by climbing."},
	{"key": "fence", "name": "Fences", "icon": "Fences_01",
		"text": "Wide wooden fences. Time your jump.", "counter": "Spinosaurus tramples them."},
	{"key": "pit", "name": "Pits", "icon": "res://assets/terrain/cap_right.png",
		"text": "Gaps in the ground. Fall in and the run ends.", "counter": "Jump across, or fly over as Pteranodon."},
	{"key": "bridge", "name": "Log Bridges", "icon": "Logs_04",
		"text": "Thick logs laid over a pit. Sturdy enough for anyone.", "counter": "No transformation needed."},
	{"key": "ledge", "name": "Low Ledges", "icon": "res://assets/traps/forest_overhead.png",
		"text": "Low branches with hanging vines (forest), fossil rib arches (desert) and floating rock (volcanic). Tap SLIDE to get under them. Running into a forest vine just snags Rok (the T-rex gains), but the solid arches and rock end the run.", "counter": "Raptor, Triceratops and Pteranodon fit underneath standing."},
	{"key": "wall", "name": "Rock Walls", "icon": "Tile-3_08",
		"text": "Stacked stone. Jump, then jump again in mid-air.", "counter": "Triceratops smashes them. Raptor leaps them."},
	{"key": "gate_spino", "name": "Bramble Wall", "icon": "Grasses_15", "gate": true,
		"text": "A towering wall of thorns.", "counter": "DINO GATE: only Spinosaurus can trample through. A shield won't save anyone else."},
	{"key": "tall_fence", "name": "Tall Fences", "icon": "Fences_03",
		"text": "A tall post fence. Double-jump to clear it.", "counter": "Spinosaurus tramples them."},
	{"key": "gate_water", "name": "Flooded Crossing", "icon": "res://assets/props/Terrain-variation_03.png", "gate": true,
		"text": "Deep forest water, far too wide to jump.", "counter": "DINO GATE: swim across as Spinosaurus, or fly as Pteranodon."},
	{"key": "steam", "name": "Steam Vents", "icon": "trap:volcanic_steam:4",
		"text": "Volcanic vents that puff (warning), then blast a scalding column. A blast makes Rok stumble and the T-rex gains.", "counter": "Watch the rhythm. The cone itself is harmless."},
	{"key": "rolling_boulder", "name": "Rolling Boulders", "icon": "res://assets/props/Stones_05.png",
		"text": "Glowing volcanic boulders rolling straight at you, faster than you'd think.", "counter": "Jump or fly over, or smash as Triceratops."},
	{"key": "hunter_carnotaurus", "name": "Carnotaurus (Desert hunter)", "icon": "res://assets/portraits/carnotaurus.png", "facts": "carnotaurus",
		"text": "In the Desert the Carnotaurus takes over the hunt. It keeps your pace, but its charges are short and fierce.", "counter": "When it charges, turn Runner or use a pepper right away."},
	{"key": "hunter_allosaurus", "name": "Allosaurus (Volcanic hunter)", "icon": "res://assets/portraits/allosaurus.png", "facts": "allosaurus",
		"text": "In the Volcanic Badlands the Allosaurus hunts you. It's relentless: its charges last longest of all.", "counter": "Save peppers and Runner energy for the badlands; slide downhill to win back ground."},
	{"key": "stampede", "name": "Stampedes", "icon": "res://assets/portraits/gallimimus.png",
		"text": "Wild dinosaurs running straight at you, a different one in each zone: a head-down Pachycephalosaurus in the forest, a lightning-fast Gallimimus in the desert, a spiky Kentrosaurus in the badlands. Running into one bumps Rok and the T-rex gains, but once it's past you the T-rex stops to eat it.", "counter": "Jump over them."},
	{"key": "swooper", "name": "Swoopers", "icon": "res://assets/portraits/dimorphodon.png",
		"text": "Flying reptiles swooping at head height: a small Dimorphodon in the forest, a bobbing Pteranodon in the desert, a giant Quetzalcoatlus in the badlands. Hit one and the T-rex gains, but it snaps them up behind you.", "counter": "Slide under them. The Raptor fits underneath standing."},
	{"key": "diver", "name": "Diving Flyers", "icon": "res://assets/portraits/quetzalcoatlus.png",
		"text": "Some swoopers come in high, out of reach, then screech and dive at you, levelling out at head height just as they reach you.", "counter": "Slide as it swoops down, or ATTACK it once it's low. Jumping into the dive gets you hit."},
	{"key": "gate_lava", "name": "Lava Channel", "icon": "res://assets/terrain/cap_left.png", "gate": true,
		"text": "A river of molten rock, far too wide to jump.", "counter": "DINO GATE: fly over as Pteranodon."},
	{"key": "gate_ptera", "name": "Wide Canyon", "icon": "res://assets/terrain/cap_left.png", "gate": true,
		"text": "A chasm far wider than any jump.", "counter": "DINO GATE: fly over as Pteranodon."},
	{"key": "combo", "name": "Combos", "icon": "Mushrooms_05",
		"text": "Familiar hazards back to back. Land, then jump again.", "counter": "Plan your next form before you land."},
	{"key": "hard_combo", "name": "Tougher Combos", "icon": "Fences_03",
		"text": "Longer, harder chains of everything you know, three hazards at a time.", "counter": "Read ahead and pick each form early."},
]

const TERRAIN := [
	{"key": "islands", "name": "Floating Islands", "icon": "Terrain-variation_03", "always": true,
		"text": "Floating ground you can land on. Amber and peppers often wait on top, and some come as staircases."},
	{"key": "hill", "name": "Hills", "icon": "res://assets/terrain/slope_up.png",
		"text": "Gentle bumps. Rok runs right over them."},
	{"key": "slope", "name": "Slopes & Plateaus", "icon": "res://assets/terrain/mid_a.png",
		"text": "The ground climbs to higher levels and back down."},
	{"key": "drop", "name": "Drops", "icon": "res://assets/terrain/drop.png",
		"text": "Sudden steps down. Watch for hazards at the bottom."},
	{"key": "sky_trail", "name": "Sky Trails", "icon": "Other_07",
		"text": "High waves of amber that end in a pepper. Easiest to collect by flying."},
]

static var ITEMS := [
	{"name": "Amber", "icon": "Other_07",
		"text": "Fills your PRIMAL energy: +%d as Rok, only +%d as a dinosaur, so Rok is the one to collect it. Worth +25 points." % [int(Tuning.AMBER_ENERGY), int(Tuning.AMBER_ENERGY_DINO)]},
	{"name": "PRIMAL Energy", "icon": "Other_07", "seen": "amber",
		"hint": "Unlock your first dinosaur to use it.",
		"text": "The orange bar under your hearts: the fuel for the dinosaur forms (Rok himself uses none). A run starts with %d of %d, and you need %d to change into a dinosaur. While you're one it drains every second, each dinosaur at its own rate (the Raptor slowest, the Pteranodon fastest), and it gets tiring: after %d s as any dinosaur it drains twice as fast, after %d s three times (the bar turns red). Switching dinosaurs doesn't reset that; only turning back into Rok does. When it's empty you turn back into Rok (in mid-air you get a free jump). Refill it with amber (+%d as Rok, +%d as a dinosaur), Primal Amber fills it to the top, and a Primal Berry makes changing free for a while." % [int(Tuning.ENERGY_START), int(Tuning.ENERGY_MAX), int(Tuning.SHIFT_MIN_ENERGY), int(Tuning.DRAIN_DOUBLE_TIME), int(Tuning.DRAIN_DOUBLE_TIME * 2), int(Tuning.AMBER_ENERGY), int(Tuning.AMBER_ENERGY_DINO)]},
	{"name": "Meat", "icon": "res://assets/items/meat.png",
		"text": "Rok's Market money. Every piece you grab is banked when the run ends; spend it in the Market on power-ups and a third booster slot. Worth +25 points."},
	{"name": "Heart", "icon": "heart",
		"text": "Rok has 3 hearts (up to 6 with Heart Containers from the Market, on sale by best score), each split into quarters. Running into a hazard costs hearts by how dangerous it is: " + Codex.damage_tiers_text() + ". Armor softens every hit. The run ends when the hearts run out. Pits, water, lava, quicksand, a dino gate with the wrong dinosaur and being caught by the hunter end it at once. A rare heart in a run heals one."},
	# found later in runs: revealed once met (`seen` key), else "???" with where to look
	{"name": "Big Meat", "icon": "res://assets/items/meat.png", "art": "res://assets/items/big_meat.png", "seen": "big_meat",
		"hint": "Run past %d m in one go to find it." % int(Tuning.BIG_MEAT_FROM_M),
		"text": "Richer meat that turns up as a run goes on: worth %d meat. The further you get, the more of the meat is golden." % Tuning.BIG_MEAT_VALUE},
	{"name": "Rare Fossil", "icon": "Other_07", "art": "res://assets/items/fossil.png", "seen": "fossil",
		"hint": "Run past %d m in one go to find one." % int(Tuning.FOSSIL_FROM_M),
		"text": "An ancient ammonite, found only deep into long runs: %d meat and %d points." % [Tuning.FOSSIL_MEAT, Tuning.FOSSIL_SCORE]},
	{"name": "Milestone Chest", "icon": "res://assets/items/meat.png", "art": "res://assets/items/chest_common_closed.png", "seen": "chest",
		"hint": "Run %d m in one go to find one." % int(Tuning.CHEST_EVERY_M),
		"text": "One waits on the ground every %d m of a run (and an early one near the start): run into it. You can tell its rarity from afar: red-brown common chests hold meat, XP or materials; teal rare ones can hold a power-up, a heart or a card; purple ultra rare and golden legendary ones a Primal Frenzy, full hearts or a strong dinosaur card, and far more meat and XP. The further you get, the rarer they are." % int(Tuning.CHEST_EVERY_M)},
	{"name": "Combo & Primal Frenzy", "icon": "Other_07", "art": "res://assets/badges/clean_3.png", "seen": "combo",
		"hint": "Clear a few hazards in a row without a stumble.",
		"text": "Every hazard cleared without a stumble builds your combo: x1.5 points after 5, up to x5 after 60, and from x2 every meat counts double or more. A stumble or a long gap ends it. The streak also fills the gold meter: full, Rok goes into a Primal Frenzy and smashes through everything for a few seconds (pits still bite!)."}
]

var tab := 0
var unlocked: Array = []


## "¼ heart: small rocks, mushrooms...; ½ heart: ..." from config/damage.cfg.
const TIER_NAMES := {"small": "small rocks", "mushroom": "mushrooms", "thorns": "thorns", "steam": "steam",
		"vine": "vines", "log": "logs", "fence": "fences", "stampede": "wild dinosaurs", "swooper": "swooping flyers",
		"boulder": "boulders", "tall_fence": "tall fences", "wall": "walls", "ledge": "solid ledges",
		"rolling_boulder": "rolling boulders"}
static func damage_tiers_text() -> String:
	var parts: Array = []
	for t in Hearts.TIER_ORDER:
		var keys := Hearts.in_tier(t)
		if keys.is_empty():
			continue
		parts.append("%s for %s" % [Hearts.text(Hearts.damage(keys[0], 0.0)), ", ".join(keys.map(func(k): return TIER_NAMES.get(k, k)))])
	return "; ".join(parts)
var best_m := 0.0
var seen: Array = []
var viewed: Array = []      # entry ids already looked at in the guide
var boosters_owned: Array = ["pepper"]   # set by main: unlocked power-ups
## Expansion dinosaurs the player owns (main.dinos_owned): their pages are revealed.
static var species_owned: Array = []
## Badge progress (main.badge_stats / badge_tiers), and whether a tier was
## earned since the guide was last opened (lights the book button's badge).
static var badge_stats: Dictionary = {}
static var badge_tiers: Dictionary = {}
static var badges_new := false
var _new_ids: Array = []

var root: Control
var grid: HBoxContainer      # the shelf: one tile per entry (its full page kept inside, hidden)
var scroll: ScrollContainer
var scene: MarketScene       # the Elder's cave (MarketScene kind "elder")
var hero: AnimatedSprite2D   # the hero you play, come to listen
var bubble: PanelContainer   # the Elder's speech bubble
var tail: Polygon2D
var pscroll: ScrollContainer
var page: VBoxContainer      # the chosen entry's page, in the bubble
var shelf: VBoxContainer
var selected := -1           # index of the chosen tile on the shelf (-1 = the Elder's greeting)
var _drag_target: ScrollContainer
var _drag_dist := 0.0
var _tile_h := 150.0
var progress_label: Label
var tab_buttons: Array[Button] = []
var _fling := 0.0        # scroll momentum (px/s) after a drag
## The user's scene kit (SceneKit): the archive backdrop, Elder Numa, the
## open book (left page: name, status, portrait; right page: the entry's
## field notes), the roster frame, kit tabs and cards, arrows.
var _kit := false
var elder: TextureRect
var elder_plate: Label
var numa_bubble: PanelContainer   # Elder Numa's speech bubble over her head (her lines: NUMA_LINES)
var numa_anim: AnimatedSprite2D   # her animations (idle, explain, wave; tools/prepare_elder.py), fitted into `elder`'s box
var numa_label: Label
var numa_tail: Polygon2D
var roster: Panel
var left_page: VBoxContainer
var book_prev: TextureButton
var book_next: TextureButton
var shelf_prev: TextureButton
var shelf_next: TextureButton
var _dragging := false


func _ready() -> void:
	layer = 20
	visible = false
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	_kit = SceneKit.has()
	var kit_bg := SceneKit.backdrop("encyclopedia_archive")
	root.add_child(kit_bg if kit_bg else Market.backdrop("res://assets/bg/bg_2.png", Color(0.45, 0.6, 0.8)))   # its own scene: the Elder's cave
	scene = MarketScene.new()
	scene.kind = "elder"
	scene.sign_text = "ELDER"
	scene.style = "niches"   # the entries sit in niches carved in the stone
	root.add_child(scene)
	hero = AnimatedSprite2D.new()
	hero.name = "Hero"
	hero.centered = false
	root.add_child(hero)
	if _kit:   # the painted archive replaces the drawn cave; Elder Numa tells the stories
		scene.visible = false
		hero.visible = false
		elder = SceneKit.picture("elder_numa", 300.0, "Elder")
		root.add_child(elder)
		var nf := numa_frames()
		if nf:   # the user's animations replace the still cut-out (`elder` stays as her box)
			elder.texture = null
			numa_anim = AnimatedSprite2D.new()
			numa_anim.name = "NumaAnim"
			numa_anim.centered = false
			numa_anim.sprite_frames = nf
			numa_anim.offset = -Vector2(numa_meta().pivot[0], numa_meta().pivot[1])
			numa_anim.animation_finished.connect(func(): numa_anim.play("idle"))
			root.add_child(numa_anim)
			numa_anim.play("idle")
		elder_plate = SceneKit.badge("Elder Numa", "button_secondary", 20)
		root.add_child(elder_plate)
		numa_tail = Polygon2D.new()
		numa_tail.color = Color(1.0, 0.96, 0.86)
		root.add_child(numa_tail)
		numa_bubble = PanelContainer.new()
		numa_bubble.name = "NumaBubble"
		numa_bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var nb := StyleBoxFlat.new()
		nb.bg_color = Color(1.0, 0.96, 0.86)
		nb.border_color = Color(0.45, 0.27, 0.12)
		nb.set_border_width_all(3)
		nb.set_corner_radius_all(16)
		nb.content_margin_left = 16
		nb.content_margin_right = 16
		nb.content_margin_top = 8
		nb.content_margin_bottom = 10
		nb.shadow_color = Color(0, 0, 0, 0.25)
		nb.shadow_size = 4
		numa_bubble.add_theme_stylebox_override("panel", nb)
		numa_label = _text("", 17, Color(0.42, 0.22, 0.08))
		numa_label.name = "NumaSays"
		numa_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		numa_bubble.add_child(numa_label)
		root.add_child(numa_bubble)

	var header := HBoxContainer.new()
	header.name = "Header"
	header.set_anchors_preset(Control.PRESET_TOP_WIDE)
	header.offset_left = Tuning.UI_MARGIN
	header.offset_right = -Tuning.UI_MARGIN
	header.offset_top = 14
	header.add_theme_constant_override("separation", 12)
	root.add_child(header)
	var close := _button("‹ Back", Vector2(130, 52))
	close.pressed.connect(close_guide)
	close.name = "Back"
	header.add_child(close)
	var title := _text("FIELD GUIDE", 40)
	var kit_title := SceneKit.picture("encyclopedia_title", 62.0, "TitleBanner")
	if kit_title:
		SceneKit.style_back(close)
		title.free()
		header.add_child(kit_title)
	else:
		header.add_child(Market.title_banner("encyclopedia", title))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	var pill := PanelContainer.new()
	var pst := StyleBoxFlat.new()
	pst.bg_color = Color(0.25, 0.13, 0.06, 0.75)
	pst.set_corner_radius_all(16)
	pst.content_margin_left = 14
	pst.content_margin_right = 14
	var plate := SceneKit.box("counter_plate")
	if plate:
		plate.content_margin_left = 30
		plate.content_margin_right = 30
	pill.add_theme_stylebox_override("panel", plate if plate else pst)
	header.add_child(pill)
	progress_label = _text("", 22, Color(1, 0.95, 0.82))
	if plate:
		progress_label.add_theme_font_override("font", SpriteLib.ui_font("heading"))
	progress_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pill.add_child(progress_label)

	# the Elder's speech bubble: the chosen entry's page
	bubble = PanelContainer.new()
	bubble.name = "Bubble"
	var bs := StyleBoxFlat.new()
	bs.bg_color = Color(1.0, 0.97, 0.88, 0.97)
	bs.set_corner_radius_all(22)
	bs.set_border_width_all(4)
	bs.border_color = Color(0.45, 0.25, 0.1)
	bs.set_content_margin_all(14)
	bs.shadow_color = Color(0, 0, 0, 0.25)
	bs.shadow_size = 8
	bubble.add_theme_stylebox_override("panel", bs)
	root.add_child(bubble)
	tail = Polygon2D.new()
	tail.color = Color(1.0, 0.97, 0.88)
	root.add_child(tail)
	pscroll = ScrollContainer.new()
	pscroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	if _kit:   # the open book: two pages (sized in _layout to keep its shape)
		var book := StyleBoxTexture.new()
		book.texture = SceneKit.tex("open_book")
		bubble.add_theme_stylebox_override("panel", book)
		var pages := HBoxContainer.new()
		pages.name = "Pages"
		bubble.add_child(pages)
		left_page = VBoxContainer.new()
		left_page.name = "LeftPage"
		left_page.alignment = BoxContainer.ALIGNMENT_CENTER
		left_page.add_theme_constant_override("separation", 6)
		pages.add_child(left_page)
		pscroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		pages.add_child(pscroll)
	else:
		bubble.add_child(pscroll)
	page = VBoxContainer.new()
	page.name = "Page"
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.add_theme_constant_override("separation", 6)
	pscroll.add_child(page)

	# the shelf: the tabs, then the entries in niches, in a row
	shelf = VBoxContainer.new()
	shelf.name = "Shelf"
	shelf.add_theme_constant_override("separation", 8)
	root.add_child(shelf)
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 8)
	shelf.add_child(tabs)
	for i in 7:
		var b := _button(["Dinosaurs", "Hazards & Terrain", "Items", "Power-Ups", "Zones", "Badges", "Cards"][i], Vector2(0, 46))
		b.toggle_mode = true
		b.pressed.connect(func(): _show_tab(i))
		tabs.add_child(b)
		tab_buttons.append(b)
	scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	shelf.add_child(scroll)
	grid = HBoxContainer.new()
	grid.add_theme_constant_override("separation", 12)
	scroll.add_child(grid)
	if _kit:
		tail.visible = false
		roster = Panel.new()   # the wooden roster frame behind the tabs and cards
		roster.name = "Roster"
		roster.add_theme_stylebox_override("panel", SceneKit.box("roster_panel"))
		roster.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(roster)
		root.move_child(roster, shelf.get_index())
		for b in tab_buttons:
			SceneKit.style_button(b, "tab_inactive", "tab_active", 20)
		book_prev = _arrow("page_previous", func(): select(maxi(selected - 1, 0)))
		book_next = _arrow("page_next", func(): select(mini(selected + 1, grid.get_child_count() - 1)))
		shelf_prev = _arrow("page_previous", func(): scroll.scroll_horizontal -= int(_tile_h * 2.0))
		shelf_next = _arrow("page_next", func(): scroll.scroll_horizontal += int(_tile_h * 2.0))
	root.resized.connect(_layout)


## A kit arrow button (the book's pages, the roster's scroll).
func _arrow(piece: String, act: Callable) -> TextureButton:
	var b := TextureButton.new()
	b.texture_normal = SceneKit.tex(piece)
	b.ignore_texture_size = true
	b.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	b.custom_minimum_size = Vector2(40, 62)
	b.size = b.custom_minimum_size
	b.pressed.connect(act)
	root.add_child(b)
	return b


## Place everything around the Elder's cave (it follows the screen size).
func _layout() -> void:
	var w := root.size.x
	var h := root.size.y
	if _kit:
		_layout_kit(w, h)
		return
	var gy: float = scene.ground_y
	var hs: Vector2 = scene.hero_spot()
	hero.position = hs
	var left := hs.x + 110.0
	var right: float = scene.cave_x() - 160.0
	bubble.position = Vector2(left, 78.0)
	bubble.size = Vector2(maxf(right - left, 440.0), gy - 78.0 - 24.0)
	var by := bubble.position.y + bubble.size.y * 0.5
	var bx := bubble.position.x + bubble.size.x - 2.0
	var elder := Vector2(scene.cave_x() + 60.0, gy - 150.0)
	tail.polygon = PackedVector2Array([Vector2(bx, by - 18.0), Vector2(bx, by + 18.0), elder])
	shelf.position = Vector2(Tuning.UI_MARGIN, gy + 28.0)
	shelf.size = Vector2(w - Tuning.UI_MARGIN * 2.0, h - gy - 36.0)
	_tile_h = maxf(shelf.size.y - 46.0 - 8.0 - 14.0, 120.0)
	scene.band = Rect2(0.0, gy + 26.0, w, h - gy - 26.0)
	scene.tiles_top = shelf.position.y + 54.0
	scene.shelf_y = scene.tiles_top + _tile_h
	for t in grid.get_children():
		(t as Control).custom_minimum_size.y = _tile_h


## The kit's layout (docs/layout_reference.json of the kit: a 1920x1080
## design scaled by the screen height; the book and roster anchored to the
## right and bottom so wider screens just get more room in the middle).
func _layout_kit(w: float, h: float) -> void:
	var k := h / 1080.0
	# the book keeps its shape; right-aligned
	var bw := minf(1190.0 * k, w - 520.0 * k)
	var bh := bw * 720.0 / 1536.0
	bubble.position = Vector2(w - 40.0 * k - bw, 125.0 * k + (565.0 * k - bh) * 0.5)
	bubble.size = Vector2(bw, bh)
	var book := bubble.get_theme_stylebox("panel") as StyleBoxTexture
	book.content_margin_left = bw * 0.08
	book.content_margin_right = bw * 0.07
	book.content_margin_top = bh * 0.13
	book.content_margin_bottom = bh * 0.16
	(bubble.get_node("Pages") as HBoxContainer).add_theme_constant_override("separation", int(bw * 0.07))
	left_page.custom_minimum_size = Vector2(bw * 0.38, 0)
	pscroll.custom_minimum_size = Vector2(bw * 0.40, 0)
	book_prev.position = Vector2(bubble.position.x - 12.0 * k, bubble.position.y + bh * 0.5 - 31.0)
	book_next.position = Vector2(bubble.position.x + bw - 30.0, bubble.position.y + bh * 0.5 - 31.0)
	# Elder Numa in the space on the left, her plate at her feet
	var ex := 60.0 * k
	var ew := maxf(bubble.position.x - ex - 10.0, 200.0)
	elder.position = Vector2(ex, 150.0 * k)
	elder.size = Vector2(ew, 520.0 * k)
	_place_numa()
	elder_plate.position = Vector2(ex + ew * 0.5 - 90.0, 150.0 * k + 520.0 * k - 30.0)
	elder_plate.custom_minimum_size = Vector2(180, 0)
	elder_plate.size = Vector2(180, 0)
	# the roster along the bottom
	roster.position = Vector2(20.0 * k, 700.0 * k)
	roster.size = Vector2(w - 40.0 * k, h - 700.0 * k - 12.0 * k)
	shelf.position = roster.position + Vector2(64.0, 14.0)
	shelf.size = roster.size - Vector2(128.0, 26.0)
	_tile_h = maxf(shelf.size.y - 46.0 - 8.0 - 10.0, 110.0)
	var ty := shelf.position.y + 54.0 + _tile_h * 0.5 - 31.0
	shelf_prev.position = Vector2(roster.position.x + 14.0, ty)
	shelf_next.position = Vector2(roster.position.x + roster.size.x - 54.0, ty)
	for t in grid.get_children():
		(t as Control).custom_minimum_size = Vector2(_tile_h * 0.86, _tile_h)


## Drag to scroll on touch screens (and with a mouse drag on desktop, where
## clicks arrive as touches): sideways along the shelf, up and down in the
## Elder's bubble. Handled here because the tiles would otherwise swallow it.
func _input(event: InputEvent) -> void:
	if not visible:
		return
	var drag := event as InputEventScreenDrag
	if drag:
		_dragging = true
		_drag_dist += drag.relative.length()
		if _drag_target == null:
			_drag_target = pscroll if pscroll.get_global_rect().has_point(drag.position) else scroll
		if _drag_target == pscroll:
			pscroll.scroll_vertical -= int(drag.relative.y)
			_fling = -drag.velocity.y
		else:
			scroll.scroll_horizontal -= int(drag.relative.x)
			_fling = -drag.velocity.x
		get_viewport().set_input_as_handled()
		return
	var t := event as InputEventScreenTouch
	if t:
		if t.pressed:
			_fling = 0.0
			_drag_dist = 0.0
			_drag_target = null
		else:
			_dragging = false


func _process(delta: float) -> void:
	if not visible or _dragging or absf(_fling) < 5.0:
		return
	if _drag_target == pscroll:
		pscroll.scroll_vertical += int(_fling * delta)
	else:
		scroll.scroll_horizontal += int(_fling * delta)
	_fling = lerpf(_fling, 0.0, minf(delta * 5.0, 1.0))


func _text(t: String, size: int, color := INK) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


func _button(t: String, min_size: Vector2) -> Button:
	var b := Button.new()
	b.text = t
	b.custom_minimum_size = min_size
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 22)
	for state in ["normal", "hover", "pressed", "hover_pressed"]:
		var sb := StyleBoxFlat.new()
		var on: bool = state == "pressed" or state == "hover_pressed"
		sb.bg_color = Color(0.55, 0.3, 0.12) if on else Color(0.85, 0.7, 0.45)
		sb.set_corner_radius_all(12)
		sb.set_border_width_all(3)
		sb.border_color = Color(0.45, 0.25, 0.1)
		sb.content_margin_left = 16
		sb.content_margin_right = 16
		b.add_theme_stylebox_override(state, sb)
	b.add_theme_color_override("font_color", INK)
	b.add_theme_color_override("font_hover_color", INK)
	b.add_theme_color_override("font_pressed_color", Color(1, 0.95, 0.85))
	b.add_theme_color_override("font_hover_pressed_color", Color(1, 0.95, 0.85))
	return b


# ------------------------------------------------------------ data

## Every entry id the player currently knows.
static func known_ids(p_unlocked: Array, p_best_m: float, p_seen: Array) -> Array:
	var ids := []
	for f in Forms.ORDER:
		if p_unlocked.has(f):
			ids.append("dino_%d" % f)
	for id in Dinos.ids():
		if species_owned.has(id):
			ids.append("dino_" + id)
	for h in HAZARDS + TERRAIN:
		if h.get("always", false) or Progression.taught(h.key, p_best_m, p_seen):
			ids.append(h.key)
	for i in Zones.ZONES.size():
		if zone_known(i, p_best_m, p_seen):
			ids.append("zone_" + Zones.ZONES[i].id)
	return ids


static func zone_known(i: int, p_best_m: float, p_seen: Array) -> bool:
	return i == 0 or p_seen.has("zone_" + Zones.ZONES[i].id) or p_best_m >= i * Zones.ZONE_LEN_M


static func total_entries() -> int:
	return Forms.ORDER.size() + Dinos.ids().size() + HAZARDS.size() + TERRAIN.size() + Zones.ZONES.size()


## True if something was discovered since the guide was last opened.
static func has_new(p_unlocked: Array, p_best_m: float, p_seen: Array, p_viewed: Array) -> bool:
	if badges_new:
		return true
	for id in known_ids(p_unlocked, p_best_m, p_seen):
		if not p_viewed.has(id):
			return true
	return false


# ------------------------------------------------------------ open / close

func open_guide(p_unlocked: Array, p_best_m: float, p_seen: Array, p_viewed: Array) -> void:
	unlocked = p_unlocked
	best_m = p_best_m
	seen = p_seen
	viewed = p_viewed
	var known := known_ids(unlocked, best_m, seen)
	_new_ids = known.filter(func(id): return not viewed.has(id))
	progress_label.text = "Discovered %d / %d    " % [known.size(), total_entries()]
	visible = true
	Market.enter(root)
	hero.sprite_frames = SpriteLib.character(Forms.ROK)
	if not hero.has_node("Gear"):
		var gl := GearLayer.new()
		gl.name = "Gear"
		hero.add_child(gl)
	(hero.get_node("Gear") as GearLayer).hero = String(Forms.get_data(Forms.ROK).id)
	hero.offset = -Vector2(Forms.get_data(Forms.ROK).pivot)
	hero.scale = Vector2.ONE * 1.25
	hero.play("idle")
	_layout()
	_show_tab(tab)
	numa_say("greet")


# ------------------------------------------------------------ Elder Numa's lines

## What Elder Numa says (the user's request; her animations come later). A
## pool per situation, picked at random without repeating the last line;
## "%s" is filled with the entry's name. She is the cave's old storyteller:
## warm, a little mischievous, fond of proverbs and of the old days, and she
## remembers every creature and every runner who came before.
## Tab pools are "tab_<index>" in tab order (Dinosaurs, Hazards & Terrain,
## Items, Power-Ups, Zones, Badges, Cards).
const NUMA_LINES := {
	"greet": [
		"Come, sit by the fire, little runner. What would you know?",
		"Ah, the runner returns! My old bones knew you would.",
		"Every creature you meet leaves a story. I keep them all here.",
		"The fire is warm and the stories are long. Choose one.",
		"You smell of dust and dinosaur. A good run, then?",
		"Welcome back. The cave walls have been waiting for news.",
		"My grandmother kept this book, and hers before her. Now it is yours too.",
		"Sit, sit. Even the fastest runner must rest the legs.",
	],
	"tab_0": [
		"The great beasts. Learn them well, and they will carry you far.",
		"Each dinosaur has a gift. Find the one the path needs.",
		"I rode a Triceratops once. Well... it rode me, mostly.",
		"Fast, strong, tough or flying. The trail asks for all four.",
		"Be kind to the beasts you borrow. They remember.",
	],
	"tab_1": [
		"Rocks, logs, pits and worse. The trail is a cruel teacher.",
		"Every hazard has an answer. Jump, slide, smash or fly.",
		"Quicksand swallowed my sandal when I was young. Never found it.",
		"Learn the ground, runner, and the ground will not trip you.",
		"What you have passed, I have written down. The rest... run further.",
	],
	"tab_2": [
		"Amber for your spirit, meat for the merchant. Gather both.",
		"Ugo will take every bit of meat you bring. Every bit.",
		"Little things on the trail add up to big things in the cave.",
		"A fossil is a story the earth kept for us. Treasure it.",
		"Pick up what shines. Leave what bites.",
	],
	"tab_3": [
		"Powers from the old earth. Use them at the right moment.",
		"A pepper, a crystal, a berry... small wonders for hard runs.",
		"Save your power-ups for when the hunter is closest.",
		"The Time Crystal slows the world. I wish it slowed my aching knees.",
		"A wise runner carries a power-up. A wiser one uses it.",
	],
	"tab_4": [
		"The forest, the desert, the burning badlands. Each has its own song.",
		"The land changes as you run. So must you.",
		"In the desert the sun bleaches everything. Even bad memories.",
		"The volcanic lands could cook meat. Do not test that on yourself.",
		"Run far enough and the land comes round again, wilder each time.",
	],
	"tab_5": [
		"Badges for the brave. Bronze, Silver, Gold. Each one earned.",
		"Every badge is a promise you kept to yourself.",
		"Gold is heavy, runner. Earn it slowly.",
		"I had a badge once. A beetle ate it. Long story.",
		"Your deeds are scratched on these walls. Add more.",
	],
	"tab_6": [
		"Cards of the beasts you have faced. They carry a little of their strength.",
		"Bonk a wild one and it may leave its card behind. Gently, now.",
		"A card on a weapon is a dinosaur at your side.",
		"Collect them all, and the whole herd runs with you.",
		"Each card shows the land its beast calls home.",
	],
	"new": [
		"Something new! Let me tell you of the %s.",
		"Ah, you met the %s. I have been waiting to tell you about it.",
		"The %s! A new story for the book. Listen closely.",
		"Fresh from the trail: the %s. Sit, sit.",
		"The %s left its mark on you, I see. Here is what I know.",
	],
	"known": [
		"Ah, the %s. Listen...",
		"The %s. I remember the first time I saw one.",
		"Let me tell you again of the %s.",
		"The %s. A good story, this one.",
		"Hmm, the %s. The old songs speak of it.",
		"The %s. Pay attention, it may save your hide.",
	],
	"locked": [
		"That one you have not seen yet. Run further, and you will.",
		"Patience. That page stays empty until the trail shows you.",
		"Not yet, little runner. Some stories must be earned.",
		"I know that one... but you must meet it first.",
		"Keep running. The trail will fill this page.",
	],
}
var _numa_said := {}   # pool -> its last line (no repeats)


const NUMA_DIR := "res://assets/scenes/elder/"
static var _numa_meta := {}
static var _numa_frames: SpriteFrames


## Her clips' data (elder.json): frame, pivot, visible box, per clip times and loop.
static func numa_meta() -> Dictionary:
	if _numa_meta.is_empty() and FileAccess.file_exists(NUMA_DIR + "elder.json"):
		_numa_meta = JSON.parse_string(FileAccess.get_file_as_string(NUMA_DIR + "elder.json"))
	return _numa_meta


## Her idle (loop), explain and wave (once) clips, or null without the art.
static func numa_frames() -> SpriteFrames:
	if _numa_frames:
		return _numa_frames
	var m := numa_meta()
	if m.is_empty():
		return null
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	for clip in m.clips:
		SpriteLib._sheet_frames(sf, clip, SpriteLib.tex(NUMA_DIR + clip + ".png"), Vector2(m.frame[0], m.frame[1]),
				m.clips[clip].times, bool(m.clips[clip].loop))
	_numa_frames = sf
	return sf


## Numa acts out what she says: a wave when greeting, an explaining nod
## otherwise; then back to her idle.
func numa_act(key: String) -> void:
	if numa_anim == null:
		return
	numa_anim.play("wave" if key == "greet" else "explain")


## A line from one of Numa's pools (not the same as `last`).
static func numa_pick(key: String, last := "") -> String:
	var pool: Array = NUMA_LINES.get(key, [""])
	var pick: String = pool[randi() % pool.size()]
	while pool.size() > 1 and pick == last:
		pick = pool[randi() % pool.size()]
	return pick


## Numa says a line from a pool in her bubble, with a soft murmur (Ugo's
## mumble sounds, higher and gentler: Tuning.NUMA_PITCH / NUMA_DB).
func numa_say(key: String, arg := "") -> String:
	if numa_label == null:
		return ""
	var line := numa_pick(key, String(_numa_said.get(key, "")))
	_numa_said[key] = line
	var text := (line % arg) if line.contains("%s") else line
	numa_label.text = text
	numa_act(key)
	_place_numa()
	var g = get_parent()
	if visible and g and g.get("audio"):
		var n := clampi(text.length() / 18 + randi_range(0, 1), 1, 6)
		g.audio.play("mumble_%d" % n, 0.05, Tuning.NUMA_PITCH, Tuning.NUMA_DB)
	return text


## Her bubble sits above her head, between the title and her; she stands a
## little shorter when it's tall (her feet stay at her plate), and its tail
## points down at her.
## Fit her animation in her box: the drawing's visible height fills the box,
## feet on its bottom, centred.
func _place_numa_anim() -> void:
	if numa_anim == null or elder == null:
		return
	var m := numa_meta()
	var vis: Array = m.visible
	var vw := float(vis[2]) - float(vis[0])
	var vh := float(vis[3]) - float(vis[1])
	var k := minf(elder.size.y / vh, elder.size.x / vw)
	var pv := Vector2(m.pivot[0], m.pivot[1])
	var cx := (float(vis[0]) + float(vis[2])) * 0.5 - pv.x   # the drawing's centre, relative to the feet
	numa_anim.scale = Vector2(k, k)
	numa_anim.position = Vector2(elder.position.x + elder.size.x * 0.5 - cx * k, elder.position.y + elder.size.y - (pv.y - float(vis[3])) * k)


func _place_numa() -> void:
	if numa_bubble == null or elder == null:
		return
	var k := root.size.y / 1080.0
	var ex := 60.0 * k
	var ew := elder.size.x
	if ew < 120.0:
		return   # not laid out yet
	numa_label.custom_minimum_size = Vector2(ew - 32.0, 0)   # wrap at the bubble's width before measuring
	numa_bubble.position = Vector2(ex, 84.0)
	numa_bubble.custom_minimum_size = Vector2(ew, 0)
	numa_bubble.size = Vector2(ew, 0)
	var font := numa_label.get_theme_font("font")
	var fs := numa_label.get_theme_font_size("font_size")
	var text_h := font.get_multiline_string_size(numa_label.text, HORIZONTAL_ALIGNMENT_LEFT, ew - 32.0, fs).y
	numa_bubble.size = Vector2(ew, text_h + 22.0)
	var bottom := numa_bubble.position.y + numa_bubble.size.y
	var top := maxf(150.0 * k, bottom + 6.0)
	elder.position.y = top
	elder.size.y = 670.0 * k - top
	_place_numa_anim()
	var cx := ex + ew * 0.5
	numa_tail.polygon = PackedVector2Array([Vector2(cx - 16.0, bottom - 3.0), Vector2(cx + 16.0, bottom - 3.0), Vector2(cx + 4.0, top + 12.0)])
	numa_bubble.visible = numa_label.text != ""
	numa_tail.visible = numa_bubble.visible


func close_guide() -> void:
	visible = false
	closed.emit()


## Ids to remember as viewed once the guide has been opened.
func viewed_after_open() -> Array:
	badges_new = false
	var out := viewed.duplicate()
	for id in known_ids(unlocked, best_m, seen):
		if not out.has(id):
			out.append(id)
	return out


func _show_tab(i: int) -> void:
	tab = i
	for k in tab_buttons.size():
		tab_buttons[k].button_pressed = k == i
	for c in grid.get_children():
		grid.remove_child(c)   # out of the tree now, so new cards keep their names
		c.queue_free()
	scroll.scroll_horizontal = 0
	selected = -1
	match i:
		0:
			for f in Forms.ORDER:
				_dino_card(f)
			for id in Dinos.ids():
				_species_card(id)
		1:
			for h in HAZARDS:
				_hazard_card(h, true)
			for h in TERRAIN:
				_hazard_card(h, false)
		2:
			for it in ITEMS:
				var icon: Texture2D = Hearts.icon(Hearts.QUARTERS) if it.icon == "heart" else _tex(it.icon)
				if it.has("art") and ResourceLoader.exists(it.art):
					icon = load(it.art)
				if it.has("seen") and not seen.has(it.seen):
					_card(icon, "???", it.hint, "", true, false)
					continue
				var itext: String = it.text
				if it.name == "Milestone Chest":
					itext += "\n\n" + Drops.for_chests()
				_card(icon, it.name, itext, "", false, false)
			_gear_pages()
		3:
			_powerup_cards()
		4:
			for zi in Zones.ZONES.size():
				var z: Dictionary = Zones.ZONES[zi]
				var start := int(zi * Zones.ZONE_LEN_M)
				if not zone_known(zi, best_m, seen):
					_card(zone_icon(z.id), "???", "Reach %d m to discover." % start, "", true, false)
					continue
				_card(zone_icon(z.id), z.name, z.blurb,
						"From %d m, then every %d m after" % [start, int(Zones.ZONE_LEN_M * Zones.ZONES.size())],
						false, _new_ids.has("zone_" + z.id), Color(0.55, 0.35, 0.15))
			_card(SpriteLib.tex("res://assets/ui/daynight_half.png"), "Day & Night",
					"Night falls every %d m and lasts a while. At night the world dims, stars and the moon come out, and fireflies glow in the forest." % int(Zones.DAY_CYCLE_M),
					"Hazards work the same, but they're harder to spot!", false, false, Color(0.3, 0.35, 0.6))
		5:
			for id in Badges.DATA:
				_badge_card(id)
		6:
			_cards_tab()
	select(0)
	if visible:
		numa_say("tab_%d" % i)   # her words for the tab (after the first entry's line)


## The Items tab's gear pages (the user's request: explain the weapon, armor
## and card slot systems): Weapons, Armor and Card Slots, written at view
## time from Gear.ITEMS and the config (durability, rarity, repair, card
## slots, selling) so they stay in sync. Locked until the Crafting Bench opens.
func _gear_pages() -> void:
	var open := best_m >= Crafting.bench_m()
	var lock_hint := "Reach %d m in one run to open the Crafting Bench." % Crafting.bench_m()
	var rn := Crafting.rarity_names()
	var rar := "Every craft rolls a rarity, %s to %s: a %s has its bonuses x%s and lasts x%s as long." % [
			rn[0], rn[-1], rn[-1], Dinos.fmt(Crafting.bonus_mult(rn.size() - 1)), Dinos.fmt(Crafting.durability_mult(rn.size() - 1))]
	var rmeat: Array = Crafting.num("repair", "meat")
	var rep := "Repair it at the Dinosaur Camp or Kora's Items screen for meat: a full repair costs %d (Common) to %d (Legendary)." % [int(rmeat[0]), int(rmeat[-1])]
	var sell := "Sell spares in the Market (Sell tab) for %d%% of their value." % int(round(float(Economy.num("sell", "share")) * 100.0))
	# --- weapons
	var wl: Array = []
	for id in Gear.ITEMS:
		var it: Dictionary = Gear.ITEMS[id]
		if it.slot != "weapon":
			continue
		var cs := Gear.card_slots(id)
		wl.append("• %s: %s, reach %d, %d runs, %s%s (from %d m)" % [it.name, Gear.bonus_text(id), int(it.reach), Gear.max_durability(id),
				Gear.style(id).capitalize() if Gear.style(id) != "" else "attack", (", %d card slot%s" % [cs, "" if cs == 1 else "s"]) if cs > 0 else ", no card slot", Crafting.learn_m(id)])
	var wt := "Crafted at Kora's Crafting Bench from materials, and equipped on a hero at the Dinosaur Camp (one weapon each). A weapon adds its bonuses, sets how far ATTACK reaches, and gives its attack style. " \
			+ "Every run it's equipped in uses 1; at 0 it's Worn Out and gives half its bonus until repaired. %s %s %s\n\n%s" % [rep, rar, sell, "\n".join(wl)]
	_card(Gear.icon("club"), "Weapons" if open else "???", wt if open else lock_hint, "", not open, false, Color(0.55, 0.32, 0.12))
	# --- armor
	var al: Array = []
	for id in Gear.ITEMS:
		var it: Dictionary = Gear.ITEMS[id]
		if it.slot == "armor":
			al.append("• %s: %s, %d runs (from %d m)" % [it.name, Gear.bonus_text(id), Gear.max_durability(id), Crafting.learn_m(id)])
	var at := "Crafted at the bench and worn by a hero (one armor each). Armor softens every hit: at Armor 10 a hit costs half as much (a whole heart becomes half). " \
			+ "Every run it's worn uses 1; at 0 it's Worn Out and protects at half strength until repaired. %s %s %s\n\n%s" % [rep, rar, sell, "\n".join(al)]
	_card(Gear.icon("shell_plate"), "Armor" if open else "???", at if open else lock_hint, "", not open, false, Color(0.4, 0.35, 0.3))
	# --- card slots
	var with_slot: Array = Gear.ITEMS.keys().filter(func(id): return Gear.ITEMS[id].slot == "weapon" and Gear.card_slots(id) > 0).map(func(id): return Gear.ITEMS[id].name)
	var tiers: Array = []
	for t in Gear.CARD_BONUS.size():
		tiers.append("%s +%s" % ["Original" if t == 0 else Dinos.TIER_NAMES[t - 1], Dinos.fmt(float(Gear.CARD_BONUS[t]))])
	var ct := "Dinosaur cards aren't equipped: they're slotted into a weapon's card slot at the Dinosaur Camp (Change beside Card slot). A slot can stay empty. " \
			+ "A slotted card adds its dinosaur's best attribute (a Runner's Speed, a Smasher's Power, a Tank's Armor, a Flyer's Jump) on top of the weapon's bonuses, while that weapon is equipped (at half while it's Worn Out). " \
			+ "The card stays in the weapon when you swap weapons; take it out, or salvage or sell the weapon, and it goes back to your pile. A card in a weapon can't go in another, so a second copy is useful.\n\n" \
			+ "Bonus by the dinosaur's tier: %s.\nWeapons with a card slot: %s.\nCards drop from wild dinosaurs you bonk with ATTACK, and come in chests (see the Cards tab)." % [", ".join(tiers), ", ".join(with_slot) if not with_slot.is_empty() else "none yet"]
	_card(CardView.icon("raptor"), "Card Slots" if open else "???", ct if open else lock_hint, "", not open, false, Color(0.55, 0.32, 0.12))


## Every dinosaur card (the four originals, then the expansion species): a
## found one shows its card (the user's art, or its portrait on a card) with
## what it gives the weapon it's used on, how many you have and where they
## come from; one not found yet is "???" with where to look.
func _cards_tab() -> void:
	var ids: Array = []
	for f in Forms.ORDER:
		if f != Forms.ROK:
			ids.append(String(Forms.DATA[f].id))
	ids.append_array(Dinos.ids())
	for id in ids:
		var have := int(Gear.cards.get(id, 0))
		var found := have > 0 or seen.has("card_" + id)
		var bonus := Gear.bonus_text(Gear.CARD_PREFIX + id)
		var where := ("Dropped by a wild %s in %s: bonk one with ATTACK (%s the first time, %s after). Also in chests." % [Herd.name_of(id), Drops.wild_zones(id), Drops.pct(Drops.card_chance(id, true)), Drops.pct(Drops.card_chance(id, false))]) \
				if Critters.DATA.has(id) else "Found in rare, ultra rare and legendary chests%s." % ("" if Dinos.tier(id) <= 2 else " (ultra rare and legendary only)")
		if found:
			_card(CardView.icon(id), Herd.name_of(id) + " Card", "Use it on a weapon at the Dinosaur Camp: it gives the weapon %s." % bonus,
					"You have x%d  ·  %s" % [have, where], false, false, Color(0.55, 0.32, 0.12))
		else:
			_card(CardView.icon(id), "???", "Not found yet. " + where, "", true, false)
		var tile: Node = grid.get_child(grid.get_child_count() - 1)
		tile.name = "Card_" + id
		tile.set_meta("card", id)
		tile.set_meta("card_text", bonus)


## Pick an entry off the shelf: the Elder tells you about it (its full page
## in the bubble). -1 shows his greeting.
func select(i: int) -> void:
	if _drag_dist > 12.0:
		return   # that was a scroll, not a tap
	var tiles := grid.get_children().filter(func(c): return not c.is_queued_for_deletion())
	selected = i if i >= 0 and i < tiles.size() else -1
	for k in tiles.size():
		var lk: bool = tiles[k].get_meta("locked", false)
		for st in ["normal", "hover", "pressed", "hover_pressed"]:
			(tiles[k] as Button).add_theme_stylebox_override(st, _tile_box(k == selected, lk))
		var chk: Node = tiles[k].get_node_or_null("Check")
		if chk:
			chk.visible = k == selected
	for c in page.get_children():
		page.remove_child(c)
		c.queue_free()
	pscroll.scroll_vertical = 0
	if selected < 0:
		var g := _text("Sit by the fire, little runner. What would you know?", 22)
		g.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		page.add_child(g)
		return
	var tile: Node = tiles[selected]
	var locked: bool = tile.get_meta("locked", false)
	var nm: String = tile.get_meta("title", "")
	numa_say("locked" if locked else ("new" if tile.get_meta("new", false) else "known"), nm)
	var line := _text("“That one you have not seen yet. Run further, and you will.”" if locked else "“Ah, %s. Listen...”" % nm, 18, Color(0.55, 0.3, 0.1))
	line.name = "Says"
	line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	page.add_child(line)
	var full: Control = tile.get_node("Card").duplicate()
	full.visible = true
	_compact(full)
	if _kit:
		_fill_book(tile, full, locked, nm)
	page.add_child(full)


## The book: the left page shows the entry (name, status, a big picture);
## the right page its field notes (the entry's page without its own picture,
## name and frame).
func _fill_book(tile: Node, full: Control, locked: bool, nm: String) -> void:
	for c in left_page.get_children():
		left_page.remove_child(c)
		c.queue_free()
	var name_l := _text(nm, 34)
	name_l.add_theme_font_override("font", SpriteLib.ui_font("heading"))
	name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left_page.add_child(name_l)
	if tile.has_meta("card"):   # a dinosaur card: drawn as the card, its bonus on the parchment
		var cv := CardView.new(String(tile.get_meta("card")), String(tile.get_meta("card_text", "")), locked)
		cv.name = "CardView"
		cv.custom_minimum_size = Vector2(0, bubble.size.y * 0.58)
		cv.size_flags_vertical = Control.SIZE_EXPAND_FILL
		left_page.add_child(cv)
	else:
		var pic := TextureRect.new()
		pic.texture = tile.get_meta("tex", null)
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		pic.custom_minimum_size = Vector2(0, bubble.size.y * 0.42)
		pic.size_flags_vertical = Control.SIZE_EXPAND_FILL
		if locked:
			pic.modulate = Color(0.12, 0.07, 0.03, 0.85)
		left_page.add_child(pic)
	var st := SceneKit.badge("✓ DISCOVERED" if not locked else "NOT YET FOUND", "status_pill_blank" if not locked else "button_secondary", 16)
	if st:
		st.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		left_page.add_child(st)
	# the right page: "Field Notes", then the page minus its picture, name and frame
	var says := page.get_node_or_null("Says") as Label
	if says:
		says.text = "Field Notes" if not locked else "Not yet discovered"
		says.add_theme_font_override("font", SpriteLib.ui_font("heading"))
		says.add_theme_font_size_override("font_size", 26)
		says.add_theme_color_override("font_color", INK)
		says.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if full is PanelContainer:
		full.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
		var hb := full.get_child(0)
		if hb is HBoxContainer and hb.get_child_count() > 1:
			if hb.get_child(0) is TextureRect:
				hb.get_child(0).visible = false
			var vb := hb.get_child(1)
			if vb is VBoxContainer and vb.get_child_count() > 0 and vb.get_child(0) is HBoxContainer:
				vb.get_child(0).visible = false   # the name row (it's on the left page)
	_wrap_to_page(full)


## Keep the field notes on the right page: every label wraps and none asks
## for more width than the page (stat notes used to run off the book).
func _wrap_to_page(n: Node) -> void:
	for c in n.get_children():
		if c is Label:
			var l := c as Label
			var in_row := l.get_parent() is HBoxContainer
			if in_row and l.get_index() < l.get_parent().get_child_count() - 1:
				l.autowrap_mode = TextServer.AUTOWRAP_OFF   # a row's leading labels ("Speed") keep their word
			else:
				l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				l.custom_minimum_size.x = 0.0
				if in_row:
					l.size_flags_horizontal = Control.SIZE_EXPAND_FILL   # a row's last label takes the rest and wraps
		_wrap_to_page(c)


## Fit a page in the bubble: narrower text and a smaller picture than the old
## two-column cards used.
func _compact(n: Node) -> void:
	for c in n.get_children():
		if c is Label and (c as Label).custom_minimum_size.x > 220.0:
			(c as Label).custom_minimum_size.x = 220.0
		elif c is TextureRect and (c as TextureRect).custom_minimum_size.x >= 84.0:
			(c as TextureRect).custom_minimum_size = Vector2(80, 80)
			(c as TextureRect).size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		_compact(c)


## A shelf tile in its niche; the chosen one glows (the kit's cards: normal,
## selected, locked).
func _tile_box(chosen: bool, locked := false) -> StyleBox:
	if _kit:
		return SceneKit.card_box(chosen, locked)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.17, 0.13, 0.11)
	sb.set_corner_radius_all(14)
	sb.set_border_width_all(5 if chosen else 4)
	sb.border_color = Color(1.0, 0.75, 0.3) if chosen else Color(0.32, 0.29, 0.27)
	return sb


## Put an entry on the shelf: a tile with its picture and name (and NEW),
## its full page kept inside it, hidden ("Card"), for the bubble.
func _add_entry(card: Control, tex: Texture2D, title: String, locked: bool, is_new: bool, tile_name := "") -> void:
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(150, _tile_h)
	if tile_name != "":
		b.name = tile_name
	b.set_meta("title", title)
	b.set_meta("locked", locked)
	b.set_meta("new", is_new)
	b.set_meta("tex", tex)
	for st in ["normal", "hover", "pressed", "hover_pressed"]:
		b.add_theme_stylebox_override(st, _tile_box(false, locked))
	var idx := grid.get_child_count()
	b.pressed.connect(func(): select(idx))
	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	vb.offset_left = 6
	vb.offset_right = -6
	vb.offset_top = 6
	vb.offset_bottom = -6
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 2)
	b.add_child(vb)
	var ic := TextureRect.new()
	ic.texture = tex
	ic.custom_minimum_size = Vector2(0, 70)
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if locked:
		ic.modulate = Color(0.12, 0.07, 0.03, 0.85)
	vb.add_child(ic)
	var l := _text(title, 16, Color(1, 0.96, 0.85) if not locked else Color(0.75, 0.7, 0.62))
	l.add_theme_color_override("font_outline_color", Color(0.15, 0.08, 0.03))
	l.add_theme_constant_override("outline_size", 6)
	if _kit:   # names in the kit's font: light with a dark outline, on parchment and on the dark locked card
		l.add_theme_font_override("font", SpriteLib.ui_font("heading"))
		l.add_theme_font_size_override("font_size", 17)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(l)
	var kit_new := SceneKit.badge("NEW", "badge_new_blank", 13) if is_new and _kit else null
	if kit_new:   # the kit's orange badge, on the card's top right
		kit_new.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		kit_new.position = Vector2(-62, -6)
		kit_new.size = Vector2(60, 26)
		b.add_child(kit_new)
	elif is_new:
		var tag := _text(" NEW ", 14, Color(1, 0.97, 0.9))
		var ts := StyleBoxFlat.new()
		ts.bg_color = Color(0.85, 0.3, 0.15)
		ts.set_corner_radius_all(8)
		tag.add_theme_stylebox_override("normal", ts)
		tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vb.add_child(tag)
	if _kit:   # the kit's check, shown on the chosen card (select)
		var chk := SceneKit.picture("badge_check", 30.0, "Check")   # top left: NEW sits top right
		chk.position = Vector2(-6, -8)
		chk.size = Vector2(30, 30)
		chk.visible = false
		b.add_child(chk)
		if locked:
			var lock := SceneKit.picture("icon_lock", 34.0, "Lock")
			lock.set_anchors_preset(Control.PRESET_CENTER)
			lock.position = Vector2(-15, -30)
			b.add_child(lock)
	Herd._ignore_mouse(b)
	card.name = "Card"
	card.visible = false
	b.add_child(card)
	grid.add_child(b)


## "Speed ■■■■□ Fast: pulls away from the T-rex". Energy pips are orange
## (more = hungrier); the others green.
## `of` is the scale: 5 for the form cards' gameplay pips, 10 for a species'
## attributes (smaller pips so the row stays the same width).
func _stat_row(label: String, pips: int, note: String, cost: bool, of := 5) -> Control:
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 6)
	var l := _text(label, 16, Color(0.4, 0.22, 0.08))
	l.custom_minimum_size = Vector2(62, 0)
	hb.add_child(l)
	var pip_box := HBoxContainer.new()
	pip_box.add_theme_constant_override("separation", 3)
	pip_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	for i in of:
		var p := ColorRect.new()
		p.custom_minimum_size = Vector2(16 if of <= 5 else 7, 11)
		var on := Color(0.92, 0.55, 0.15) if cost else Color(0.4, 0.68, 0.25)
		p.color = on if i < pips else Color(0.55, 0.45, 0.32, 0.45)
		pip_box.add_child(p)
	hb.add_child(pip_box)
	var n := _text(note, 15, Color(0.45, 0.3, 0.15))
	hb.add_child(n)
	return hb


## Power-ups: owned ones normally; locked ones show their art greyed out
## with what they'll do, waiting for the market.
func _powerup_cards() -> void:
	for kind in Boosters.DATA:
		var d: Dictionary = Boosters.DATA[kind]
		var owned := boosters_owned.has(kind)
		var body: String = d.desc
		if kind == "pepper":
			body += " Carry it in a booster slot (1 of each type) and tap the slot to use it."
		var meta := "+%d points when picked up" % d.score if owned else ("LOCKED · in the Market for %d meat" % Market.price(kind)) + ("" if Market.on_sale(kind, best_m) else " (on sale from %d m)" % Market.unlock_m(kind))
		_card(Boosters.icon(kind), d.name, body, meta, false, false,
				Color(0.85, 0.55, 0.15) if owned else Color(0.5, 0.42, 0.34))
		if not owned:
			var card: Control = grid.get_child(grid.get_child_count() - 1)
			var icon := card.find_children("*", "TextureRect", true, false)[0] as TextureRect
			icon.modulate = Color(0.45, 0.42, 0.4, 0.85)   # greyed out until bought
			(card.get_theme_stylebox("panel") as StyleBoxFlat).bg_color = Color(0.82, 0.75, 0.62)


func _tex(icon: String) -> Texture2D:
	if icon.begins_with("trap:"):   # a frame of a trap's animation, e.g. "trap:volcanic_steam:4"
		var parts := icon.split(":")
		return SpriteLib.trap(parts[1]).get_frame_texture("a", int(parts[2]))
	return load(icon if icon.begins_with("res://") else P % icon)


func _dino_card(f: int) -> void:
	var d: Dictionary = Forms.DATA[f]   # the original form (expansion dinosaurs have their own pages)
	var tex: Texture2D = SpriteLib.tex("res://assets/portraits/%s.png" % d.id)
	if not unlocked.has(f):
		_card(tex, "???", "Run %d m in one go to unlock." % Progression.unlock_m(f), "", true, false)
		return
	var breaks: Array = d.breaks
	var meta := []
	if breaks.size() > 0:
		meta.append("Smashes: " + ", ".join(breaks.map(func(k): return {"small": "small hazards", "wood": "logs", "rock": "rocks & walls", "fence": "fences", "thorns": "thorns"}.get(k, k))))
	if d.score_mult > 1.0:
		meta.append("Score ×%s" % str(d.score_mult))
	var how: String = {
		Forms.ROK: "The hero. Can double-jump: tap JUMP again in mid-air. Costs no energy, and runs at the T-rex's pace.",
		Forms.RAPTOR: "Fast and light: outruns the T-rex (even uphill), has the highest leap and a double jump, and earns double points.",
		Forms.TRICERATOPS: "A living battering ram that charges straight through rocks, walls and logs. It can only single-jump.",
		Forms.SPINOSAURUS: "Huge and tough. Tramples fences and logs, and each transformation gives a shield that survives one hit.",
		Forms.PTERANODON: "Takes to the sky. Hold JUMP to climb, let go to glide. Flies over pits and walls.",
	}[f]
	if Critters.DATA.has(d.id):
		how += "\n\nIt also runs wild in %s.\n%s" % [Drops.wild_zones(d.id), Drops.for_wild(d.id)]
	_card(tex, d.name, how, "  ·  ".join(meta), false,
			_new_ids.has("dino_%d" % f), d.color, dino_stats(f), d.id)


## [label, pips 1-5, note] rows for a dinosaur card.
static func dino_stats(f: int) -> Array:
	var d: Dictionary = Forms.DATA[f]
	var rows := []
	var chase: float = Tuning.CHASE_RECOVER + d.get("chase_rate", 0.0)
	var vs := "pulls away from the T-rex" if chase > 0.0 else ("keeps pace with the T-rex" if chase == 0.0 else "the T-rex gains on it")
	rows.append(["Speed", clampi(ceili(int(d.speed) / 2.0), 1, 5), "%s: %s" % [d.speed_label, vs]])   # 10-point speed on 5 pips
	var h: float = d.jump * d.jump / (2.0 * Tuning.GRAVITY)
	if d.get("flies", false):
		rows.append(["Jump", 5, "Flies"])
	else:
		rows.append(["Jump", clampi(int(round(h / 52.0)), 1, 5), "double jump" if d.air_jumps > 0 else "single jump"])
	if f == Forms.ROK:
		rows.append(["Energy", 0, "Free"])
	else:
		rows.append(["Energy", clampi(int(ceil(d.drain / 13.0 * 5.0)), 1, 5), "uses %d per second" % int(d.drain)])
	return rows


## An expansion dinosaur's page: revealed once bought (category, attributes,
## its trade-off and real-world facts), a silhouette until then.
func _species_card(id: String) -> void:
	var tex := Dinos.icon(id)
	var cat: Dictionary = Dinos.CATEGORIES[Dinos.category_of(id)]
	if not species_owned.has(id):
		var wild := (" You may meet it running wild in %s." % Drops.wild_zones(id)) if Critters.DATA.has(id) else ""
		_card(tex, "???", "A %s for the %s button. To unlock it: buy it in the Market once you %s.%s" % [
				String(cat.name).to_lower(), cat.name, Market.lock_text(id, best_m).replace(" ✓", "").replace(" · ", " and "), wild], "", true, false)
		return
	var rows := []
	for a in Dinos.ATTRS:
		var sv := Dinos.stat(id, a)
		rows.append([Dinos.ATTR_NAMES[a], int(roundf(sv)), ("%s/10, its speciality" if a == cat.lean else "%s/10") % Dinos.fmt(sv), Dinos.ATTR_MAX])
	var how := "%s %s. Equip it at the Dinosaur Camp to play as it on the %s button." % [Dinos.desc(id), cat.role, cat.name]
	if Critters.DATA.has(id):
		how += "\n\nIt also runs wild in %s.\n%s" % [Drops.wild_zones(id), Drops.for_wild(id)]
	_card(tex, Dinos.name_of(id), how, "%s · %s · Lv %d★  ·  %s" % [cat.name, Dinos.tier_label(id), Dinos.level(id), Dinos.tradeoff(id)], false,
			_new_ids.has("dino_" + id), Forms.DATA[cat.form].color, rows, id)


## A badge: its medal at the tier earned, the next goal, a progress bar
## and the three tiers (with their meat rewards).
func _badge_card(id: String) -> void:
	var b: Dictionary = Badges.DATA[id]
	var t := int(badge_tiers.get(id, 0))
	var v := float(badge_stats.get(b.stat, 0.0))
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var cs := StyleBoxFlat.new()
	cs.bg_color = CARD
	cs.set_corner_radius_all(14)
	cs.set_border_width_all(3)
	cs.border_color = Badges.TIER_COLORS[t - 1].darkened(0.2) if t > 0 else Color(0.5, 0.42, 0.34)
	cs.set_content_margin_all(12)
	card.add_theme_stylebox_override("panel", cs)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 14)
	card.add_child(hb)
	var icon := TextureRect.new()
	icon.texture = Badges.icon(id, t)
	icon.custom_minimum_size = Vector2(84, 84)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hb.add_child(icon)
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation", 4)
	hb.add_child(vb)
	vb.add_child(_text(b.name + ("  ·  " + Badges.TIERS[t - 1] if t > 0 else ""), 24))
	var done := t >= Badges.TIERS.size()
	var goal := _text("All tiers earned!" if done else Badges.goal_text(id, t), 18)
	goal.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	goal.custom_minimum_size = Vector2(260, 0)
	vb.add_child(goal)
	# what each tier unlocks, one line per tier: "Silver unlocks Deinonychus, Carnotaurus"
	var by_tier := {}
	for u in Badges.unlocks(id):
		if not by_tier.has(u[1]):
			by_tier[u[1]] = []
		by_tier[u[1]].append(Market.item_name(u[0]))
	var tier_keys := by_tier.keys()
	tier_keys.sort()
	if Badges.PERKS.has(id):
		var pk := _text("Permanent bonus: " + "  ·  ".join(range(1, 4).map(func(t): return "%s %s" % [Badges.TIERS[t - 1], Badges.perk_text(id, t)])), 15, Color(0.25, 0.5, 0.2))
		pk.name = "Perk"
		pk.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vb.add_child(pk)
	for tk in tier_keys:
		var un := _text("%s unlocks %s" % [Badges.TIERS[tk - 1], ", ".join(by_tier[tk])], 15, Color(0.55, 0.28, 0.1))
		un.name = "Unlocks"
		un.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vb.add_child(un)
	var bar := ProgressBar.new()
	bar.name = "Progress"
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 14)
	bar.max_value = Badges.target(id, t)
	bar.value = minf(v, bar.max_value)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.4, 0.3, 0.2, 0.35)
	bg.set_corner_radius_all(7)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Badges.TIER_COLORS[mini(t, 2)]
	fill.set_corner_radius_all(7)
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fill)
	vb.add_child(bar)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	vb.add_child(row)
	row.add_child(_text("%d / %d" % [int(v), Badges.target(id, t)], 16, Color(0.45, 0.3, 0.18)))
	for k in Badges.TIERS.size():
		var got := k < t
		row.add_child(_text(("✓ " if got else "") + "%s +%d" % [Badges.TIERS[k], Badges.TIER_REWARD[k]], 15,
				Badges.TIER_COLORS[k].darkened(0.35) if got else Color(0.55, 0.45, 0.35)))
	_add_entry(card, Badges.icon(id, t), b.name, false, false, "Badge_" + id)


func _hazard_card(h: Dictionary, is_hazard: bool) -> void:
	# its look in the zone where it's first met (HazardIcons; "" = its own icon)
	var first_m := Progression.intro_m(h.key)
	var tex := HazardIcons.icon(h.key, "" if is_inf(first_m) else String(Zones.zone_at(first_m).id))
	if not h.get("always", false) and not Progression.taught(h.key, best_m, seen):
		_card(tex, "???", unlock_hint(h.key), "", true, false)
		return
	var counter: String = h.get("counter", "")
	var accent := Color(0.75, 0.3, 0.15) if h.get("gate", false) else Color(0.45, 0.25, 0.1)
	var body: String = h.text
	var dr := Drops.for_hazard(h.key)
	if h.key == "small":   # its mushrooms have their own table
		var mm := Drops.break_mats("mushroom")
		if mm != "":
			dr += "\n• mushrooms: %s materials (%s)" % [Drops.pct(float(Crafting.num("break_drops", "chance"))), mm]
	if dr != "":
		body += "\n\n" + dr
	_card(tex, h.name, body, counter, false, _new_ids.has(h.key), accent, [], h.get("facts", ""), _zone_looks(h.key))


## How to meet a hazard not met yet (the user's rule: say how to unlock
## things): the distance, the zone it lives in and what it waits for.
func unlock_hint(key: String) -> String:
	var m := Progression.intro_m(key)
	if is_inf(m):
		return "Keep running: it turns up in long runs."
	var zone_only: Array = HazardIcons.ZONE_ICONS.get(key, {}).keys()
	var where := ""
	if zone_only.size() == 1:
		where = " in the %s" % String(Zones.ZONES[maxi(Zones.ZONES.map(func(z): return z.id).find(zone_only[0]), 0)].name)
	var t := "Run past %d m in one run to meet it%s." % [int(m), where]
	var need := ", ".join(Requires.missing("hazard." + key))
	if need != "":
		t += " It also needs: %s." % need
	return t


## A row with a hazard's look in each zone it differs in (nothing if it
## looks the same everywhere or only lives in one zone).
## A zone's picture for its card: a little scene made from the game's own art
## (the zone's daytime sky, its background layers and a strip of its ground),
## instead of a thin background strip that left the card mostly empty.
const ZONE_LAYERS := {"forest": ["res://assets/bg/bg_2.png", "res://assets/bg/bg_1.png"],
		"desert": ["res://assets/bg/desert_far.png", "res://assets/bg/desert_dunes.png"],
		"canyon": ["res://assets/bg/canyon_far.png", "res://assets/bg/canyon_mid.png", "res://assets/bg/canyon_near.png"],
		"volcanic": ["res://assets/bg/volcanic_far.png", "res://assets/bg/volcanic_dunes.png"]}
static var _zone_icons := {}


static func zone_icon(zid: String) -> Texture2D:
	if _zone_icons.has(zid):
		return _zone_icons[zid]
	const W := 300
	const H := 200
	var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
	var z: Dictionary = Zones.ZONES[maxi(Zones.ZONES.map(func(d): return d.id).find(zid), 0)]
	var sky: Array = z.sky_day
	for y in H:
		var t := float(y) / H
		img.fill_rect(Rect2i(0, y, W, 1), (sky[0] as Color).lerp(sky[1], t * 1.4) if t < 0.7 else (sky[1] as Color).lerp(sky[2], (t - 0.7) / 0.3))
	for path in ZONE_LAYERS.get(zid, []):
		if not ResourceLoader.exists(path):
			continue
		var l := HazardIcons._rgba(load(path))
		# the lower part of the layer (its bottom is near the ground line), a screen's width
		var cw := mini(l.get_width(), 900)
		var crop := l.get_region(Rect2i(0, l.get_height() - 600, cw, 600))
		crop.resize(W, int(600.0 * W / cw), Image.INTERPOLATE_LANCZOS)
		img.blend_rect(crop, Rect2i(Vector2i.ZERO, crop.get_size()), Vector2i(0, H - crop.get_height() + 30))
	var gpath := "res://assets/terrain/%s_ground.png" % String(z.get("ground", zid))
	if ResourceLoader.exists(gpath):
		var g := HazardIcons._rgba(load(gpath))
		var strip := g.get_region(Rect2i(0, 0, mini(g.get_width(), 600), 70))
		strip.resize(W, 35, Image.INTERPOLATE_LANCZOS)
		img.blend_rect(strip, Rect2i(Vector2i.ZERO, strip.get_size()), Vector2i(0, H - 35))
	var tex := ImageTexture.create_from_image(img)
	_zone_icons[zid] = tex
	return tex


func _zone_looks(key: String) -> Control:
	var zones := HazardIcons.variant_zones(key)
	if zones.size() < 2:
		return null
	var row := HBoxContainer.new()
	row.name = "ZoneLooks"
	row.add_theme_constant_override("separation", 4)   # four zones fit the page (it ran off with 78 px cells)
	for zid in zones:
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 0)
		var ic := TextureRect.new()
		ic.texture = HazardIcons.icon(key, zid)
		ic.custom_minimum_size = Vector2(66, 48)
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		v.add_child(ic)
		var z: Dictionary = Zones.ZONES[Zones.ZONES.map(func(d): return d.id).find(zid)]
		var cap := _text(String(z.name).replace(" Badlands", ""), 13, Color(0.5, 0.35, 0.2))
		cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(cap)
		row.add_child(v)
	return row


func _card(tex: Texture2D, name: String, body: String, meta: String, locked: bool, is_new: bool,
		accent := Color(0.45, 0.25, 0.1), stats := [], facts_id := "", extra: Control = null) -> void:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var cs := StyleBoxFlat.new()
	cs.bg_color = CARD if not locked else Color(0.78, 0.7, 0.55)
	cs.set_corner_radius_all(14)
	cs.set_border_width_all(3)
	cs.border_color = accent if not locked else Color(0.5, 0.4, 0.3)
	cs.set_content_margin_all(12)
	card.add_theme_stylebox_override("panel", cs)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 14)
	card.add_child(hb)
	var icon := TextureRect.new()
	icon.texture = tex
	icon.custom_minimum_size = Vector2(110, 110)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if locked:
		icon.modulate = Color(0.12, 0.07, 0.03, 0.85)   # silhouette
	hb.add_child(icon)
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation", 4)
	hb.add_child(vb)
	var top := HBoxContainer.new()
	vb.add_child(top)
	top.add_child(_text(name, 26, INK if not locked else Color(0.35, 0.28, 0.2)))
	if is_new:
		var tag := _text(" NEW ", 16, Color(1, 0.97, 0.9))
		var ts := StyleBoxFlat.new()
		ts.bg_color = Color(0.85, 0.3, 0.15)
		ts.set_corner_radius_all(8)
		tag.add_theme_stylebox_override("normal", ts)
		tag.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		top.add_child(tag)
	var b := _text(body, 19)
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.custom_minimum_size = Vector2(300, 0)
	vb.add_child(b)
	for row in stats:
		vb.add_child(_stat_row(row[0], row[1], row[2], row[0] == "Energy", row[3] if row.size() > 3 else 5))
	if meta != "":
		var m := _text(meta, 17, Color(0.55, 0.28, 0.1))
		m.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		m.custom_minimum_size = Vector2(300, 0)
		vb.add_child(m)
	if facts_id != "" and not DinoFacts.for_id(facts_id).is_empty():
		vb.add_child(_facts_box(facts_id))
	if extra != null:
		vb.add_child(extra)
	_add_entry(card, tex, name, locked, is_new)


## A "learn about the real animal" panel: basics, then a Did you know? fact.
func _facts_box(id: String) -> Control:
	var f := DinoFacts.for_id(id)
	var box := PanelContainer.new()
	box.name = "Facts"
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.93, 0.88, 0.74)
	st.set_corner_radius_all(10)
	st.set_content_margin_all(10)
	box.add_theme_stylebox_override("panel", st)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	box.add_child(v)
	v.add_child(_text(String(f.heading).to_upper(), 18, Color(0.2, 0.4, 0.3)))
	var basics := _text(DinoFacts.text(id), 17)
	basics.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	basics.custom_minimum_size = Vector2(300, 0)
	v.add_child(basics)
	var dyk := _text("Did you know? " + String(f.fact), 17, Color(0.5, 0.22, 0.08))
	dyk.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dyk.custom_minimum_size = Vector2(300, 0)
	v.add_child(dyk)
	return box
