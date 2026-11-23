class_name Market
extends CanvasLayer
## The Market, laid out like the user's reference (Rok's cave marketplace
## with Blaze Pepper): the cave room on the left (Rok facing the merchant across
## his counter, MarketScene), a log-framed shop panel on the right with pill
## tabs, a grid of parchment item cards with price pills, and a details strip
## with a big green BUY. The merchant talks in a bubble over his head and
## holds up the chosen item. Buying makes him hand over a parcel (his buy
## clip), the item fly to the hero and the hero cheer; Back makes him wave.
## Pieces of the reference's UI art not yet supplied are drawn
## (`_ui_box`: assets/market/ui/<name>.png replaces each when it exists).
## Spend banked meat on permanent unlocks — the power-ups that
## start locked (Boosters.DATA without "starter"), the third booster slot and
## the expansion dinosaurs (Dinos).
## Prices come from config/progression.cfg [market] (Progression.PRICES).
##
## main owns the state (meat_bank, boosters_owned, slot_count) and does the
## buying in main.buy(id); this screen only shows it. A Buy button asks for a
## second tap ("Confirm?") so a stray touch can't spend meat.

signal closed

const SLOT_ID := "booster_slot_3"
## Heart Containers: each adds a heart for good. They go on sale by best SCORE
## (one run, config [market_score]), each after the one before it.
const HEART_IDS := ["heart_1", "heart_2", "heart_3"]
## Set by main: the best score (one run) and how many containers are owned.
static var best_score := 0
static var hearts_owned := 0
const INK := Codex.INK
const PAPER := Codex.PAPER
const CARD := Codex.CARD
const MEAT := Hud.MEAT_ICON   # currency icon

var game   # main.gd: meat_bank, boosters_owned, slot_count, buy(id)
var root: Control
var grid: GridContainer          # the item cards of the open tab, three across (named by item id)
var scroll: ScrollContainer
var scene: MarketScene           # the cave, counter, sign and torches
var hero: AnimatedSprite2D       # the hero you play, outside the cave (inside it with the user's cave room)
var merchant: AnimatedSprite2D   # the user's merchant (idle / buy / goodbye), in the cave room
var counter: TextureRect         # the user's trading counter, in front of the merchant
var ugo_plate: Label             # his name on the scene kit's wooden plank (as Elder Numa's)
var on_counter: TextureRect      # the chosen item, on the counter
var bubble: PanelContainer       # the merchant's speech bubble
var tail: Polygon2D              # its tail, pointing at the merchant
var detail: VBoxContainer        # the details strip's text (name, what it does, numbers)
var say_label: Label             # the merchant's line, in the bubble over his head
var panel: PanelContainer        # the shop panel on the right (log frame)
var corners: Control             # bones drawn on the frame's corners
var foot_icon: TextureRect       # the chosen item's picture in the details strip
var buy_box: CenterContainer     # holds BUY (or OWNED / LOCKED / NEED)
var selected := ""               # the item on the counter ("" = the merchant's greeting)
var _say := ""                   # a line the merchant says instead of the usual one (after a sale)
var bank_label: Label
## Market sections, each its own tab: id -> label.
const TABS := {"powerups": "Power-Ups", "gear": "Materials", "dinos": "Dinosaurs", "heroes": "Heroes", "other": "Other", "sell": "Sell"}
var tab := "powerups"
var tab_buttons := {}     # tab id -> Button
var _confirm := ""        # item waiting for its confirming tap
var _anims: Array = []    # dino card idle loops: [TextureRect, id, frame, time left]
var _new: Array = []      # items newly on sale, tagged NEW this visit
var _fling := 0.0
var _dragging := false
var _drag_dist := 0.0


## Everything for sale (the third slot and the non-starter power-ups), in
## shop order: the order they go on sale.
static func items() -> Array:
	var a := [SLOT_ID] + HEART_IDS
	for k in Boosters.DATA:
		if not Boosters.DATA[k].get("starter", false):
			a.append(k)
	a.append_array(Dinos.ids())
	a.append_array(Heroes.IDS.filter(func(h): return Heroes.has(h)))   # Nira, Boro
	a.append_array(Crafting.market_ids())   # basic crafting materials (gear is crafted, not sold)
	# (no Card Pack: dinosaur cards are dropped by wild dinosaurs, main._drop_card)
	a.sort_custom(func(x, y): return unlock_m(x) < unlock_m(y) if unlock_m(x) != unlock_m(y) else price(x) < price(y))
	return a


## Which tab an item is listed under.
static func category(id: String) -> String:
	if Gear.has(id) or id == Gear.CARD_PACK or id.begins_with(Crafting.MAT_PREFIX):
		return "gear"
	if id == SLOT_ID or is_heart(id):
		return "other"
	if Heroes.has(id):
		return "heroes"
	return "dinos" if Dinos.has(id) else "powerups"


static func price(id: String) -> int:
	if id.begins_with(Crafting.MAT_PREFIX):
		return int(Crafting.mat(id.substr(Crafting.MAT_PREFIX.length())).price)
	if Gear.has(id):
		return int(Progression.PRICES.get(id, Gear.ITEMS[id].price))
	if id == Gear.CARD_PACK:
		return int(Progression.PRICES.get(id, Gear.CARD_PACK_PRICE))
	return int(Progression.PRICES.get(id, 0))


## Best distance that puts an item on sale.
static func unlock_m(id: String) -> int:
	if id.begins_with(Crafting.MAT_PREFIX):   # never before the Crafting Bench opens
		return maxi(Crafting.bench_m(), int(Crafting.mat(id.substr(Crafting.MAT_PREFIX.length())).unlock_m))
	if Gear.has(id):
		return int(Progression.MARKET_UNLOCK_M.get(id, Gear.ITEMS[id].unlock_m))
	return int(Progression.MARKET_UNLOCK_M.get(id, 0))


## On sale once the best distance reaches its unlock distance and, for some
## dinosaurs, a badge tier is earned too (config [market_badges]).
static func on_sale(id: String, p_best_m: float) -> bool:
	if is_heart(id):
		return best_score >= unlock_score(id) and hearts_owned >= heart_index(id) - 1
	return p_best_m >= unlock_m(id) and badge_ok(id) and Requires.ok("market." + id)


static func is_heart(id: String) -> bool:
	return HEART_IDS.has(id)


## Heart Container number, 1-3.
static func heart_index(id: String) -> int:
	return HEART_IDS.find(id) + 1


## The best score (one run) that puts a Heart Container on sale.
static func unlock_score(id: String) -> int:
	return int(Progression.MARKET_SCORE.get(id, 0))


static func badge_ok(id: String) -> bool:
	var r: Array = Progression.MARKET_BADGES.get(id, [])
	return r.is_empty() or Badges.has_tier(r[0], r[1])


## What still keeps an item off sale, e.g. "reach 2700 m in one run ✓ · earn
## Rock Breaker (Silver)". "" if it's on sale.
static func lock_text(id: String, p_best_m: float) -> String:
	if is_heart(id):
		var parts := ["score %d points in one run%s" % [unlock_score(id), " ✓" if best_score >= unlock_score(id) else ""]]
		if heart_index(id) > 1:
			parts.append("buy %s first%s" % [item_name(HEART_IDS[heart_index(id) - 2]), " ✓" if hearts_owned >= heart_index(id) - 1 else ""])
		return " · ".join(parts)
	var r: Array = Progression.MARKET_BADGES.get(id, [])
	var dist := "reach %d m in one run" % unlock_m(id)
	var needs := Requires.missing("market." + id)   # config/requirements.cfg
	if r.is_empty() and needs.is_empty():
		return dist
	var parts := [dist + (" ✓" if p_best_m >= unlock_m(id) else "")]
	if not r.is_empty():
		parts.append("earn " + Badges.tier_name(r[0], r[1]) + (" ✓" if badge_ok(id) else ""))
	parts.append_array(needs)
	return " · ".join(parts)


## The merchant's line for an item still locked: how to unlock it, in his
## words, from what's still missing (best distance, a badge tier, best score,
## the Heart Container before it). The user's request.
func unlock_hint(id: String) -> String:
	var need: Array = []
	if is_heart(id):
		if best_score < unlock_score(id):
			need.append("score %d points in one run" % unlock_score(id))
		if hearts_owned < heart_index(id) - 1:
			need.append("buy %s first" % item_name(HEART_IDS[heart_index(id) - 2]))
	else:
		if game.best_m < unlock_m(id):
			need.append("run %d m in one go" % unlock_m(id))
		var r: Array = Progression.MARKET_BADGES.get(id, [])
		if not r.is_empty() and not badge_ok(id):
			need.append("earn the %s badge" % Badges.tier_name(r[0], r[1]))
		need.append_array(Requires.missing("market." + id))
	if need.is_empty():
		return "Not for you yet, little runner..."
	var txt := " and ".join(need)
	return say("locked", [txt.substr(0, 1).to_upper() + txt.substr(1)], id)


