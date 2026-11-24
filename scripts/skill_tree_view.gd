class_name SkillTreeView
extends Control
## A hero's skill tree, full screen over the Camp (variant A of the
## level-path prototype): the hero bottom-left with a panel (level, XP bar,
## skill points, the chosen skill's details with Learn, Reset (free), Back);
## the three branches grow upward on the right as columns of five skill cards
## (the user's card frames: learned, learnable with a gold rim, locked), the
## branch name at the foot of each column. Tapping a card selects it; Learn
## (or a second tap on a learnable card) learns it (main.learn_skill).
## Sized from the visible screen (1280x720 and wide phones).

signal closed

const INK := Color(0.25, 0.15, 0.07)
const PAPER := Color(0.96, 0.9, 0.76)
const FRAME := {"learned": "res://assets/ui/camp/skill_card_learned.png",
		"learnable": "res://assets/ui/camp/skill_card_learnable.png",
		"locked": "res://assets/ui/camp/skill_card_locked.png"}
const CARD_ASPECT := 195.0 / 300.0
const PANEL_W := 300.0
const GAP := 8.0

var game
var hero := "rok"
var selected := ""
var _panel: VBoxContainer
var _cards: Control


func open(g, h: String) -> void:
	game = g
	hero = h
	selected = ""
	visible = true
	refresh()


func refresh() -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()
	var vs := get_viewport().get_visible_rect().size
	position = Vector2.ZERO
	size = vs
	mouse_filter = Control.MOUSE_FILTER_STOP
	var shade := ColorRect.new()
	shade.color = Color(0.08, 0.05, 0.02, 0.86)
	shade.size = vs
	add_child(shade)
	_build_panel(vs)
	_build_branches(vs)


## Left: the hero, its level and points, the selected skill, Reset and Back.
func _build_panel(vs: Vector2) -> void:
	var box := PanelContainer.new()
	box.name = "SkillPanel"
	var sb := StyleBoxFlat.new()
	sb.bg_color = PAPER
	sb.set_corner_radius_all(16)
	sb.set_border_width_all(4)
	sb.border_color = Color(0.45, 0.25, 0.1)
	sb.set_content_margin_all(14)
	box.add_theme_stylebox_override("panel", sb)
	box.position = Vector2(16, 16)
	box.size = Vector2(PANEL_W, vs.y - 32)
	add_child(box)
	_panel = VBoxContainer.new()
	_panel.add_theme_constant_override("separation", 6)
	box.add_child(_panel)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 10)
	_panel.add_child(top)
	var pic := TextureRect.new()
	pic.custom_minimum_size = Vector2(72, 96)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var fr: Array = RunSummary.idle_frames(hero)
	if not fr.is_empty() and not (fr[0] as Array).is_empty():
		pic.texture = fr[0][0]
	top.add_child(pic)
	var tv := VBoxContainer.new()
	tv.alignment = BoxContainer.ALIGNMENT_CENTER
	top.add_child(tv)
	tv.add_child(Market._text(Heroes.name_of(hero), 24, INK))
	tv.add_child(Market._text(Dinos.level_text(hero), 16, Color(0.85, 0.55, 0.1)))
	var pr := Dinos.xp_progress(hero)
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(150, 10)
	bar.max_value = pr.y
	bar.value = pr.x
	var bbg := StyleBoxFlat.new()
	bbg.bg_color = Color(0.72, 0.64, 0.52)
	bbg.set_corner_radius_all(5)
	var bfg := StyleBoxFlat.new()
	bfg.bg_color = Color(0.3, 0.6, 0.9)
	bfg.set_corner_radius_all(5)
	bar.add_theme_stylebox_override("background", bbg)
	bar.add_theme_stylebox_override("fill", bfg)
	tv.add_child(bar)
	var pts := Market._text("Skill points: %d" % Skills.free_points(hero), 20, Color(0.25, 0.5, 0.2))
	pts.name = "Points"
	_panel.add_child(pts)
	_panel.add_child(Market._text("One point per level · each skill needs the one below", 13, Color(0.5, 0.3, 0.12)))
	var sep := HSeparator.new()
	_panel.add_child(sep)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_panel.add_child(scroll)
	var info := VBoxContainer.new()
	info.name = "SkillInfo"
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 6)
	scroll.add_child(info)
	if selected == "":
		var hint := Market._text("Tap a skill to see what it does.", 16, Color(0.45, 0.3, 0.18))
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		info.add_child(hint)
	else:
		info.add_child(Market._text(Skills.name_of(selected), 20, INK))
		var t := Market._text(Skills.text_of(selected), 16, Color(0.4, 0.28, 0.15))
		t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		info.add_child(t)
		var c := Skills.cost(hero, selected)
		if Skills.knows(hero, selected):
			info.add_child(Market._text("Learned", 17, Color(0.25, 0.5, 0.2)))
		else:
			var lb := Market._button("Learn · %d point%s" % [c, "" if c == 1 else "s"], Vector2(200, 44))
			lb.name = "Learn"
			lb.disabled = not Skills.can_learn(hero, selected)
			lb.pressed.connect(func(): _learn(selected))
			info.add_child(lb)
			if lb.disabled:
				var why := "Learn the skill below it first." if not _below_known(selected) else "Needs %d point%s (you have %d)." % [c, "" if c == 1 else "s", Skills.free_points(hero)]
				var w := Market._text(why, 14, Color(0.6, 0.3, 0.15))
				w.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				info.add_child(w)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	_panel.add_child(row)
	var back := Market._button("Back", Vector2(110, 44))
	back.name = "Back"
	back.pressed.connect(close)
	row.add_child(back)
	var rs := Market._button("Reset (free)", Vector2(150, 44))
	rs.name = "Reset"
	rs.disabled = Skills.learned_by(hero).is_empty()
	rs.pressed.connect(func():
		game.reset_skills(hero)
		game.audio.play("click", 0.0)
		refresh())
	row.add_child(rs)


