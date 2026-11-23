class_name Audio
extends Node
## Sound effects (small player pool) and one looping music track per zone,
## cross-faded by distance (Zones.weights). All sounds are synthesised by
## tools/make_sounds.py, except Rok's voice (rok_alarm), a recording the user
## supplies, imported by tools/prepare_voice.py; silent until it exists.

const SFX := ["jump", "double_jump", "land", "shift", "form_rok", "form_raptor",
		"form_triceratops", "form_spinosaurus", "form_pteranodon", "flap", "smash", "amber", "egg", "shield",
		"hit", "fall", "click", "denied", "start", "slide", "intro", "unlock", "trex_roar", "stomp", "bite",
		"trex_growl", "step_rok", "step_raptor", "step_heavy", "step_grass", "step_sand", "step_rock",
		"jump_raptor", "jump_heavy", "land_heavy", "death_jingle", "rok_alarm",
		"weapon_break", "break_wood", "break_rock",
		"mumble_1", "mumble_2", "mumble_3", "mumble_4", "mumble_5", "mumble_6",
		"powerup_pickup", "powerup_activate", "powerup_expire"]
const VOLUME := {"land": -8.0, "click": -6.0, "jump": -4.0, "amber": -5.0, "shift": -3.0, "slide": -4.0,
		"flap": -7.0, "stomp": -6.0, "step_rok": -15.0, "step_raptor": -14.0, "step_heavy": -9.0,
		"step_grass": -17.0, "step_sand": -15.0, "step_rock": -16.0, "jump_raptor": -5.0,
		"jump_heavy": -4.0, "land_heavy": -4.0, "trex_growl": -3.0, "rok_alarm": -2.0,
		"powerup_pickup": -4.0, "powerup_activate": -3.0, "powerup_expire": -5.0}
const MUSIC_DB := -9.0
const POOL := 14
## Zone id -> music file (in Zones.ZONES order).
const MUSIC := {"forest": "music", "desert": "music_desert", "volcanic": "music_volcanic"}   # a zone not listed plays its kin's (Zones.kin)

var streams := {}
var players: Array[AudioStreamPlayer] = []
var music: AudioStreamPlayer                 # the forest track (kept for compatibility)
var music_players: Array[AudioStreamPlayer] = []
var muted := false
## The last sounds asked for (even while muted), newest last, for tests.
var played: Array[String] = []
var _next := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for n in SFX:
		var path := "res://assets/sounds/%s.wav" % n
		if ResourceLoader.exists(path):   # rok_alarm waits for the user's recording
			streams[n] = load(path)
	for i in POOL:
		var p := AudioStreamPlayer.new()
		add_child(p)
		players.append(p)
	for z in Zones.ZONES:
		var mp := AudioStreamPlayer.new()
		var m: AudioStreamWAV = load("res://assets/sounds/%s.wav" % MUSIC.get(z.id, MUSIC.get(Zones.kin(z.id), "music")))
		m.loop_mode = AudioStreamWAV.LOOP_FORWARD
		m.loop_begin = 0
		m.loop_end = int(m.get_length() * m.mix_rate)
		mp.stream = m
		mp.volume_db = -80.0
		add_child(mp)
		music_players.append(mp)
	music = music_players[0]
	music.volume_db = MUSIC_DB
	set_muted(SaveData.load_muted())


func play(name: String, pitch_jitter := 0.06, pitch := 1.0, extra_db := 0.0) -> void:
	played.append(name)
	if played.size() > 32:
		played.pop_front()
	if muted or not streams.has(name):
		return
	var p := players[_next]
	_next = (_next + 1) % POOL
	p.stream = streams[name]
	p.volume_db = VOLUME.get(name, 0.0) + extra_db
	p.pitch_scale = pitch * randf_range(1.0 - pitch_jitter, 1.0 + pitch_jitter)
	p.play()


func start_music() -> void:
	if muted:
		return
	for mp in music_players:
		if not mp.playing:
			mp.play()


var _duck := 0.0   # dB taken off the music (death)


## Cross-fade the zone tracks by their zone weights (0..1 each).
func set_music_weights(w: Array) -> void:
	for i in music_players.size():
		var v: float = w[i] if i < w.size() else 0.0
		music_players[i].volume_db = MUSIC_DB + _duck + linear_to_db(maxf(v, 0.0001))


## On death the music cuts out so the death jingle plays on its own.
func duck_music(on: bool) -> void:
	_duck = -80.0 if on else 0.0
	for mp in music_players:
		mp.volume_db = -80.0 if on else mp.volume_db


func set_muted(m: bool) -> void:
	muted = m
	if muted:
		for mp in music_players:
			mp.stop()
		for p in players:
			p.stop()
	else:
		for mp in music_players:
			mp.play()
	SaveData.save_muted(muted)
