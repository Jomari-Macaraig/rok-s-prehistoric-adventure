class_name Herd
extends CanvasLayer
## The Herd: choose which dinosaur each dino button uses, and compare them.
## One tab per category (Runner, Smasher, Tank, Flyer). The list shows all
## eight members of that category: the button's original dinosaur, the ones
## you own, and silhouettes of the rest (they can still be tapped to compare
## before buying them in the Market). The detail panel shows the selected
## dinosaur's five attributes as bars against the one equipped now: gains in
## green, losses in red, with the difference. Equip puts it on the button
## (main.equip / main.unequip); the button itself still unlocks by distance.
##
## LEVELS: an owned dinosaur (the originals too) shows its level as stars
## (Dinos.level_stars, 1-5). Each attribute row has a "+": the first tap asks
## to confirm with the price, the second levels it up (main.level_up), adding
## +1 to that attribute. Attributes are on a 10-point scale.

signal closed

const INK := Codex.INK
const PAPER := Codex.PAPER
const CARD := Codex.CARD
const GAIN := Color(0.25, 0.6, 0.2)
const LOSS := Color(0.8, 0.25, 0.15)
const EMPTY := Color(0.72, 0.64, 0.52)
const FILL := Color(0.55, 0.37, 0.2)      # an attribute point both dinosaurs share

var game   # main.gd: dinos_owned, unlocked, equip(id), unequip(cat), equipped_in(cat)
var root: Control
var tab := "runner"
var selected := ""          # the dinosaur shown in the detail panel
var tab_buttons := {}       # category -> Button
var list: HBoxContainer      # the shelf row: one tile per member (named by id), or the gear choices
var scroll: ScrollContainer
var detail: VBoxContainer
var _anim: Array = []       # [TextureRect, id, frame, time left] for the detail idle loop
var _confirm := ""          # attribute waiting for its confirming tap ("" = none)
var dscroll: ScrollContainer   # the detail panel's scroll (a hero with gear runs long)
var scene: MarketScene        # the camp: a hut, a campfire (MarketScene kind "camp")
var hero: AnimatedSprite2D    # the hero you play, at the left
var stage: TextureRect        # the chosen dinosaur or hero, standing by the hut
var board: PanelContainer     # the wooden board holding `detail`
var shelf: VBoxContainer      # tabs + the row of tiles (`list`)
var _tile_h := 160.0
var _drag_target: ScrollContainer
var picking := ""           # a hero gear slot being chosen ("weapon"/"armor"): the list shows its choices
var bank_label: Label
var _fling := 0.0
var _dragging := false
var _drag_dist := 0.0
## The user's scene kit (SceneKit): the painted camp, the parchment stats
## panel, the roster frame, kit tabs, cards, status pills and buttons.
var _kit := false
var roster: Panel


## Tabs: the heroes first (Rok, Nira, Boro; tab id "rok"), then one per dino category.
static func tabs() -> Array:
	return ["rok"] + Dinos.CATEGORIES.keys()


## A tab's title ("Rok", "Runner"...).
static func tab_name(cat: String) -> String:
	return "Heroes" if cat == "rok" else String(Dinos.CATEGORIES[cat].name)


## A tab's highlighted attribute ("" for Rok, who has no category).
static func lean_of(cat: String) -> String:
	return "" if cat == "rok" else String(Dinos.CATEGORIES[cat].lean)


## The one on a tab's button now (the equipped hero on the Heroes tab).
func current(cat: String) -> String:
	return game.equipped_in("hero" if cat == "rok" else cat)


## Every member of a category: the button's original first, then the Market
## dinosaurs in the order they go on sale. The Heroes tab: Rok, Nira, Boro.
static func members(cat: String) -> Array:
	if cat == "rok":
		return Heroes.IDS.filter(func(h): return h == "rok" or Heroes.has(h))
	var out := [Forms.DATA[Dinos.slot_of(cat)].id]
	var rest: Array = Dinos.ids().filter(func(id): return Dinos.category_of(id) == cat)
	rest.sort_custom(func(a, b): return Market.unlock_m(a) < Market.unlock_m(b))
	out.append_array(rest)
	return out


## The button's original dinosaur, or Rok (always yours).
static func is_original(id: String) -> bool:
	return not Dinos.has(id) and not Heroes.has(id)


func owns(id: String) -> bool:
	return is_original(id) or game.dinos_owned.has(id)


static func icon_of(id: String) -> Texture2D:
	if Heroes.is_hero(id):
		return SpriteLib.tex("res://assets/portraits/%s.png" % id)
	return Dinos.icon(id) if Dinos.has(id) else SpriteLib.tex("res://assets/portraits/%s.png" % id)


