class_name Workshop
extends CanvasLayer
## Two full screens in the Camp's style (the user's request), one script:
## - mode "bench": the CRAFTING BENCH. Tabs Weapons / Armor, a shelf of
##   recipes (locked ones show the distance that teaches them), and a board
##   with the chosen recipe's materials (have / need), a catalyst choice, the
##   rarity odds and Craft (a second tap confirms). Crafting reveals the
##   rolled rarity.
## - mode "items": the ITEMS screen. Tabs Materials / Weapons / Armor /
##   Cards, a shelf of everything owned, and a board with what the chosen one
##   is (rarity, stats, where it comes from) and Salvage for unequipped gear.
## Opened from the Camp's header (main.open_bench / open_items). Rules live in
## Crafting and main (craft, salvage); this only shows them.

signal closed

const INK := Codex.INK
const SHORT := Color(0.8, 0.2, 0.1)      # a material you don't have enough of
const ENOUGH := Color(0.25, 0.55, 0.2)

var game   # main.gd
var mode := "bench"
var root: Control
var tab := ""
var selected := ""          # recipe item id, material id, gear copy id or "card:<dino>"
var catalyst := ""          # the bench's chosen catalyst ("" = none)
var tab_buttons := {}
var list: HBoxContainer
var scroll: ScrollContainer
var detail: VBoxContainer
var dscroll: ScrollContainer
var board: PanelContainer
var shelf: VBoxContainer
var roster: Panel
var hero: AnimatedSprite2D
var bench_art: Control      # the workbench (drawn in code until the user's art exists)
var result_label: Label     # the bench's last craft ("EPIC STONE AXE!")
var _confirm := ""          # an action waiting for its confirming tap
var _tile_h := 150.0
var _kit := false
var _drag_target: ScrollContainer
var _dragging := false
var _drag_dist := 0.0
var _fling := 0.0
var last_crafted := ""      # (tests) the copy the last Craft made


static func tabs_of(m: String) -> Array:
	return ["weapon", "armor"] if m == "bench" else ["materials", "weapon", "armor", "cards"]


static func tab_name(t: String) -> String:
	return {"weapon": "Weapons", "armor": "Armor", "materials": "Materials", "cards": "Cards"}.get(t, t.capitalize())


