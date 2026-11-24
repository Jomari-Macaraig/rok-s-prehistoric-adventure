class_name Workshop
extends CanvasLayer
## Kora the Craftkeeper's workshop: two full screens built from the user's
## Crafting and Items kit (tools/prepare_workshop.py, assets/workshop/) to
## match the approved references, one script:
## - mode "bench": the CRAFTING BENCH. Kora works at her bench by the tool
##   rack and campfire. The parchment panel shows the chosen recipe (picture,
##   rarity, stats with icons, what it does), its MATERIALS as cards (have /
##   need, a check when there's enough), the CATALYST choices, the rarity
##   odds and the big CRAFT button (a second tap confirms; Kora swings her
##   mallet and a sparkle bursts on the strike). Below, the Weapons / Armor
##   shelf of recipe cards ("Ready" or the distance that teaches it).
## - mode "items": the ITEMS screen. Kora at her open storage chest; a panel
##   with Materials / Weapons / Armor / Cards tabs, a grid of item cards in
##   their rarity frames (EQUIPPED tag), and the chosen one's page: stats,
##   durability bar, description, where it's equipped, SALVAGE (two taps)
##   and what salvaging RETURNS.
## Everything is laid out on the kit's 1536x864 design canvas (its demo
## layouts, workshop.json), scaled to fit the screen and centred; the
## workshop background covers the rest. Opened from the Dinosaur Camp's
## header (main.open_bench / open_items); the top-right button switches
## between the two. Rules live in Crafting and main (craft, salvage).

signal closed

const DIR := "res://assets/workshop/"
const INK := Color("#4e2b1b")
const LIGHT := Color("#fff0cc")
const SHORT := Color("#a23921")
const ENOUGH := Color("#35782e")
const MUTED := Color("#6d5033")
## Rarity text colours (the kit's), Common .. Legendary.
const RARITY_TEXT := [Color("#73614c"), Color("#2b7f32"), Color("#196aab"), Color("#8836b4"), Color("#9a731b")]
const CARD_FRAME := ["card_common", "card_uncommon", "card_rare", "card_epic", "card_legendary"]

var game   # main.gd
var mode := "bench"
var root: Control
var canvas: Control           # the 1536x864 design canvas
var tab := ""
var selected := ""            # recipe item id, material id, gear copy id or "card:<dino>"
var catalyst := ""            # the bench's chosen catalyst ("" = none)
var tab_buttons := {}
var list: Container           # the tiles (recipe shelf or item grid)
var scroll: ScrollContainer
var detail: Control           # the panel's contents, rebuilt on every change
var kora: AnimatedSprite2D
var sparkle: AnimatedSprite2D
var result_label: Label
var kora_bubble: Panel   # her speech bubble beside her head (KORA_LINES)
var kora_label: Label
var kora_tail: Polygon2D
var kora_plate: Label             # her name on the scene kit's wooden plank (as Elder Numa's and Ugo's)
var _kora_said := {}              # pool -> its last line (no repeats)
var last_crafted := ""        # (tests) the copy the last Craft made
var _confirm := ""            # an action waiting for its confirming tap
var _meta := {}
var _dragging := false
var _drag_dist := 0.0
var _fling := 0.0


static func tabs_of(m: String) -> Array:
	return ["weapon", "armor"] if m == "bench" else ["materials", "weapon", "armor", "cards"]


static func tab_name(t: String) -> String:
	return {"weapon": "Weapons", "armor": "Armor", "materials": "Materials", "cards": "Cards"}.get(t, t.capitalize())


# ------------------------------------------------------------ building blocks

func _tex(name: String) -> Texture2D:
	return SpriteLib.tex(DIR + name + ".png")


func _img(tex: Texture2D, r: Rect2, parent: Node, node_name := "") -> TextureRect:
	var t := TextureRect.new()
	t.texture = tex
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.position = r.position
	t.size = r.size
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if node_name != "":
		t.name = node_name
	parent.add_child(t)
	return t


## A kit piece as a StyleBox: panels and card frames 9-slice (their kit
## margins), pills, tabs, signs and bars stretch whole.
func _box(name: String) -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	sb.texture = _tex(name)
	var m := float((_meta.get("nine", {}) as Dictionary).get(name, 0))
	sb.texture_margin_left = m
	sb.texture_margin_right = m
	sb.texture_margin_top = m
	sb.texture_margin_bottom = m
	return sb


func _panel(name: String, r: Rect2, parent: Node, node_name := "") -> Panel:
	var p := Panel.new()
	p.add_theme_stylebox_override("panel", _box(name))
	p.position = r.position
	p.size = r.size
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if node_name != "":
		p.name = node_name
	parent.add_child(p)
	return p


func _label(text: String, r: Rect2, size: int, color: Color, parent: Node, bold := true, align := HORIZONTAL_ALIGNMENT_CENTER, outline := 0) -> Label:
	var l := Label.new()
	l.text = text
	l.position = r.position
	l.size = r.size
	l.horizontal_alignment = align
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", SpriteLib.ui_font("heading" if bold else "body"))
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if outline > 0:
		l.add_theme_color_override("font_outline_color", Color(0.22, 0.11, 0.04))
		l.add_theme_constant_override("outline_size", outline * 3)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l


## A wrapping paragraph: autowrap is on before the size is set, so the label
## keeps its width instead of growing to one long line.
func _para(text: String, r: Rect2, size: int, color: Color, parent: Node, bold := false, align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := _label("", r, size, color, parent, bold, align)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	l.text = text
	l.size = r.size
	return l


## A button painted with a kit piece (tabs, CRAFT, SALVAGE): light text with
## an outline; pressing darkens it.
func _button(text: String, piece: String, r: Rect2, size: int, parent: Node, node_name: String, cb: Callable) -> Button:
	var b := Button.new()
	b.name = node_name
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.position = r.position
	b.size = r.size
	for st in ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]:
		b.add_theme_stylebox_override(st, _box(piece))
	b.add_theme_font_override("font", SpriteLib.ui_font("heading"))
	b.add_theme_font_size_override("font_size", size)
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(c, LIGHT)
	b.add_theme_color_override("font_disabled_color", LIGHT.darkened(0.25))
	b.add_theme_color_override("font_outline_color", Color(0.22, 0.11, 0.04))
	b.add_theme_constant_override("outline_size", 6)
	b.button_down.connect(func(): b.self_modulate = Color(0.85, 0.85, 0.85))
	b.button_up.connect(func(): b.self_modulate = Color.WHITE)
	b.pressed.connect(cb)
	parent.add_child(b)
	return b


