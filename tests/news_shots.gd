extends SceneTree
## Captures unlock news: the game-over screen listing what was new this run,
## including a Market item that went on sale (`news_gameover`), and the
## Market with that item tagged NEW on the first visit (`news_market`):
##   godot --path . --fixed-fps 60 --resolution 1280x720 -s tests/news_shots.gd -- <out_dir>

var main
var out := "user://news_shots"
var frame := 0


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	DirAccess.make_dir_recursive_absolute(out)
	AudioServer.set_bus_mute(0, true)
	SaveData.path = "user://news_shots.cfg"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveData.path))
	main = load("res://main.tscn").instantiate()
	main.pause_for_info = false
	root.add_child(main)


func _shot(name: String) -> void:
	root.get_texture().get_image().save_png("%s/%s.png" % [out, name])


func _process(_delta: float) -> bool:
	frame += 1
	match frame:
		5:
			# a player whose best was just short of the Time Crystal going on sale
			main.best_m = Progression.MARKET_UNLOCK_M["time_crystal"] - 60
			main.unlocked = [Forms.ROK, Forms.RAPTOR, Forms.TRICERATOPS]
			main.meat_bank = 45
			main.market_seen = ["amber_shield", "fossil_magnet"]
			main.boosters_owned.append("amber_shield")
			main.seen = Progression.INTROS.map(func(e): return e[1])
			main.start_run(false)
			main.distance = (Progression.MARKET_UNLOCK_M["time_crystal"] - 20.0) * Tuning.PX_PER_M
		40:
			main.distance = (Progression.MARKET_UNLOCK_M["time_crystal"] + 25.0) * Tuning.PX_PER_M
			main._check_unlocks()
			# what this run met for the first time
			main.new_this_run = ["Quicksand", "Combos!", "Boulders"]
			main.run_meat = 9
		45:
			main._bank_meat()
			main._finish_game_over()
		60:
			_shot("news_gameover")
			main.open_market()
		75:
			_shot("news_market")
			return true
	if frame > 5 and frame < 45:
		main.player.invuln = 0.0
		main.chase_gap = Tuning.CHASE_GAP_MAX
		if main.player.position.y > 600.0:
			main.player.position.y = 300.0
			main.player.vy = 0.0
	return false
