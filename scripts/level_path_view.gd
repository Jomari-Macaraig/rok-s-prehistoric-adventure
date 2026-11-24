class_name LevelPathView
extends Control
## A dinosaur's level path, full screen over the Camp (variant A of the
## level-path prototype): its portrait, level, XP bar and a "Next" chip on
## top; levels 1-20 as a winding road (left to right, then back), drawn with
## the user's path art: plain levels are small dots, milestones gold circles,
## evolutions (10, 20) the biggest, purple; reached ones lit, the next one
## glowing. Tapping a level shows what it gives below (a milestone's card:
## Trick or Trait, what it does, unlocked or at which level).
## Sized from the visible screen (1280x720 and wide phones).

signal closed

const INK := Color(0.25, 0.15, 0.07)
const PAPER := Color(0.96, 0.9, 0.76)
const ART := "res://assets/ui/camp/path_%s_%s.png"   # kind (dot, milestone, evolution), lit/unlit

var game
var dino := "raptor"
var selected := 0          # the level shown in the info strip (0 = the next one)
var _info: VBoxContainer


func open(g, id: String) -> void:
	game = g
	dino = id
	selected = 0
	visible = true
	refresh()


## What a level is: "milestone", "evolution" or "dot".
func kind_of(l: int) -> String:
	if Milestones.evolutions.has(l):
		return "evolution"
	return "milestone" if Milestones.of(dino).has(l) else "dot"


func refresh() -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()
	var vs := get_viewport().get_visible_rect().size
	position = Vector2.ZERO
	size = vs
	mouse_filter = Control.MOUSE_FILTER_STOP
	var shade := ColorRect.new()
	shade.color = Color(0.08, 0.05, 0.02, 0.88)
	shade.size = vs
	add_child(shade)
	_build_header(vs)
	_build_road(vs)
	_build_info(vs)


func _panel(r: Rect2, name_: String) -> PanelContainer:
	var box := PanelContainer.new()
	box.name = name_
	var sb := StyleBoxFlat.new()
	sb.bg_color = PAPER
	sb.set_corner_radius_all(16)
	sb.set_border_width_all(4)
	sb.border_color = Color(0.45, 0.25, 0.1)
	sb.set_content_margin_all(12)
	box.add_theme_stylebox_override("panel", sb)
	box.position = r.position
	box.size = r.size
	add_child(box)
	return box


func _build_header(vs: Vector2) -> void:
	var box := _panel(Rect2(16, 16, vs.x - 32, 120), "Header")
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	box.add_child(row)
	var pic := TextureRect.new()
	pic.custom_minimum_size = Vector2(120, 92)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var fr: Array = RunSummary.idle_frames(dino)
	if not fr.is_empty() and not (fr[0] as Array).is_empty():
		pic.texture = fr[0][0]
	row.add_child(pic)
	var tv := VBoxContainer.new()
	tv.alignment = BoxContainer.ALIGNMENT_CENTER
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(tv)
	var stage := Milestones.stage(dino)
	tv.add_child(Market._text(Herd.name_of(dino) + ("  ·  Evolved" + (" ×2" if stage > 1 else "") if stage > 0 else ""), 24, INK))
	tv.add_child(Market._text(Dinos.level_text(dino), 16, Color(0.85, 0.55, 0.1)))
	var pr := Dinos.xp_progress(dino)
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(240, 12)
	bar.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	bar.max_value = pr.y
	bar.value = pr.x
	var bbg := StyleBoxFlat.new()
	bbg.bg_color = Color(0.72, 0.64, 0.52)
	bbg.set_corner_radius_all(6)
	var bfg := StyleBoxFlat.new()
	bfg.bg_color = Color(0.3, 0.6, 0.9)
	bfg.set_corner_radius_all(6)
	bar.add_theme_stylebox_override("background", bbg)
	bar.add_theme_stylebox_override("fill", bfg)
	tv.add_child(bar)
	var nxt := _next_text()
	if nxt != "":
		var chip := Market._text(" " + nxt + " ", 15, Color(1, 0.97, 0.88))
		chip.name = "NextChip"
		var cs := StyleBoxFlat.new()
		cs.bg_color = Color(0.55, 0.37, 0.12)
		cs.set_corner_radius_all(10)
		cs.set_content_margin_all(4)
		chip.add_theme_stylebox_override("normal", cs)
		chip.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		tv.add_child(chip)
	var back := Market._button("Back", Vector2(120, 50))
	back.name = "Back"
	back.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(close)
	row.add_child(back)


## "Next: Lv 8 · Light Step" (the next milestone or evolution), or "".
func _next_text() -> String:
	var lv := Dinos.level(dino)
	for l in range(lv + 1, Dinos.max_level + 1):
		var k := kind_of(l)
		if k == "milestone":
			return "Next: Lv %d · %s" % [l, Milestones.name_of(Milestones.of(dino)[l])]
		if k == "evolution":
			return "Next: Lv %d · Evolution" % l
	return ""


## Levels 1-10 left to right on the upper row, 11-20 right to left below,
## joined by a bend on the right.
func node_pos(l: int, vs: Vector2) -> Vector2:
	var left := 80.0
	var right := vs.x - 150.0
	var step := (right - left) / 9.0
	var y1 := 150.0 + (vs.y - 150.0 - 190.0) * 0.27
	var y2 := 150.0 + (vs.y - 150.0 - 190.0) * 0.82
	if l <= 10:
		return Vector2(left + (l - 1) * step, y1)
	return Vector2(right - (l - 11) * step, y2)