func _disable(b: Button, off: bool) -> void:
	b.disabled = off
	b.modulate = Color(0.6, 0.6, 0.6, 0.85) if off else Color.WHITE


## A rounded pill (rarity tags, the shelf's status bars).
func _pill(r: Rect2, color: Color, parent: Node) -> Panel:
	var p := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(int(r.size.y * 0.5))
	p.add_theme_stylebox_override("panel", sb)
	p.position = r.position
	p.size = r.size
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(p)
	return p


func _frames(clips: Array) -> SpriteFrames:
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	var anims: Dictionary = _meta.get("animations", {})
	for clip in clips:
		if not anims.has(clip):
			continue
		var a: Dictionary = anims[clip]
		SpriteLib._sheet_frames(sf, clip, _tex(String(a.sheet).get_basename()), Vector2(a.frame[0], a.frame[1]), a.times, bool(a.loop))
	return sf


# ------------------------------------------------------------ the scene

func _ready() -> void:
	layer = 23
	visible = false
	_meta = JSON.parse_string(FileAccess.get_file_as_string(DIR + "workshop.json")) if FileAccess.file_exists(DIR + "workshop.json") else {}
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	var bg := TextureRect.new()   # covers any screen shape
	bg.name = "Backdrop"
	bg.texture = _tex("background")
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bg)
	canvas = Control.new()
	canvas.name = "Canvas"
	canvas.size = Vector2(1536, 864)
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(canvas)
	_build_scene()
	_build_header()
	if mode == "bench":
		_panel("panel_parchment", Rect2(650, 105, 860, 525), canvas, "Parchment")
		_panel("panel_inventory", Rect2(18, 650, 1494, 198), canvas, "Shelf")
		for i in tabs_of(mode).size():
			var t: String = tabs_of(mode)[i]
			tab_buttons[t] = _button(tab_name(t), "tab_brown", Rect2(72 + 212 * i, 626, 202, 53), 22, canvas, "Tab_" + t, show_tab.bind(t))
		scroll = ScrollContainer.new()
		scroll.position = Vector2(40, 690)
		scroll.size = Vector2(1456, 150)
		scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
		canvas.add_child(scroll)
		var hb := HBoxContainer.new()
		hb.name = "List"
		hb.add_theme_constant_override("separation", 14)
		scroll.add_child(hb)
		list = hb
	else:
		_panel("panel_inventory", Rect2(557, 107, 955, 737), canvas, "Inventory")
		for i in tabs_of(mode).size():
			var t: String = tabs_of(mode)[i]
			tab_buttons[t] = _button(tab_name(t), "tab_brown", Rect2(587 + 224 * i, 129, 214, 59), 22, canvas, "Tab_" + t, show_tab.bind(t))
		_panel("panel_parchment", Rect2(1020, 211, 468, 608), canvas, "Parchment")
		scroll = ScrollContainer.new()
		scroll.position = Vector2(584, 212)
		scroll.size = Vector2(430, 612)
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
		canvas.add_child(scroll)
		var g := GridContainer.new()
		g.name = "List"
		g.add_theme_constant_override("h_separation", 12)
		g.add_theme_constant_override("v_separation", 16)
		scroll.add_child(g)
		list = g
	detail = Control.new()
	detail.name = "Detail"
	detail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(detail)
	root.resized.connect(_layout)


## The workshop: tool rack, campfire, Kora (between the bench's two layers
## at the bench; behind her open chest on the Items screen) and her name.
func _build_scene() -> void:
	_img(_tex("tool_rack"), Rect2(18, 205, 190, 340), canvas)
	var fire := Node2D.new()
	fire.name = "Campfire"
	fire.position = Vector2(520, 455) if mode == "bench" else Vector2(455, 455)
	fire.scale = Vector2.ONE * 0.22
	canvas.add_child(fire)
	var base := Sprite2D.new()
	base.texture = _tex("firepit_base")
	base.position = Vector2(0, -163.5)
	fire.add_child(base)
	var flame := AnimatedSprite2D.new()
	flame.sprite_frames = _frames(["fire_loop"])
	flame.centered = false
	flame.position = Vector2(0, -165)
	flame.offset = Vector2(-192, -397)
	fire.add_child(flame)
	if flame.sprite_frames.has_animation("fire_loop"):
		flame.play("fire_loop")
	if mode == "bench":
		_img(_tex("workbench_rear"), Rect2(20, 390, 610, 280), canvas)
	kora = AnimatedSprite2D.new()
	kora.name = "Kora"
	kora.sprite_frames = _frames(["idle", "craft", "present", "wave"])
	kora.centered = false
	kora.offset = Vector2(-206, -499)
	kora.position = Vector2(285, 630) if mode == "bench" else Vector2(265, 735)
	kora.scale = Vector2.ONE * (1.0 if mode == "bench" else 1.07)
	canvas.add_child(kora)
	kora.animation_finished.connect(func(): kora.play("idle"))
	kora.frame_changed.connect(_kora_frame)
	if kora.sprite_frames.has_animation("idle"):
		kora.play("idle")
	sparkle = AnimatedSprite2D.new()
	sparkle.name = "Sparkle"
	sparkle.sprite_frames = _frames(["craft_success"])
	sparkle.centered = false
	sparkle.offset = Vector2(-192, -270)
	sparkle.position = Vector2(31, -140)
	sparkle.visible = false
	sparkle.z_index = 2
	sparkle.animation_finished.connect(sparkle.hide)
	kora.add_child(sparkle)
	if mode == "bench":
		_img(_tex("workbench_front"), Rect2(20, 390, 610, 280), canvas)
		_label("Craftkeeper", Rect2(220, 524, 200, 55), 22, INK, canvas).name = "Plaque"
	else:
		_img(_tex("storage_chest_open"), Rect2(30, 444, 500, 375), canvas)
		_label("Craftkeeper", Rect2(175, 682, 210, 64), 25, INK, canvas).name = "Plaque"
	# her name on a wooden plank (the user's call: the same wood as Numa's and Ugo's)
	kora_plate = SceneKit.badge("Kora", "button_secondary", 24)
	if kora_plate:
		kora_plate.name = "KoraPlate"
		kora_plate.size = Vector2(170, 0)
		kora_plate.position = Vector2(235, 472) if mode == "bench" else Vector2(195, 822)
		canvas.add_child(kora_plate)
	_build_bubble()