static func item_name(id: String) -> String:
	if id.begins_with(Crafting.MAT_PREFIX):
		return "%s ×%d" % [Crafting.mat_name(id.substr(Crafting.MAT_PREFIX.length())), Crafting.bundle()]
	if Gear.has(id):
		return Gear.name_of(id)
	if id == Gear.CARD_PACK:
		return "Dino Card Pack"
	if id == SLOT_ID:
		return "Third Booster Slot"
	if is_heart(id):
		return "Heart Container " + ["I", "II", "III"][heart_index(id) - 1]
	if Heroes.has(id):
		return Heroes.name_of(id)
	return Dinos.name_of(id) if Dinos.has(id) else Boosters.DATA[id].name


func owns(id: String) -> bool:
	if Gear.has(id):
		return game.gear_owned.has(id)
	if id == Gear.CARD_PACK or id.begins_with(Crafting.MAT_PREFIX):
		return false   # buy as many as you like
	if id == SLOT_ID:
		return game.slot_count >= Boosters.MAX_SLOTS
	if is_heart(id):
		return game.heart_containers >= heart_index(id)
	return game.dinos_owned.has(id) if (Dinos.has(id) or Heroes.has(id)) else game.boosters_owned.has(id)


func _ready() -> void:
	layer = 21
	visible = false
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	root.add_child(outdoor_backdrop())   # the sky, hills and jungle around the cave
	scene = MarketScene.new()
	root.add_child(scene)
	hero = AnimatedSprite2D.new()
	hero.name = "Hero"
	hero.centered = false
	root.add_child(hero)
	hero.animation_finished.connect(func(): hero.play("idle"))
	# the user's merchant and his counter (drawn over him), when the cave room is imported
	merchant = AnimatedSprite2D.new()
	merchant.name = "Merchant"
	merchant.centered = false
	merchant.visible = false
	root.add_child(merchant)
	merchant.animation_finished.connect(func():
		if merchant.animation == "buy":
			merchant.play("idle"))
	counter = TextureRect.new()
	counter.name = "Counter"
	counter.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	counter.stretch_mode = TextureRect.STRETCH_SCALE
	counter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	counter.visible = false
	root.add_child(counter)
	if scene.room():
		merchant.sprite_frames = merchant_frames()
		merchant.visible = true
		merchant.play("idle")
		counter.texture = load("res://assets/market/merchant_counter.png")
		counter.visible = true
	ugo_plate = SceneKit.badge("Ugo", "button_secondary", 20)
	if ugo_plate:
		ugo_plate.name = "UgoPlate"
		ugo_plate.visible = scene.room()
		root.add_child(ugo_plate)
	# the chosen item, offered in the merchant's hand
	on_counter = TextureRect.new()
	on_counter.name = "OnCounter"
	on_counter.size = Vector2(96, 96)
	on_counter.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	on_counter.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	on_counter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(on_counter)
	# the merchant's speech: a small bubble over his head
	bubble = PanelContainer.new()
	bubble.name = "Bubble"
	var bs := StyleBoxFlat.new()
	bs.bg_color = Color(1.0, 0.97, 0.88, 0.97)
	bs.set_corner_radius_all(18)
	bs.set_border_width_all(3)
	bs.border_color = Color(0.45, 0.25, 0.1)
	bs.set_content_margin_all(10)
	bubble.add_theme_stylebox_override("panel", bs)
	bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bubble)
	say_label = _text("", 18, Color(0.45, 0.22, 0.08))
	say_label.name = "Says"
	say_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	say_label.custom_minimum_size = Vector2(250, 0)
	bubble.add_child(say_label)
	tail = Polygon2D.new()
	tail.color = Color(1.0, 0.97, 0.88)
	root.add_child(tail)

	# the shop panel on the right: a log frame with bones at the corners
	panel = PanelContainer.new()
	panel.name = "ShopPanel"
	panel.add_theme_stylebox_override("panel", _ui_box("panel_frame", _flat(Color(0.2, 0.12, 0.06), Color(0.5, 0.3, 0.13), 14, 22, 26)))
	root.add_child(panel)
	var pv := VBoxContainer.new()
	pv.add_theme_constant_override("separation", 10)
	panel.add_child(pv)
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 4)
	pv.add_child(tabs)
	for t in TABS:
		var tb := Button.new()
		tb.name = "Tab_" + t
		tb.text = TABS[t]
		tb.toggle_mode = true
		tb.focus_mode = Control.FOCUS_NONE
		tb.custom_minimum_size = Vector2(0, 48)
		tb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tb.clip_text = true   # tabs share the panel's width; text never widens it
		tb.add_theme_font_size_override("font_size", 17)
		tb.pressed.connect(func(): show_tab(t))
		tabs.add_child(tb)
		tab_buttons[t] = tb
	scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	pv.add_child(scroll)
	grid = GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 10)
	scroll.add_child(grid)
	# the details strip: picture | name, what it does, numbers | BUY
	var foot := PanelContainer.new()
	foot.name = "Footer"
	foot.custom_minimum_size = Vector2(0, FOOT_H)
	var fst := _ui_box("detail_strip", _flat(Color(0.3, 0.18, 0.09), Color(0.45, 0.27, 0.12), 3, 14, 10))
	var strip_art := has_ui("detail_strip")
	if strip_art:   # its divider is painted 112 px in: the picture sits left of it, the text right
		fst.content_margin_left = 8
		fst.content_margin_top = 20      # keep the text inside the frame's thick border
		fst.content_margin_bottom = 22
	foot.add_theme_stylebox_override("panel", fst)
	pv.add_child(foot)
	var fh := HBoxContainer.new()
	fh.add_theme_constant_override("separation", 12)
	foot.add_child(fh)
	foot_icon = TextureRect.new()
	foot_icon.custom_minimum_size = Vector2(92 if strip_art else 96, 96)
	foot_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	foot_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	foot_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	fh.add_child(foot_icon)
	var divider := ColorRect.new()
	divider.color = Color(0.6, 0.4, 0.2, 0.7)
	divider.custom_minimum_size = Vector2(3, 0)
	if strip_art:
		divider.modulate.a = 0.0   # keeps the gap; the art draws the line
	fh.add_child(divider)
	var dscroll := ScrollContainer.new()
	dscroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dscroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	dscroll.clip_contents = true   # long text scrolls inside the strip, never over its frame
	fh.add_child(dscroll)
	detail = VBoxContainer.new()
	detail.name = "Detail"
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail.add_theme_constant_override("separation", 2)
	dscroll.add_child(detail)
	buy_box = CenterContainer.new()
	buy_box.custom_minimum_size = Vector2(196, 0)
	fh.add_child(buy_box)
	corners = Control.new()   # bones on the frame's corners (drawn until the frame art exists)
	corners.name = "FrameBones"
	corners.mouse_filter = Control.MOUSE_FILTER_IGNORE
	corners.draw.connect(_draw_bones)
	root.add_child(corners)

	# top bar: a stone Back button and the title on the left, the meat on the right
	var header := HBoxContainer.new()
	header.name = "Header"
	header.set_anchors_preset(Control.PRESET_TOP_WIDE)
	header.offset_left = Tuning.UI_MARGIN - 12
	header.offset_right = -(Tuning.UI_MARGIN - 12)
	header.offset_top = 10
	header.add_theme_constant_override("separation", 12)
	root.add_child(header)
	var close := Button.new()
	close.name = "Back"
	close.text = "←"
	close.focus_mode = Control.FOCUS_NONE
	close.custom_minimum_size = Vector2(70, 64)
	close.add_theme_font_size_override("font_size", 38)
	close.add_theme_color_override("font_color", Color(0.25, 0.14, 0.06))
	close.add_theme_color_override("font_hover_color", Color(0.25, 0.14, 0.06))
	close.add_theme_color_override("font_pressed_color", Color(0.25, 0.14, 0.06))
	for st in ["normal", "hover", "pressed", "hover_pressed"]:
		close.add_theme_stylebox_override(st, _ui_box("back_button", _flat(Color(0.66, 0.6, 0.54) if st == "normal" else Color(0.58, 0.52, 0.46), Color(0.3, 0.22, 0.16), 4, 12, 6)))
	if has_ui("back_button"):   # the stone tablet has its arrow baked in
		close.text = ""
		close.custom_minimum_size = Vector2(68, 68)
		close.button_down.connect(func(): close.modulate = Color(0.8, 0.8, 0.8))
		close.button_up.connect(func(): close.modulate = Color.WHITE)
	close.pressed.connect(leave)
	header.add_child(close)
	var title := _text("MARKETPLACE", 40, Color(1, 0.95, 0.82))
	title.add_theme_color_override("font_outline_color", Color(0.3, 0.15, 0.05))
	title.add_theme_constant_override("outline_size", 10)
	if has_ui("title"):   # the pack's mossy plaque (label baked in)
		title.free()
		var tt := _ui_tex("title")
		var plaque := TextureRect.new()
		plaque.name = "TitleBanner"
		plaque.set_meta("art", UI_ART % "title")
		plaque.texture = tt
		plaque.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		plaque.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		plaque.custom_minimum_size = Vector2(76.0 * tt.get_width() / tt.get_height(), 76.0)
		plaque.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		plaque.mouse_filter = Control.MOUSE_FILTER_IGNORE
		header.add_child(plaque)
	else:
		header.add_child(title_banner("marketplace", title))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	var pouch := PanelContainer.new()
	pouch.name = "MeatCounter"
	var pst := _ui_box("meat_counter", _flat(Color(0.32, 0.18, 0.08), Color(0.18, 0.09, 0.03), 4, 22, 8))
	if pst is StyleBoxFlat:
		(pst as StyleBoxFlat).content_margin_left = 16
		(pst as StyleBoxFlat).content_margin_right = 20
	pouch.add_theme_stylebox_override("panel", pst)
	pouch.custom_minimum_size = Vector2(300, 84)   # a roomy counter (the pack's frame stretches as a 9-slice)
	if pst is StyleBoxTexture:   # keep the meat and number inside the frame's thick border
		pst.content_margin_left = 40
		pst.content_margin_right = 34
		pst.content_margin_top = 12
		pst.content_margin_bottom = 12
	pouch.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	header.add_child(pouch)
	var prow := HBoxContainer.new()
	prow.add_theme_constant_override("separation", 12)
	prow.alignment = BoxContainer.ALIGNMENT_CENTER
	pouch.add_child(prow)
	var coin := TextureRect.new()
	coin.texture = load(MEAT)
	coin.custom_minimum_size = Vector2(52, 52)
	coin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	coin.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	prow.add_child(coin)
	bank_label = _text("0", 36, Color(1, 0.96, 0.85))
	bank_label.add_theme_color_override("font_outline_color", Color(0.2, 0.1, 0.03))
	bank_label.add_theme_constant_override("outline_size", 8)
	bank_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	prow.add_child(bank_label)
	root.resized.connect(_layout)