static func name_of(id: String) -> String:
	if Heroes.is_hero(id):
		return Heroes.name_of(id)
	return Dinos.name_of(id) if Dinos.has(id) else String(Forms.DATA[Dinos.slot_of(Dinos.category_of(id))].name)


static func tier_text(id: String) -> String:
	if Heroes.is_hero(id):
		return "Hero · " + Heroes.role_of(id)
	return "Original" if is_original(id) else Dinos.tier_label(id)


func _ready() -> void:
	layer = 22
	visible = false
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	_kit = SceneKit.has()
	var kit_bg := SceneKit.backdrop("dinosaur_camp")
	root.add_child(kit_bg if kit_bg else Market.backdrop("res://assets/bg/bg_1.png", Color(0.5, 0.68, 0.85)))   # its own scene: the camp in the forest
	scene = MarketScene.new()
	scene.kind = "camp"
	scene.sign_text = "CAMP"
	scene.style = "stall"
	root.add_child(scene)
	# the hero you play, at the left
	hero = AnimatedSprite2D.new()
	hero.name = "Hero"
	hero.centered = false
	root.add_child(hero)
	# the chosen dinosaur (or hero), standing by the hut
	stage = TextureRect.new()
	stage.name = "Stage"
	stage.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stage.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.flip_h = true   # facing the hero
	root.add_child(stage)
	if _kit:
		scene.visible = false   # the painted camp has its own fire, tent and forest

	var header := HBoxContainer.new()
	header.name = "Header"
	header.set_anchors_preset(Control.PRESET_TOP_WIDE)
	header.offset_left = Tuning.UI_MARGIN
	header.offset_right = -Tuning.UI_MARGIN
	header.offset_top = 14
	header.add_theme_constant_override("separation", 12)
	root.add_child(header)
	var close := Market._button("‹ Back", Vector2(130, 52))
	close.pressed.connect(close_herd)
	close.name = "Back"
	header.add_child(close)
	var kit_title := SceneKit.picture("dinosaurs_title", 62.0, "TitleBanner")
	if kit_title:
		SceneKit.style_back(close)
		header.add_child(kit_title)
	else:
		header.add_child(Market.title_banner("dinosaurs", Market._text("CAMP", 40)))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	var pouch := PanelContainer.new()
	var pst := StyleBoxFlat.new()
	pst.bg_color = Color(0.25, 0.13, 0.06, 0.75)
	pst.set_corner_radius_all(16)
	pst.content_margin_left = 14
	pst.content_margin_right = 16
	var plate := SceneKit.box("counter_plate")
	if plate:
		plate.content_margin_left = 26
		plate.content_margin_right = 30
	pouch.add_theme_stylebox_override("panel", plate if plate else pst)
	header.add_child(pouch)
	var prow := HBoxContainer.new()
	pouch.add_child(prow)
	var coin := TextureRect.new()
	coin.texture = load(Market.MEAT)
	coin.custom_minimum_size = Vector2(36, 36)
	coin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	coin.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	prow.add_child(coin)
	bank_label = Market._text("0", 28, Color(1, 0.95, 0.82))
	bank_label.name = "Bank"
	bank_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	prow.add_child(bank_label)

	# the camp's board: the chosen one's level, attributes and gear
	board = PanelContainer.new()
	board.name = "Board"
	var ds := StyleBoxFlat.new()
	ds.bg_color = Color(0.96, 0.9, 0.76, 0.97)
	ds.set_corner_radius_all(10)
	ds.set_border_width_all(6)
	ds.border_color = Color(0.45, 0.27, 0.12)
	ds.set_content_margin_all(14)
	ds.shadow_color = Color(0, 0, 0, 0.25)
	ds.shadow_size = 8
	var kit_panel := SceneKit.box("stats_panel")
	if kit_panel:   # clear of the frame's wood and bones
		kit_panel.content_margin_left = 50
		kit_panel.content_margin_right = 46
		kit_panel.content_margin_top = 40
		kit_panel.content_margin_bottom = 40
	board.add_theme_stylebox_override("panel", kit_panel if kit_panel else ds)
	root.add_child(board)
	dscroll = ScrollContainer.new()   # a hero's detail (with gear) can run long
	dscroll.name = "DetailScroll"
	dscroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	board.add_child(dscroll)
	detail = VBoxContainer.new()
	detail.name = "Detail"
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail.add_theme_constant_override("separation", 6)
	dscroll.add_child(detail)

	# the shelf: the tabs, then everyone in that group as tiles in a row
	shelf = VBoxContainer.new()
	shelf.name = "Shelf"
	shelf.add_theme_constant_override("separation", 8)
	root.add_child(shelf)
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 10)
	shelf.add_child(tabs)
	for cat in tabs():
		var tb := Market._button(tab_name(cat), Vector2(176, 46))
		tb.name = "Tab_" + cat
		tb.toggle_mode = true
		tb.pressed.connect(func(): show_tab(cat))
		tabs.add_child(tb)
		tab_buttons[cat] = tb
	scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	shelf.add_child(scroll)
	list = HBoxContainer.new()
	list.name = "List"
	list.add_theme_constant_override("separation", 12)
	scroll.add_child(list)
	if _kit:
		roster = Panel.new()   # the wooden roster frame behind the tabs and cards
		roster.name = "Roster"
		roster.add_theme_stylebox_override("panel", SceneKit.box("roster_panel"))
		roster.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(roster)
		root.move_child(roster, shelf.get_index())
		for cat in tab_buttons:
			SceneKit.style_button(tab_buttons[cat], "tab_inactive", "tab_active", 20)
	root.resized.connect(_layout)


