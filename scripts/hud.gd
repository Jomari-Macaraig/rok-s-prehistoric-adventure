class_name Hud
extends CanvasLayer
## Mobile-landscape HUD. Top: pause / sound buttons, energy bar, score.
## Bottom (sitting on the dirt below the ground line): form buttons on the
## left, a big jump button on the right. Touch handling lives in main.gd,
## which asks action_at() which button (if any) a touch hit.

const MEAT_ICON := "res://assets/items/meat.png"   # static icon (tools/prepare_meat.gd)
var score_label: Label
var best_label: Label
var meat_label: Label    # meat collected this run (Market currency)
var meat_pill: PanelContainer   # its own pill under the score panel
var _meat_shown := -1
var energy_bar: ProgressBar
var status_panel: PanelContainer   # Rok's hearts and PRIMAL energy, top left
var _energy_fill: StyleBoxFlat
const ENERGY_COLOR := Color(1.0, 0.65, 0.15)
const ENERGY_HOT := Color(0.95, 0.2, 0.12)
var shield_label: Label
var hearts_box: HBoxContainer   # Rok's hearts, the status panel's first row
var _hearts_shown := -1
var form_buttons := {}          # form -> TouchButton
var jump_button: TouchButton
var slide_button: TouchButton
var attack_button: TouchButton   # lunge at the nearest thing ahead (main._attack)
var slot_buttons: Array[TouchButton] = []   # booster slots
var pause_button: TouchButton
var sound_button: TouchButton
var codex_button: TouchButton
var market_button: TouchButton
var herd_button: TouchButton   # opens the Camp (level up, gear, choose dinosaurs)
var stop_button: TouchButton   # ends the run early (two taps; main._press_stop)
var tips_button: TouchButton   # coach hints on/off, shown on the pause screen
var tutorial_button: TouchButton   # replays the training run, on the main menu
var tutorial_plaque: PanelContainer   # "Tutorial", top centre while the training run plays
var skip_button: TouchButton          # "Skip »" beside it (action "stop": a tap asks, a second skips)
var _bulb_on: Texture2D
var _bulb_off: Texture2D
var buttons: Array[TouchButton] = []
var center: VBoxContainer
var center_panel: PanelContainer
var title_label: Label
var sub_label: Label
var help_label: Label
var root: Control
var danger_rect: TextureRect
var chase_meter: ChaseMeter
var combo_meter: ComboMeter   # combo streak + Primal Frenzy, under the meat pill
var event_label: Label        # a mid-run event and its countdown, under the combo meter
var missions_panel: PanelContainer   # today's missions, on the title screen
var missions_label: Label
var banner: PanelContainer
var info_card: Control
var info_icon: TextureRect
var info_title: Label
var info_body: Label
var info_hint: Label
var banner_title: Label
var banner_hint: Label
var _banner_tween: Tween
var _icon_pause: Texture2D
var _icon_sound_on: Texture2D
var _icon_sound_off: Texture2D


