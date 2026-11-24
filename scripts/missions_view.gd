class_name MissionsView
extends CanvasLayer
## The Missions scene (the user's art, tools/prepare_missions_ui.py): a full
## screen like the Camp and the Market. Tala the Trail Scout stands on the
## left (idle loop; she waves when it opens, gives a thumbs-up when every
## mission is done, and talks when tapped), with her nameplate and a speech
## bubble. On the right a wooden board with DAILY and WEEKLY tabs holds the
## period's three missions as parchment cards: icon, name, what to do, a
## progress bar, the meat it pays and its state (DONE with a tick, or IN
## PROGRESS). Missions pay by themselves the moment they're done (Missions,
## main.missions / main.missions_week). The title banner and a Back button
## sit on top. Laid out from the visible screen (1280x720 and wide phones).

signal closed

const DIR := "res://assets/ui/missions/"
const INK := Color(0.25, 0.15, 0.07)
const CREAM := Color(1, 0.96, 0.86)
const TALA_FRAME := Vector2(384, 512)   # @2x cell
const TALA_MS := {"idle": 160, "talk": 110, "wave": 110, "thumbs": 120, "present": 140}
const TITLES := {"run_m": "Find Your Stride", "meat": "Stock the Camp", "amber": "Amber Trail", "ledges": "Duck and Dash",
		"combo": "Keep the Streak", "chests": "Treasure Hunter", "smashed": "Break Through", "gates": "Gatekeeper",
		"snacks": "Hunter's Bait", "frenzy": "Primal Fury"}
const ICONS := {"meat": "res://assets/items/meat.png", "amber": "res://assets/props/Other_07.png",
		"chests": "res://assets/items/chest_common_closed.png", "smashed": "res://assets/portraits/triceratops.png",
		"gates": "res://assets/portraits/raptor.png", "snacks": "res://assets/portraits/trex.png",
		"run_m": "res://assets/portraits/rok.png", "frenzy": "res://assets/portraits/spinosaurus.png",
		"ledges": "res://assets/portraits/raptor.png", "combo": "res://assets/portraits/pteranodon.png"}
const LINES := {
	"open": ["A little progress. A big adventure!", "New trails today. Ready?", "The forest is full of goals!"],
	"done": ["Every mission done! Great running!", "All done! Come back tomorrow.", "You cleared the board!"],
	"some": ["Nice work, one's done already!", "Keep going, you're on the trail!", "Halfway there, scout!"],
	"weekly": ["Bigger goals, bigger rewards.", "These take all week. No rush!", "A whole week of trails."],
}

var game
var tab := "daily"
var root: Control
var tala: AnimatedSprite2D
var bubble_label: Label
var _tala_next := "idle"


func _ready() -> void:
	layer = 23
	visible = false


func open(g, t := "daily") -> void:
	game = g
	tab = t
	visible = true
	refresh()
	_say("done" if _list().all_done() else "open")
	_play("thumbs" if _list().all_done() else "wave")


func close() -> void:
	visible = false
	closed.emit()


func _list() -> Missions:
	return game.missions if tab == "daily" else game.missions_week


func show_tab(t: String) -> void:
	tab = t
	refresh()
	_say("weekly" if t == "weekly" else ("done" if _list().all_done() else "open"))


func _tex(name: String) -> Texture2D:
	var p := DIR + name + ".png"
	return SpriteLib.tex(p) if ResourceLoader.exists(p) else null


func _nine(name: String, r: Rect2, margin: float, parent: Control) -> NinePatchRect:
	var n := NinePatchRect.new()
	n.texture = _tex(name)
	var m := int(margin)
	n.patch_margin_left = m
	n.patch_margin_right = m
	n.patch_margin_top = m
	n.patch_margin_bottom = m
	n.position = r.position
	n.size = r.size
	n.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(n)
	return n


func _label(t: String, size: int, color: Color, r: Rect2, parent: Control, align := HORIZONTAL_ALIGNMENT_LEFT, outline := false) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if outline:
		l.add_theme_color_override("font_outline_color", Color(0.25, 0.13, 0.05))
		l.add_theme_constant_override("outline_size", 6)
	l.horizontal_alignment = align
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.position = r.position
	l.size = r.size
	l.clip_text = true
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l


func refresh() -> void:
	if root:
		remove_child(root)
		root.queue_free()
	root = Control.new()
	root.name = "Missions"
	var vs: Vector2 = get_viewport().get_visible_rect().size
	root.size = vs
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)
	var bg := SceneKit.backdrop("dinosaur_camp")
	if bg == null:
		bg = Market.backdrop("res://assets/bg/bg_1.png", Color(0.5, 0.68, 0.85))
	root.add_child(bg)
	if bg is Control:
		(bg as Control).size = vs
	# Back and the title banner
	var back := TextureButton.new()
	back.name = "Back"
	back.texture_normal = _tex("back")
	back.ignore_texture_size = true
	back.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	back.position = Vector2(16, 12)
	back.size = Vector2(96, 74)
	back.pressed.connect(close)
	root.add_child(back)
	var bt := load("res://assets/ui/banner_missions.png") as Texture2D if ResourceLoader.exists("res://assets/ui/banner_missions.png") else null
	if bt:
		var title := TextureRect.new()
		title.name = "Title"
		title.texture = bt
		title.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		title.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		title.size = Vector2(330, 110)
		title.position = Vector2(vs.x * 0.5 + 150.0 - 165.0, 2)
		title.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(title)
	_build_tala(vs)
	_build_board(vs)


