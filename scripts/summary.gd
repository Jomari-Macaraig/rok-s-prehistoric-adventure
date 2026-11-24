class_name RunSummary
extends CanvasLayer
## The end-of-run summary card (main._finish_game_over -> show_run): how the
## run ended, a NEW BEST ribbon, tiles for distance, score, meat and best
## distance, then a table of Rok and the dinosaurs he played this run (up to
## 4, one per dino button; Rok levels too, so he comes first): a small
## idle-animated icon, name and level, metres, XP gained, an XP bar where this
## run's gain fills in with a glow (1 XP per metre; Dinos.xp_progress), and
## LEVEL UP! LV N if it levelled this run. Below that, badges and other news.
## It ignores the mouse; a tap anywhere goes on to the main menu (main.gd
## _to_title: run again, Field Guide, Camp or Market), and it
## sits under the Field Guide, Market and Herd (layer 15).

const INK := Codex.INK
const PAPER := Codex.PAPER
const CARD := Codex.CARD
const XP_COLOR := Color(0.3, 0.6, 0.9)
const XP_GAIN := Color(0.45, 0.85, 1.0)

var root: Control
var panel: PanelContainer
var _bars: Array = []   # XPBars, animated after the card pops in
var _levelups: Dictionary = {}   # id -> level reached this run
var _icons: Array = []  # [TextureRect, frames, times, frame, time left]: the table's idle loops
static var _idle_cache := {}
var _t := 0.0


## A thin XP bar: the XP from before this run, and this run's gain glowing on top.
class XPBar:
	extends Control
	var before := 0.0   # 0-1 of this level
	var after := 0.0
	var shown := 0.0

	func _init() -> void:
		custom_minimum_size = Vector2(140, 12)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		draw_rect(r, Color(0.72, 0.64, 0.52), true)
		draw_rect(Rect2(Vector2.ZERO, Vector2(size.x * before, size.y)), RunSummary.XP_COLOR, true)
		if shown > before:
			draw_rect(Rect2(Vector2(size.x * before, 0), Vector2(size.x * (shown - before), size.y)), RunSummary.XP_GAIN, true)
		draw_rect(r, Color(0.35, 0.22, 0.1), false, 2.0)


func _ready() -> void:
	layer = 15
	visible = false
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)


const RANK_COLORS := {"C": Color(0.5, 0.42, 0.32), "B": Color(0.35, 0.55, 0.25), "A": Color(0.2, 0.45, 0.7),
		"S": Color(0.6, 0.3, 0.75), "SS": Color(0.9, 0.55, 0.1)}


## The rank a run's score earns: [min score, rank, multiplier] (Tuning.RUN_RANKS).
static func rank_for(score: float) -> Array:
	var r: Array = Tuning.RUN_RANKS[0]
	for k in Tuning.RUN_RANKS:
		if score >= float(k[0]):
			r = k
	return r


## The next rank up and the score it needs ([] at the top).
static func next_rank(score: float) -> Array:
	for k in Tuning.RUN_RANKS:
		if score < float(k[0]):
			return k
	return []


## Plain words for how a run ended (main.death_cause).
static func cause_text(cause: String) -> String:
	if cause == "stopped":
		return "You stopped the run"
	if cause == "caught":
		return "The hunter caught Rok"
	if cause == "pit":
		return "Rok fell into a pit"
	if cause == "water":
		return "Rok sank in the water"
	if cause == "lava":
		return "Rok fell into the lava"
	if cause == "quicksand":
		return "The quicksand swallowed Rok"
	if cause.begins_with("gate"):
		return "Only the right dinosaur gets through a dino gate"
	var what := cause.get_slice(" ", 0)
	var names := {"rock": "a boulder", "wood": "a log", "fence": "a fence", "overhead": "a ledge", "thorns": "a thorn wall"}
	return "Out of hearts: Rok crashed into %s" % names.get(what, "an obstacle")