func _build_header() -> void:
	var back := TextureButton.new()
	back.name = "Back"
	back.texture_normal = _tex("button_back")
	back.ignore_texture_size = true
	back.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	back.position = Vector2(16, 16)
	back.size = Vector2(76, 76)
	back.pressed.connect(close_screen)
	canvas.add_child(back)
	var w := 500.0 if mode == "bench" else 320.0
	var sign := _panel("title_sign", Rect2(106, 9, w, 91), canvas, "TitleBanner")
	_label("CRAFTING BENCH" if mode == "bench" else "ITEMS", Rect2(21, 14, w - 42, 57), 34, LIGHT, sign, true, HORIZONTAL_ALIGNMENT_CENTER, 3)
	_button("Items" if mode == "bench" else "Crafting", "tab_brown", Rect2(1292, 20, 218, 55), 22, canvas, "Switch", _switch)


## The top-right button: to the other workshop screen.
func _switch() -> void:
	if mode == "bench":
		visible = false
		game.open_items()
	else:
		if not game.bench_open():
			game.audio.play("denied", 0.0)
			return
		visible = false
		game.open_bench()


## Scale the design canvas to fit the screen, centred.
func _layout() -> void:
	var vs := root.size if root.size.x > 0.0 else root.get_viewport_rect().size
	var s := minf(vs.x / canvas.size.x, vs.y / canvas.size.y)
	canvas.scale = Vector2(s, s)
	canvas.position = (vs - canvas.size * s) * 0.5


func open_screen(t := "") -> void:
	visible = true
	Market.enter(root)
	_layout()
	show_tab(t if t != "" else (tab if tab != "" else tabs_of(mode)[0]))
	kora_play("wave")
	kora_say("greet_bench" if mode == "bench" else ("greet_items" if not entries().is_empty() else "empty"))


func close_screen() -> void:
	visible = false
	closed.emit()


func kora_play(clip: String) -> void:
	if kora and kora.sprite_frames.has_animation(clip):
		kora.play(clip)


## Kora's mallet strike (craft frame `impact`): the success sparkle bursts there.
func _kora_frame() -> void:
	if String(kora.animation) != "craft":
		return
	var impact: int = int(((_meta.get("animations", {}) as Dictionary).get("craft", {}) as Dictionary).get("impact", 4))
	if kora.frame == impact and sparkle.sprite_frames.has_animation("craft_success"):
		sparkle.visible = true
		sparkle.play("craft_success")


func show_tab(t: String) -> void:
	tab = t
	_confirm = ""
	catalyst = ""
	var ids := entries()
	selected = ids[0] if not ids.is_empty() else ""
	scroll.scroll_horizontal = 0
	scroll.scroll_vertical = 0
	refresh()


func select(id: String) -> void:
	if _drag_dist > 24.0:
		return   # it was a drag, not a tap
	var changed := id != selected
	if changed:
		kora_play("present")
	selected = id
	_confirm = ""
	catalyst = ""
	refresh()
	if changed:
		_kora_about(id)


## What the shelf or grid lists on the current tab.
func entries() -> Array:
	if mode == "bench":
		var out: Array = Crafting.recipes().filter(func(k): return String(Gear.ITEMS[k].slot) == tab)
		out.sort_custom(func(a, b): return Crafting.learn_m(a) < Crafting.learn_m(b))
		return out
	match tab:
		"materials":
			return Crafting.materials().filter(func(m): return Crafting.have(m) > 0)
		"cards":
			var ds: Array = Gear.cards.keys().filter(func(d): return int(Gear.cards[d]) > 0)
			ds.sort()
			return ds.map(func(d): return Gear.CARD_PREFIX + String(d))
	return Gear.choices(tab)


func refresh() -> void:
	for t in tab_buttons:
		var b: Button = tab_buttons[t]
		for st in ["normal", "hover", "pressed", "hover_pressed", "focus"]:
			b.add_theme_stylebox_override(st, _box("tab_teal" if t == tab else "tab_brown"))
	for c in list.get_children():
		list.remove_child(c)
		c.queue_free()
	if list is GridContainer:
		(list as GridContainer).columns = 3 if tab == "materials" else 2
	for id in entries():
		list.add_child(_tile(id))
	for c in detail.get_children():
		detail.remove_child(c)
		c.queue_free()
	result_label = null
	if mode == "bench":
		_bench_detail()
	else:
		_item_detail()


# ------------------------------------------------------------ tiles