## The shop's look: the user's Marketplace UI pack (assets/market/ui/<name>.png,
## tools/prepare_market_ui.py; drawn from its sharper @2x twin) stretched as a
## 9-slice with the pack's margins (ui.json), else the drawn stand-in.
const UI_ART := "res://assets/market/ui/%s.png"
static var _ui_meta := {}


static func has_ui(name: String) -> bool:
	return ResourceLoader.exists(UI_ART % name)


## A plain picture from the pack (title, check, padlock, hearts...), or null.
static func _ui_tex(name: String) -> Texture2D:
	return SpriteLib.tex(UI_ART % name) if has_ui(name) else null


func _ui_box(name: String, fallback: StyleBox) -> StyleBox:
	if not has_ui(name):
		return fallback
	if _ui_meta.is_empty() and FileAccess.file_exists("res://assets/market/ui/ui.json"):
		_ui_meta = JSON.parse_string(FileAccess.get_file_as_string("res://assets/market/ui/ui.json"))
	var t := StyleBoxTexture.new()
	t.texture = _ui_tex(name)
	var m: Dictionary = _ui_meta.get(name, {})
	var tm: Array = m.get("margin", [0, 0, 0, 0])   # not a 9-slice (the back tablet): stretch the whole picture
	var cm: Array = m.get("content", [])
	if m.has("region"):   # only the visible art, not its transparent padding
		var rg: Array = m.region
		t.region_rect = Rect2(rg[0], rg[1], rg[2], rg[3])
	for i in 4:
		t.set_texture_margin(i, float(tm[i]))
		t.set_content_margin(i, float(cm[i]) if not cm.is_empty() else fallback.get_content_margin(i))
	return t