## Place everything around the camp (it follows the screen size).
func _layout() -> void:
	var w := root.size.x
	var h := root.size.y
	if _kit:
		_layout_kit(w, h)
		return
	var gy: float = scene.ground_y
	hero.position = scene.hero_spot()
	var cx: float = scene.cave_x()
	stage.size = Vector2(250, 210)
	stage.position = Vector2(cx - 10.0 - 125.0, gy - 210.0 + 8.0)
	var left: float = scene.hero_spot().x + 105.0
	var right := cx - 210.0
	board.position = Vector2(left, 78.0)
	board.size = Vector2(maxf(right - left, 440.0), gy - 78.0 - 20.0)
	var top_gap := 30.0
	shelf.position = Vector2(Tuning.UI_MARGIN, gy + 14.0 + top_gap)
	shelf.size = Vector2(w - Tuning.UI_MARGIN * 2.0, h - gy - 22.0 - top_gap)
	_tile_h = maxf(shelf.size.y - 46.0 - 8.0 - 14.0 - 30.0, 120.0)
	scene.band = Rect2(0.0, gy + 26.0, w, h - gy - 26.0)
	scene.tiles_top = shelf.position.y + 46.0 + 8.0
	scene.shelf_y = scene.tiles_top + _tile_h
	for t in list.get_children():
		if t is Button:
			(t as Control).custom_minimum_size.y = _tile_h


## The kit's layout (its 1920x1080 reference scaled by the screen height;
## the stats panel anchored right, the roster along the bottom): the hero on
## the left, the chosen one beside him by the tent.
func _layout_kit(w: float, h: float) -> void:
	var k := h / 1080.0
	var pw := maxf(680.0 * k, 560.0)   # (its rows need ~440 px inside the frame)
	board.position = Vector2(w - 30.0 * k - pw, 96.0 * k)
	board.size = Vector2(pw, 590.0 * k)
	var ground := 650.0 * k
	hero.position = Vector2(300.0 * k, ground)
	hero.scale = Vector2.ONE * (440.0 * k / 224.0)
	var sx := 600.0 * k
	var sw := maxf(board.position.x - sx - 20.0, 220.0)
	stage.size = Vector2(sw, 360.0 * k)
	stage.position = Vector2(sx, ground - 360.0 * k + 8.0)
	roster.position = Vector2(20.0 * k, 700.0 * k)
	roster.size = Vector2(w - 40.0 * k, h - 700.0 * k - 12.0 * k)
	shelf.position = roster.position + Vector2(56.0, 14.0)
	shelf.size = roster.size - Vector2(112.0, 26.0)
	_tile_h = maxf(shelf.size.y - 46.0 - 8.0 - 10.0, 110.0)
	for t in list.get_children():
		if t is Button:
			(t as Control).custom_minimum_size = Vector2(_tile_h * 0.9, _tile_h)


func open_herd(cat := "") -> void:
	visible = true
	Market.enter(root)
	hero.sprite_frames = SpriteLib.character(Forms.ROK)
	if not hero.has_node("Gear"):
		var gl := GearLayer.new()
		gl.name = "Gear"
		hero.add_child(gl)
	(hero.get_node("Gear") as GearLayer).hero = String(Forms.get_data(Forms.ROK).id)   # the hero you play
	hero.offset = -Vector2(Forms.get_data(Forms.ROK).pivot)
	hero.scale = Vector2.ONE * 1.25
	hero.play("idle")
	_layout()   # (the kit's layout sets its own hero scale)
	show_tab(cat if cat != "" else tab)