func _ready() -> void:
	layer = 23
	visible = false
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	_kit = SceneKit.has()
	var bg := SceneKit.backdrop("dinosaur_camp")
	root.add_child(bg if bg else Market.backdrop("res://assets/bg/bg_1.png", Color(0.5, 0.68, 0.85)))
	var shade := ColorRect.new()   # a warmer, darker workshop light over the camp painting
	shade.color = Color(0.25, 0.12, 0.04, 0.35) if mode == "bench" else Color(0.1, 0.08, 0.05, 0.3)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(shade)
	hero = AnimatedSprite2D.new()
	hero.name = "Hero"
	hero.centered = false
	root.add_child(hero)
	if mode == "bench":
		bench_art = _bench_placeholder()
		root.add_child(bench_art)

	var header := HBoxContainer.new()
	header.name = "Header"
	header.set_anchors_preset(Control.PRESET_TOP_WIDE)
	header.offset_left = Tuning.UI_MARGIN
	header.offset_right = -Tuning.UI_MARGIN
	header.offset_top = 14
	header.add_theme_constant_override("separation", 12)
	root.add_child(header)
	var back := Market._button("‹ Back", Vector2(130, 52))
	back.name = "Back"
	back.pressed.connect(close_screen)
	header.add_child(back)
	if _kit:
		SceneKit.style_back(back)
	var title: Control = SceneKit.text_plaque("CRAFTING BENCH" if mode == "bench" else "ITEMS")
	if title == null:
		title = _plaque("CRAFTING BENCH" if mode == "bench" else "ITEMS")
		title.name = "TitleBanner"
	header.add_child(title)

	board = PanelContainer.new()
	board.name = "Board"
	var kit_panel := SceneKit.box("stats_panel")
	if kit_panel:
		kit_panel.content_margin_left = 62
		kit_panel.content_margin_right = 56
		kit_panel.content_margin_top = 40
		kit_panel.content_margin_bottom = 40
	board.add_theme_stylebox_override("panel", kit_panel if kit_panel else _paper())
	root.add_child(board)
	dscroll = ScrollContainer.new()
	dscroll.name = "DetailScroll"
	dscroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	board.add_child(dscroll)
	detail = VBoxContainer.new()
	detail.name = "Detail"
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail.add_theme_constant_override("separation", 6)
	dscroll.add_child(detail)

	shelf = VBoxContainer.new()
	shelf.name = "Shelf"
	shelf.add_theme_constant_override("separation", 8)
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 10)
	shelf.add_child(tabs)
	for t in tabs_of(mode):
		var tb := Market._button(tab_name(t), Vector2(160, 46))
		tb.name = "Tab_" + t
		tb.toggle_mode = true
		tb.pressed.connect(func(): show_tab(t))
		tabs.add_child(tb)
		tab_buttons[t] = tb
		if _kit:
			SceneKit.style_button(tb, "tab_inactive", "tab_active", 20)
	scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	shelf.add_child(scroll)
	list = HBoxContainer.new()
	list.name = "List"
	list.add_theme_constant_override("separation", 12)
	scroll.add_child(list)
	roster = Panel.new()
	roster.name = "Roster"
	var rp := SceneKit.box("roster_panel")
	roster.add_theme_stylebox_override("panel", rp if rp else _wood())
	roster.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(roster)
	root.add_child(shelf)
	root.resized.connect(_layout)


## The kit's layout, like the Camp's: the board anchored right, the shelf
## along the bottom, the hero (and the bench) on the left.
func _layout() -> void:
	var w := root.size.x
	var h := root.size.y
	var k := h / 1080.0
	var pw := maxf(680.0 * k, 560.0)
	board.position = Vector2(w - 30.0 * k - pw, 96.0 * k)
	board.size = Vector2(pw, 590.0 * k)
	var ground := 650.0 * k
	hero.position = Vector2(220.0 * k, ground)
	hero.scale = Vector2.ONE * (400.0 * k / 224.0)
	if bench_art:
		var bw := clampf(board.position.x - 380.0 * k - 24.0, 180.0, 420.0)
		bench_art.size = Vector2(bw, bw * 0.62)
		bench_art.position = Vector2(380.0 * k, ground - bench_art.size.y + 10.0)
	roster.position = Vector2(20.0 * k, 700.0 * k)
	roster.size = Vector2(w - 40.0 * k, h - 700.0 * k - 12.0 * k)
	shelf.position = roster.position + Vector2(56.0, 14.0)
	shelf.size = roster.size - Vector2(112.0, 26.0)
	_tile_h = maxf(shelf.size.y - 46.0 - 8.0 - 10.0, 110.0)
	for t in list.get_children():
		if t is Button:
			(t as Control).custom_minimum_size = Vector2(_tile_h * 0.9, _tile_h)


func open_screen(t := "") -> void:
	visible = true
	Market.enter(root)
	hero.sprite_frames = SpriteLib.character(Forms.ROK)
	hero.offset = -Vector2(Forms.get_data(Forms.ROK).pivot)
	hero.play("idle")
	if not hero.has_node("Gear"):
		var gl := GearLayer.new()
		gl.name = "Gear"
		hero.add_child(gl)
	(hero.get_node("Gear") as GearLayer).hero = String(Forms.get_data(Forms.ROK).id)
	_layout()
	show_tab(t if t != "" else (tab if tab != "" else tabs_of(mode)[0]))


func close_screen() -> void:
	visible = false
	closed.emit()


func show_tab(t: String) -> void:
	tab = t
	_confirm = ""
	catalyst = ""
	var ids := entries()
	selected = ids[0] if not ids.is_empty() else ""
	scroll.scroll_horizontal = 0
	refresh()