static func _flat(bg: Color, border: Color, bw: int, radius: int, margin: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(bw)
	sb.set_corner_radius_all(radius)
	sb.set_content_margin_all(margin)
	return sb


## Bones tied across the shop panel's corners (the reference's frame), drawn
## until the frame art exists.
func _draw_bones() -> void:
	if ResourceLoader.exists(UI_ART % "panel_frame"):
		return
	var r := Rect2(panel.position, panel.size)
	var bone := Color(0.95, 0.9, 0.78)
	var dark := Color(0.35, 0.22, 0.1)
	for c in [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]:
		var dir := Vector2(1, 1) if (c.x == r.position.x) == (c.y == r.position.y) else Vector2(1, -1)
		var a: Vector2 = c - dir * 22.0
		var b: Vector2 = c + dir * 22.0
		for pass_i in 2:
			var col := dark if pass_i == 0 else bone
			var w := 13.0 if pass_i == 0 else 8.0
			corners.draw_line(a, b, col, w)
			for e in [a, b]:
				for side in [-1.0, 1.0]:
					corners.draw_circle(e + dir.orthogonal() * side * 5.0, 7.5 if pass_i == 0 else 5.5, col)
		corners.draw_line(c + dir.orthogonal() * 6.0, c - dir.orthogonal() * 6.0, Color(0.7, 0.5, 0.28), 4.0)   # the tie


## Place everything: the cave on the left (zoomed like the reference), the
## shop panel on the right. Follows the screen size.
func _layout() -> void:
	var w := root.size.x
	var h := root.size.y
	var pw := clampf(w * 0.52, 600.0, 820.0)   # wider would cover the merchant
	panel.position = Vector2(w - pw - 16.0, 84.0)
	panel.size = Vector2(pw, h - 84.0 - 10.0)
	corners.position = Vector2.ZERO
	corners.size = root.size
	corners.queue_redraw()
	var left := panel.position.x   # the scene's room
	scene.ground_override = h * 0.86
	# the cave, the hero and the merchant a size smaller (the user's call), and
	# never so big that the counter runs under the shop panel
	var s := clampf(h / 720.0 * 0.54, 0.4, 0.8)   # the size the user picked (the 1280x720 look)
	if scene.room():
		var rm: Dictionary = scene.room_meta
		var span := float(rm.counter_bottom_center[0]) + float(rm.counter_width) * 0.5 - float(rm.hero_feet[0])
		s = minf(s, (left * 0.8 - 24.0) / span)
	if scene.room():
		var m: Dictionary = scene.room_meta
		var hero_x := left * 0.2
		scene.room_s = s
		scene.room_o = Vector2(hero_x - float(m.hero_feet[0]) * s, scene.ground_y - float(m.hero_feet[1]) * s)
		hero.scale = Vector2.ONE * (float(m.character_height) * s / 175.0)   # as tall as the merchant
		merchant.position = scene.merchant_spot()
		merchant.scale = Vector2.ONE * (float(m.character_height) * s / 440.0)
		merchant.offset = -Vector2(m.anchor[0], m.anchor[1])
		var cr: Rect2 = scene.counter_rect()
		counter.position = cr.position
		counter.size = cr.size
		if ugo_plate:   # on the floor in front of his counter, under him
			ugo_plate.size = Vector2(150, 0)
			ugo_plate.position = Vector2(merchant.position.x - 75.0, maxf(cr.end.y, scene.ground_y) + 6.0)
	else:
		scene.room_s = 0.0
		hero.scale = Vector2.ONE * 1.4
	hero.position = scene.hero_spot()
	var ct: Vector2 = scene.counter_top()
	on_counter.position = ct - Vector2(48, 92)
	_place_bubble()
	# three cards across: the frame's real content margins, two 12 px gaps and the
	# scrollbar (a guess of 52 + 14 left the grid 4 px too wide, pushing the panel)
	var ps := panel.get_theme_stylebox("panel")
	var inner := pw - ps.get_margin(SIDE_LEFT) - ps.get_margin(SIDE_RIGHT)
	var bar := scroll.get_v_scroll_bar().get_combined_minimum_size().x + 2.0
	var cw := floorf((inner - 24.0 - bar) / 3.0)
	# two full rows always fit above the details strip (they overlapped it on short screens)
	var grid_h := panel.size.y - 64.0 - 48.0 - 20.0 - FOOT_H
	var ch := minf(cw * 1.02, floorf((grid_h - 10.0) / 2.0))
	_card_size = Vector2(cw, ch)   # each card fills its column (no dead space between them); the frame stretches
	for t in grid.get_children():
		(t as Control).custom_minimum_size = _card_size


## The merchant's speech bubble sits over his head, its tail at his face.
func _place_bubble() -> void:
	var m: Vector2 = scene.mouth()
	var bsz := bubble.get_combined_minimum_size()
	var x := clampf(m.x - bsz.x * 0.5, 12.0, panel.position.x - bsz.x - 12.0)
	bubble.position = Vector2(x, maxf(m.y - 110.0 - bsz.y, 84.0))
	bubble.size = bsz
	var bx := clampf(m.x, x + 30.0, x + bsz.x - 30.0)
	var by := bubble.position.y + bsz.y - 2.0
	tail.polygon = PackedVector2Array([Vector2(bx - 14.0, by), Vector2(bx + 14.0, by), m + Vector2(0, -60.0)])


func open_market() -> void:
	_confirm = ""
	_say = ""
	_visit += 1   # a fresh greeting each visit
	_new = game.market_new()   # NEW tags for this visit (main then marks them seen)
	visible = true
	enter(root)
	hero.sprite_frames = SpriteLib.character(Forms.ROK)
	if not hero.has_node("Gear"):
		var gl := GearLayer.new()
		gl.name = "Gear"
		hero.add_child(gl)
	(hero.get_node("Gear") as GearLayer).hero = String(Forms.get_data(Forms.ROK).id)   # the hero you play
	var d := Forms.get_data(Forms.ROK)
	hero.offset = -Vector2(d.pivot)
	hero.play("idle")
	if merchant.visible:
		merchant.play("idle")
	_leaving = false
	_layout()
	# open on the first section with something new, else Power-Ups
	var start := "powerups"
	for t in TABS:
		if _new.any(func(id): return category(id) == t):
			start = t
			break
	show_tab(start)


## Switch section: only that tab's goods are in the grid; the first is chosen.
func show_tab(t: String) -> void:
	tab = t
	_confirm = ""
	scroll.scroll_vertical = 0
	var first: Array = items().filter(func(id): return category(id) == t)
	selected = first[0] if not first.is_empty() else ""
	refresh()


func close_market() -> void:
	visible = false
	closed.emit()


## Back: the merchant waves goodbye (his goodbye clip) as the screen fades,
## then the Market closes. Without his art it just closes.
func leave() -> void:
	if _leaving:
		return
	if not merchant.visible or not is_inside_tree():
		close_market()
		return
	_leaving = true
	_say = say("bye", [], str(_visit))
	_build_detail()
	merchant.play("goodbye")
	game.audio.play("click", 0.0)
	var t := root.create_tween()
	t.tween_interval(0.75)
	t.tween_property(root, "modulate:a", 0.0, 0.3)
	t.tween_callback(func():
		root.modulate.a = 1.0
		close_market())


var _leaving := false
static var _merchant_sf: SpriteFrames


## The merchant's clips from his 4 x 2 sheets (assets/market/merchant_*.png).
static func merchant_frames() -> SpriteFrames:
	if _merchant_sf:
		return _merchant_sf
	var m: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/market/market.json"))
	_merchant_sf = SpriteFrames.new()
	_merchant_sf.remove_animation("default")
	var fs := Vector2(m.frame[0], m.frame[1])
	for clip in m.clips:
		var c: Dictionary = m.clips[clip]
		var ms := 1000.0 / float(c.fps)
		SpriteLib._sheet_frames(_merchant_sf, clip, load("res://assets/market/merchant_%s.png" % clip), fs,
				[ms, ms, ms, ms, ms, ms, ms, ms], bool(c.loop))
	return _merchant_sf


## Pick an item: it's highlighted, the merchant holds it up and talks about
## it, and the strip below shows what it is with BUY.
func select(id: String) -> void:
	if _drag_dist > 12.0:
		return   # that was a scroll, not a tap
	selected = id
	_confirm = ""
	_say = ""
	if game.audio:
		game.audio.play("click", 0.0)
	refresh()


## Rebuild the cards and the strip from main's current state.
func refresh() -> void:
	bank_label.text = str(game.meat_bank)
	_anims.clear()
	for c in grid.get_children():
		grid.remove_child(c)
		c.queue_free()
	for t in TABS:
		var tb: Button = tab_buttons[t]
		tb.button_pressed = t == tab
		var fresh := _new.filter(func(id): return category(id) == t and not owns(id)).size()
		tb.text = TABS[t] + (" ●" if fresh > 0 else "")   # a dot: something new in there
		_style_tab(tb, t == tab)
	var n := 0
	if tab == "sell":   # the player's own things, sold at 80% of their value (Economy)
		for sid in Economy.sellables(game.gear_owned, game.gear_equipped, game.materials):
			grid.add_child(_sell_card(sid))
			n += 1
	for id in items():
		if category(id) == tab:
			grid.add_child(_card(id))
			n += 1
	# empty display spots fill out the two visible rows (and the last row), so a
	# tab with only a few goods (Heroes, Other) doesn't leave a bare board
	var pad := maxi(GRID_ROWS * grid.columns - n, (grid.columns - n % grid.columns) % grid.columns)
	for k in pad:
		grid.add_child(_empty_spot(k))
	_build_detail()


const GRID_ROWS := 2   # rows that fit above the details strip (_layout)


## An empty spot on the shelf: a faint recessed frame, nothing to tap. Meta
## `empty` (tests and code that walk the grid skip these).
func _empty_spot(k: int) -> Control:
	var p := Panel.new()
	p.name = "Empty_%d" % k
	p.set_meta("empty", true)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.custom_minimum_size = _card_size
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.06, 0.02, 0.28)
	sb.border_color = Color(0.55, 0.36, 0.18, 0.35)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(14)
	p.add_theme_stylebox_override("panel", sb)
	return p


## Pill tabs: the open one teal (the reference), the others brown.
func _style_tab(tb: Button, on: bool) -> void:
	var bg := Color(0.2, 0.58, 0.52) if on else Color(0.42, 0.25, 0.12)
	var border := Color(0.55, 0.95, 0.85) if on else Color(0.25, 0.13, 0.05)
	for st in ["normal", "hover", "pressed", "hover_pressed"]:
		var sb := _ui_box("tab_on" if on else "tab_off", _flat(bg if st == "normal" or on else bg.lightened(0.1), border, 3, 22, 6))
		tb.add_theme_stylebox_override(st, sb)
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color"]:
		tb.add_theme_color_override(c, Color(1, 0.97, 0.88) if on else Color(0.98, 0.86, 0.66))
	tb.add_theme_color_override("font_outline_color", Color(0.12, 0.08, 0.04))
	tb.add_theme_constant_override("outline_size", 5)


## The picture of an item (an animated dinosaur's first frame, a power-up...).
func _icon_of(id: String) -> Texture2D:
	if id == SLOT_ID:
		return _slot_icon()
	if is_heart(id):
		var ht := _ui_tex("heart_full")   # the pack's Heart Container
		return ht if ht else Hearts.icon(Hearts.QUARTERS)
	if Heroes.has(id):
		return Herd.icon_of(id)
	if Dinos.has(id):
		return Dinos.icon(id)
	if Gear.has(id) or id == Gear.CARD_PACK:
		return Gear.icon(id)
	if id.begins_with(Crafting.MAT_PREFIX):
		return Crafting.icon(id.substr(Crafting.MAT_PREFIX.length()))
	return Boosters.icon(id)


var _card_size := Vector2(170, 175)
const FOOT_H := 164.0   # the details strip's height
const CARD_INSET := Vector2(16, 12)   # card contents clear of its frame (the art's border is ~12 px)