func _label(size: int, color := Color(1, 0.97, 0.88)) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0.28, 0.14, 0.05))
	l.add_theme_constant_override("outline_size", maxi(8, size / 4))
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.45))
	l.add_theme_constant_override("shadow_offset_x", 0)
	l.add_theme_constant_override("shadow_offset_y", maxi(2, size / 14))
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _ready() -> void:
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	_make_icons()

	# --- red pulse on the left edge while the T-rex is close
	danger_rect = TextureRect.new()
	var dg := GradientTexture2D.new()
	dg.gradient = Gradient.new()
	dg.gradient.set_color(0, Color(0.85, 0.05, 0.0, 0.75))
	dg.gradient.set_color(1, Color(0.85, 0.05, 0.0, 0.0))
	dg.fill_from = Vector2(0, 0)
	dg.fill_to = Vector2(1, 0)
	danger_rect.texture = dg
	danger_rect.stretch_mode = TextureRect.STRETCH_SCALE
	danger_rect.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	danger_rect.offset_right = 260
	danger_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	danger_rect.modulate.a = 0.0
	root.add_child(danger_rect)

	# --- top left: pause, sound, energy
	pause_button = _button("pause", 64.0)
	pause_button.icon = _icon_pause
	sound_button = _button("sound", 64.0)
	stop_button = _button("stop", 64.0)
	stop_button.icon = _icon_from(func(img: Image):
		img.fill_rect(Rect2i(16, 16, 32, 32), Color(0.45, 0.12, 0.08))
		img.fill_rect(Rect2i(20, 20, 24, 24), Color(0.8, 0.22, 0.12)))
	stop_button.visible = false
	# coach hints on/off, on the pause screen (the tutorial; main._toggle_tips)
	tips_button = _button("tips", Tuning.TIPS_BUTTON_SIZE)
	_bulb_on = _icon_from(func(img: Image): _bulb(img, true))
	_bulb_off = _icon_from(func(img: Image): _bulb(img, false))
	tips_button.icon = _bulb_on
	tips_button.visible = false
	# the Field Guide and the Camp on the left edge, the Market on the right
	# (big, captioned side buttons on the title, pause and game-over screens)
	codex_button = _button("codex", Tuning.SIDE_BUTTON_SIZE)
	codex_button.icon = _icon_from(func(img: Image): _book(img))
	codex_button.caption = "GUIDE"
	market_button = _button("market", Tuning.SIDE_BUTTON_SIZE)
	market_button.icon = _icon_from(func(img: Image): _bag(img))
	market_button.caption = "MARKET"
	market_button.visible = false
	herd_button = _button("herd", Tuning.SIDE_BUTTON_SIZE)
	herd_button.icon = _icon_from(func(img: Image): _footprint(img))
	herd_button.caption = "CAMP"
	herd_button.visible = false
	# the training run again (main.start_tutorial), on the main menu
	tutorial_button = _button("tutorial", Tuning.TUTORIAL_BUTTON_SIZE)
	tutorial_button.icon = SpriteLib.tex("res://assets/portraits/rok.png")
	tutorial_button.caption = "Tutorial"
	tutorial_button.caption_below = true
	tutorial_button.visible = false
	# the training run's plaque and Skip (after the user's mockups)
	tutorial_plaque = PanelContainer.new()
	tutorial_plaque.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var psb := StyleBoxFlat.new()
	psb.bg_color = Color(0.96, 0.86, 0.62)
	psb.border_color = Color(0.45, 0.26, 0.1)
	psb.set_border_width_all(3)
	psb.set_corner_radius_all(12)
	psb.content_margin_left = 22
	psb.content_margin_right = 22
	psb.content_margin_top = 4
	psb.content_margin_bottom = 6
	psb.shadow_color = Color(0, 0, 0, 0.3)
	psb.shadow_size = 3
	var kit_plaque := SpriteLib.tutorial_box("plaque")   # the user's wood-and-bone plaque
	if kit_plaque:
		kit_plaque.content_margin_left = 40
		kit_plaque.content_margin_right = 40
		kit_plaque.content_margin_top = 4
		kit_plaque.content_margin_bottom = 8
	tutorial_plaque.add_theme_stylebox_override("panel", kit_plaque if kit_plaque else psb)
	var pl := _label(26, Color(1.0, 0.95, 0.82) if kit_plaque else Color(0.32, 0.17, 0.06))
	pl.text = "Tutorial"
	pl.add_theme_font_override("font", SpriteLib.ui_font("heading"))
	if kit_plaque:
		pl.add_theme_constant_override("outline_size", 6)
	else:
		pl.remove_theme_constant_override("outline_size")
	tutorial_plaque.add_child(pl)
	tutorial_plaque.visible = false
	root.add_child(tutorial_plaque)
	skip_button = _button("stop", 60.0)
	skip_button.pill_text = "Skip »"
	skip_button.custom_minimum_size = Vector2(112, 44)
	skip_button.size = skip_button.custom_minimum_size
	skip_button.visible = false
	# the user's square menu buttons replace the drawn ones when imported, their name below
	for trio in [[codex_button, "encyclopedia", "Encyclopedia"], [market_button, "marketplace", "Marketplace"], [herd_button, "dinosaurs", "Dinosaurs"], [tutorial_button, "tutorial", "Tutorial"]]:
		var path := "res://assets/ui/square_%s.png" % trio[1]
		if ResourceLoader.exists(path):
			(trio[0] as TouchButton).caption = trio[2]
			(trio[0] as TouchButton).set_banner(load(path), Tuning.SIDE_BUTTON_SIZE)
	# --- top left, after the pause/sound/book buttons: Rok's status panel,
	# stacked: row 1 his hearts (and any shield), row 2 PRIMAL energy, row 3
	# the hunter meter. Everything about Rok's survival in one spot.
	status_panel = PanelContainer.new()
	status_panel.name = "Status"
	status_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.25, 0.13, 0.06, 0.55)
	sb.set_corner_radius_all(14)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 6
	sb.content_margin_bottom = 8
	status_panel.add_theme_stylebox_override("panel", sb)
	root.add_child(status_panel)
	var rows := VBoxContainer.new()
	rows.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rows.add_theme_constant_override("separation", 4)
	status_panel.add_child(rows)
	var hrow := HBoxContainer.new()
	hrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rows.add_child(hrow)
	hearts_box = HBoxContainer.new()
	hearts_box.name = "Hearts"
	hearts_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hearts_box.add_theme_constant_override("separation", 3)
	for i in Tuning.MAX_HEARTS:
		var h := TextureRect.new()
		h.texture = Hearts.icon(Hearts.QUARTERS)
		h.custom_minimum_size = Vector2(34, 34)
		h.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		h.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		h.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hearts_box.add_child(h)
	hrow.add_child(hearts_box)
	shield_label = _label(18, Color(0.6, 0.9, 1.0))
	shield_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hrow.add_child(shield_label)
	var ebox := HBoxContainer.new()
	ebox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ebox.add_theme_constant_override("separation", 6)
	rows.add_child(ebox)
	var el := _label(15)
	el.text = "PRIMAL"
	ebox.add_child(el)
	energy_bar = ProgressBar.new()
	energy_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	energy_bar.custom_minimum_size = Vector2(262, 16)
	energy_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	energy_bar.show_percentage = false
	energy_bar.max_value = Tuning.ENERGY_MAX
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.15, 0.08, 0.04, 0.8)
	bg.set_corner_radius_all(8)
	var fill := StyleBoxFlat.new()
	fill.bg_color = ENERGY_COLOR
	_energy_fill = fill
	fill.set_corner_radius_all(8)
	energy_bar.add_theme_stylebox_override("background", bg)
	energy_bar.add_theme_stylebox_override("fill", fill)
	ebox.add_child(energy_bar)
	# row 3: how far behind the hunter is
	chase_meter = ChaseMeter.new()
	rows.add_child(chase_meter)


	# --- top right: score
	var sbox := VBoxContainer.new()
	sbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sbox.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	sbox.offset_left = -380
	sbox.offset_right = -Tuning.UI_MARGIN
	sbox.offset_top = 12
	var score_bg := Panel.new()
	score_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ssb := StyleBoxFlat.new()
	ssb.bg_color = Color(0.25, 0.13, 0.06, 0.55)
	ssb.set_corner_radius_all(14)
	score_bg.add_theme_stylebox_override("panel", ssb)
	score_bg.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	score_bg.offset_left = -300
	score_bg.offset_right = -Tuning.UI_MARGIN + 14
	score_bg.offset_top = 14
	score_bg.offset_bottom = 124
	root.add_child(score_bg)
	root.add_child(sbox)
	score_label = _label(48)
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	best_label = _label(22, Color(1, 0.85, 0.55))
	best_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	sbox.add_child(score_label)
	sbox.add_child(best_label)

	# --- meat collected this run: its own pill under the score panel, growing
	# leftwards from the right edge, with a pop on every pickup
	meat_pill = PanelContainer.new()
	meat_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var msb := ssb.duplicate() as StyleBoxFlat
	msb.content_margin_left = 12
	msb.content_margin_right = 16
	msb.content_margin_top = 4
	msb.content_margin_bottom = 4
	meat_pill.add_theme_stylebox_override("panel", msb)
	meat_pill.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	meat_pill.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	meat_pill.offset_right = -Tuning.UI_MARGIN + 14
	meat_pill.offset_left = meat_pill.offset_right
	meat_pill.offset_top = 134
	root.add_child(meat_pill)
	combo_meter = ComboMeter.new()
	combo_meter.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	combo_meter.offset_right = -Tuning.UI_MARGIN + 14
	combo_meter.offset_left = combo_meter.offset_right - ComboMeter.W
	combo_meter.offset_top = 250   # below where wide banners reach
	combo_meter.offset_bottom = combo_meter.offset_top + ComboMeter.H
	root.add_child(combo_meter)
	event_label = _label(24, Color(1, 0.85, 0.4))
	event_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	event_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	event_label.offset_right = -Tuning.UI_MARGIN
	event_label.offset_left = event_label.offset_right - 420
	event_label.offset_top = 334
	event_label.visible = false
	root.add_child(event_label)
	var meat_row := HBoxContainer.new()
	meat_row.add_theme_constant_override("separation", 8)
	meat_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	meat_pill.add_child(meat_row)
	var meat_icon := TextureRect.new()
	meat_icon.texture = load(MEAT_ICON)
	meat_icon.custom_minimum_size = Vector2(44, 44)
	meat_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	meat_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	meat_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	meat_row.add_child(meat_icon)
	meat_label = _label(32, Color(1, 0.85, 0.75))
	meat_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	meat_row.add_child(meat_label)

	# --- bottom: form buttons + jump
	for i in Forms.ORDER.size():
		var f: int = Forms.ORDER[i]
		var b := _button("form_%d" % f, Tuning.FORM_BUTTON_SIZE)
		b.icon = SpriteLib.tex("res://assets/portraits/%s.png" % Forms.get_data(f).id)
		form_buttons[f] = b
	jump_button = _button("jump", Tuning.JUMP_BUTTON_SIZE)
	jump_button.arrow = true
	jump_button.caption = "JUMP"
	jump_button.fill = Color(1.0, 0.8, 0.4, 0.92)
	slide_button = _button("slide", Tuning.SLIDE_BUTTON_SIZE)
	slide_button.arrow = true
	slide_button.arrow_down = true
	slide_button.caption = "SLIDE"
	slide_button.fill = Color(0.85, 0.92, 0.7, 0.92)
	attack_button = _button("attack", Tuning.ATTACK_BUTTON_SIZE)
	attack_button.caption = "ATTACK"
	attack_button.fill = Color(1.0, 0.6, 0.45, 0.92)
	# the user's action button art (icons baked in, so no captions)
	for pair in [[jump_button, "jump"], [slide_button, "slide"], [attack_button, "attack"]]:
		var path := "res://assets/ui/button_%s.png" % pair[1]
		if ResourceLoader.exists(path):
			(pair[0] as TouchButton).art = SpriteLib.tex(path)
			(pair[0] as TouchButton).caption = ""
			(pair[0] as TouchButton).arrow = false
	for i in Boosters.MAX_SLOTS:
		var slot_b := _button("slot_%d" % i, Tuning.FORM_BUTTON_SIZE * 0.9)
		slot_b.fill = Color(1.0, 0.95, 0.82, 0.92)
		slot_buttons.append(slot_b)
	# the user's sandstone slot rings: hero on Rok's button, dino on the four
	# dinosaur buttons, power-up on the booster slots (tools/prepare_slot_frames.py)
	if FileAccess.file_exists("res://assets/ui/slot_frames.json"):
		var geo: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/ui/slot_frames.json"))
		var ring_of := func(b: TouchButton, kind: String) -> void:
			b.frame = SpriteLib.tex("res://assets/ui/slot_%s.png" % kind)
			b.frame_geo = geo[kind]
		for f in form_buttons:
			ring_of.call(form_buttons[f], "hero" if f == Forms.ROK else "dino")
		for slot_ring in slot_buttons:
			ring_of.call(slot_ring, "powerup")

	# --- centre messages
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	cc.offset_top = 84.0
	cc.offset_bottom = -230.0
	cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(cc)
	center_panel = PanelContainer.new()
	center_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var cp := StyleBoxFlat.new()
	cp.bg_color = Color(0.16, 0.08, 0.03, 0.78)
	cp.set_corner_radius_all(24)
	cp.border_color = Color(0.55, 0.32, 0.12, 0.9)
	cp.set_border_width_all(3)
	cp.content_margin_left = 40
	cp.content_margin_right = 40
	cp.content_margin_top = 18
	cp.content_margin_bottom = 22
	cp.shadow_color = Color(0, 0, 0, 0.3)
	cp.shadow_size = 10
	center_panel.add_theme_stylebox_override("panel", cp)
	cc.add_child(center_panel)
	center = VBoxContainer.new()
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_theme_constant_override("separation", 10)
	center_panel.add_child(center)
	title_label = _label(68, Color(1.0, 0.82, 0.35))
	sub_label = _label(34)
	help_label = _label(22, Color(1, 0.93, 0.8))
	for l in [title_label, sub_label, help_label]:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		center.add_child(l)
	help_label.add_theme_constant_override("line_spacing", 4)
	# wrapped a little narrower, so the side banner buttons fit beside the panel
	help_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	help_label.custom_minimum_size = Vector2(Tuning.VIEW_W - 2.0 * (Tuning.SIDE_BUTTON_SIZE + 30.0 + Tuning.UI_MARGIN) - 120.0, 0)

	# --- daily missions (title screen), bottom centre between the thumb clusters
	missions_panel = PanelContainer.new()
	missions_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mp := cp.duplicate() as StyleBoxFlat
	mp.content_margin_left = 22
	mp.content_margin_right = 22
	mp.content_margin_top = 10
	mp.content_margin_bottom = 12
	mp.set_corner_radius_all(16)
	missions_panel.add_theme_stylebox_override("panel", mp)
	missions_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	missions_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	missions_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	missions_panel.offset_bottom = -16
	missions_label = _label(20, Color(1, 0.93, 0.8))
	missions_label.add_theme_constant_override("line_spacing", 2)
	missions_panel.add_child(missions_label)
	missions_panel.visible = false
	root.add_child(missions_panel)

	# --- banner for new hazards / unlocks (below the top bar)
	var bc := CenterContainer.new()
	bc.set_anchors_preset(Control.PRESET_TOP_WIDE)
	bc.offset_top = 146
	bc.offset_bottom = 264
	bc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bc)
	banner = PanelContainer.new()
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bsb := StyleBoxFlat.new()
	bsb.bg_color = Color(0.16, 0.08, 0.03, 0.85)
	bsb.set_corner_radius_all(18)
	bsb.set_border_width_all(3)
	bsb.border_color = Color(1.0, 0.8, 0.35)
	bsb.content_margin_left = 30
	bsb.content_margin_right = 30
	bsb.content_margin_top = 10
	bsb.content_margin_bottom = 12
	banner.add_theme_stylebox_override("panel", bsb)
	bc.add_child(banner)
	var bv := VBoxContainer.new()
	bv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.add_child(bv)
	banner_title = _label(38, Color(1.0, 0.85, 0.4))
	banner_hint = _label(24)
	for l in [banner_title, banner_hint]:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		bv.add_child(l)
	banner.modulate.a = 0.0

	# --- info card: the game pauses so something new can be read
	var ic := CenterContainer.new()
	ic.set_anchors_preset(Control.PRESET_FULL_RECT)
	ic.offset_bottom = -150.0
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(ic)
	info_card = ic
	var ip := PanelContainer.new()
	ip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var isb := StyleBoxFlat.new()
	isb.bg_color = Color(0.97, 0.9, 0.74, 0.97)
	isb.set_corner_radius_all(22)
	isb.set_border_width_all(5)
	isb.border_color = Color(0.55, 0.3, 0.12)
	isb.set_content_margin_all(22)
	isb.shadow_color = Color(0, 0, 0, 0.35)
	isb.shadow_size = 14
	ip.add_theme_stylebox_override("panel", isb)
	ic.add_child(ip)
	var ih := HBoxContainer.new()
	ih.add_theme_constant_override("separation", 22)
	ih.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ip.add_child(ih)
	info_icon = TextureRect.new()
	info_icon.custom_minimum_size = Vector2(170, 170)
	info_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	info_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ih.add_child(info_icon)
	var iv := VBoxContainer.new()
	iv.add_theme_constant_override("separation", 8)
	iv.custom_minimum_size = Vector2(520, 0)
	ih.add_child(iv)
	var ink := Color(0.32, 0.17, 0.06)
	info_title = Label.new()
	info_title.add_theme_font_size_override("font_size", 40)
	info_title.add_theme_color_override("font_color", ink)
	iv.add_child(info_title)
	info_body = Label.new()
	info_body.add_theme_font_size_override("font_size", 24)
	info_body.add_theme_color_override("font_color", ink)
	info_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_body.custom_minimum_size = Vector2(520, 0)
	iv.add_child(info_body)
	info_hint = Label.new()
	info_hint.add_theme_font_size_override("font_size", 20)
	info_hint.add_theme_color_override("font_color", Color(0.55, 0.3, 0.12))
	info_hint.text = "Tap to continue"
	iv.add_child(info_hint)
	info_card.visible = false

	get_viewport().size_changed.connect(_layout)
	_layout()