func select(id: String) -> void:
	if _drag_dist > 24.0:
		return   # it was a drag along the shelf, not a tap
	selected = id
	_confirm = ""
	catalyst = ""
	refresh()


## What the shelf lists on the current tab.
func entries() -> Array:
	if mode == "bench":
		var out: Array = Crafting.recipes().filter(func(k): return String(Gear.ITEMS[k].slot) == tab)
		out.sort_custom(func(a, b): return Crafting.learn_m(a) < Crafting.learn_m(b))
		return out
	match tab:
		"materials":
			return Crafting.materials().filter(func(m): return Crafting.have(m) > 0)
		"cards":
			return Gear.choices("weapon").filter(func(id): return String(id).begins_with(Gear.CARD_PREFIX))
	return Gear.choices(tab).filter(func(id): return not String(id).begins_with(Gear.CARD_PREFIX))


func refresh() -> void:
	for t in tab_buttons:
		(tab_buttons[t] as Button).button_pressed = t == tab
	for c in list.get_children():
		list.remove_child(c)
		c.queue_free()
	var ids := entries()
	for id in ids:
		list.add_child(_tile(id))
	if ids.is_empty():
		var l := _light("Nothing here yet." if mode == "items" else "No recipes.", 20)
		l.name = "Empty"
		list.add_child(l)
	for c in detail.get_children():
		detail.remove_child(c)
		c.queue_free()
	if mode == "bench":
		_bench_detail()
	else:
		_item_detail()


# ------------------------------------------------------------ tiles

func _tile(id: String) -> Button:
	var b := Button.new()
	b.name = id.replace(":", "_")
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(_tile_h * 0.9, _tile_h)
	var locked: bool = mode == "bench" and game.best_m < Crafting.learn_m(id)
	var r := _rarity_of(id)
	var sb := _tile_box(id == selected, r, locked)
	for s in ["normal", "hover", "pressed", "hover_pressed", "focus"]:
		b.add_theme_stylebox_override(s, sb)
	b.pressed.connect(func(): select(id))
	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	vb.offset_left = 10
	vb.offset_right = -10
	vb.offset_top = 10
	vb.offset_bottom = -8
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 2)
	b.add_child(vb)
	var ic := TextureRect.new()
	ic.texture = _icon(id)
	ic.custom_minimum_size = Vector2(0, _tile_h * 0.42)
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if locked:
		ic.modulate = Color(0.3, 0.3, 0.3, 0.8)
	vb.add_child(ic)
	var nm := _light(_name(id), 15 if _name(id).length() < 13 else 13, Crafting.RARITY_COLOR[r].lightened(0.35) if r > 0 else Color(1, 0.96, 0.85))
	nm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(nm)
	var sub := ""
	if mode == "bench":
		sub = ("%d m" % Crafting.learn_m(id)) if locked else ("Ready ●" if game.can_craft(id) else "")
	elif tab == "materials":
		sub = "×%d" % Crafting.have(id)
	elif tab == "cards":
		sub = "×%d" % int(Gear.cards.get(id.substr(Gear.CARD_PREFIX.length()), 0))
	elif _equipped_by(id) != "":
		sub = "EQUIPPED"
	if sub != "":
		var sl := _light(sub, 14, Color(1.0, 0.55, 0.45) if sub.begins_with("Ready") else Color(0.95, 0.88, 0.7))
		sl.name = "Sub"
		vb.add_child(sl)
	_ignore_mouse(b)
	return b


func _tile_box(chosen: bool, rarity: int, locked: bool) -> StyleBox:
	var sb := StyleBoxFlat.new()
	sb.set_corner_radius_all(14)
	sb.bg_color = Color(0.32, 0.18, 0.08, 0.85) if not locked else Color(0.2, 0.15, 0.1, 0.8)
	if chosen:
		sb.bg_color = sb.bg_color.lightened(0.18)
	sb.set_border_width_all(5 if chosen else 3)
	sb.border_color = Color(1.0, 0.85, 0.35) if chosen else Crafting.RARITY_COLOR[rarity].darkened(0.1 if rarity > 0 else 0.35)
	return sb


