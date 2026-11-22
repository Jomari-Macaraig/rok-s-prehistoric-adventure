extends SceneTree
## Captures the Market: the title screen with its button (`market_title`),
## the shop with some amber banked (`market_shop`), a Buy button waiting for
## its confirming tap (`market_confirm`), the shop after buying
## (`market_bought`), and the Time Crystal running in a run (`power_time`):
##   godot --path . --fixed-fps 60 --resolution 1280x720 -s tests/market_shots.gd -- <out_dir>

var main
var out := "user://market_shots"
var frame := 0


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out = args[0]
	DirAccess.make_dir_recursive_absolute(out)
	AudioServer.set_bus_mute(0, true)
	SaveData.path = "user://market_shots.cfg"
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
			main.meat_bank = 130
			main.best_m = 1300   # some items on sale, some still locked by distance
			main.boosters_owned.append("fossil_magnet")
			main._show_menu_text()
		15:
			_shot("market_title")
			main.open_market()
		25:
			_shot("market_shop")
			main.market.press_buy("time_crystal")
		32:
			_shot("market_confirm")
			main.market.press_buy("time_crystal")
		40:
			_shot("market_bought")
			main.market.close_market()
			main.unlocked = Forms.ORDER.duplicate()
			main.seen = Progression.INTROS.map(func(e): return e[1])
			main.start_run(false)
			main.distance = 300.0 * Tuning.PX_PER_M
			main.slots = ["time_crystal", "", ""]
		90:
			main.use_slot(0)
			main.run_meat = 7
			main.course._ground = Tuning.GROUND_Y
			for i in 3:
				main.course._pickup("meat", main.player.position + Vector2(420 + i * 90, -150 - sin(i * 1.5) * 40))
		110:
			_shot("power_time")
			return true
	if frame > 40:
		main.player.invuln = 99.0 if frame < 100 else 0.0   # 99 would leave him mid-blink (hidden)
		main.chase_gap = Tuning.CHASE_GAP_MAX
		if main.player.position.y > 600.0:   # keep him out of pits for the shot
			main.player.position.y = 300.0
			main.player.vy = 0.0

	return false