func _tile(id: String) -> Button:
	var b := Button.new()
	b.name = id.replace(":", "_")
	b.focus_mode = Control.FOCUS_NONE
	b.flat = true
	b.pressed.connect(func(): select(id))
	var chosen := id == selected
	if mode == "bench":
		b.custom_minimum_size = Vector2(195, 138)
		var locked: bool = game.best_m < Crafting.learn_m(id)
		_panel("card_selected" if chosen else "card_common", Rect2(Vector2.ZERO, b.custom_minimum_size), b)
		var ic := _img(Gear.icon(id), Rect2(30, 8, 135, 68), b)
		if locked:
			ic.modulate = Color(0.55, 0.5, 0.45)
			_img(_tex("badge_lock"), Rect2(156, 6, 30, 30), b, "Lock")
		_label(Gear.name_of(id), Rect2(4, 76, 187, 29), 18, INK, b)
		_pill(Rect2(22, 106, 151, 24), Color(0.3, 0.17, 0.08, 0.85), b)
		var ready: bool = game.can_craft(id)
		var st := ("%d m" % Crafting.learn_m(id)) if locked else ("● Ready" if ready else "Need materials")
		_label(st, Rect2(22, 106, 151, 24), 15, Color("#9fe07a") if ready else LIGHT, b).name = "Sub"
		return b
	var r := _rarity_of(id)
	if tab == "materials":
		b.custom_minimum_size = Vector2(132, 182)
		if chosen:   # the gold frame glows behind the rarity frame
			_panel("card_selected", Rect2(-7, -7, 146, 196), b)
		_panel(CARD_FRAME[r], Rect2(Vector2.ZERO, b.custom_minimum_size), b)
		_img(Crafting.icon(id), Rect2(23, 14, 86, 92), b)
		_label(Crafting.mat_name(id), Rect2(3, 110, 126, 34), 16 if Crafting.mat_name(id).length() < 12 else 13, INK, b)
		_label("×%d" % Crafting.have(id), Rect2(3, 144, 126, 26), 18, INK, b).name = "Sub"
		return b
	if tab == "cards":
		var d := id.substr(Gear.CARD_PREFIX.length())
		b.custom_minimum_size = Vector2(198, 400)
		if chosen:
			_panel("card_selected", Rect2(-7, -7, 212, 308), b)
		_img(CardView.icon(d), Rect2(2, 2, 194, 290), b)
		_para(Gear.name_of(id), Rect2(0, 300, 198, 56), 19, LIGHT, b, true, HORIZONTAL_ALIGNMENT_CENTER)
		_label("×%d" % int(Gear.cards.get(d, 0)), Rect2(0, 354, 198, 30), 20, LIGHT, b).name = "Sub"
		return b
	b.custom_minimum_size = Vector2(198, 282)
	if chosen:   # the gold frame glows behind the rarity frame
		_panel("card_selected", Rect2(-8, -8, 214, 298), b)
	_panel(CARD_FRAME[r], Rect2(Vector2.ZERO, b.custom_minimum_size), b)
	_label(Crafting.rarity_name(r).to_upper(), Rect2(5, 22, 188, 28), 16, RARITY_TEXT[r], b)
	var equipped := _equipped_by(id) != ""
	_img(Gear.icon(id), Rect2(33, 52, 132, 108 if equipped else 140), b)
	var nl := _label(Gear.full_name(id), Rect2(10, 194, 178, 62), 20 if Gear.full_name(id).length() < 15 else 17, INK, b)
	nl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nl.size = Vector2(178, 62)
	if equipped:
		_img(_tex("badge_check"), Rect2(10, 168, 30, 30), b)
		_label("EQUIPPED", Rect2(42, 170, 150, 27), 15, Color("#2c8232"), b, true, HORIZONTAL_ALIGNMENT_LEFT).name = "Sub"
	return b


func _rarity_of(id: String) -> int:
	if tab == "materials":
		return clampi(Crafting.mat_rarity(id), 0, 4)
	if Gear.has(id):
		return clampi(Gear.rarity_of(id), 0, 4)
	return 0


## Which hero has this copy equipped ("" = none).
func _equipped_by(id: String) -> String:
	for h in Gear.equipped:
		if (Gear.equipped[h] as Dictionary).values().has(id):
			return String(h)
	return ""