func _rarity_of(id: String) -> int:
	if mode == "items" and tab == "materials":
		return Crafting.mat_rarity(id)
	if mode == "items" and Gear.has(id):
		return Gear.rarity_of(id)
	return 0


func _icon(id: String) -> Texture2D:
	if mode == "items" and tab == "materials":
		return Crafting.icon(id)
	return Gear.icon(id)


func _name(id: String) -> String:
	if mode == "items" and tab == "materials":
		return Crafting.mat_name(id)
	return Gear.full_name(id) if mode == "items" else Gear.name_of(id)


## Which hero has this copy equipped ("" = none).
func _equipped_by(id: String) -> String:
	for h in Gear.equipped:
		if (Gear.equipped[h] as Dictionary).values().has(id):
			return String(h)
	return ""


# ------------------------------------------------------------ the bench

func _bench_detail() -> void:
	if selected == "":
		return
	var id := selected
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 10)
	detail.add_child(top)
	var head := _text(Gear.name_of(id), 28, INK)
	head.name = "Name"
	head.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.clip_text = true
	top.add_child(head)
	var craft_b := Market._button("Sure? Craft!" if _confirm == "craft" else "Craft", Vector2(170, 48))
	craft_b.name = "Craft"
	craft_b.disabled = not game.can_craft(id, catalyst)
	craft_b.pressed.connect(press_craft)
	top.add_child(craft_b)
	if _kit:
		SceneKit.style_button(craft_b, "button_primary", "", 22)
	result_label = _text("", 19, INK)
	result_label.name = "Result"
	result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result_label.visible = false
	detail.add_child(result_label)
	var it: Dictionary = Gear.ITEMS[id]
	var stats := "%s  ·  %s" % [String(it.slot).capitalize(), Gear.bonus_text(id)]
	if it.has("reach"):
		stats += "  ·  reach %d" % int(it.reach)
	if Gear.max_durability(id) > 0:
		stats += "  ·  %d hits" % Gear.max_durability(id)
	var st := _text(stats + " (Common)", 15, Color(0.45, 0.28, 0.12))
	st.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.add_child(st)
	if game.best_m < Crafting.learn_m(id):
		var lk := _text("Learn this recipe by running %d m in one run." % Crafting.learn_m(id), 17, SHORT)
		lk.name = "Locked"
		lk.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		detail.add_child(lk)
	# materials: have / need
	detail.add_child(_text("MATERIALS", 15, Color(0.75, 0.35, 0.1)))
	var grid := HFlowContainer.new()
	grid.name = "Materials"
	grid.add_theme_constant_override("h_separation", 18)
	detail.add_child(grid)
	var r := Crafting.recipe(id)
	for m in r:
		grid.add_child(_mat_row(m, Crafting.have(m), int(r[m])))
	# catalyst
	detail.add_child(_text("CATALYST (better odds)", 15, Color(0.75, 0.35, 0.1)))
	var cats := HFlowContainer.new()
	cats.name = "Catalysts"
	cats.add_theme_constant_override("h_separation", 6)
	cats.add_theme_constant_override("v_separation", 6)
	detail.add_child(cats)
	for c in [""] + Crafting.catalysts():
		var label := "None" if c == "" else "%s ×%d" % [Crafting.mat_name(c), Crafting.have(c)]
		var cb := Market._button(label, Vector2(0, 34))
		cb.name = "Cat_" + (c if c != "" else "none")
		cb.add_theme_font_size_override("font_size", 13)
		cb.toggle_mode = true
		cb.button_pressed = c == catalyst
		cb.disabled = c != "" and Crafting.have(c) < 1 + int(r.get(c, 0))
		cb.pressed.connect(func(): pick_catalyst(c))
		cats.add_child(cb)
	# odds
	var odds := Crafting.odds(catalyst)
	var ol := RichTextLabel.new()
	ol.name = "Odds"
	ol.bbcode_enabled = true
	ol.fit_content = true
	ol.scroll_active = false
	ol.add_theme_font_size_override("normal_font_size", 15)
	ol.add_theme_color_override("default_color", INK)
	var parts: Array = []
	for i in odds.size():
		parts.append("[color=#%s]%s %s[/color]" % [Crafting.RARITY_COLOR[i].darkened(0.35).to_html(false), Crafting.rarity_name(i), _pct(float(odds[i]))])
	ol.text = "Odds: " + "  ·  ".join(parts)
	detail.add_child(ol)
	var d := _text(String(it.desc), 15, INK)
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.add_child(d)
	if last_crafted != "" and Gear.base(last_crafted) == id and game.gear_owned.has(last_crafted):
		_show_result(last_crafted)