func close_herd() -> void:
	visible = false
	closed.emit()


func show_tab(cat: String) -> void:
	tab = cat
	_confirm = ""
	picking = ""
	selected = current(cat)
	scroll.scroll_horizontal = 0
	refresh()


## Show a dinosaur in the detail panel (compared with the equipped one).
func select(id: String) -> void:
	if _drag_dist > 12.0:
		return   # that was a scroll, not a tap
	selected = id
	_confirm = ""
	picking = ""
	game.audio.play("click", 0.0)
	refresh()


## "Change" beside a gear slot: the list shows what can go in it.
func press_slot(slot: String) -> void:
	if _drag_dist > 12.0:
		return
	picking = "" if picking == slot else slot
	game.audio.play("click", 0.0)
	scroll.scroll_horizontal = 0
	refresh()


## A choice in the gear list: put it on the selected hero ("" empties the slot).
func press_gear(id: String) -> void:
	if _drag_dist > 12.0:
		return
	game.equip_gear(selected, picking, id)
	picking = ""
	game.audio.play("click", 0.0)
	refresh()


## Repair beside a worn weapon: the first tap asks, the second spends the meat.
func press_repair(gid: String) -> void:
	if _drag_dist > 12.0:
		return
	if _confirm != "repair:" + gid:
		_confirm = "repair:" + gid
		game.audio.play("click", 0.0)
	else:
		_confirm = ""
		game.repair_gear(gid)
	refresh()


## "+" beside an attribute: the first tap shows the price, the second levels up.
func press_level(attr: String) -> void:
	if _drag_dist > 12.0:
		return
	if _confirm != attr:
		_confirm = attr
		game.audio.play("click", 0.0)
	else:
		_confirm = ""
		game.level_up(selected, attr)
	refresh()


func press_equip(id: String) -> void:
	if not owns(id):
		return
	if is_original(id):
		game.unequip(tab)
	else:
		game.equip(id)
	game.audio.play("click", 0.0)
	refresh()


func refresh() -> void:
	bank_label.text = str(game.meat_bank)
	for cat in tab_buttons:
		var tb: Button = tab_buttons[cat]
		tb.button_pressed = cat == tab
		var have := members(cat).filter(func(id): return owns(id)).size()
		var ready: bool = members(cat).any(func(id): return game.level_ready().has(id)) or (cat == "rok" and game.gear_ready())
		tb.text = "%s %d/%d%s" % [tab_name(cat), have, members(cat).size(), " ●" if ready else ""]
	for c in list.get_children():
		list.remove_child(c)
		c.queue_free()
	if picking != "":
		_gear_list()
	else:
		for id in members(tab):
			list.add_child(_row(id))
	_build_detail()
	_show_stage()


## The chosen one, standing by the hut: a dinosaur's idle loop (a silhouette
## if you don't own it), or a hero's portrait.
func _show_stage() -> void:
	# the hero you play already stands at the left: only other heroes take the stage
	var shown := selected != "" and not (Heroes.is_hero(selected) and selected == current("rok"))
	stage.texture = icon_of(selected) if shown else null
	stage.modulate = Color.WHITE if owns(selected) else Color(0.12, 0.07, 0.03, 0.85)
	stage.flip_h = not Heroes.is_hero(selected)
	if Dinos.has(selected):
		_anim.append([stage, selected, 0, Dinos.frame_times(selected)[0]])