func _button(action: String, d: float) -> TouchButton:
	var b := TouchButton.new(action, d)
	root.add_child(b)
	buttons.append(b)
	return b


## Bottom buttons sit on the dirt below the ground line, so they never
## cover the running lane.
func _layout() -> void:
	var vw := root.get_viewport_rect().size.x
	var vh := root.get_viewport_rect().size.y
	var m := Tuning.UI_MARGIN
	pause_button.position = Vector2(m, 16)
	# just under the energy panel
	status_panel.position = Vector2(m + 232.0, 14.0)
	sound_button.position = Vector2(m + 76, 16)
	stop_button.position = Vector2(m + 152, 16)
	# under the PAUSED panel, above the grass, clear of Rok's lane and both clusters
	tips_button.position = Vector2(vw * 0.5 - tips_button.size.x * 0.5, Tuning.GROUND_Y - Tuning.TIPS_BUTTON_SIZE - 24.0)
	# side buttons: vertically centred on the screen edges, above the thumb clusters
	var mid := vh * 0.5 - 30.0
	codex_button.position = Vector2(m, mid - codex_button.size.y - 22.0)   # room for its name below
	herd_button.position = Vector2(m, mid + 14.0)
	market_button.position = Vector2(vw - m - market_button.size.x, mid - market_button.size.y * 0.5)
	# Tutorial above the Marketplace (room for its name below), under the score panel
	tutorial_button.position = Vector2(market_button.position.x + (market_button.size.x - tutorial_button.size.x) * 0.5,
			market_button.position.y - Tuning.TUTORIAL_GAP - tutorial_button.size.y)
	# Thumb clusters (MLBB-style): each thumb's main button sits in its bottom
	# corner and the secondary buttons arc around it, at the screen edges and
	# clear of Rok's running lane.
	# Left thumb: Rok (main) + the four dinosaurs in an arc.
	var lc := Vector2(m + Tuning.MAIN_FORM_SIZE * 0.5, vh - 12.0 - Tuning.MAIN_FORM_SIZE * 0.5)
	_place(form_buttons[Forms.ROK], lc, Tuning.MAIN_FORM_SIZE)
	var dinos := Forms.ORDER.slice(1)
	for i in dinos.size():
		var a := deg_to_rad(Tuning.LEFT_ARC_DEG[i])
		_place(form_buttons[dinos[i]], lc + Vector2(cos(a), -sin(a)) * Tuning.LEFT_ARC_R, Tuning.ARC_FORM_SIZE)
	# Right thumb: JUMP (main) + SLIDE and the three booster slots in an arc.
	var js := Tuning.JUMP_BUTTON_SIZE
	var rc := Vector2(vw - m - js * 0.5, vh - 12.0 - js * 0.5)
	_place(jump_button, rc, js)
	var aa := deg_to_rad(Tuning.ATTACK_DEG)
	_place(attack_button, rc + Vector2(cos(aa), -sin(aa)) * Tuning.ATTACK_R, Tuning.ATTACK_BUTTON_SIZE)
	var arc := [slide_button] + slot_buttons
	for i in arc.size():
		var a := deg_to_rad(Tuning.RIGHT_ARC_DEG[i])
		var d: float = Tuning.SLIDE_BUTTON_SIZE if i == 0 else Tuning.SLOT_BUTTON_SIZE
		_place(arc[i], rc + Vector2(cos(a), -sin(a)) * Tuning.RIGHT_ARC_R[i], d)
	# buttons that rise above the ground are a little see-through
	for b in buttons:
		if b != pause_button and b != sound_button and b != codex_button and b != market_button and b != herd_button and b != tips_button and b != tutorial_button and b != skip_button:
			b.self_modulate.a = 0.82 if b.position.y < Tuning.GROUND_Y else 1.0