## One item card (the reference's parchment card): picture, name, and a price
## pill (or OWNED / LOCKED); the chosen one glows green, owned ones get a ✓.
## A thing the player can sell: its picture, name (and how many) and the
## meat the merchant pays (Economy.sell_price, 80% of its value).
func _sell_card(sid: String) -> Control:
	var b := Button.new()
	b.name = sid.replace(":", "_").replace("#", "_")
	b.set_meta("sell", sid)
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = _card_size
	var chosen := sid == selected
	var sb := _flat(Color(0.92, 0.8, 0.58), Color(0.3, 0.75, 0.35) if chosen else Color(0.42, 0.26, 0.12), 5 if chosen else 3, 16, 8)
	var box: StyleBox = _ui_box("card_selected" if chosen else "card", sb)
	for st in ["normal", "hover", "pressed", "hover_pressed"]:
		b.add_theme_stylebox_override(st, box)
	b.pressed.connect(func(): select(sid))
	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	vb.offset_left = CARD_INSET.x
	vb.offset_right = -CARD_INSET.x
	vb.offset_top = CARD_INSET.y
	vb.offset_bottom = -CARD_INSET.y - 2.0
	vb.add_theme_constant_override("separation", 2)
	b.add_child(vb)
	var icon := TextureRect.new()
	icon.texture = Economy.icon_of(sid)
	icon.size_flags_vertical = Control.SIZE_EXPAND_FILL
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	vb.add_child(icon)
	var n := _sell_count(sid)
	var label := Economy.name_of(sid) + ("  x%d" % n if n > 1 else "")
	var nm := _text(label, 17 if label.length() <= 12 else 14, Color(1, 0.97, 0.88))
	nm.add_theme_color_override("font_outline_color", Color(0.3, 0.15, 0.05))
	nm.add_theme_constant_override("outline_size", 6)
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.clip_text = true
	vb.add_child(nm)
	var pill := PanelContainer.new()
	pill.add_theme_stylebox_override("panel", _ui_box("price_pill", _flat(Color(0.25, 0.14, 0.07), Color(0.18, 0.09, 0.03), 2, 12, 3)))
	vb.add_child(pill)
	var prow := HBoxContainer.new()
	prow.alignment = BoxContainer.ALIGNMENT_CENTER
	prow.add_theme_constant_override("separation", 6)
	pill.add_child(prow)
	var coin := TextureRect.new()
	coin.texture = load(MEAT)
	coin.custom_minimum_size = Vector2(24, 24)
	coin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	coin.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	prow.add_child(coin)
	prow.add_child(_text("+%d" % Economy.sell_price(sid), 20, Color(0.7, 1.0, 0.6)))
	Herd._ignore_mouse(vb)
	return b


## How many of a sellable there are (materials and cards stack; gear is one copy).
func _sell_count(sid: String) -> int:
	var kind := sid.get_slice(":", 1)
	var what := sid.substr(Economy.PREFIX.length() + kind.length() + 1)
	match kind:
		"mat": return int(game.materials.get(what, 0))
		"card": return Gear.free_cards(what)
	return 1


## The Sell tab's strip: what it is, what it's worth and what the merchant
## pays (80%), and SELL (a second tap confirms).
func _sell_detail(sid: String) -> void:
	var light := Color(1, 0.95, 0.82)
	detail.add_child(_text(Economy.name_of(sid), 22, light))
	var kind := sid.get_slice(":", 1)
	var what := sid.substr(Economy.PREFIX.length() + kind.length() + 1)
	var extra := ""
	if kind == "gear":
		extra = Gear.bonus_text(what) + (("  ·  Durability %d/%d" % [Gear.durability(what), Gear.max_durability(what)]) if Gear.max_durability(what) > 0 else "")
		if Gear.socketed(what) != "":
			extra += "  ·  its %s Card goes back to your pile" % Herd.name_of(Gear.socketed(what))
	elif kind == "mat":
		extra = "One piece (you have %d)." % _sell_count(sid)
	else:
		extra = "One card (%d spare)." % _sell_count(sid)
	var d := _text("%s\nWorth %d meat: the merchant pays %d%%." % [extra, int(round(Economy.value(sid))), int(round(float(Economy.num("sell", "share")) * 100.0))], 15, Color(0.95, 0.88, 0.75))
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d.name = "SellInfo"
	detail.add_child(d)
	var b := _buy_button("SURE?" if _confirm == sid else "SELL", str(Economy.sell_price(sid)), true, "Sell")
	b.pressed.connect(func(): press_sell(sid))
	buy_box.add_child(b)


## First tap arms SELL, the second sells: the meat goes into the bank.
func press_sell(sid: String) -> void:
	if _drag_dist > 12.0:
		return
	if _confirm != sid:
		_confirm = sid
		selected = sid
		_say = ""
		game.audio.play("click", 0.0)
	else:
		_confirm = ""
		var got: int = game.sell(sid)
		if got > 0:
			_say = "A fine trade! +%d meat." % got
			scene.happy()
			if not Economy.sellables(game.gear_owned, game.gear_equipped, game.materials).has(sid):
				selected = ""
	refresh()


func _card(id: String) -> Control:
	var have := owns(id)
	var sale := on_sale(id, game.best_m)
	var b := Button.new()
	b.name = id
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = _card_size
	var chosen := id == selected
	var bg := Color(0.92, 0.8, 0.58) if (have or sale) else Color(0.62, 0.55, 0.45)
	var sb := _flat(bg, Color(0.3, 0.75, 0.35) if chosen else Color(0.42, 0.26, 0.12), 5 if chosen else 3, 16, 8)
	if chosen:
		sb.shadow_color = Color(0.3, 1.0, 0.45, 0.55)
		sb.shadow_size = 10
	var box: StyleBox = _ui_box("card_selected" if chosen else ("card" if (have or sale) else "card_locked"), sb)
	for st in ["normal", "hover", "pressed", "hover_pressed"]:
		b.add_theme_stylebox_override(st, box)
	b.pressed.connect(func(): select(id))
	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	# the picture, name and price sit inside the card frame's border, never on it
	vb.offset_left = CARD_INSET.x
	vb.offset_right = -CARD_INSET.x
	vb.offset_top = CARD_INSET.y
	vb.offset_bottom = -CARD_INSET.y - 2.0
	vb.add_theme_constant_override("separation", 2)
	b.add_child(vb)
	var icon := TextureRect.new()
	icon.texture = _icon_of(id)
	icon.size_flags_vertical = Control.SIZE_EXPAND_FILL
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if Dinos.has(id) and (have or sale):
		_anims.append([icon, id, 0, Dinos.frame_times(id)[0]])
	if not have and not sale:
		icon.modulate = Color(0.12, 0.07, 0.03, 0.85)   # silhouette until on sale
	vb.add_child(icon)
	var nm := _text(item_name(id), 17 if item_name(id).length() <= 12 else 14, Color(1, 0.97, 0.88))   # long names a size down
	nm.add_theme_color_override("font_outline_color", Color(0.3, 0.15, 0.05))
	nm.add_theme_constant_override("outline_size", 6)
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.clip_text = true
	vb.add_child(nm)
	# the price pill
	var pill := PanelContainer.new()
	var short: bool = sale and not have and game.meat_bank < price(id)
	pill.add_theme_stylebox_override("panel", _ui_box("price_pill_short" if short else "price_pill", _flat(Color(0.25, 0.14, 0.07), Color(0.18, 0.09, 0.03), 2, 12, 3)))
	vb.add_child(pill)
	var prow := HBoxContainer.new()
	prow.alignment = BoxContainer.ALIGNMENT_CENTER
	prow.add_theme_constant_override("separation", 6)
	pill.add_child(prow)
	if have:
		prow.add_child(_text("OWNED", 17, Color(0.55, 1.0, 0.5)))
	elif not sale:
		var lock_tex := _ui_tex("padlock")
		if lock_tex:
			var lk := TextureRect.new()
			lk.texture = lock_tex
			lk.custom_minimum_size = Vector2(22, 22)
			lk.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			lk.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			prow.add_child(lk)
		prow.add_child(_text("LOCKED" if lock_tex else "🔒 LOCKED", 16, Color(0.85, 0.78, 0.68)))
	else:
		var coin := TextureRect.new()
		coin.texture = load(MEAT)
		coin.custom_minimum_size = Vector2(24, 24)
		coin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		coin.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		prow.add_child(coin)
		prow.add_child(_text(str(price(id)), 20, Color(1, 0.96, 0.85) if game.meat_bank >= price(id) else Color(1.0, 0.6, 0.5)))
	if have:   # ✓ badge (the pack's green check, or a drawn one)
		var ck: Control
		var ck_tex := _ui_tex("check")
		if ck_tex:
			var tr := TextureRect.new()
			tr.texture = ck_tex
			tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			ck = tr
		else:
			var cl := _text("✓", 22, Color(1, 1, 1))
			cl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			cl.add_theme_stylebox_override("normal", _flat(Color(0.25, 0.65, 0.3), Color(0.12, 0.35, 0.15), 3, 8, 0))
			ck = cl
		ck.name = "Owned"
		ck.position = Vector2(_card_size.x - 44.0, 8.0)
		ck.size = Vector2(36, 36)
		b.add_child(ck)
	if _new.has(id) and not have:
		var tag := _text(" NEW ", 14, Color(1, 0.97, 0.9))
		tag.name = "New"
		tag.add_theme_stylebox_override("normal", _flat(Color(0.85, 0.3, 0.15), Color(0.5, 0.15, 0.05), 2, 8, 0))
		tag.position = Vector2(12, 10)
		b.add_child(tag)
	Herd._ignore_mouse(b)
	return b