## Left: Tala, her bubble and her nameplate.
func _build_tala(vs: Vector2) -> void:
	var foot := Vector2(190.0, vs.y - 96.0)
	var k := minf((vs.y - 270.0) / TALA_FRAME.y, 0.9)   # her height from the screen
	tala = AnimatedSprite2D.new()
	tala.name = "Tala"
	tala.sprite_frames = _tala_frames()
	tala.centered = false
	tala.offset = Vector2(-TALA_FRAME.x * 0.5, -TALA_FRAME.y * 0.95)
	tala.scale = Vector2.ONE * k
	tala.position = foot
	tala.animation_finished.connect(func(): tala.play("idle"))
	root.add_child(tala)
	tala.play("idle")
	var hit := Button.new()   # tap her: she talks
	hit.name = "TalaTap"
	hit.flat = true
	hit.position = foot + Vector2(-TALA_FRAME.x * 0.3 * k, -TALA_FRAME.y * 0.9 * k)
	hit.size = Vector2(TALA_FRAME.x * 0.6 * k, TALA_FRAME.y * 0.9 * k)
	hit.pressed.connect(func():
		game.audio.play("click", 0.0)
		_say("done" if _list().all_done() else ("some" if _list().done.any(func(d): return d) else "open"))
		_play("talk"))
	root.add_child(hit)
	var bub := _nine("bubble", Rect2(36, 96, 300, 104), 30.0, root)
	bub.name = "Bubble"
	bubble_label = _label("", 19, INK, Rect2(56, 104, 260, 70), root, HORIZONTAL_ALIGNMENT_CENTER)
	bubble_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bubble_label.clip_text = false
	bubble_label.name = "BubbleText"
	var np := _tex("nameplate")
	if np:
		var plate := TextureRect.new()
		plate.texture = np
		plate.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		plate.stretch_mode = TextureRect.STRETCH_SCALE
		plate.size = Vector2(250, 86)
		plate.position = Vector2(foot.x - 125.0, vs.y - 96.0)
		plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(plate)
	_label("TALA", 22, INK, Rect2(foot.x - 70.0, vs.y - 80.0, 140, 28), root, HORIZONTAL_ALIGNMENT_CENTER)
	_label("Trail Scout", 15, Color(0.4, 0.28, 0.15), Rect2(foot.x - 70.0, vs.y - 54.0, 140, 22), root, HORIZONTAL_ALIGNMENT_CENTER)


func _tala_frames() -> SpriteFrames:
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	for clip in TALA_MS:
		var p := DIR + "tala_%s@2x.png" % clip
		if not ResourceLoader.exists(p):
			continue
		var t: Texture2D = load(p)
		sf.add_animation(clip)
		sf.set_animation_loop(clip, clip == "idle")
		sf.set_animation_speed(clip, 1000.0 / float(TALA_MS[clip]))
		for i in 8:
			var a := AtlasTexture.new()
			a.atlas = t
			a.region = Rect2((i % 4) * TALA_FRAME.x, (i / 4) * TALA_FRAME.y, TALA_FRAME.x, TALA_FRAME.y)
			sf.add_frame(clip, a)
	if not sf.has_animation("idle"):
		sf.add_animation("idle")
	return sf


func _play(clip: String) -> void:
	if tala and tala.sprite_frames.has_animation(clip):
		tala.play(clip)


func _say(kind: String) -> void:
	if bubble_label:
		bubble_label.text = (LINES[kind] as Array).pick_random()