## r: caught, cause, metres, score, best_m, new_best (score), new_best_m,
## meat, banked, zones, dinos ([id, metres this run]), levelups (id -> level
## reached this run), milestones (lines for the NEW card), news (Array of text).
func show_run(r: Dictionary) -> void:
	for c in root.get_children():
		c.queue_free()
	_bars.clear()
	_icons.clear()
	_levelups = r.get("levelups", {})
	_t = 0.0
	visible = true
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(cc)
	panel = PanelContainer.new()
	panel.name = "Summary"
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ps := StyleBoxFlat.new()
	ps.bg_color = PAPER
	ps.set_corner_radius_all(22)
	ps.set_border_width_all(5)
	ps.border_color = Color(0.45, 0.25, 0.1)
	ps.set_content_margin_all(18)
	ps.shadow_color = Color(0, 0, 0, 0.35)
	ps.shadow_size = 12
	panel.add_theme_stylebox_override("panel", ps)
	panel.custom_minimum_size = Vector2(780, 0)
	cc.add_child(panel)
	var vb := VBoxContainer.new()
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_theme_constant_override("separation", 10)
	panel.add_child(vb)

	# title + how it ended (+ a ribbon for a record)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 14)
	vb.add_child(top)
	var tv := VBoxContainer.new()
	tv.add_theme_constant_override("separation", -4)
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(tv)
	tv.add_child(_text("RUN OVER" if r.get("cause", "") == "stopped" else ("CAUGHT!" if r.caught else "EXTINCT!"), 44, Color(0.75, 0.2, 0.12) if r.caught else INK))
	var cause := _text(cause_text(r.cause), 18, Color(0.5, 0.3, 0.12))
	cause.name = "Cause"
	tv.add_child(cause)
	if r.new_best_m or r.new_best:
		var rib := _chip("NEW BEST!", Color(0.9, 0.55, 0.1), 24)
		rib.name = "NewBest"
		top.add_child(rib)
	# the run's rank: a big letter, its bonus, and what the next one needs
	var rk: Array = r.rank
	var rb := VBoxContainer.new()
	rb.name = "Rank"
	rb.add_theme_constant_override("separation", -6)
	var letter := _text(String(rk[1]), 56, RANK_COLORS.get(rk[1], INK))
	letter.name = "RankLetter"
	letter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	letter.add_theme_color_override("font_outline_color", Color(0.3, 0.16, 0.06))
	letter.add_theme_constant_override("outline_size", 8)
	rb.add_child(letter)
	var nxt := next_rank(r.score)
	var mult_txt := ("x%s bonus" % str(rk[2])) if float(rk[2]) > 1.0 else "no bonus"
	var rn := _text("RANK  ·  " + mult_txt, 14, Color(0.5, 0.3, 0.12))
	rn.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rb.add_child(rn)
	if not nxt.is_empty():
		var nt := _text("%s at %d points (x%s)" % [nxt[1], int(nxt[0]), str(nxt[2])], 13, Color(0.55, 0.35, 0.15))
		nt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rb.add_child(nt)
	top.add_child(rb)

	# the numbers
	var tiles := HBoxContainer.new()
	tiles.add_theme_constant_override("separation", 10)
	vb.add_child(tiles)
	tiles.add_child(_tile("Distance", "%d m" % r.metres, "%d zone%s" % [r.zones, "" if r.zones == 1 else "s"]))
	tiles.add_child(_tile("Score", str(r.score), "best" if r.new_best else ""))
	tiles.add_child(_tile("Meat", "+%d" % r.meat, ("incl. +%d rank bonus" % r.bonus_meat) if r.bonus_meat > 0 else "%d banked" % r.banked, load(Hud.MEAT_ICON)))
	tiles.add_child(_tile("Best run", "%d m" % r.best_m, "new record!" if r.new_best_m else ""))

	# the dinosaurs Rok played
	var dinos: Array = r.dinos
	if not dinos.is_empty():
		var hero := Heroes.name_of(Forms.get_data(Forms.ROK).id) if Heroes.is_hero(Forms.get_data(Forms.ROK).id) else "Rok"
		vb.add_child(_text("%s and the dinosaurs this run" % hero, 20, Color(0.45, 0.28, 0.12)))
		var table := PanelContainer.new()
		table.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var tsb := StyleBoxFlat.new()
		tsb.bg_color = CARD
		tsb.set_corner_radius_all(14)
		tsb.set_content_margin_all(10)
		table.add_theme_stylebox_override("panel", tsb)
		vb.add_child(table)
		var grid := GridContainer.new()
		grid.name = "Dinos"
		grid.columns = 6
		grid.add_theme_constant_override("h_separation", 16)
		grid.add_theme_constant_override("v_separation", 4)
		table.add_child(grid)
		for h in ["", "Dinosaur", "Ran", "XP", "Progress", ""]:
			grid.add_child(_text(h.to_upper(), 13, Color(0.5, 0.3, 0.12)))
		for d in dinos.slice(0, 5):   # Rok and one per dino button
			_dino_row(grid, d[0], float(d[1]), float(r.rank[2]) * float(r.get("xp_mult", 1.0)))

	# a card for each milestone learned (and evolution) this run
	var ms: Array = r.get("milestones", [])
	if not ms.is_empty():
		var card := _chip("NEW: " + "  ·  ".join(ms.slice(0, 3)) + ("!" if not String(ms[0]).ends_with("!") else ""), Color(0.35, 0.55, 0.2), 17)
		card.name = "MilestoneCard"
		card.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card.custom_minimum_size = Vector2(740, 0)
		vb.add_child(card)
	# news: badges, Market items, unlocks, dinosaurs ready to level
	var news: Array = (r.news as Array).filter(func(t): return not ms.has(t))
	if not news.is_empty():
		var nl := _text("NEW: " + "  ·  ".join(news.slice(0, 6)) + (" +%d more" % (news.size() - 6) if news.size() > 6 else ""), 16, Color(0.4, 0.28, 0.15))
		nl.name = "News"
		nl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		nl.custom_minimum_size = Vector2(740, 0)
		vb.add_child(nl)
	var tap := _text("Tap to continue", 20, Color(0.55, 0.3, 0.1))
	tap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(tap)

	# pop in
	panel.pivot_offset = Vector2(390, 220)
	panel.scale = Vector2(0.85, 0.85)
	panel.modulate.a = 0.0
	var tw := panel.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(panel, "scale", Vector2.ONE, 0.35)
	tw.parallel().tween_property(panel, "modulate:a", 1.0, 0.25)