## The gear list for the slot being picked: "Nothing", then owned weapons or
## armor (and dinosaur cards for the weapon slot), each with its bonuses.
func _gear_list() -> void:
	var head := _light("Choose the %s for %s:" % [picking, name_of(selected)], 18)
	head.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	head.custom_minimum_size = Vector2(150, 0)
	head.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	list.add_child(head)
	var on := Gear.slot_item(selected, picking)
	var options: Array = [""] + Gear.choices(picking)
	for gid in options:
		var b := Button.new()
		b.name = "Gear_" + (gid if gid != "" else "none")
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(170, _tile_h)
		for st in ["normal", "hover", "pressed", "hover_pressed"]:
			b.add_theme_stylebox_override(st, _tile_box(false, gid == on))
		b.pressed.connect(func(): press_gear(gid))
		var hb := VBoxContainer.new()
		hb.set_anchors_preset(Control.PRESET_FULL_RECT)
		hb.offset_left = 6
		hb.offset_right = -6
		hb.alignment = BoxContainer.ALIGNMENT_CENTER
		hb.add_theme_constant_override("separation", 2)
		b.add_child(hb)
		var ic := TextureRect.new()
		ic.custom_minimum_size = Vector2(0, 60)
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		if gid != "":
			ic.texture = Gear.icon(gid)
		hb.add_child(ic)
		var names := VBoxContainer.new()
		names.alignment = BoxContainer.ALIGNMENT_CENTER
		names.add_child(_light("Nothing" if gid == "" else Gear.name_of(gid), 17))
		var sub := "Empty slot" if gid == "" else Gear.bonus_text(gid)
		if gid.begins_with(Gear.CARD_PREFIX):
			sub += "  ·  x%d" % int(Gear.cards.get(gid.substr(Gear.CARD_PREFIX.length()), 0))
		if gid == on:
			sub += "  ·  EQUIPPED"
		var sl := _light(sub, 13, Color(0.6, 1.0, 0.55) if gid == on else Color(1.0, 0.85, 0.5))
		sl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		names.add_child(sl)
		hb.add_child(names)
		_ignore_mouse(hb)
		list.add_child(b)
	if options.size() == 1:
		var none := Market._text("Nothing to put here yet: buy %s in the Market's Gear tab%s." % [
				"weapons" if picking == "weapon" else "armor", " or find dinosaur cards in chests" if picking == "weapon" else ""], 16, Color(0.5, 0.3, 0.15))
		none.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		list.add_child(none)


## One tile on the camp shelf: picture, name, tier and level, a tag
## (EQUIPPED / OWNED / MARKET / LOCKED) and ● LEVEL UP! when it's ready.
func _row(id: String) -> Control:
	var have := owns(id)
	var on: bool = current(tab) == id
	var b := Button.new()
	b.name = id
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(156, _tile_h)
	for state in ["normal", "hover", "pressed", "hover_pressed"]:
		b.add_theme_stylebox_override(state, _tile_box(id == selected, on, not have))
	b.pressed.connect(func(): select(id))
	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	vb.offset_left = 6
	vb.offset_right = -6
	vb.offset_top = 4
	vb.offset_bottom = -4
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 0)
	b.add_child(vb)
	var ic := TextureRect.new()
	ic.texture = icon_of(id)
	ic.custom_minimum_size = Vector2(0, 66)
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if not have:
		ic.modulate = Color(0.12, 0.07, 0.03, 0.85)
	vb.add_child(ic)
	var nm := _light(name_of(id), 17)
	nm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(nm)
	var tr := _light(tier_text(id) if not have else "%s · Lv %d★" % [tier_text(id).get_slice(" ", 0), Dinos.level(id)], 13, Dinos.tier_color(id).lightened(0.35))
	tr.name = "Stars" if have else "Tier"
	vb.add_child(tr)
	var tag_text := "EQUIPPED" if on else ("OWNED" if have else ("MARKET" if Market.on_sale(id, game.best_m) else "LOCKED"))
	var tag: Label = null
	if _kit and tag_text != "LOCKED":   # the kit's green pill (orange for the Market)
		tag = SceneKit.badge(tag_text, "status_pill_blank" if have else "badge_new_blank", 13)
		tag.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	if tag == null:
		tag = _light(tag_text, 14, Color(0.6, 1.0, 0.55) if have else Color(0.9, 0.82, 0.7))
	tag.name = "Tag"
	vb.add_child(tag)
	if _kit:
		if on:   # the kit's check on the one equipped
			var chk := SceneKit.picture("badge_check", 30.0, "Check")
			chk.set_anchors_preset(Control.PRESET_TOP_RIGHT)
			chk.position = Vector2(-26, -8)
			chk.size = Vector2(30, 30)
			b.add_child(chk)
		if not have and tag_text == "LOCKED":
			var lock := SceneKit.picture("icon_lock", 32.0, "Lock")
			lock.set_anchors_preset(Control.PRESET_CENTER_TOP)
			lock.position = Vector2(-14, 22)
			b.add_child(lock)
	if game.level_ready().has(id):
		var up := _light("● LEVEL UP!", 14, Color(1.0, 0.45, 0.35))
		up.name = "LevelReady"
		vb.add_child(up)
	_ignore_mouse(vb)
	return b


## A tile on the wooden shelf: open (the dinosaur stands on the plank), a soft
## glow when chosen, a green rim on the one equipped.
func _tile_box(chosen: bool, equipped: bool, locked := false) -> StyleBox:
	if _kit:
		return SceneKit.card_box(chosen, locked)
	var sb := StyleBoxFlat.new()
	sb.set_corner_radius_all(14)
	sb.bg_color = Color(1.0, 0.9, 0.55, 0.28) if chosen else Color(0, 0, 0, 0)
	sb.set_border_width_all(3 if (chosen or equipped) else 0)
	sb.border_color = Color(1.0, 0.8, 0.3) if chosen else Color(0.45, 0.85, 0.35)
	return sb