## The merchant's lines (the user wants him varied, never predictable): a pool
## per situation, picked at random by say() without repeating the last one; a
## line stays while you look at the same thing. %d / %s are filled in by the
## caller (a price, a shortfall, a name, what's still needed).
## He's Ugo, an old cave trader: a big-hearted showman who loves meat more
## than anything, tells tall tales about outfoxing the T-rex, grumbles about
## his back, trusts his lucky rock, haggles for fun and secretly worries about
## the runners he sells to.
const LINES := {
	"greet": [
		"Welcome, runner! Ugo's cave is open. Wipe your feet.",
		"Ah! A customer! My lucky rock said one would come today.",
		"Back again? Ugo kept the good stuff hidden. Just for you.",
		"Meat for treasures! The finest trade under any mountain.",
		"You're alive! Ugo is so happy. Happy customers buy more.",
		"Oof, my back... Never mind me. Look, look! Everything shines!",
		"Ugo once traded a tooth with a T-rex. Its tooth. Long story. Browse!",
		"Smell that? That's the smell of bargains. And smoke. Mostly bargains.",
		"Come in, come in, before the hunter sees you standing there.",
		"Ugo dreamed of you last night. You bought everything. Ha! No pressure.",
		"Every runner needs an edge. Ugo sells edges. Sharp ones.",
		"Fresh stock today! Well... fresh-ish. Ugo dusted it.",
		"The moon was round last night. Good luck for buying, very good.",
		"Sit by the fire? No? Always running, you lot. Quick look, then!",
	],
	"powerups": [
		"Fresh from the deep caves! Ugo got lost three days finding it.",
		"A little magic for a long run. Ugo tested it. Mostly.",
		"The elders swear by these. The ones who are still around.",
		"Pop it when the T-rex breathes down your neck. Works every time! Ugo thinks.",
		"Small, yes. But small things save big runners.",
		"It glowed when Ugo found it in a hot spring. Glowing means good. Right?",
		"Ugo's mother used these. She outran a whole herd once. True story!",
		"Don't eat it. Unless it's the berry. Then eat it fast.",
		"Ugo would keep this for himself, but his running days are over. Oof.",
	],
	"gear": [
		"Gathered by Ugo's own hands! Mostly. A raccoon helped.",
		"Take it to the Crafting Bench and make something sharp!",
		"Good stone, good wood, good knots. Ugo-standard quality!",
		"Craft it yourself, Ugo says. Ugo hit his toe the last time he crafted.",
		"Ugo's grandfather built a whole hut from these. It fell down. Nicely.",
		"Lucky crafters get shiny gold weapons. Ugo is not a lucky crafter.",
		"A runner without gear is a runner with bruises. Ugo knows. Ugo has many.",
		"Ugo blessed this pile with his lucky rock. Twice. Extra lucky.",
		"Break things out there and you find this for free. But Ugo is closer!",
	],
	"dinos": [
		"A fine beast! Tame, fed, and only bites when asked nicely.",
		"Ugo raised this one from an egg. It still thinks Ugo is its mother.",
		"Fast legs, strong tail, huge appetite. Like Ugo, but faster.",
		"Ride it once and you'll never want to walk again. Ugo hasn't walked in years. Oof.",
		"Careful, it likes you already. Look at that tail go!",
		"Ugo named it, but it doesn't answer. Call it whatever you like.",
		"This one chased a hunter off once. True! Ugo saw it. From far away.",
		"Feed it, train it, love it, and it carries you to the end of the world.",
		"It ate Ugo's sandal yesterday. Good teeth! Very healthy.",
	],
	"heroes": [
		"A brave friend to run with! Ugo vouches for them. Mostly.",
		"Two runners are better than one tired runner.",
		"Good heart, quick feet. You'll get along. Ugo can tell.",
		"Tough as old hide! Tougher than Ugo's old hide, anyway.",
		"They've outrun more hunters than Ugo has traded meat. That's a LOT of meat.",
		"Every hero has a story. This one's is still being run.",
		"Ugo taught them everything they know. Well, how to haggle.",
	],
	"other": [
		"Something special, for the serious runner. Are you serious? You look serious.",
		"Not flashy, but worth every bite of meat. Ugo promises on his lucky rock.",
		"For runners who mean to go far. Far, far, far.",
		"Rare goods. Ugo doesn't show these to just anyone. You're not just anyone!",
		"You'll thank Ugo in a thousand metres. Ugo accepts thanks in meat.",
		"Ugo hid this under the counter. From whom? From everybody.",
	],
	"owned": [
		"That's already yours, friend! Ugo never forgets a sale. Or a face. Mostly faces.",
		"You have that one! Want Ugo to wrap it again? No? Fine, fine.",
		"Already yours. Greedy! Ugo likes greedy.",
		"Sold! To you. Some time ago. Ugo's memory is fine, see?",
		"You own it! Go use it, before Ugo sells it again by mistake.",
		"Ugo doesn't sell things twice. Not to the same runner, anyway. Ha!",
	],
	"short": [
		"Come back with %d more meat, little runner. Ugo will wait. Ugo is good at waiting.",
		"Hmm. %d meat short. Ugo counted twice. On both hands.",
		"So close! Only %d more meat and it's yours forever.",
		"%d more meat. Go run! The meat won't catch itself.",
		"Ugo likes you. Ugo does not like you %d meat off the price.",
		"Ugo's family has to eat, friend! %d more meat, please.",
		"Not enough... %d more meat should do it. Ugo's tummy agrees.",
	],
	"confirm": [
		"%d meat, and it's yours. Shake on it? Ugo's hand is only a little sticky.",
		"%d meat! A steal. For you, not for Ugo. Deal?",
		"For %d meat? Done! ...If you say so. Say so!",
		"%d meat. Last chance to change your mind! Don't change your mind.",
		"Hand over %d meat and it's all yours. Ugo is already smiling.",
		"%d meat. Ugo's lucky rock says yes. What do you say?",
	],
	"locked": [
		"Not yet, little runner! %s, then come back to Ugo.",
		"Ooh, not so fast! %s first. Ugo has standards. A few.",
		"That one isn't ready for you. %s, and Ugo will sell it gladly.",
		"Patience, runner! %s. Ugo waited forty winters for his. You can wait a bit.",
		"Ugo saves that for real runners. Prove it: %s!",
		"Ugo's lucky rock says no... for now. %s.",
		"Ha! Ugo likes your eyes, but your legs aren't ready. %s.",
	],
	"sold": [
		"Pleasure doing business! Ugo will buy a feast with this.",
		"Good choice! Ugo knew you had taste. And meat.",
		"Ha! You won't regret it. Probably! Ugo never regrets selling.",
		"Meat in Ugo's pouch, treasure in your hands. Perfect day!",
		"Take care of it, and it'll take care of you. Like Ugo's lucky rock.",
		"Another happy runner! Ugo is going to tell everyone.",
		"May it carry you past the T-rex! Ugo will be cheering. From here.",
		"Ugo would hug you, but his back. Oof. Consider yourself hugged!",
	],
	"bye": [
		"Come back soon, runner! Ugo gets lonely. Don't tell anyone.",
		"Run fast, come back rich!",
		"Don't get eaten! Ugo needs the business.",
		"Mind the T-rex on your way out. It's been sniffing around.",
		"Off you go! Bring meat next time. Lots of meat.",
		"Be safe out there. Ugo means it. Mostly for business reasons.",
		"See you after the next run! Ugo's lucky rock says you'll make it.",
	],
}
var _said := {}   # situation -> the line last used (no repeats)
var _visit := 0
var _say_key := ""
var _say_text := ""


## Ugo says a line: it shows in his bubble and, if it's a new line, he
## mumbles (mumble_1..6, tools/make_sounds.py: longer lines, longer mumbles,
## each with a little pitch wobble). No words: caveman gibberish.
func _speak(text: String) -> void:
	if text == say_label.text:
		return
	say_label.text = text
	if text != "" and visible and game and game.audio:
		var n := clampi(text.length() / 16 + randi_range(0, 1), 1, 6)
		game.audio.play("mumble_%d" % n, 0.08, randf_range(0.92, 1.08))


## A line for a situation (`key` names a LINES pool), formatted with `args`.
## The same key for the same item keeps its line; a new one never repeats the
## last line of that pool.
func say(key: String, args := [], stable := "") -> String:
	var tag := key + "|" + stable
	if tag == _say_key:
		return _say_text
	var pool: Array = LINES.get(key, [""])
	var pick: String = pool[randi() % pool.size()]
	if pool.size() > 1:
		while pick == String(_said.get(key, "")):
			pick = pool[randi() % pool.size()]
	_said[key] = pick
	_say_key = tag
	_say_text = (pick % args) if not args.is_empty() else pick
	return _say_text