func hide_run() -> void:
	visible = false


## One table row: idle-animated icon, name and level, metres, XP gained, the
## XP bar (this run's gain glows in) and a ready tag.
func _dino_row(grid: GridContainer, id: String, m: float, mult := 1.0) -> void:
	var ic := TextureRect.new()
	ic.name = "Dino_" + id
	ic.custom_minimum_size = Vector2(64, 44)
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fr: Array = idle_frames(id)
	ic.texture = fr[0][0]
	_icons.append([ic, fr[0], fr[1], 0, float(fr[1][0])])
	grid.add_child(ic)
	var nv := VBoxContainer.new()
	nv.add_theme_constant_override("separation", -4)
	nv.alignment = BoxContainer.ALIGNMENT_CENTER
	nv.add_child(_text(Herd.name_of(id), 18))
	nv.add_child(_text("%s · Lv %d" % [Herd.tier_text(id), Dinos.level(id)], 13, Dinos.tier_color(id)))
	grid.add_child(nv)
	var mt := _text("%d m" % int(m), 20, Color(0.75, 0.35, 0.1))
	mt.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	grid.add_child(mt)
	var gained := m * mult   # XP earned: its metres, times the rank bonus and Seasoned's
	var xt := _text("+%d" % int(gained), 18, XP_COLOR.darkened(0.2))
	xt.name = "XPGain"
	xt.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	grid.add_child(xt)
	var bar := XPBar.new()
	bar.name = "XPBar"
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var l := Dinos.level(id)
	var pr := Dinos.xp_progress(id)
	var after := 1.0 if pr.y <= 0.0 else pr.x / pr.y
	var before := 0.0 if pr.y <= 0.0 or _levelups.has(id) else clampf((Dinos.xp_of(id) - gained - Dinos.xp_for(l)) / pr.y, 0.0, after)
	bar.before = before
	bar.after = after
	bar.shown = before
	grid.add_child(bar)
	_bars.append(bar)
	if _levelups.has(id):
		var up := _chip("LEVEL UP! LV %d" % l, Color(0.25, 0.55, 0.2), 13)
		up.name = "LevelUp"
		grid.add_child(up)
	elif l >= Dinos.max_level:
		grid.add_child(_chip("MAX LEVEL", Color(0.85, 0.55, 0.1), 13))
	else:
		grid.add_child(_text("%d to Lv %d" % [ceili(pr.y - pr.x), l + 1], 13, Color(0.55, 0.35, 0.15)))