func _mat_row(m: String, have: int, need: int) -> Control:
	var hb := HBoxContainer.new()
	hb.name = "Mat_" + m
	hb.add_theme_constant_override("separation", 6)
	var ic := TextureRect.new()
	ic.texture = Crafting.icon(m)
	ic.custom_minimum_size = Vector2(30, 30)
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hb.add_child(ic)
	var l := _text("%s  %d/%d" % [Crafting.mat_name(m), have, need], 16, ENOUGH if have >= need else SHORT)
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hb.add_child(l)
	return hb


static func _pct(p: float) -> String:
	return "%d%%" % int(round(p * 100.0)) if p >= 0.01 or p == 0.0 else "<1%"


func pick_catalyst(c: String) -> void:
	catalyst = c
	_confirm = ""
	refresh()


## Craft takes two taps (the first arms it); the result shows on the board.
func press_craft() -> String:
	if not game.can_craft(selected, catalyst):
		game.audio.play("denied", 0.0)
		return ""
	if _confirm != "craft":
		_confirm = "craft"
		game.audio.play("click", 0.0)
		refresh()
		return ""
	_confirm = ""
	var copy: String = game.craft(selected, catalyst)
	if copy == "":
		return ""
	last_crafted = copy
	if catalyst != "" and Crafting.have(catalyst) < 1:
		catalyst = ""
	var r := Gear.rarity_of(copy)
	game.audio.play("unlock", 0.0, 1.0 + 0.08 * r)
	if r >= 2:
		game.audio.play("powerup_activate", 0.0, 1.0 + 0.1 * r)
	refresh()
	return copy


func _show_result(copy: String) -> void:
	var r := Gear.rarity_of(copy)
	result_label.visible = true
	result_label.text = "%s!  (%s)" % [Gear.full_name(copy).to_upper(), Gear.bonus_text(copy)]
	result_label.add_theme_color_override("font_color", Crafting.RARITY_COLOR[r].darkened(0.3))
	result_label.pivot_offset = Vector2(0, 14)
	result_label.scale = Vector2.ONE * 1.25
	result_label.create_tween().tween_property(result_label, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK)


# ------------------------------------------------------------ items