func _place(b: TouchButton, center: Vector2, d: float) -> void:
	b.set_diameter(d)
	b.position = center - Vector2(d, d) * 0.5


func _make_icons() -> void:
	_icon_pause = _icon_from(func(img: Image):
		img.fill_rect(Rect2i(14, 10, 12, 44), Color(0.45, 0.24, 0.1))
		img.fill_rect(Rect2i(38, 10, 12, 44), Color(0.45, 0.24, 0.1)))
	_icon_sound_on = _icon_from(func(img: Image): _speaker(img, true))
	_icon_sound_off = _icon_from(func(img: Image): _speaker(img, false))


## The pause screen's Tips button: on (lit, "TIPS ON") or off.
func set_tips(visible_now: bool, on: bool) -> void:
	tips_button.visible = visible_now
	var cap := "TIPS ON" if on else "TIPS OFF"
	if tips_button.caption != cap or tips_button.active != on:
		tips_button.caption = cap
		tips_button.active = on
		tips_button.icon = _bulb_on if on else _bulb_off
		tips_button.queue_redraw()


## A little light bulb (the Tips button's icon): lit, or grey when off.
func _bulb(img: Image, lit: bool) -> void:
	var glass := Color(1.0, 0.85, 0.3) if lit else Color(0.55, 0.52, 0.48)
	for y in 64:
		for x in 64:
			if Vector2(x, y).distance_to(Vector2(32, 26)) <= 16.0:
				img.set_pixel(x, y, glass)
	img.fill_rect(Rect2i(24, 38, 16, 8), glass)
	img.fill_rect(Rect2i(24, 46, 16, 4), Color(0.45, 0.3, 0.15))
	img.fill_rect(Rect2i(26, 51, 12, 4), Color(0.45, 0.3, 0.15))
	if lit:
		img.fill_rect(Rect2i(28, 18, 3, 8), Color(1, 1, 0.9))