## The details strip (the chosen item: name, what it does, its numbers, and
## BUY / OWNED / LOCKED / NEED) and the merchant's line over his head.
func _build_detail() -> void:
	for c in detail.get_children():
		detail.remove_child(c)
		c.queue_free()
	for c in buy_box.get_children():
		buy_box.remove_child(c)
		c.queue_free()
	var id := selected
	if id.begins_with(Economy.PREFIX):
		on_counter.texture = Economy.icon_of(id)
		on_counter.modulate = Color.WHITE
		foot_icon.texture = on_counter.texture
		foot_icon.modulate = Color.WHITE
		_speak(_say if _say != "" else ("Selling? I'll give you %d meat for that." % Economy.sell_price(id)) if _confirm != id else "Sure? Tap SELL again.")
		_place_bubble()
		_sell_detail(id)
		return
	on_counter.texture = _icon_of(id) if id != "" else null
	foot_icon.texture = on_counter.texture
	if id == "":
		_speak(_say if _say != "" else say("greet", [], str(_visit)))
		_place_bubble()
		return
	var have := owns(id)
	var cost := price(id)
	var sale := on_sale(id, game.best_m)
	on_counter.modulate = Color.WHITE if (have or sale) else Color(0.12, 0.07, 0.03, 0.85)
	foot_icon.modulate = on_counter.modulate
	var dino := Dinos.has(id)
	var hero_item := Heroes.has(id)
	# the merchant's line
	var line := _say
	if line == "":
		if have:
			line = say("owned", [], id)
		elif not sale:
			line = unlock_hint(id)   # how to unlock it
		elif game.meat_bank < cost:
			line = say("short", [cost - game.meat_bank], id + str(game.meat_bank))
		elif _confirm == id:
			line = say("confirm", [cost], id)
		else:
			line = say(category(id), [], id)
	_speak(line)
	_place_bubble()
	var light := Color(1, 0.95, 0.82)
	var title_row := HFlowContainer.new()   # wraps rather than widening the strip
	title_row.add_theme_constant_override("h_separation", 8)
	detail.add_child(title_row)
	title_row.add_child(_text(item_name(id), 22, light))
	if _new.has(id) and not have:
		var tag := _text(" NEW ", 14, Color(1, 0.97, 0.9))
		tag.name = "New"
		tag.add_theme_stylebox_override("normal", _flat(Color(0.85, 0.3, 0.15), Color(0.5, 0.15, 0.05), 2, 8, 0))
		tag.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		title_row.add_child(tag)
	if dino:
		title_row.add_child(_category_badge(Dinos.category_of(id)))
		var tl := _text("%s tier%s" % [Dinos.tier_label(id), ("  ·  Lv %d★" % Dinos.level(id)) if have else ""], 13, Dinos.tier_color(id).lightened(0.3))
		tl.name = "Tier"
		detail.add_child(tl)
	var desc: String
	if id == SLOT_ID:
		desc = "Carry a third booster at once (the most Rok can hold)."
	elif is_heart(id):
		desc = "One more heart in every run, for good (%d in all once you have it)." % (Tuning.MAX_HEARTS + heart_index(id))
	elif Gear.has(id):
		desc = "%s %s%s%s. Equip it at the Dinosaur Camp." % [Gear.ITEMS[id].desc, Gear.bonus_text(id),
				(", reach %d" % int(Gear.ITEMS[id].reach)) if Gear.ITEMS[id].has("reach") else "",
				(", lasts %d hits" % Gear.max_durability(id)) if Gear.max_durability(id) > 0 else ""]
	elif id.begins_with(Crafting.MAT_PREFIX):
		var m := id.substr(Crafting.MAT_PREFIX.length())
		desc = "%d %s for crafting weapons and armor at the Crafting Bench. You have %d. Also from: %s" % [
				Crafting.bundle(), Crafting.mat_name(m), Crafting.have(m), String(Crafting.mat(m).from)]
	elif id == Gear.CARD_PACK:
		var n := 0
		for k in game.cards:
			n += int(game.cards[k])
		desc = "A random dinosaur card to slot into a weapon. You have %d card%s." % [n, "" if n == 1 else "s"]
		if game.last_card != "":
			desc += " Last: %s Card." % Herd.name_of(game.last_card)
	elif dino:
		desc = Dinos.desc(id)
	elif hero_item:
		desc = "A new hero (%s): %s" % [Heroes.role_of(id), String(Heroes.INFO[id].blurb)]
	else:
		desc = String(Boosters.DATA[id].desc)
	var d := _text(desc, 15 if not (dino or hero_item) else 14, Color(0.95, 0.88, 0.75))
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.add_child(d)
	if dino or hero_item:
		detail.add_child(_stats_row(id))
		var trade := _text(Dinos.tradeoff(id), 13, Color(0.9, 0.78, 0.6))
		trade.name = "Tradeoff"
		detail.add_child(trade)
	if have:
		var on: bool = (dino or hero_item) and game.equipped_in("hero" if hero_item else Dinos.category_of(id)) == id
		var hint := _text(("Equipped" if on else "Owned") + " · level up, equip and compare at the Dinosaur Camp.", 14, Color(0.6, 1.0, 0.55))
		hint.name = "CampHint" if Gear.has(id) else "HerdHint"
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		detail.add_child(hint)
		buy_box.add_child(_buy_button("OWNED", "", false, "BuyState"))
		return
	if not sale:
		# one requirement per line ("✓" when met), not a run-on line
		var lock := _text("Needs: " + lock_text(id, game.best_m).replace(" · ", "\n"), 14, Color(1.0, 0.75, 0.55))
		lock.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lock.name = "Locked"
		detail.add_child(lock)
		# right under the name (and tier), so what unlocks it never scrolls out of view
		detail.move_child(lock, 2 if dino else 1)
		buy_box.add_child(_buy_button("LOCKED", "", false, "BuyState"))
		return
	if game.meat_bank < cost:
		buy_box.add_child(_buy_button("NEED %d" % (cost - game.meat_bank), str(cost), false, "BuyState"))
		return
	var b := _buy_button("SURE?" if _confirm == id else "BUY", str(cost), true, "Buy")
	b.pressed.connect(func(): press_buy(id))
	buy_box.add_child(b)


## The big green BUY button with the price (greyed when you can't buy).
func _buy_button(label: String, cost: String, live: bool, node_name: String) -> Button:
	var b := Button.new()
	b.name = node_name
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(188, 112)   # the green pill fills it (its art's padding is cropped)
	b.disabled = not live
	var green := Color(0.38, 0.72, 0.22) if label != "SURE?" else Color(0.85, 0.72, 0.2)
	var sb := _flat(green if live else Color(0.42, 0.38, 0.34), Color(0.16, 0.32, 0.08) if live else Color(0.22, 0.2, 0.18), 5, 20, 6)
	for st in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		var s2: StyleBox = _ui_box("buy_button" if live else "buy_button_disabled", sb)
		if st.begins_with("pressed") or st == "hover_pressed":
			s2 = _ui_box("buy_button_pressed", _flat(green.darkened(0.15), Color(0.16, 0.32, 0.08), 5, 20, 6)) if live else s2
		b.add_theme_stylebox_override(st, s2)
	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_FULL_RECT)
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 0)
	b.add_child(vb)
	var l := _text(label, 30 if label.length() <= 5 else 20, Color(1, 1, 0.95))
	l.add_theme_color_override("font_outline_color", Color(0.12, 0.22, 0.05) if live else Color(0.15, 0.12, 0.1))
	l.add_theme_constant_override("outline_size", 8)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(l)
	if cost != "":
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 6)
		var coin := TextureRect.new()
		coin.texture = load(MEAT)
		coin.custom_minimum_size = Vector2(28, 28)
		coin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		coin.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(coin)
		var pl := _text(cost, 26, Color(1, 1, 0.95))
		pl.add_theme_color_override("font_outline_color", Color(0.12, 0.22, 0.05))
		pl.add_theme_constant_override("outline_size", 8)
		row.add_child(pl)
		vb.add_child(row)
	Herd._ignore_mouse(vb)
	return b


## First tap arms the button, the second buys: the merchant beams, the item
## flies from the counter to the hero, and the hero cheers.
func press_buy(id: String) -> void:
	if _drag_dist > 12.0:
		return   # that was a scroll, not a tap
	if _confirm != id:
		_confirm = id
		selected = id
		_say = ""
		game.audio.play("click", 0.0)
	else:
		_confirm = ""
		if game.buy(id):
			_sold(id)
	refresh()