func _item_detail() -> void:
	if selected == "":
		var l := _text("Run, break things and bonk wild dinosaurs to find materials. Craft gear at the Crafting Bench.", 17, INK)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		detail.add_child(l)
		return
	var id := selected
	if tab == "materials":
		var r := Crafting.mat_rarity(id)
		detail.add_child(_head(Crafting.mat_name(id), r))
		detail.add_child(_text("%s material  ·  you have %d" % [Crafting.rarity_name(r), Crafting.have(id)], 16, Color(0.45, 0.28, 0.12)))
		var fr := _text("Found by: " + String(Crafting.mat(id).from), 16, INK)
		fr.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		detail.add_child(fr)
		var uses: Array = Crafting.recipes().filter(func(k): return Crafting.recipe(k).has(id)).map(func(k): return Gear.name_of(k))
		if Crafting.catalysts().has(id):
			uses.append("a catalyst for better odds")
		if not uses.is_empty():
			var ul := _text("Used for: " + ", ".join(uses), 16, INK)
			ul.name = "Uses"
			ul.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			detail.add_child(ul)
		return
	if tab == "cards":
		var d := id.substr(Gear.CARD_PREFIX.length())
		detail.add_child(_head(Gear.name_of(id), 0))
		detail.add_child(_text("Gives the weapon slot %s  ·  reach %d  ·  you have %d" % [Gear.bonus_text(id), int(Gear.CARD_REACH), int(Gear.cards.get(d, 0))], 16, INK))
		detail.add_child(_text("Dropped by wild %s and found in chests. Equip it at the Dinosaur Camp." % Herd.name_of(d), 15, Color(0.45, 0.28, 0.12)))
		return
	var r := Gear.rarity_of(id)
	detail.add_child(_head(Gear.full_name(id), r))
	var it: Dictionary = Gear.ITEMS[Gear.base(id)]
	var line := "%s %s  ·  %s" % [Crafting.rarity_name(r), String(it.slot), Gear.bonus_text(id)]
	if it.has("reach"):
		line += "  ·  reach %d" % int(it.reach)
	var sl := _text(line, 16, Color(0.45, 0.28, 0.12))
	sl.name = "Stats"
	sl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.add_child(sl)
	if Gear.max_durability(id) > 0:
		var br := Gear.broken(id)
		detail.add_child(_text("BROKEN · repair it at the Dinosaur Camp" if br else "Durability %d/%d hits" % [Gear.durability(id), Gear.max_durability(id)], 16, SHORT if br else INK))
	var d2 := _text(String(it.desc), 15, INK)
	d2.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.add_child(d2)
	var who := _equipped_by(id)
	if who != "":
		detail.add_child(_text("Equipped by %s (change it at the Dinosaur Camp)." % Heroes.name_of(who), 16, ENOUGH))
		return
	detail.add_child(_text("Not equipped · equip it at the Dinosaur Camp.", 15, Color(0.45, 0.28, 0.12)))
	var back := Crafting.salvage_return(Gear.base(id), r)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	detail.add_child(row)
	var sb := Market._button("Sure? Salvage" if _confirm == "salvage" else "Salvage", Vector2(170, 46))
	sb.name = "Salvage"
	sb.add_theme_font_size_override("font_size", 18)
	sb.pressed.connect(press_salvage)
	row.add_child(sb)
	var gl := _text("Returns " + Crafting.cost_text(back), 15, INK)
	gl.name = "SalvageReturn"
	gl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(gl)


func press_salvage() -> bool:
	if _confirm != "salvage":
		_confirm = "salvage"
		game.audio.play("click", 0.0)
		refresh()
		return false
	_confirm = ""
	var ok: bool = game.salvage(selected)
	if ok:
		var ids := entries()
		selected = ids[0] if not ids.is_empty() else ""
	refresh()
	return ok


func _head(t: String, rarity: int) -> Label:
	var l := _text(t, 28, Crafting.RARITY_COLOR[rarity].darkened(0.4) if rarity > 0 else INK)
	l.name = "Name"
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


# ------------------------------------------------------------ look

func _text(t: String, size: int, color: Color) -> Label:
	return Market._text(t, size, color)


func _light(t: String, size: int, color := Color(1, 0.96, 0.85)) -> Label:
	var l := Market._text(t, size, color)
	l.add_theme_color_override("font_outline_color", Color(0.22, 0.11, 0.04))
	l.add_theme_constant_override("outline_size", 6)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l