func _below_known(sid: String) -> bool:
	var p := Skills.place(hero, sid)
	return p[1] <= 0 or Skills.knows(hero, String(Skills.branches[p[0]].skills[p[1] - 1]))


## Right: three columns growing upward, the branch name at the foot.
func _build_branches(vs: Vector2) -> void:
	_cards = Control.new()
	_cards.name = "Branches"
	add_child(_cards)
	var left := 16.0 + PANEL_W + 16.0
	var area := Vector2(vs.x - left - 16.0, vs.y - 32.0)
	var label_h := 30.0
	var tree := Skills.tree(hero)
	var n := maxi(tree.size(), 1)
	var card_h := minf((area.y - label_h - GAP * 4.0) / 5.0, (area.x - GAP * (n - 1)) / n * CARD_ASPECT)
	var card_w := card_h / CARD_ASPECT
	var total_w := card_w * n + GAP * (n - 1)
	var x0 := left + (area.x - total_w) / 2.0
	for bi in tree.size():
		var b: String = tree[bi]
		var br: Dictionary = Skills.branches[b]
		var x := x0 + bi * (card_w + GAP)
		var name_l := Market._text(String(br.name).to_upper(), 18, Color(1, 0.92, 0.75))
		name_l.name = "Branch_" + b
		name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_l.position = Vector2(x, 16.0 + area.y - label_h)
		name_l.size = Vector2(card_w, label_h)
		_cards.add_child(name_l)
		var skills: Array = br.skills
		for i in skills.size():
			var y := 16.0 + area.y - label_h - GAP - (i + 1) * card_h - i * GAP
			_cards.add_child(_card(String(skills[i]), br.color, Rect2(x, y, card_w, card_h)))


func _card(sid: String, color: Color, r: Rect2) -> Control:
	var state := "learned" if Skills.knows(hero, sid) else ("learnable" if Skills.can_learn(hero, sid) else "locked")
	var b := Button.new()
	b.name = "Skill_" + sid
	b.flat = true
	b.position = r.position
	b.size = r.size
	b.set_meta("state", state)
	b.pressed.connect(func(): _tap(sid))
	var inset := r.size * Vector2(0.09, 0.14)   # inside the frame's border
	var bg := ColorRect.new()
	bg.position = inset * 0.6
	bg.size = r.size - inset * 1.2
	bg.color = color.darkened(0.15) if state == "learned" else (Color(0.93, 0.85, 0.66) if state == "learnable" else Color(0.55, 0.5, 0.45))
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(bg)
	var fr := TextureRect.new()
	fr.texture = SpriteLib.tex(FRAME[state]) if ResourceLoader.exists(FRAME[state]) else null
	fr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fr.stretch_mode = TextureRect.STRETCH_SCALE
	fr.size = r.size
	fr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(fr)
	var vb := VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.position = inset
	vb.size = r.size - inset * 2.0
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(vb)
	var ink := Color(1, 0.97, 0.88) if state == "learned" else (INK if state == "learnable" else Color(0.92, 0.9, 0.86))
	var fs := 17 if r.size.x >= 180.0 else 15
	var nm := Market._text(Skills.name_of(sid), fs, ink)
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(nm)
	var c := Skills.cost(hero, sid)
	var cl := Market._text("%d pt%s" % [c, "" if c == 1 else "s"] if state != "learned" else "✓", 13, ink)
	cl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(cl)
	if sid == selected:
		var ring := ReferenceRect.new()
		ring.border_color = Color(1, 0.85, 0.3)
		ring.border_width = 3.0
		ring.editor_only = false
		ring.size = r.size
		ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(ring)
	return b


## First tap selects; a second tap on a learnable skill learns it.
func _tap(sid: String) -> void:
	if selected == sid and Skills.can_learn(hero, sid):
		_learn(sid)
		return
	selected = sid
	game.audio.play("click", 0.0)
	refresh()


func _learn(sid: String) -> void:
	if game.learn_skill(hero, sid):
		refresh()


func close() -> void:
	visible = false
	closed.emit()