func _build_road(vs: Vector2) -> void:
	var road := Control.new()
	road.name = "Road"
	road.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(road)
	var line := Line2D.new()
	line.width = 16.0
	line.default_color = Color(0.55, 0.37, 0.2)
	line.joint_mode = Line2D.LINE_JOINT_ROUND
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	var a := node_pos(10, vs)
	var b := node_pos(11, vs)
	for l in range(1, 11):
		line.add_point(node_pos(l, vs))
	var r := (b.y - a.y) * 0.5
	for i in range(1, 12):   # the bend on the right
		var t := PI * (-0.5 + float(i) / 12.0)
		line.add_point(Vector2(a.x + r * cos(t) * 0.9, a.y + r + r * sin(t)))
	for l in range(11, 21):
		line.add_point(node_pos(l, vs))
	road.add_child(line)
	var lit := Line2D.new()   # the part already travelled
	lit.width = 8.0
	lit.default_color = Color(0.95, 0.75, 0.3)
	lit.joint_mode = Line2D.LINE_JOINT_ROUND
	var lv := Dinos.level(dino)
	for l in range(1, lv + 1):
		lit.add_point(node_pos(l, vs))
		if l == 10 and lv > 10:
			for i in range(1, 12):
				var t := PI * (-0.5 + float(i) / 12.0)
				lit.add_point(Vector2(a.x + r * cos(t) * 0.9, a.y + r + r * sin(t)))
	if lit.get_point_count() > 1:
		road.add_child(lit)
	var box := minf((node_pos(2, vs).x - node_pos(1, vs).x) * 0.98, 116.0)
	for l in range(1, Dinos.max_level + 1):
		add_child(_node(l, node_pos(l, vs), box))


func _node(l: int, at: Vector2, box: float) -> Control:
	var k := kind_of(l)
	var lv := Dinos.level(dino)
	var on := l <= lv
	var b := Button.new()
	b.name = "Node_%d" % l
	b.flat = true
	b.size = Vector2(box, box)
	b.position = at - b.size * 0.5
	b.set_meta("kind", k)
	b.set_meta("lit", on)
	b.pressed.connect(func(): _tap(l))
	var path := ART % [k, "lit" if on else "unlit"]
	var tr := TextureRect.new()
	tr.texture = SpriteLib.tex(path) if ResourceLoader.exists(path) else null
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.size = b.size
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(tr)
	if l == lv + 1 or (selected == l):
		var glow := tr.create_tween().set_loops()
		glow.tween_property(tr, "modulate", Color(1.5, 1.35, 0.9), 0.6)
		glow.tween_property(tr, "modulate", Color(1, 1, 1), 0.6)
	var num := Market._text(str(l), 15 if k == "dot" else 17, Color(1, 0.95, 0.85) if k != "dot" else Color(0.95, 0.88, 0.7))
	num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	num.size = Vector2(box, 22)
	num.position = Vector2(0, box * 0.5 - 11.0) if k != "dot" else Vector2(0, box * 0.5 + 12.0)
	num.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(num)
	if k != "dot":
		var cap := Market._text(Milestones.name_of(Milestones.of(dino)[l]) if k == "milestone" else "Evolution", 13, Color(1, 0.88, 0.55) if on else Color(0.8, 0.72, 0.6))
		cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cap.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		cap.size = Vector2(box + 10.0, 36)
		cap.position = Vector2(-5.0, box * 0.86)
		cap.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(cap)
	return b


## Bottom strip: what the tapped level (or the next one) gives.
func _build_info(vs: Vector2) -> void:
	var box := _panel(Rect2(16, vs.y - 136, vs.x - 32, 120), "Info")
	_info = VBoxContainer.new()
	_info.name = "LevelInfo"
	_info.add_theme_constant_override("separation", 4)
	box.add_child(_info)
	var lv := Dinos.level(dino)
	var l := selected if selected > 0 else mini(lv + 1, Dinos.max_level)
	var k := kind_of(l)
	var got := l <= lv
	var title := ""
	var text := ""
	if k == "milestone":
		var mid: String = Milestones.of(dino)[l]
		title = "Lv %d · %s %s" % [l, Milestones.kind_of(mid).capitalize(), Milestones.name_of(mid)]
		text = Milestones.text_of(mid)
	elif k == "evolution":
		title = "Lv %d · Evolution" % l
		text = "+1 to every attribute" + (", and its best attribute may go 1 past its cap." if l >= 20 else ".") + " A new look when its evolved art arrives (a glow until then)."
	else:
		title = "Lv %d" % l
		var g := _growth_at(l)
		text = ("Grows " + g + ".") if g != "" else "Its starting level."
	var t := Market._text(title, 20, INK)
	t.name = "InfoTitle"
	_info.add_child(t)
	var d := Market._text(text, 16, Color(0.4, 0.28, 0.15))
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_info.add_child(d)
	var st := Market._text("Unlocked" if got else "Unlocks at Lv %d (now Lv %d)" % [l, lv], 15, Color(0.25, 0.5, 0.2) if got else Color(0.6, 0.35, 0.15))
	st.name = "InfoState"
	_info.add_child(st)


## What reaching level l adds ("+0.4 Speed"), from the growth pattern.
func _growth_at(l: int) -> String:
	if l <= 1:
		return ""
	var a: Dictionary = Dinos._pts_at(dino, l - 1)
	var b: Dictionary = Dinos._pts_at(dino, l)
	var parts: Array = []
	for at in Dinos.ATTRS:
		var dv := float(b.get(at, 0.0)) - float(a.get(at, 0.0))
		if dv > 0.001:
			parts.append("+%s %s" % [Dinos.fmt(snappedf(dv, 0.01)), Dinos.ATTR_NAMES[at]])
	return ", ".join(parts)


func _tap(l: int) -> void:
	selected = l
	game.audio.play("click", 0.0)
	refresh()


func close() -> void:
	visible = false
	closed.emit()