func _icon_from(painter: Callable) -> Texture2D:
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	painter.call(img)
	return ImageTexture.create_from_image(img)


func _book(img: Image) -> void:
	var c := Color(0.45, 0.24, 0.1)
	var page := Color(1, 0.95, 0.82)
	for side in [-1, 1]:
		for y in range(16, 50):
			var tilt := int((y - 16) * 0.12)
			var x0 := 32 if side == 1 else 8 + tilt
			var x1 := 56 - tilt if side == 1 else 32
			img.fill_rect(Rect2i(x0, y, x1 - x0, 1), page)
		img.fill_rect(Rect2i(8 if side == -1 else 32, 14, 24, 3), c)
	img.fill_rect(Rect2i(30, 12, 4, 40), c)
	for y in [24, 30, 36, 42]:
		img.fill_rect(Rect2i(13, y, 13, 2), Color(0.6, 0.4, 0.2))
		img.fill_rect(Rect2i(38, y, 13, 2), Color(0.6, 0.4, 0.2))


## A leather pouch with a gem: the Market.
func _bag(img: Image) -> void:
	var c := Color(0.45, 0.24, 0.1)
	var leather := Color(0.72, 0.45, 0.2)
	for y in range(22, 56):
		var w := int(20 + 6 * sin((y - 22) / 34.0 * PI))
		img.fill_rect(Rect2i(32 - w, y, w * 2, 1), leather)
		img.fill_rect(Rect2i(32 - w - 2, y, 2, 1), c)
		img.fill_rect(Rect2i(32 + w, y, 2, 1), c)
	img.fill_rect(Rect2i(12, 54, 40, 3), c)
	img.fill_rect(Rect2i(22, 14, 20, 8), leather)
	img.fill_rect(Rect2i(20, 20, 24, 3), c)
	for y in range(30, 48):
		var w := 8 - absi(y - 39) * 8 / 9
		img.fill_rect(Rect2i(32 - w, y, w * 2, 1), Color(1.0, 0.65, 0.15))
	img.fill_rect(Rect2i(28, 33, 3, 5), Color(1.0, 0.92, 0.6))


## A three-toed dinosaur footprint: the Herd.
func _footprint(img: Image) -> void:
	var c := Color(0.45, 0.24, 0.1)
	var fill := Color(0.62, 0.78, 0.35)
	var pad := Vector2(32, 42)
	for y in 64:
		for x in 64:
			var p := Vector2(x + 0.5, y + 0.5)
			var d := ((p - pad) / Vector2(13, 11)).length()
			var toe := false
			for a in [-0.55, 0.0, 0.55]:
				var tip: Vector2 = pad + Vector2.from_angle(-PI / 2 + a) * 26.0
				var q := Geometry2D.get_closest_point_to_segment(p, pad, tip)
				if p.distance_to(q) < 5.5 - 2.5 * (q.distance_to(pad) / 26.0):
					toe = true
			if d < 1.0 or toe:
				img.set_pixel(x, y, fill if d < 0.8 or toe else c)
	for a in [-0.55, 0.0, 0.55]:
		var tip: Vector2 = pad + Vector2.from_angle(-PI / 2 + a) * 28.0
		img.fill_rect(Rect2i(int(tip.x) - 2, int(tip.y) - 2, 4, 4), c)