static func _ignore_mouse(n: Node) -> void:
	for c in n.get_children():
		if c is Control:
			(c as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
		_ignore_mouse(c)


## The title: the kit's blank plaque with the name on it (no baked-in art yet).
func _plaque(t: String) -> Control:
	var p := PanelContainer.new()
	var bx := SceneKit.box("title_blank")
	if bx:
		bx.content_margin_left = 44
		bx.content_margin_right = 44
		bx.content_margin_top = 6
		bx.content_margin_bottom = 10
	p.add_theme_stylebox_override("panel", bx if bx else _wood())
	var l := _light(t, 30)
	l.add_theme_font_override("font", SpriteLib.ui_font("heading"))
	p.add_child(l)
	return p


func _paper() -> StyleBoxFlat:
	var ds := StyleBoxFlat.new()
	ds.bg_color = Color(0.96, 0.9, 0.76, 0.97)
	ds.set_corner_radius_all(10)
	ds.set_border_width_all(6)
	ds.border_color = Color(0.45, 0.27, 0.12)
	ds.set_content_margin_all(16)
	return ds


func _wood() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.3, 0.17, 0.08, 0.9)
	sb.set_corner_radius_all(14)
	sb.set_border_width_all(4)
	sb.border_color = Color(0.18, 0.09, 0.03)
	sb.set_content_margin_all(10)
	return sb


## A stone workbench with a few tools, drawn in code until the user's
## Crafting Bench art arrives (assets/scenes/crafting_bench.png).
func _bench_placeholder() -> Control:
	var path := "res://assets/scenes/crafting_bench.png"
	if ResourceLoader.exists(path):
		var t := TextureRect.new()
		t.name = "Bench"
		t.texture = SpriteLib.tex(path)
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		t.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return t
	var c := Control.new()
	c.name = "Bench"
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.draw.connect(func():
		var s := c.size
		var dark := Color(0.2, 0.12, 0.06)
		var stone := Color(0.55, 0.52, 0.48)
		# legs: two stone blocks
		for x in [s.x * 0.12, s.x * 0.7]:
			c.draw_rect(Rect2(x - 3, s.y * 0.42 - 3, s.x * 0.18 + 6, s.y * 0.58 + 3), dark)
			c.draw_rect(Rect2(x, s.y * 0.42, s.x * 0.18, s.y * 0.58), stone.darkened(0.15))
		# the slab
		c.draw_rect(Rect2(-4, s.y * 0.28 - 4, s.x + 8, s.y * 0.16 + 8), dark)
		c.draw_rect(Rect2(0, s.y * 0.28, s.x, s.y * 0.16), stone)
		c.draw_rect(Rect2(0, s.y * 0.28, s.x, s.y * 0.04), stone.lightened(0.2))
		# a hammerstone, a flint blade and a coil of fibre on top
		c.draw_circle(Vector2(s.x * 0.2, s.y * 0.2), s.y * 0.08, dark)
		c.draw_circle(Vector2(s.x * 0.2, s.y * 0.2), s.y * 0.065, Color(0.65, 0.62, 0.58))
		c.draw_colored_polygon(PackedVector2Array([Vector2(s.x * 0.42, s.y * 0.27), Vector2(s.x * 0.5, s.y * 0.06), Vector2(s.x * 0.56, s.y * 0.27)]), Color(0.32, 0.35, 0.42))
		c.draw_arc(Vector2(s.x * 0.78, s.y * 0.2), s.y * 0.07, 0, TAU, 20, Color(0.45, 0.62, 0.25), 6.0)
		c.draw_arc(Vector2(s.x * 0.78, s.y * 0.2), s.y * 0.035, 0, TAU, 14, Color(0.45, 0.62, 0.25), 5.0))
	return c


# ------------------------------------------------------------ dragging

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
			scroll.scroll_horizontal -= int(drag.relative.x)
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
	if not visible or _dragging or absf(_fling) < 5.0 or _drag_target == null:
		return
	if _drag_target == scroll:
		scroll.scroll_horizontal += int(_fling * delta)
	else:
		_drag_target.scroll_vertical += int(_fling * delta)
	_fling = move_toward(_fling, 0.0, 2400.0 * delta)