## A dinosaur's idle loop as textures + seconds per frame: a bought species'
## card loop (Dinos.frame), or the original's idle sheet (4x2 at its frame size).
static func idle_frames(id: String) -> Array:
	if _idle_cache.has(id):
		return _idle_cache[id]
	var out: Array
	if Dinos.has(id):
		out = [range(8).map(func(i): return Dinos.frame(id, i)), Dinos.frame_times(id)]
	else:
		var fs: Vector2
		if Heroes.has(id):
			var hf: Array = Heroes.play(id).frame
			fs = Vector2(hf[0], hf[1])
		else:
			fs = Forms.DATA[Forms.ROK if id == "rok" else Dinos.slot_of(Dinos.category_of(id))].frame
		var img: Image = (load("res://assets/characters/%s/idle.png" % id) as Texture2D).get_image()
		# crop every frame to the art's shared bounds (the sheets are padded),
		# so originals show as big as the bought species' card loops
		var cells := []
		var used := Rect2i()
		for i in 8:
			var c := img.get_region(Rect2i(i % 4 * int(fs.x), i / 4 * int(fs.y), int(fs.x), int(fs.y)))
			cells.append(c)
			var u := c.get_used_rect()
			used = u if used.size == Vector2i.ZERO else used.merge(u)
		var texs := []
		for c in cells:
			texs.append(ImageTexture.create_from_image(c.get_region(used)))
		out = [texs, [0.14, 0.14, 0.14, 0.14, 0.14, 0.14, 0.14, 0.14]]
	_idle_cache[id] = out
	return out


func _process(delta: float) -> void:
	if not visible:
		return
	for a in _icons:
		a[4] -= delta
		if a[4] <= 0.0:
			a[3] = (a[3] + 1) % 8
			a[4] += float(a[2][a[3]])
			(a[0] as TextureRect).texture = a[1][a[3]]
	_t += delta
	var k := clampf((_t - 0.35) / 0.8, 0.0, 1.0)   # after the pop-in, fill the gains
	for b in _bars:
		b.shown = lerpf(b.before, b.after, ease(k, 0.4))
		b.queue_redraw()


func _tile(label: String, value: String, note: String, icon: Texture2D = null) -> Control:
	var t := PanelContainer.new()
	t.name = "Tile_" + label
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ts := StyleBoxFlat.new()
	ts.bg_color = CARD
	ts.set_corner_radius_all(14)
	ts.set_content_margin_all(10)
	t.add_theme_stylebox_override("panel", ts)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", -2)
	t.add_child(v)
	v.add_child(_text(label.to_upper(), 14, Color(0.5, 0.3, 0.12)))
	var hv := HBoxContainer.new()
	hv.add_theme_constant_override("separation", 6)
	if icon:
		var ic := TextureRect.new()
		ic.texture = icon
		ic.custom_minimum_size = Vector2(30, 30)
		ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		hv.add_child(ic)
	var val := _text(value, 30)
	val.name = "Value"
	hv.add_child(val)
	v.add_child(hv)
	v.add_child(_text(note, 14, Color(0.55, 0.35, 0.15)))
	return t


func _chip(t: String, color: Color, size: int) -> Label:
	var l := _text(" %s " % t, size, Color(1, 0.97, 0.9))
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(10)
	sb.content_margin_left = 6
	sb.content_margin_right = 6
	l.add_theme_stylebox_override("normal", sb)
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	l.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	return l


func _text(t: String, size: int, color := INK) -> Label:
	var l := Market._text(t, size, color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l