func _speaker(img: Image, on: bool) -> void:
	var c := Color(0.45, 0.24, 0.1)
	img.fill_rect(Rect2i(8, 24, 12, 16), c)
	for x in range(20, 36):
		var h := int((x - 20) * 1.1)
		img.fill_rect(Rect2i(x, 24 - h, 1, 16 + h * 2), c)
	if on:
		for a in range(-40, 41, 4):
			for rr in [10, 18]:
				var p: Vector2 = Vector2(38, 32) + Vector2.from_angle(deg_to_rad(a)) * rr
				img.fill_rect(Rect2i(int(p.x), int(p.y), 3, 3), c)
	else:
		for i in 18:
			img.fill_rect(Rect2i(40 + i, 23 + i, 3, 3), Color(0.75, 0.2, 0.15))
			img.fill_rect(Rect2i(57 - i, 23 + i, 3, 3), Color(0.75, 0.2, 0.15))


func action_at(p: Vector2) -> String:
	if coach_marker != null:
		var chip := coach_marker.chip_at(p)   # a tutorial note's Back / Next
		if chip != "":
			return "note_" + chip
	for b in buttons:
		if b.hit(p):
			return b.action
	return ""


var coach_marker: CoachMarker   # the tutorial's hint (Tutorial, main._coach_step)


## Show a coach hint on the button for `action` (a pulsing ring and a few
## words). Returns false if there's no such button on screen.
func coach(action: String, text: String, under := false) -> bool:
	var b: TouchButton = null
	for x in buttons:
		if x.action == action and x.visible:
			b = x
	if b == null:
		return false
	return coach_control(b, text, under)


## The coach marker on any control (a HUD part, or a screen's Back button).
## It lives on its own layer above everything, the Market, Camp and Field
## Guide included, so the menu tour can point inside them.
func coach_control(target: Control, text: String, under := false, chips: Array = [], title := "", card := false, arc := PackedVector2Array()) -> bool:
	if target == null and title == "":
		return false
	if coach_marker == null:
		var layer := CanvasLayer.new()
		layer.name = "CoachLayer"
		layer.layer = 30
		add_child(layer)
		coach_marker = CoachMarker.new()
		coach_marker.name = "Coach"
		layer.add_child(coach_marker)
	coach_marker.show_on(target, text, under, chips, title, card, arc)
	return true


## The training run's moment to act (after the user's mockups): a big card at
## the top (title + a line, [WORD] highlighted), the button for `action`
## glowing with rays and the tap hand, and optionally a dashed `arc` (screen
## points) showing the move.
func coach_card(action: String, title: String, text: String, arc := PackedVector2Array()) -> bool:
	for x in buttons:
		if x.action == action and x.visible:
			return coach_control(x, text, false, [], title, true, arc)
	return false


## A tutorial note: on a HUD part (hud_part key), or free-standing near the
## top with a heading (key ""), with Back / Next chips.
func coach_note(key: String, title: String, text: String, chips: Array) -> bool:
	return coach_control(hud_part(key) if key != "" else null, text, false, chips, title)


## The HUD part the training run explains: hearts, chase (hunter meter),
## score, distance, meat, primal.
func hud_part(key: String) -> Control:
	match key:
		"hearts": return hearts_box
		"chase": return chase_meter
		"score": return score_label
		"distance": return best_label
		"meat": return meat_pill
		"primal": return energy_bar.get_parent()
	return null


func coach_part(key: String, text: String) -> bool:
	return coach_control(hud_part(key), text)


func hide_coach() -> void:
	if coach_marker:
		coach_marker.hide_now()


func set_held(action: String, held: bool) -> void:
	for b in buttons:
		if b.action == action:
			b.set_held(held)


## The guide button only shows outside gameplay (title, pause, game over).
## The Market button shows on the title and game-over screens; its badge
## means you can afford something.
func set_market(visible_now: bool, affordable: bool) -> void:
	market_button.visible = visible_now
	if market_button.badge != affordable:
		market_button.badge = affordable
		market_button.queue_redraw()


## The Camp (Herd) button shows on the title and game-over screens, beside
## the Market; its red dot means something can level up (or be equipped).
func set_herd(visible_now: bool, ready := false) -> void:
	herd_button.visible = visible_now
	if herd_button.badge != ready:
		herd_button.badge = ready
		herd_button.queue_redraw()


## The Stop button shows during a run (and while paused); armed = waiting
## for its confirming second tap.
## The training run's "Tutorial" plaque and "Skip »", centred in the gap
## between Rok's status panel and the score panel (armed = waiting for the
## confirming second tap).
func set_tutorial_bar(visible_now: bool, armed: bool) -> void:
	tutorial_plaque.visible = visible_now
	skip_button.visible = visible_now
	if not visible_now:
		return
	var vw := root.get_viewport_rect().size.x
	var x0 := status_panel.position.x + status_panel.size.x + 12.0
	var x1 := vw - 300.0 - Tuning.UI_MARGIN   # the score panel's left edge
	var w := tutorial_plaque.size.x + 12.0 + skip_button.size.x
	var x := x0 + maxf((x1 - x0 - w) * 0.5, 0.0)
	tutorial_plaque.position = Vector2(x, 16.0)
	skip_button.position = Vector2(x + tutorial_plaque.size.x + 12.0, 16.0 + (tutorial_plaque.size.y - skip_button.size.y) * 0.5)
	if skip_button.active != armed:
		skip_button.active = armed
		skip_button.queue_redraw()


func set_stop(visible_now: bool, armed: bool) -> void:
	stop_button.visible = visible_now
	if stop_button.active != armed:
		stop_button.active = armed
		stop_button.queue_redraw()


## The Tutorial button shows on the main menu only.
func set_tutorial(visible_now: bool) -> void:
	tutorial_button.visible = visible_now


func set_codex(visible_now: bool, has_new: bool) -> void:
	codex_button.visible = visible_now
	if codex_button.badge != has_new:
		codex_button.badge = has_new
		codex_button.queue_redraw()


## Pulse a form button as a hint (level 1 soft, 2 strong); -1 clears.
func set_glow(form: int, level: int) -> void:
	for f in form_buttons:
		var b: TouchButton = form_buttons[f]
		var want: int = level if f == form else 0
		if b.glow != want:
			b.glow = want
			b.glow_color = Forms.get_data(f).color.lightened(0.2)
			b.queue_redraw()