## Light text with a dark outline, readable on the wooden shelf.
func _light(t: String, size: int, color := Color(1, 0.96, 0.85)) -> Label:
	var l := Market._text(t, size, color)
	l.add_theme_color_override("font_outline_color", Color(0.22, 0.11, 0.04))
	l.add_theme_constant_override("outline_size", 6)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l


## Row contents mustn't take the tap: the row Button does.
static func _ignore_mouse(n: Node) -> void:
	for c in n.get_children():
		if c is Control:
			(c as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
		_ignore_mouse(c)


## The selected dinosaur, its attributes as bars against the equipped one,
## what that means in play, and the Equip button.
func _build_detail() -> void:
	_build_detail_content()
	if _kit:
		_kit_buttons(detail)


## The detail's action buttons in the kit's style: Equip / Play as green,
## the rest brown (the small + level buttons keep theirs).
func _kit_buttons(n: Node) -> void:
	for c in n.get_children():
		if c is Button and (c as Button).text.length() > 4:
			var b := c as Button
			var primary := b.name == "Equip" or b.text.begins_with("Play as") or b.text.begins_with("Use the")
			SceneKit.style_button(b, "button_primary" if primary else "button_secondary", "", 18)
		_kit_buttons(c)


func _build_detail_content() -> void:
	_anim.clear()
	for c in detail.get_children():
		detail.remove_child(c)
		c.queue_free()
	var id := selected
	var eq: String = current(tab)
	var have := owns(id)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 12)
	detail.add_child(top)
	var ic := TextureRect.new()
	ic.texture = icon_of(id)
	ic.custom_minimum_size = Vector2(150, 112)
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if not have:
		ic.modulate = Color(0.12, 0.07, 0.03, 0.85)
	elif Dinos.has(id):
		_anim.append([ic, id, 0, Dinos.frame_times(id)[0]])
	top.add_child(ic)
	var tv := VBoxContainer.new()
	tv.alignment = BoxContainer.ALIGNMENT_CENTER
	tv.add_theme_constant_override("separation", 0)
	top.add_child(tv)
	tv.add_child(Market._text(name_of(id), 28))
	tv.add_child(Market._text(tier_text(id) if tab == "rok" else "%s · %s" % [tab_name(tab), tier_text(id)], 16, Dinos.tier_color(id)))
	if have:
		var lv := Market._text("Lv %d  %s" % [Dinos.level(id), Dinos.level_stars(id)], 16, Color(0.85, 0.55, 0.1))
		lv.name = "Level"
		tv.add_child(lv)
		# experience toward the next level (1 XP per metre run as it)
		var xb := HBoxContainer.new()
		xb.name = "XP"
		xb.add_theme_constant_override("separation", 6)
		var pr := Dinos.xp_progress(id)
		var bar := ProgressBar.new()
		bar.show_percentage = false
		bar.custom_minimum_size = Vector2(130, 12)
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		bar.max_value = pr.y
		bar.value = pr.x
		var bbg := StyleBoxFlat.new()
		bbg.bg_color = EMPTY
		bbg.set_corner_radius_all(6)
		var bfg := StyleBoxFlat.new()
		bfg.bg_color = Color(0.3, 0.6, 0.9)
		bfg.set_corner_radius_all(6)
		bar.add_theme_stylebox_override("background", bbg)
		bar.add_theme_stylebox_override("fill", bfg)
		xb.add_child(bar)
		var xt := "MAX" if not Dinos.can_level(id) else "%d / %d XP" % [int(pr.x), int(pr.y)]
		xb.add_child(Market._text(xt, 14, Color(0.2, 0.4, 0.65)))
		tv.add_child(xb)
	tv.add_child(Market._text(Dinos.tradeoff(id), 15, Color(0.45, 0.3, 0.18)))
	var cmp := id != eq
	var head := Market._text(("Compared with your %s:" % name_of(eq)) if cmp else ("Your hero: runs on foot and turns into the dinosaurs" if tab == "rok" else "Equipped on the %s button" % tab_name(tab)), 16,
			Color(0.45, 0.3, 0.18))
	head.name = "CompareHead"
	detail.add_child(head)
	var lean: String = lean_of(tab)
	var lvl_ok := have and Dinos.can_level(id)
	var bars := GridContainer.new()
	bars.name = "Bars"
	bars.columns = 5 if lvl_ok else 4
	bars.add_theme_constant_override("h_separation", 10)
	bars.add_theme_constant_override("v_separation", 4)
	detail.add_child(bars)
	for a in Dinos.ATTRS:
		var v := Dinos.stat(id, a)
		var e := Dinos.stat(eq, a)
		var vt := Market._text(Dinos.fmt(v), 17, INK)
		vt.custom_minimum_size = Vector2(34, 0)
		bars.add_child(Market._text(Dinos.ATTR_NAMES[a], 17, Color(0.75, 0.35, 0.1) if a == lean else INK))
		var seg := HBoxContainer.new()
		seg.add_theme_constant_override("separation", 4)
		seg.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		for i in Dinos.ATTR_MAX:
			# how much of this segment each one fills (0-1): decimals show as part-filled
			var sv := clampf(v - i, 0.0, 1.0)
			var se := clampf(e - i, 0.0, 1.0)
			var r := ColorRect.new()
			r.custom_minimum_size = Vector2(17, 16)
			if sv <= 0.0 and se <= 0.0:
				r.color = EMPTY
			elif cmp and sv > se + 0.001:
				r.color = EMPTY.lerp(GAIN, 0.35 + 0.65 * sv)        # better than the equipped one
			elif cmp and sv < se - 0.001:
				r.color = EMPTY.lerp(LOSS.lightened(0.35), se)      # what you'd give up
			else:
				r.color = EMPTY.lerp(FILL, 0.35 + 0.65 * sv)
			seg.add_child(r)
		bars.add_child(seg)
		bars.add_child(vt)
		var dv := snappedf(v - e, 0.01)
		var dl := Market._text(("%s%s" % ["+" if dv > 0 else "-", Dinos.fmt(absf(dv))]) if cmp and absf(dv) > 0.001 else "", 17, GAIN if dv > 0 else LOSS)
		dl.name = "Delta_" + a
		dl.custom_minimum_size = Vector2(34, 0)
		bars.add_child(dl)
		if lvl_ok:
			var g := Dinos.gain(id, a)
			var pb := Market._button("Confirm?" if _confirm == a else ("+" + Dinos.fmt(g) if Dinos.can_raise(id, a) else "max"), Vector2(64, 30))
			pb.name = "Level_" + a
			pb.add_theme_font_size_override("font_size", 15)
			pb.disabled = not Dinos.can_raise(id, a) or game.meat_bank < Dinos.level_cost(id) or not Dinos.xp_ok(id)
			pb.tooltip_text = "Up to %d" % Dinos.level_cap(id, a)
			pb.pressed.connect(func(): press_level(a))
			bars.add_child(pb)
	if have and Dinos.can_level(id):
		var note := "Level %d for %d meat: tap + on an attribute (higher ones grow less)." % [Dinos.level(id) + 1, Dinos.level_cost(id)]
		if _confirm != "" and not _confirm.begins_with("repair:"):   # a level-up waiting (not a repair)
			note = "Tap Confirm? to raise %s by %s for %d meat." % [Dinos.ATTR_NAMES[_confirm], Dinos.fmt(Dinos.gain(id, _confirm)), Dinos.level_cost(id)]
		elif not Dinos.xp_ok(id):
			note = "Run %d m more as %s to reach Lv %d (1 XP per metre)." % [ceili(Dinos.xp_for(Dinos.level(id) + 1) - Dinos.xp_of(id)), name_of(id) if Heroes.is_hero(id) else "the " + name_of(id), Dinos.level(id) + 1]
		elif game.meat_bank < Dinos.level_cost(id):
			note = "Next level: %d meat (you have %d)." % [Dinos.level_cost(id), game.meat_bank]
		var ln := Market._text(note, 15, Color(0.5, 0.3, 0.12))
		ln.name = "LevelNote"
		detail.add_child(ln)
	elif have:
		detail.add_child(Market._text("Max level!", 15, Color(0.85, 0.55, 0.1)))
	for p in Dinos.perks(id):
		detail.add_child(Market._text("• " + p, 15, Color(0.4, 0.28, 0.15)))
	if Heroes.is_hero(id) and have:
		_gear_rows(id)
	var gap := Control.new()
	gap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail.add_child(gap)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	detail.add_child(row)
	var slot := Forms.ROK if tab == "rok" else Dinos.slot_of(tab)
	if id == eq:
		row.add_child(Market._text("EQUIPPED", 22, Color(0.25, 0.5, 0.2)))
	elif have:
		var b := Market._button(("Play as Rok" if id == "rok" else "Use the original") if is_original(id) else ("Play as " + name_of(id) if Heroes.is_hero(id) else "Equip"), Vector2(170, 50))
		b.name = "Equip"
		b.pressed.connect(func(): press_equip(id))
		row.add_child(b)
	else:
		var how := ("Buy it in the Market (%d meat)" % Market.price(id)) if Market.on_sale(id, game.best_m) \
				else "Locked · " + Market.lock_text(id, game.best_m)
		var l := Market._text(how, 16, Color(0.5, 0.3, 0.15))
		l.name = "HowToGet"
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(400, 0)
		row.add_child(l)
	if tab != "rok" and not game.unlocked.has(slot):
		var note := Market._text("The %s button unlocks at %d m." % [tab_name(tab), Progression.UNLOCKS[slot]], 15, Color(0.5, 0.3, 0.15))
		note.name = "SlotLocked"
		detail.add_child(note)