## "+2 Power | Reach 175 | 40 hits", each with its stat icon, in a row.
func _stat_row(parts: Array, pos: Vector2, size: int, parent: Node, node_name: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = node_name
	row.position = pos
	row.add_theme_constant_override("separation", 8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(row)
	for i in parts.size():
		if i > 0:
			var sep := _label("|", Rect2(), size, MUTED, row)
			sep.custom_minimum_size = Vector2(10, 30)
		var p: Array = parts[i]
		var ic := TextureRect.new()
		ic.texture = _tex(p[0])
		ic.custom_minimum_size = Vector2(28, 28)
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(ic)
		var l := _label(String(p[1]), Rect2(), size, INK, row)
		l.custom_minimum_size = Vector2(0, 32)
	return row


## A recipe's (Common) stats for _stat_row.
func _stats(id: String) -> Array:
	var it: Dictionary = Gear.ITEMS[Gear.base(id)]
	var parts: Array = [["stat_power", Gear.bonus_text(id)]]
	if it.has("reach"):
		parts.append(["stat_reach", "Reach %d" % int(it.reach)])
	if Gear.max_durability(id) > 0:
		parts.append(["stat_durability", "%d hits" % Gear.max_durability(id)])
	return parts


# ------------------------------------------------------------ the bench

func _bench_detail() -> void:
	if selected == "":
		return
	var id := selected
	var it: Dictionary = Gear.ITEMS[id]
	_img(Gear.icon(id), Rect2(690, 151, 212, 254), detail, "Picture")
	_label(Gear.name_of(id), Rect2(950, 151, 330, 52), 38, INK, detail, true, HORIZONTAL_ALIGNMENT_LEFT).name = "Name"
	_pill(Rect2(1285, 163, 146, 29), Color(0.6, 0.56, 0.5, 0.75), detail)
	_label("COMMON", Rect2(1285, 163, 146, 29), 18, Color("#fff8e8"), detail)
	_stat_row(_stats(id), Vector2(950, 204), 20, detail, "Stats")
	_para(String(it.desc), Rect2(950, 240, 490, 40), 18, INK, detail)
	_label("MATERIALS", Rect2(950, 280, 470, 30), 20, INK, detail, true, HORIZONTAL_ALIGNMENT_LEFT)
	var mats := Control.new()
	mats.name = "Materials"
	mats.mouse_filter = Control.MOUSE_FILTER_IGNORE
	detail.add_child(mats)
	var r := Crafting.recipe(id)
	var n := r.size()
	var w := minf(154.0, (530.0 - 8.0 * (n - 1)) / maxf(n, 1))
	var i := 0
	for m in r:
		var have := Crafting.have(m)
		var need := int(r[m])
		var x := 950.0 + i * (w + 8.0)
		var card := _panel("card_common", Rect2(x, 308, w, 106), mats, "Mat_" + m)
		_img(Crafting.icon(m), Rect2((w - 74.0) * 0.5, 4, 74, 57), card)
		_label("%s %d/%d" % [Crafting.mat_name(m), have, need], Rect2(3, 63, w - 6, 31), 19 if w >= 150.0 else 15, ENOUGH if have >= need else SHORT, card)
		if have >= need:
			_img(_tex("badge_check"), Rect2(w - 30, -8, 34, 32), card)
		i += 1
	_label("CATALYST · BETTER ODDS", Rect2(689, 421, 730, 28), 19, INK, detail, true, HORIZONTAL_ALIGNMENT_LEFT)
	var cats := Control.new()
	cats.name = "Catalysts"
	cats.mouse_filter = Control.MOUSE_FILTER_IGNORE
	detail.add_child(cats)
	var opts: Array = [""] + Crafting.catalysts()
	for k in opts.size():
		var c: String = opts[k]
		var label := "None" if c == "" else "%s ×%d" % [Crafting.mat_name(c), Crafting.have(c)]
		var cb := _button(label, "tab_teal" if c == catalyst else "tab_brown", Rect2(689 + 151 * k, 454, 144, 57), 15, cats,
				"Cat_" + (c if c != "" else "none"), pick_catalyst.bind(c))
		_disable(cb, c != "" and Crafting.have(c) < 1 + int(r.get(c, 0)))
	var odds := Control.new()
	odds.name = "Odds"
	odds.mouse_filter = Control.MOUSE_FILTER_IGNORE
	detail.add_child(odds)
	var o := Crafting.odds(catalyst)
	var xs := [691, 834, 1016, 1157, 1282]
	for k in o.size():
		_label("%s %s" % [Crafting.rarity_name(k), _pct(float(o[k]))], Rect2(xs[k], 514, 182, 26), 16, RARITY_TEXT[k], odds, true, HORIZONTAL_ALIGNMENT_LEFT)
	var craft := _button("SURE?" if _confirm == "craft" else "CRAFT", "button_craft_green", Rect2(1054, 552, 370, 57), 26, detail, "Craft", press_craft)
	_img(_tex("icon_craft"), Rect2(40, 6, 42, 44), craft)
	_disable(craft, not game.can_craft(id, catalyst))
	result_label = _label("", Rect2(689, 556, 350, 50), 20, INK, detail, true, HORIZONTAL_ALIGNMENT_LEFT)
	result_label.name = "Result"
	result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result_label.size = Vector2(350, 50)
	result_label.visible = false
	if game.best_m < Crafting.learn_m(id):
		var lk := _label("Run %d m in one run to learn this." % Crafting.learn_m(id), Rect2(689, 556, 350, 50), 18, SHORT, detail, true, HORIZONTAL_ALIGNMENT_LEFT)
		lk.name = "Locked"
		lk.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lk.size = Vector2(350, 50)
	elif last_crafted != "" and Gear.base(last_crafted) == id and game.gear_owned.has(last_crafted):
		_show_result(last_crafted)


static func _pct(p: float) -> String:
	return "%d%%" % int(round(p * 100.0)) if p >= 0.01 or p == 0.0 else "<1%"


func pick_catalyst(c: String) -> void:
	catalyst = c
	_confirm = ""
	refresh()


## Craft takes two taps (the first arms it). Kora swings her mallet, the
## sparkle bursts on the strike, and the result shows on the panel.
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
	kora_play("craft")
	var r := Gear.rarity_of(copy)
	kora_say("crafted_legendary" if r >= 4 else ("crafted_rare" if r >= 2 else "crafted"), Gear.full_name(copy))
	game.audio.play("stomp", 0.05, 1.4, -2.0)
	game.audio.play("unlock", 0.0, 1.0 + 0.08 * r)
	if r >= 2:
		game.audio.play("powerup_activate", 0.0, 1.0 + 0.1 * r)
	refresh()
	return copy


func _show_result(copy: String) -> void:
	var r := Gear.rarity_of(copy)
	result_label.visible = true
	result_label.text = "%s!" % Gear.full_name(copy).to_upper()
	result_label.add_theme_color_override("font_color", RARITY_TEXT[r])
	result_label.pivot_offset = Vector2(0, 25)
	result_label.scale = Vector2.ONE * 1.2
	result_label.create_tween().tween_property(result_label, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK)


# ------------------------------------------------------------ items

func _item_detail() -> void:
	if selected == "":
		_para("Nothing here yet. Break things, bonk wild dinosaurs and open chests to find materials, then craft at the Crafting Bench.",
				Rect2(1076, 270, 366, 200), 19, INK, detail, false, HORIZONTAL_ALIGNMENT_CENTER)
		return
	var id := selected
	if tab == "materials":
		var r := Crafting.mat_rarity(id)
		_label(Crafting.mat_name(id), Rect2(1076, 250, 366, 50), 29, RARITY_TEXT[r] if r > 0 else INK, detail, true, HORIZONTAL_ALIGNMENT_LEFT).name = "Name"
		_img(Crafting.icon(id), Rect2(1072, 305, 140, 140), detail, "Picture")
		_pill(Rect2(1220, 318, 150, 30), RARITY_TEXT[r], detail)
		_label(Crafting.rarity_name(r).to_upper(), Rect2(1220, 318, 150, 30), 16, Color.WHITE, detail)
		_label("You have %d" % Crafting.have(id), Rect2(1220, 360, 240, 34), 22, INK, detail, true, HORIZONTAL_ALIGNMENT_LEFT).name = "Stats"
		_para("Found by: " + String(Crafting.mat(id).from), Rect2(1076, 465, 366, 120), 18, INK, detail).name = "Found"
		var uses: Array = Crafting.recipes().filter(func(k): return Crafting.recipe(k).has(id)).map(func(k): return Gear.name_of(k))
		if Crafting.catalysts().has(id):
			uses.append("a catalyst for better odds")
		_para("Used for: " + (", ".join(uses) if not uses.is_empty() else "gear still to come (keep it!)"), Rect2(1076, 595, 366, 160), 18, INK, detail, true).name = "Uses"
		return
	if tab == "cards":
		var d := id.substr(Gear.CARD_PREFIX.length())
		_label(Gear.name_of(id), Rect2(1050, 245, 400, 50), 29, INK, detail).name = "Name"
		_img(CardView.icon(d), Rect2(1143, 300, 204, 300), detail, "Picture")
		_label("%s  ·  ×%d (%d free)" % [Gear.bonus_text(id), int(Gear.cards.get(d, 0)), Gear.free_cards(d)], Rect2(1051, 612, 402, 34), 20, INK, detail).name = "Stats"
		_para("Dropped by wild %s and found in chests. Slot it into a weapon's card slot at the Dinosaur Camp: it adds this on top of the weapon." % Herd.name_of(d), Rect2(1076, 655, 366, 120), 18, INK, detail, false, HORIZONTAL_ALIGNMENT_CENTER)
		return
	var r := Gear.rarity_of(id)
	var it: Dictionary = Gear.ITEMS[Gear.base(id)]
	var nm := _label(Gear.full_name(id), Rect2(1050, 238, 410, 50), 29 if Gear.full_name(id).length() < 18 else 24, RARITY_TEXT[r] if r > 0 else INK, detail)
	nm.name = "Name"
	_pill(Rect2(1190, 288, 130, 26), RARITY_TEXT[r], detail)
	_label(Crafting.rarity_name(r).to_upper(), Rect2(1190, 288, 130, 26), 15, Color.WHITE, detail)
	_img(Gear.icon(id), Rect2(1055, 322, 138, 160), detail, "Picture")
	var stats := Control.new()
	stats.name = "Stats"
	stats.mouse_filter = Control.MOUSE_FILTER_IGNORE
	detail.add_child(stats)
	var y := 330.0
	_stat_row([["stat_power", Gear.bonus_text(id)]], Vector2(1206, y), 20, stats, "Bonus")
	if it.has("reach"):
		y += 42.0
		_stat_row([["stat_reach", "Reach %d" % int(it.reach)]], Vector2(1206, y), 20, stats, "Reach")
	if Gear.max_durability(id) > 0:
		y += 42.0
		var br := Gear.worn_out(id)
		_stat_row([["stat_durability", "WORN OUT (half)" if br else "%d/%d runs left" % [Gear.durability(id), Gear.max_durability(id)]]], Vector2(1206, y), 17, stats, "Durability")
		_panel("durability_track", Rect2(1206, y + 38, 240, 19), stats)
		var frac := clampf(float(Gear.durability(id)) / float(Gear.max_durability(id)), 0.0, 1.0)
		if frac > 0.0:
			var clip := Control.new()
			clip.clip_contents = true
			clip.position = Vector2(1210, y + 41)
			clip.size = Vector2(232.0 * frac, 13)
			clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
			stats.add_child(clip)
			var fill := TextureRect.new()
			fill.texture = _tex("durability_fill")
			fill.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			fill.stretch_mode = TextureRect.STRETCH_SCALE
			fill.size = Vector2(232, 13)
			clip.add_child(fill)
	_para(String(it.desc), Rect2(1066, 488, 380, 60), 18, INK, detail)
	var who := _equipped_by(id)
	_pill(Rect2(1060, 552, 388, 52), Color(0.85, 0.72, 0.5, 0.45), detail)
	var eq := _label(("Equipped by %s\nChange it at the Dinosaur Camp." % Heroes.name_of(who)) if who != "" else "Not equipped\nEquip it at the Dinosaur Camp.",
			Rect2(1074, 552, 366, 52), 16, ENOUGH if who != "" else INK, detail, true, HORIZONTAL_ALIGNMENT_LEFT)
	eq.name = "Equip"
	# REPAIR for worn or broken gear (the user's request: Kora mends it here
	# too, not only at the Camp); beside SALVAGE when it isn't equipped
	var worn := Gear.repair_cost(id) > 0
	if worn:
		var rw := 354.0 if who != "" else 172.0
		var rb := _button("SURE?" if _confirm == "repair" else "REPAIR", "button_craft_green", Rect2(1077, 618, rw, 60), 25 if who != "" else 22, detail, "Repair", press_repair)
		rb.tooltip_text = "Repair it to full: %d meat" % Gear.repair_cost(id)
	if who != "":
		return
	var back := Crafting.salvage_return(Gear.base(id), r)
	var sb := _button("SURE?" if _confirm == "salvage" else "SALVAGE", "button_salvage_amber", Rect2(1259, 618, 172, 60) if worn else Rect2(1077, 618, 354, 60), 22 if worn else 25, detail, "Salvage", press_salvage)
	if not worn:
		_img(_tex("icon_salvage"), Rect2(34, 8, 44, 44), sb)
	_label("RETURNS", Rect2(1055, 696, 385, 27), 19, INK, detail).name = "SalvageReturn"
	var ks := back.keys()
	var per := mini(ks.size(), 3)   # at most three across; a fourth (a Rare+ catalyst) starts a second row
	var cw := 376.0 / maxf(per, 1)
	for k in ks.size():
		var m: String = ks[k]
		var x := 1068.0 + (k % 3) * cw
		var ry := 730.0 + (k / 3) * 40.0
		_img(Crafting.icon(m), Rect2(x, ry, 38, 36), detail)
		var rl := _label("%s ×%d" % [Crafting.mat_name(m), int(back[m])], Rect2(x + 40, ry + 1, cw - 44, 34), 15 if cw < 130.0 else 17, INK, detail, true, HORIZONTAL_ALIGNMENT_LEFT)
		rl.clip_text = true   # never wider than its column
		rl.size = Vector2(cw - 44, 34)


## REPAIR: the first tap shows the cost in Kora's bubble (or what's missing),
## the second spends the materials and mends it to full (main.repair_gear).
func press_repair() -> bool:
	var cost := Gear.repair_cost(selected)
	if cost <= 0:
		return false
	if game.meat_bank < cost:
		_confirm = ""
		game.audio.play("denied", 0.0)
		kora_say("repair_short", "%d meat" % cost)
		refresh()
		return false
	if _confirm != "repair":
		_confirm = "repair"
		game.audio.play("click", 0.0)
		kora_say("repair_ask", "%d meat" % cost)
		refresh()
		return false
	_confirm = ""
	var ok: bool = game.repair_gear(selected)
	if ok:
		kora_play("craft")
		kora_say("repaired")
	refresh()
	return ok


func press_salvage() -> bool:
	if _confirm != "salvage":
		_confirm = "salvage"
		game.audio.play("click", 0.0)
		refresh()
		return false
	_confirm = ""
	var ok: bool = game.salvage(selected)
	if ok:
		kora_play("present")
		kora_say("salvaged")
		var ids := entries()
		selected = ids[0] if not ids.is_empty() else ""
	refresh()
	return ok


# ------------------------------------------------------------ dragging

func _input(event: InputEvent) -> void:
	if not visible:
		return
	var drag := event as InputEventScreenDrag
	if drag:
		_dragging = true
		_drag_dist += drag.relative.length()
		var k := 1.0 / maxf(canvas.scale.x, 0.01)
		if mode == "bench":
			scroll.scroll_horizontal -= int(drag.relative.x * k)
			_fling = -drag.velocity.x * k
		else:
			scroll.scroll_vertical -= int(drag.relative.y * k)
			_fling = -drag.velocity.y * k
		return
	var t := event as InputEventScreenTouch
	if t:
		if t.pressed:
			_fling = 0.0
			_drag_dist = 0.0
		else:
			_dragging = false


func _process(delta: float) -> void:
	if not visible or _dragging or absf(_fling) < 5.0:
		return
	if mode == "bench":
		scroll.scroll_horizontal += int(_fling * delta)
	else:
		scroll.scroll_vertical += int(_fling * delta)
	_fling = move_toward(_fling, 0.0, 2400.0 * delta)


# ------------------------------------------------------------ Kora's lines

## What Kora the Craftkeeper says (the user's request: lines like Ugo's and
## Elder Numa's). A pool per situation, picked at random without repeating
## the last line; "%s" is filled with a name, "%d" with a distance. She's the
## camp's young toolmaker: cheerful, proud of good work, a little bossy about
## taking care of tools, fond of naming her favourite stones, and she treats
## every material like treasure.
const KORA_LINES := {
	"greet_bench": [
		"Hey, runner! The bench is warm. What are we making?",
		"Welcome to my workshop! Mind the sparks.",
		"You brought materials? I can smell the wood from here!",
		"A good tool is half the run. Let's make you a good one.",
		"My mallet's been waiting all day. Pick something!",
		"Back already? I knew you'd want something sharper.",
	],
	"greet_items": [
		"Everything you've found, all in one chest. Let's look!",
		"Your treasure! Well, mostly rocks. Good rocks, though.",
		"Kept it all safe and dry for you. Have a look.",
		"I sorted it by rarity. Don't mess it up!",
		"So many bits and pieces! Each one has a use.",
	],
	"empty": [
		"Empty chest! Break things out there and bring me pieces.",
		"Nothing yet? Smash some rocks and bonk a dinosaur or two!",
		"The chest is hungry. Feed it materials!",
		"Open chests and break logs, and this fills right up.",
		"No materials, no tools. Go on, I'll wait here.",
	],
	"ready": [
		"The %s? You've got everything. Tap CRAFT!",
		"Oh, a %s! I love making those.",
		"All the pieces are here. One %s, coming right up!",
		"Add a catalyst and the %s might come out special...",
		"I've got a good feeling about this %s.",
	],
	"short": [
		"The %s needs more pieces. The red ones are missing.",
		"Not enough for a %s yet. Keep running, keep smashing!",
		"Almost! Find what's red and the %s is yours.",
		"I can't make a %s from wishes. Bring me the rest!",
		"A %s needs proper materials. No shortcuts in my workshop.",
	],
	"locked": [
		"I haven't worked out that one yet. Run %d m and I will!",
		"That design's too tricky for now. Reach %d m first.",
		"Ooh, that one's secret. Show me %d m in one run.",
		"Run %d m and I'll teach myself how to make it.",
		"Not yet! %d m in one run, then we talk.",
	],
	"crafted": [
		"Done! One %s. Treat it kindly.",
		"There! A fine %s, if I do say so.",
		"Fresh off the bench: %s!",
		"%s! Solid work. Mine, I mean.",
		"Here's your %s. Don't leave it out in the rain.",
	],
	"crafted_rare": [
		"Whoa! A %s! The stones liked you today.",
		"Look at that shine! %s!",
		"I've only made a few like this. %s!",
		"%s! Even my mallet is impressed.",
		"Now that's special: %s!",
	],
	"crafted_legendary": [
		"I... I made a %s?! I need to sit down.",
		"A %s! The old crafters sing about these!",
		"%s! I'm telling everyone at the camp!",
	],
	"material": [
		"%s! Hold it up to the light. Pretty, right?",
		"Good %s. I could use that for so many things.",
		"%s. Keep it, don't trade it to Ugo for meat!",
		"Ah, %s. Every bit of it counts.",
		"That %s will make something nice one day.",
	],
	"gear": [
		"Your %s. Look after it and it'll look after you.",
		"%s. Worn edges? I can patch it at the Camp.",
		"A good %s. Equip it at the Dinosaur Camp.",
		"Don't need the %s? I can break it back into pieces.",
		"%s. I remember making that one!",
	],
	"card": [
		"A %s! Slot it into a weapon.",
		"%s. I didn't make that one, the dinosaurs did!",
		"Ooh, %s. That's a rare find.",
		"The %s gives a real boost. Try it at the Camp.",
		"%s! Collect them all, I say.",
	],
	"salvaged": [
		"Broken back into pieces. Nothing wasted!",
		"Back to the chest it goes. Good as new materials.",
		"Salvaged! Now let's make something better.",
		"Pieces saved. My mallet thanks you.",
		"There, all sorted. Every bit has another life.",
	],
	"repair_ask": [
		"I can fix that up for %s. Tap REPAIR again!",
		"Good as new for %s. Shall I? Tap again.",
		"That one's seen some action. %s and it's whole again.",
		"A few knocks, nothing my mallet can't mend: %s.",
		"%s and I'll have it sturdy again. Tap REPAIR!",
	],
	"repair_short": [
		"I'd need %s to fix that. Go find some!",
		"Not enough to mend it: %s.",
		"Bring me %s and I'll patch it right up.",
		"Short on meat. It takes %s.",
		"Hmm, %s for this one. Come back with more!",
	],
	"repaired": [
		"Good as new! Go give it another beating.",
		"Mended! It'll last a good while now.",
		"There, sturdy again. Take care of it!",
		"Fixed! My mallet never fails.",
		"All patched up. Off you go!",
	],
}


## A line from one of Kora's pools (not the same as `last`).
static func kora_pick(key: String, last := "") -> String:
	var pool: Array = KORA_LINES.get(key, [""])
	var pick: String = pool[randi() % pool.size()]
	while pool.size() > 1 and pick == last:
		pick = pool[randi() % pool.size()]
	return pick


## Kora says a line in her bubble, with a murmur (the shared mumble sounds,
## Tuning.KORA_PITCH / KORA_DB). Returns what she said.
func kora_say(key: String, arg: Variant = null) -> String:
	if kora_label == null:
		return ""
	var line := kora_pick(key, String(_kora_said.get(key, "")))
	_kora_said[key] = line
	var text := line
	if arg != null and (line.contains("%s") or line.contains("%d")):
		text = line % arg
	kora_label.text = text
	_place_bubble()
	if visible and game and game.get("audio"):
		var n := clampi(text.length() / 18 + randi_range(0, 1), 1, 6)
		game.audio.play("mumble_%d" % n, 0.05, Tuning.KORA_PITCH, Tuning.KORA_DB)
	return text


## What she says about the thing just picked.
func _kora_about(id: String) -> void:
	if id == "":
		return
	if mode == "bench":
		if game.best_m < Crafting.learn_m(id):
			kora_say("locked", Crafting.learn_m(id))
		else:
			kora_say("ready" if game.can_craft(id) else "short", Gear.name_of(id))
		return
	match tab:
		"materials":
			kora_say("material", Crafting.mat_name(id))
		"cards":
			kora_say("card", Gear.name_of(id))
		_:
			kora_say("gear", Gear.full_name(id))


## Her bubble: the cream bubble Numa and Ugo speak in, in the free space to
## the right of her head (between her and the panels), its tail at her face.
func _build_bubble() -> void:
	kora_tail = Polygon2D.new()
	kora_tail.name = "KoraTail"
	kora_tail.color = Color(1.0, 0.96, 0.86)
	canvas.add_child(kora_tail)
	kora_bubble = Panel.new()
	kora_bubble.name = "KoraBubble"
	kora_bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var nb := StyleBoxFlat.new()
	nb.bg_color = Color(1.0, 0.96, 0.86)
	nb.border_color = Color(0.45, 0.27, 0.12)
	nb.set_border_width_all(3)
	nb.set_corner_radius_all(16)
	nb.content_margin_left = 14
	nb.content_margin_right = 14
	nb.content_margin_top = 8
	nb.content_margin_bottom = 10
	nb.shadow_color = Color(0, 0, 0, 0.25)
	nb.shadow_size = 4
	kora_bubble.add_theme_stylebox_override("panel", nb)
	kora_label = Label.new()
	kora_label.name = "KoraSays"
	kora_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	kora_label.add_theme_font_override("font", SpriteLib.ui_font("body"))
	kora_label.add_theme_font_size_override("font_size", 19)
	kora_label.add_theme_color_override("font_color", Color(0.42, 0.22, 0.08))
	kora_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	kora_label.position = Vector2(14, 8)
	kora_bubble.add_child(kora_label)
	canvas.add_child(kora_bubble)
	kora_bubble.visible = false
	kora_tail.visible = false


## Where the bubble goes (design canvas): its box and Kora's mouth.
func _bubble_spot() -> Array:
	if mode == "bench":
		return [Rect2(392, 112, 250, 0), Vector2(318, 238)]
	return [Rect2(330, 120, 222, 0), Vector2(262, 318)]


func _place_bubble() -> void:
	if kora_bubble == null:
		return
	var spot: Array = _bubble_spot()
	var r: Rect2 = spot[0]
	var mouth: Vector2 = spot[1]
	var inner := r.size.x - 28.0
	var font := kora_label.get_theme_font("font")
	var fs := kora_label.get_theme_font_size("font_size")
	var text_h := font.get_multiline_string_size(kora_label.text, HORIZONTAL_ALIGNMENT_LEFT, inner, fs).y
	kora_label.size = Vector2(inner, text_h)
	kora_bubble.position = r.position
	kora_bubble.size = Vector2(r.size.x, text_h + 20.0)
	var by := clampf(mouth.y - 40.0, r.position.y + 14.0, r.position.y + kora_bubble.size.y - 34.0)
	kora_tail.polygon = PackedVector2Array([Vector2(r.position.x + 3.0, by), Vector2(r.position.x + 3.0, by + 26.0), mouth])
	kora_bubble.visible = kora_label.text != ""
	kora_tail.visible = kora_bubble.visible