var _danger_t := 0.0


func set_chase(gap: float, visible_now: bool) -> void:
	chase_meter.gap = gap
	chase_meter.visible = visible_now


## 0 = safe, 1 = the T-rex is about to bite.
func set_danger(v: float) -> void:
	_danger_t += get_process_delta_time() * (4.0 + 8.0 * v)
	danger_rect.modulate.a = v * (0.55 + 0.45 * sin(_danger_t))


## Booster slot buttons: each shows the booster it holds (empty slots are
## dimmed); a held booster that can't be used right now is dimmed too.
## Slots past `open` show a padlock: the distance that unlocks the second,
## "Market" for the third.
func set_slots(slots: Array, ready: Array, open := Boosters.MAX_SLOTS) -> void:
	for i in slot_buttons.size():
		var b := slot_buttons[i]
		var kind: String = slots[i]
		var tex: Texture2D = Boosters.icon(kind) if kind != "" else null
		var en: bool = ready[i]
		var lk: bool = i >= open
		if b.icon != tex or b.enabled != en or b.locked != lk:
			b.icon = tex
			b.enabled = en
			b.locked = lk
			b.lock_text = "Market" if i == Boosters.MARKET_SLOT else "%d m" % int(Progression.SLOT_UNLOCK_M)
			b.queue_redraw()


func pulse_slot(i: int) -> void:
	slot_buttons[i].set_held(true)
	slot_buttons[i].set_held(false)


## The run's meat counter; -1 hides it (title screen, which shows the bank).
## It pops when the number goes up.
## Today's missions on the title screen (an empty list hides them).
func set_missions(lines: Array, header := "DAILY MISSIONS") -> void:
	missions_panel.visible = not lines.is_empty()
	missions_label.text = header + "\n" + "\n".join(lines)


## The running mid-run event ("" hides it).
func set_event(text: String, color := Color(1, 0.85, 0.4)) -> void:
	event_label.visible = text != ""
	event_label.text = text
	event_label.add_theme_color_override("font_color", color)


func set_meat(meat: int) -> void:
	meat_pill.visible = meat >= 0
	if meat < 0:
		_meat_shown = -1
		return
	meat_label.text = str(meat)
	if _meat_shown >= 0 and meat > _meat_shown:
		meat_pill.pivot_offset = meat_pill.size * Vector2(1.0, 0.5)
		var tw := create_tween()
		tw.tween_property(meat_pill, "scale", Vector2(1.18, 1.18), 0.07)
		tw.tween_property(meat_pill, "scale", Vector2.ONE, 0.14)
	_meat_shown = meat


## 0..1: how far a dino's energy drain has climbed. The bar turns from
## orange to red so you can see it's time to change back to Rok.
func set_drain_heat(t: float) -> void:
	_energy_fill.bg_color = ENERGY_COLOR.lerp(ENERGY_HOT, t)


## Button portraits again (after a different dinosaur is equipped).
func refresh_form_icons() -> void:
	# the hunter meter's runner icon follows the hero on Rok's button
	chase_meter.rok_tex = SpriteLib.tex("res://assets/portraits/%s.png" % Forms.get_data(Forms.ROK).id)
	for f in form_buttons:
		var b: TouchButton = form_buttons[f]
		b.icon = SpriteLib.tex("res://assets/portraits/%s.png" % Forms.get_data(f).id)
		b.queue_redraw()


func set_sound_icon(muted: bool) -> void:
	sound_button.icon = _icon_sound_off if muted else _icon_sound_on
	sound_button.queue_redraw()


## Show health (in quarter hearts) as hearts filled in quarters, with as many
## hearts as the max allows (3, plus Heart Containers).
func set_hearts(quarters: int, max_quarters := Tuning.MAX_HEARTS * Hearts.QUARTERS) -> void:
	var count := ceili(max_quarters / float(Hearts.QUARTERS))
	if quarters == _hearts_shown and count == hearts_box.get_child_count():
		return
	var old_q := _hearts_shown
	_hearts_shown = quarters
	while hearts_box.get_child_count() < count:
		var h := TextureRect.new()
		h.custom_minimum_size = Vector2(34, 34)
		h.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		h.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		h.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hearts_box.add_child(h)
	while hearts_box.get_child_count() > count:
		var last := hearts_box.get_child(hearts_box.get_child_count() - 1)
		hearts_box.remove_child(last)
		last.queue_free()
	for i in hearts_box.get_child_count():
		var h := hearts_box.get_child(i) as TextureRect
		var fill := clampi(quarters - i * Hearts.QUARTERS, 0, Hearts.QUARTERS)
		var was := clampi(old_q - i * Hearts.QUARTERS, 0, Hearts.QUARTERS) if old_q >= 0 else fill
		h.set_meta("fill", fill)   # where it's heading (the drain may still be playing)
		var steps := Hearts.drain_steps(was, fill) if fill < was else []
		if steps.is_empty() or not is_inside_tree():
			h.texture = Hearts.icon(fill)
			continue
		# the stone heart drains right to left through its frames
		var tw := h.create_tween()
		for st in steps:
			tw.tween_callback(func(): h.texture = st)
			tw.tween_interval(0.035)
		tw.tween_callback(func(): h.texture = Hearts.icon(fill))


## A crash: the hearts pop and flash red (scale, since the panel's container
## owns their position).
func hearts_hit() -> void:
	hearts_box.pivot_offset = hearts_box.size * 0.5
	hearts_box.modulate = Color(1.0, 0.45, 0.45)
	var tw := hearts_box.create_tween()
	tw.tween_property(hearts_box, "scale", Vector2(1.3, 1.3), 0.08)
	tw.tween_property(hearts_box, "scale", Vector2.ONE, 0.16)
	tw.parallel().tween_property(hearts_box, "modulate", Color.WHITE, 0.4)