## A hero's two gear slots, each with what's in it and a Change button.
func _gear_rows(id: String) -> void:
	var t := Market._text("EQUIPMENT  ·  attack reach %d" % int(Gear.reach(id)), 16, Color(0.75, 0.35, 0.1))
	t.name = "EquipmentHead"
	detail.add_child(t)
	for slot in ["weapon", "armor"]:
		var row := HBoxContainer.new()
		row.name = "Slot_" + slot
		row.add_theme_constant_override("separation", 8)
		var gid := Gear.slot_item(id, slot)
		var ic := TextureRect.new()
		ic.custom_minimum_size = Vector2(40, 40)
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		if gid != "":
			ic.texture = Gear.icon(gid)
		row.add_child(ic)
		var txt := "%s: %s" % [slot.capitalize(), ("%s (%s)" % [Gear.name_of(gid), Gear.bonus_text(gid)]) if gid != "" else "empty"]
		var worn := Gear.max_durability(gid) > 0
		var l := Market._text(txt, 16)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		l.clip_text = true
		row.add_child(l)
		var can := not Gear.choices(slot).is_empty()
		var b := Market._button(("Done" if picking == slot else ("Change ●" if gid == "" and can else "Change")), Vector2(110, 40))
		b.name = "Change_" + slot
		b.add_theme_font_size_override("font_size", 15)
		b.pressed.connect(func(): press_slot(slot))
		row.add_child(b)
		if worn and Gear.repair_cost(gid) > 0:
			var rc := Gear.repair_cost(gid)
			var rb := Market._button(("Sure? %d" if _confirm == "repair:" + gid else "Repair %d") % rc, Vector2(120, 40))
			rb.name = "Repair_" + gid
			rb.add_theme_font_size_override("font_size", 15)
			rb.disabled = game.meat_bank < rc
			rb.tooltip_text = "Meat to repair it to full"
			rb.pressed.connect(func(): press_repair(gid))
			row.add_child(rb)
		detail.add_child(row)
		if worn:   # weapon durability on its own line: hits left, BROKEN at 0
			var br := Gear.broken(gid)
			var dl := Market._text(("      BROKEN · repair it to use it again" if br else "      Durability %d/%d hits") % ([] if br else [Gear.durability(gid), Gear.max_durability(gid)]),
					15, Color(0.8, 0.15, 0.1) if br else Color(0.45, 0.3, 0.15))
			dl.name = "Durability_" + gid
			detail.add_child(dl)