## Right: the board with its tabs and the three missions.
func _build_board(vs: Vector2) -> void:
	var left := 380.0
	var r := Rect2(left, 150, vs.x - left - 24.0, vs.y - 150.0 - 20.0)
	for i in 2:   # tabs above the board
		var t := "daily" if i == 0 else "weekly"
		var tr := Rect2(r.position.x + 30.0 + i * 250.0, 96, 240, 62)
		_nine("tab_on" if tab == t else "tab_off", tr, 22.0, root)
		var tl := _label(t.to_upper(), 26, CREAM, tr, root, HORIZONTAL_ALIGNMENT_CENTER, true)
		tl.name = "TabLabel_" + t
		var tb := Button.new()
		tb.name = "Tab_" + t
		tb.flat = true
		tb.position = tr.position
		tb.size = tr.size
		tb.pressed.connect(func():
			game.audio.play("click", 0.0)
			show_tab(t))
		root.add_child(tb)
	var board := _nine("board", r, 56.0, root)
	board.name = "Board"
	var m := _list()
	var sub := "Fresh goals every day" if tab == "daily" else "New goals every Monday"
	if tab == "daily" and m.streak > 1:
		sub += "  ·  %d-day streak" % m.streak
	_label(sub, 17, Color(1, 0.88, 0.6), Rect2(r.position.x, r.position.y + 22.0, r.size.x, 26), root, HORIZONTAL_ALIGNMENT_CENTER)
	var foot := "Complete missions to earn meat."
	if m.ids.size() > 0:
		foot = "All done: +%d meat bonus!" % int(Missions.num(m.period, "all_meat")) if m.all_done() else "Finish all %d for a +%d meat bonus." % [m.ids.size(), int(Missions.num(m.period, "all_meat"))]
	_label(foot, 17, Color(1, 0.88, 0.6), Rect2(r.position.x, r.end.y - 50.0, r.size.x, 26), root, HORIZONTAL_ALIGNMENT_CENTER)
	var top := r.position.y + 54.0
	var bottom := r.end.y - 56.0
	var n := maxi(m.ids.size(), 1)
	var gap := 10.0
	var ch := minf((bottom - top - gap * (n - 1)) / n, 150.0)
	var inner_x := r.position.x + 34.0
	var inner_w := r.size.x - 68.0
	if m.ids.is_empty():
		_label("No missions yet: run a little farther first!", 20, CREAM, Rect2(inner_x, top, inner_w, ch), root, HORIZONTAL_ALIGNMENT_CENTER)
	for i in m.ids.size():
		_card(m, i, Rect2(inner_x, top + i * (ch + gap), inner_w, ch))


func _card(m: Missions, i: int, r: Rect2) -> void:
	var card := _nine("card", r, 30.0, root)
	card.name = "Card_%d" % i
	var id: String = m.ids[i]
	var done: bool = m.done[i]
	var pad := r.size.y * 0.14
	var icon_s := r.size.y - pad * 2.0
	var ic := TextureRect.new()
	var ip: String = ICONS.get(id, "")
	ic.texture = SpriteLib.tex(ip) if ip != "" and ResourceLoader.exists(ip) else null
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ic.position = r.position + Vector2(pad + 6.0, pad)
	ic.size = Vector2(icon_s, icon_s)
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(ic)
	var status_w := minf(190.0, r.size.x * 0.24)
	var reward_w := 92.0
	var tx := ic.position.x + icon_s + 14.0
	var tw := r.end.x - status_w - reward_w - 24.0 - tx
	var fs := 24 if r.size.y >= 120.0 else 20
	var nm := _label(TITLES.get(id, "Mission"), fs, INK, Rect2(tx, r.position.y + pad * 0.6, tw, fs + 8), root)
	nm.name = "Title_%d" % i
	var what := _label(m.text(i), fs - 6, Color(0.35, 0.24, 0.12), Rect2(tx, nm.position.y + fs + 4.0, tw, fs), root)
	what.name = "Text_%d" % i
	var bar_r := Rect2(tx, r.end.y - pad - 30.0, tw, 30)
	_nine("bar_track", bar_r, 14.0, root)
	var frac := clampf(float(m.progress[i]) / maxf(float(m.targets[i]), 1.0), 0.0, 1.0)
	if frac > 0.02:
		var fill := _nine("bar_fill", Rect2(bar_r.position + Vector2(4, 4), Vector2(maxf((bar_r.size.x - 8.0) * frac, 28.0), bar_r.size.y - 8.0)), 11.0, root)
		fill.name = "Fill_%d" % i
	var unit := " m" if id == "run_m" else ""
	_label("%d / %d%s" % [int(m.progress[i]), int(m.targets[i]), unit], 17, CREAM, bar_r, root, HORIZONTAL_ALIGNMENT_CENTER, true).name = "Progress_%d" % i
	var rx := r.end.x - status_w - reward_w - 12.0
	var meat := TextureRect.new()
	meat.texture = SpriteLib.tex(Hud.MEAT_ICON) if ResourceLoader.exists(Hud.MEAT_ICON) else null
	meat.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	meat.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	meat.size = Vector2(46, 40)
	meat.position = Vector2(rx + (reward_w - 46.0) * 0.5, r.position.y + r.size.y * 0.5 - 40.0)
	meat.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(meat)
	_label("+%d" % m.meat(), 24, INK, Rect2(rx, r.position.y + r.size.y * 0.5, reward_w, 32), root, HORIZONTAL_ALIGNMENT_CENTER).name = "Reward_%d" % i
	var sr := Rect2(r.end.x - status_w - 14.0, r.position.y + r.size.y * 0.5 - 30.0, status_w, 60)
	_nine("button_done" if done else "button_wait", sr, 22.0, root)
	var st := _label("DONE" if done else "IN PROGRESS", 19 if not done else 22, CREAM, sr, root, HORIZONTAL_ALIGNMENT_CENTER, true)
	st.name = "State_%d" % i
	if done:
		var ck := TextureRect.new()
		ck.texture = _tex("check")
		ck.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ck.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		ck.size = Vector2(40, 40)
		ck.position = Vector2(sr.end.x - 30.0, sr.position.y - 16.0)
		ck.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(ck)