func update_play(score: int, metres: int, energy: float, form: int, armor: int, playing: bool,
		unlocked: Array, zone := "", meat := 0) -> void:
	score_label.text = str(score)
	set_meat(meat)
	best_label.text = "%d m · %s" % [metres, zone] if zone != "" else "%d m" % metres
	energy_bar.value = energy
	shield_label.text = "  SHIELD x%d" % armor if armor > 0 else ""
	for f in form_buttons:
		var b: TouchButton = form_buttons[f]
		var is_active: bool = f == form
		var is_locked: bool = not unlocked.has(f)
		var can: bool = not is_locked and (f == Forms.ROK or energy >= Tuning.SHIFT_MIN_ENERGY or is_active)
		if b.active != is_active or b.enabled != can or b.locked != is_locked:
			b.active = is_active
			b.enabled = can
			b.locked = is_locked
			b.lock_text = "%d m" % Progression.unlock_m(f)
			b.ring = Forms.get_data(f).color.darkened(0.2) if is_active else Color(0.4, 0.22, 0.1)
			b.queue_redraw()
	for b in form_buttons.values() + [jump_button, slide_button, attack_button] + slot_buttons:
		b.modulate.a = 1.0 if playing else 0.55


func _progress_line(best_m: int, unlocked: Array) -> String:
	var nxt := Progression.next_unlock(unlocked)
	if nxt == -1:
		return "All dinosaurs unlocked! Best distance %d m" % best_m
	# the button's own dinosaur (an equipped species only plays once it's unlocked)
	return "Next dino: %s at %d m (best %d m)" % [Forms.DATA[nxt].name, Progression.unlock_m(nxt), best_m]


func show_title(best: int, best_m: int, unlocked: Array, meat := 0, again := false) -> void:
	center_panel.visible = true
	help_label.visible = true
	title_label.text = "ROK RUNNER"
	sub_label.text = "Tap to run again" if again else "Tap to run"
	help_label.text = "JUMP (hold for higher) · SLIDE under ledges · tap a dinosaur to shapeshift\n" \
		+ "Run farther to unlock new dinosaurs. The book is your Field Guide\n" + _progress_line(best_m, unlocked) \
		+ "\nBest score %d · Meat %d (spend it in the Market)" % [best, meat]


func show_game_over(score: int, best: int, new_best: bool, metres: int, best_m: int, unlocked: Array,
		caught := false, run_meat := 0, meat := 0, new_things: Array = []) -> void:
	clear_banner()   # a banner from the last moments would cover the title
	center_panel.visible = true
	help_label.visible = true
	title_label.text = "CAUGHT!" if caught else "EXTINCT!"
	sub_label.text = ("NEW BEST! %d" if new_best else "Score %d") % score + "  ·  %d m" % metres
	var news := ""
	if not new_things.is_empty():
		var shown := new_things.slice(0, 4)
		news = "NEW THIS RUN: " + ", ".join(shown) + (" +%d more" % (new_things.size() - 4) if new_things.size() > 4 else "") + "\n"
	help_label.text = news + _progress_line(best_m, unlocked) + "\nBest score %d · +%d meat (%d banked)\nTap to run again" % [best, run_meat, meat]


var _banner_queue: Array = []


## Slide-in banner for a newly introduced hazard or an unlock. If one is
## already showing, the new one waits its turn.
## Drop the current banner and any queued ones (the run is over).
func clear_banner() -> void:
	_banner_queue.clear()
	if _banner_tween:
		_banner_tween.kill()
	banner.modulate.a = 0.0


func show_banner(title: String, hint: String, color: Color, duration := 2.6) -> void:
	if _banner_tween and _banner_tween.is_running():
		_banner_queue.append([title, hint, color, duration])
		return
	_show_banner_now(title, hint, color, duration)


func _show_banner_now(title: String, hint: String, color: Color, duration: float) -> void:
	banner_title.text = title
	banner_title.add_theme_color_override("font_color", color)
	banner_hint.text = hint
	banner_hint.visible = hint != ""
	(banner.get_theme_stylebox("panel") as StyleBoxFlat).border_color = color
	if _banner_tween:
		_banner_tween.kill()
	banner.modulate.a = 0.0
	banner.scale = Vector2(0.85, 0.85)
	banner.pivot_offset = banner.size * 0.5
	_banner_tween = create_tween()
	_banner_tween.set_parallel()
	_banner_tween.tween_property(banner, "modulate:a", 1.0, 0.2)
	_banner_tween.tween_property(banner, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_banner_tween.chain().tween_interval(duration)
	_banner_tween.chain().tween_property(banner, "modulate:a", 0.0, 0.4)
	_banner_tween.chain().tween_callback(func():
		if not _banner_queue.is_empty():
			var b: Array = _banner_queue.pop_front()
			_show_banner_now(b[0], b[1], b[2], b[3] * 0.85))


## Show the paused info card. The "tap to continue" line appears once the
## card can be dismissed (show_info_ready).
func show_info(title: String, body: String, icon: Texture2D, accent: Color) -> void:
	info_title.text = title
	info_title.add_theme_color_override("font_color", accent.darkened(0.35))
	info_body.text = body
	info_icon.texture = icon
	info_icon.visible = icon != null
	info_hint.modulate.a = 0.0
	info_card.visible = true
	info_card.modulate.a = 0.0
	info_card.scale = Vector2(0.9, 0.9)
	info_card.pivot_offset = info_card.size * 0.5
	var t := create_tween().set_parallel()
	t.tween_property(info_card, "modulate:a", 1.0, 0.2)
	t.tween_property(info_card, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func show_info_ready() -> void:
	create_tween().tween_property(info_hint, "modulate:a", 1.0, 0.25)


func hide_info() -> void:
	info_card.visible = false


## Pulse the newly unlocked dinosaur's button.
func celebrate(form: int) -> void:
	var b: TouchButton = form_buttons.get(form)
	if b == null:
		return
	var t := create_tween().set_loops(4)
	t.tween_property(b, "modulate", Color(1.6, 1.5, 1.1), 0.2)
	t.tween_property(b, "modulate", Color.WHITE, 0.2)


func show_pause() -> void:
	center_panel.visible = true
	title_label.text = "PAUSED"
	sub_label.text = "Tap to resume"
	help_label.text = ""
	help_label.visible = false


func hide_center() -> void:
	center_panel.visible = false