func _sold(id: String) -> void:
	selected = id
	_say = say("sold", [], id + str(game.meat_bank))
	scene.happy()
	if merchant.visible:
		merchant.play("buy")   # he hands over the parcel and gives a thumbs-up
	if not is_inside_tree():
		return
	var fly := TextureRect.new()
	fly.texture = _icon_of(id)
	fly.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fly.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	fly.size = Vector2(80, 80)
	fly.position = on_counter.position + Vector2(8, 8)
	fly.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(fly)
	var target: Vector2 = scene.hero_spot() + Vector2(-40.0, -200.0)
	var t := fly.create_tween()
	t.tween_property(fly, "position", (fly.position + target) * 0.5 + Vector2(0, -120.0), 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.tween_property(fly, "position", target, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	t.parallel().tween_property(fly, "scale", Vector2(0.4, 0.4), 0.25)
	t.tween_callback(fly.queue_free)
	if hero.sprite_frames and hero.sprite_frames.has_animation("celebrate"):
		hero.play("celebrate")
	else:
		var hop := hero.create_tween()
		hop.tween_property(hero, "position:y", hero.position.y - 40.0, 0.15)
		hop.tween_property(hero, "position:y", hero.position.y, 0.2)


## Drag to scroll (as in the Field Guide: the cards would swallow the drag).
func _input(event: InputEvent) -> void:
	if not visible:
		return
	var drag := event as InputEventScreenDrag
	if drag:
		_dragging = true
		_drag_dist += drag.relative.length()
		scroll.scroll_vertical -= int(drag.relative.y)
		_fling = -drag.velocity.y
		return
	var t := event as InputEventScreenTouch
	if t:
		if t.pressed:
			_fling = 0.0
			_drag_dist = 0.0
		else:
			_dragging = false


func _process(delta: float) -> void:
	if not visible:
		return
	_animate(delta)
	if _dragging or absf(_fling) < 5.0:
		return
	scroll.scroll_vertical += int(_fling * delta)
	_fling = lerpf(_fling, 0.0, minf(delta * 5.0, 1.0))


## Step the dino cards' idle loops (frame times from the art).
func _animate(delta: float) -> void:
	for a in _anims:
		a[3] -= delta
		if a[3] <= 0.0:
			a[2] = (a[2] + 1) % 8
			a[3] += Dinos.frame_times(a[1])[a[2]]
			(a[0] as TextureRect).texture = Dinos.frame(a[1], a[2])


## A small coloured tag with the dinosaur's category (Runner, Smasher...).
func _category_badge(cat: String) -> Label:
	var c: Dictionary = Dinos.CATEGORIES[cat]
	var tag := _text(" %s " % String(c.name).to_upper(), 15, Color(1, 0.97, 0.9))
	tag.name = "Category"
	tag.tooltip_text = c.role
	var ts := StyleBoxFlat.new()
	ts.bg_color = (Forms.get_data(c.form).color as Color).darkened(0.25)
	ts.set_corner_radius_all(8)
	tag.add_theme_stylebox_override("normal", ts)
	tag.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return tag


## The five attributes as pips; the category's lean attribute is highlighted.
## A flow row: it wraps instead of widening the details strip (one unbreakable
## line pushed the shop panel off the right edge on the Dinosaurs and Heroes tabs).
func _stats_row(id: String) -> HFlowContainer:
	var row := HFlowContainer.new()
	row.name = "Stats"
	row.add_theme_constant_override("h_separation", 8)
	row.add_theme_constant_override("v_separation", 0)
	var lean: String = "" if Heroes.is_hero(id) else String(Dinos.CATEGORIES[Dinos.category_of(id)].lean)
	for a in Dinos.ATTRS:
		var hot: bool = a == lean
		var ink := Color(1.0, 0.72, 0.35) if hot else Color(0.95, 0.86, 0.7)   # light, on the dark details strip
		var col := HBoxContainer.new()   # "Speed 7" on one line, so the strip needs no scrolling
		col.add_theme_constant_override("separation", 3)
		col.add_child(_text(Dinos.ATTR_NAMES[a], 12, ink))
		var num := _text(Dinos.fmt(Dinos.stat(id, a)), 15, ink)
		num.name = "Val_" + a
		col.add_child(num)   # out of 10
		row.add_child(col)
	return row


var _slot_tex: Texture2D


## Picture for the slot item: an empty round slot with a plus.
func _slot_icon() -> Texture2D:
	if _slot_tex:
		return _slot_tex
	var img := Image.create(128, 128, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var c := Vector2(64, 64)
	for y in 128:
		for x in 128:
			var r := Vector2(x + 0.5, y + 0.5).distance_to(c)
			if r < 52.0:
				img.set_pixel(x, y, Color(0.45, 0.25, 0.1) if r > 44.0 else Color(1.0, 0.95, 0.82))
	img.fill_rect(Rect2i(58, 34, 12, 60), Color(0.85, 0.55, 0.15))
	img.fill_rect(Rect2i(34, 58, 60, 12), Color(0.85, 0.55, 0.15))
	_slot_tex = ImageTexture.create_from_image(img)
	return _slot_tex


## A screen's title: the user's banner (assets/ui/banner_<name>.png, the
## label baked in: ENCYCLOPEDIA, MARKETPLACE, DINOSAURS) at TITLE_BANNER_H,
## or the given text label until it's imported.
static func title_banner(banner: String, fallback: Control) -> Control:
	var path := "res://assets/ui/banner_%s.png" % banner
	if not ResourceLoader.exists(path):
		return fallback
	fallback.free()
	var tex: Texture2D = load(path)
	var t := TextureRect.new()
	t.name = "TitleBanner"
	t.texture = tex
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.custom_minimum_size = Vector2(Tuning.TITLE_BANNER_H * tex.get_width() / tex.get_height(), Tuning.TITLE_BANNER_H)
	t.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t


## Opening a screen: a quick fade in, like a scene change.
static func enter(node: CanvasItem) -> void:
	node.modulate.a = 0.0
	node.create_tween().tween_property(node, "modulate:a", 1.0, 0.2)


## A full-screen scene backdrop (the user wanted the Market, Field Guide and
## Camp as their own screens, not overlays on the run): a zone painting,
## darkened with a tint, fully opaque so the game doesn't show through.
## The Market's surroundings: the game's own daytime sky, mountains (bg_2)
## and jungle (bg_1), at full strength, so the area above the cave and the
## gap beside it on wide phones read as the outdoors instead of a flat green
## wash (the old backdrop()).
static func outdoor_backdrop() -> Control:
	var c := Control.new()
	c.name = "Backdrop"
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sky := TextureRect.new()
	var g := Gradient.new()
	g.set_color(0, Color(0.42, 0.66, 0.9))
	g.set_color(1, Color(0.86, 0.9, 0.78))
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.fill_from = Vector2(0, 0)
	gt.fill_to = Vector2(0, 1)
	sky.texture = gt
	c.add_child(sky)
	for art in ["res://assets/bg/bg_2.png", "res://assets/bg/bg_1.png"]:
		var pic := TextureRect.new()
		pic.texture = load(art)
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		c.add_child(pic)
	var shade := ColorRect.new()   # a touch darker, so the shop panel stands out
	shade.color = Color(0.1, 0.12, 0.05, 0.18)
	c.add_child(shade)
	for n in c.get_children():
		(n as Control).set_anchors_preset(Control.PRESET_FULL_RECT)
		(n as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


static func backdrop(art: String, tint: Color) -> Control:
	var c := Control.new()
	c.name = "Backdrop"
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	var base := ColorRect.new()
	base.color = tint
	base.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.add_child(base)
	var pic := TextureRect.new()
	pic.texture = load(art)
	pic.set_anchors_preset(Control.PRESET_FULL_RECT)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	pic.modulate = Color(1, 1, 1, 0.55)
	c.add_child(pic)
	var shade := ColorRect.new()
	shade.color = Color(tint.r, tint.g, tint.b, 0.45)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.add_child(shade)
	for n in [base, pic, shade]:
		(n as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


static func _text(t: String, size: int, color := INK) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


static func _button(t: String, min_size: Vector2) -> Button:
	var b := Button.new()
	b.text = t
	b.custom_minimum_size = min_size
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 22)
	for state in ["normal", "hover", "pressed", "hover_pressed"]:
		var sb := StyleBoxFlat.new()
		var on: bool = state == "pressed" or state == "hover_pressed"
		sb.bg_color = Color(0.55, 0.3, 0.12) if on else Color(0.95, 0.72, 0.3)
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