## Drag to scroll the list (as in the Market and Field Guide).
func _input(event: InputEvent) -> void:
	if not visible:
		return
	var drag := event as InputEventScreenDrag
	if drag:
		_dragging = true
		_drag_dist += drag.relative.length()
		if _drag_target == null:
			_drag_target = dscroll if dscroll.get_global_rect().has_point(drag.position) else scroll
		if _drag_target == scroll:
			scroll.scroll_horizontal -= int(drag.relative.x)   # the shelf scrolls sideways
			_fling = -drag.velocity.x
		else:
			_drag_target.scroll_vertical -= int(drag.relative.y)
			_fling = -drag.velocity.y
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
	if not visible:
		return
	for a in _anim:
		a[3] -= delta
		if a[3] <= 0.0:
			a[2] = (a[2] + 1) % 8
			a[3] += Dinos.frame_times(a[1])[a[2]]
			(a[0] as TextureRect).texture = Dinos.frame(a[1], a[2])
	if _dragging or absf(_fling) < 5.0:
		return
	if _drag_target == dscroll:
		dscroll.scroll_vertical += int(_fling * delta)
	else:
		scroll.scroll_horizontal += int(_fling * delta)
	_fling = lerpf(_fling, 0.0, minf(delta * 5.0, 1.0))
