extends SceneTree
# The Zone 4 chimney must be climbable with wall jumps, spikes must hurt, enemy
# wind-ups must flash, and the mission rank must grade sensibly.

const SECTOR := preload("res://scenes/levels/sector07.tscn")
var failures: Array[String] = []

func _initialize() -> void: call_deferred("_run")
func _frames(count: int) -> void:
	for _index in range(count): await physics_frame
func _check(value: bool, label: String) -> void:
	if value: print("PASS: ", label)
	else: failures.append(label); push_error("FAIL: " + label)

func _run() -> void:
	_check(MissionRank.rank(MissionRank.score(300.0, 0, 0, 10, 10)) == "S", "flawless fast clear ranks S")
	_check(MissionRank.rank(MissionRank.score(900.0, 400, 3, 0, 10)) == "D", "slow sloppy clear ranks D")

	var level := SECTOR.instantiate(); root.add_child(level); await _frames(3)
	level.intro_skipped = true; level.intro_finished = true
	var player := level.player as GuanditoPlayer; player.input_lock_left = 0.0
	for enemy in get_nodes_in_group("enemies"): enemy.set_physics_process(false)

	# Climb the chimney with a simple wall-jump bot.
	player.respawn_at(Vector2(2450, 180)); await _frames(20)
	var dir := 1.0; var min_y := player.global_position.y; var jumps := 0
	Input.action_press(&"move_right")
	for _index in range(360):
		await physics_frame
		min_y = minf(min_y, player.global_position.y)
		if player.wall_sliding or player.is_on_floor():
			Input.action_press(&"jump"); await physics_frame; await physics_frame; Input.action_release(&"jump")
			jumps += 1
			Input.action_release(&"move_right" if dir > 0.0 else &"move_left")
			dir = -dir
			Input.action_press(&"move_right" if dir > 0.0 else &"move_left")
		if player.global_position.y < 76.0: break
	Input.action_release(&"move_left"); Input.action_release(&"move_right")
	_check(min_y < 80.0, "chimney can be climbed above the barrier with wall jumps (min y %.0f, %d jumps)" % [min_y, jumps])
	Input.action_press(&"move_right"); await _frames(60); Input.action_release(&"move_right")
	_check(player.global_position.x > 2502.0, "player clears the barrier from the top of the chimney")

	# Spikes.
	player.respawn_at(Vector2(2600, 182)); await _frames(30)
	_check(player.health.current_health < player.health.max_health, "spike strip damages the player")

	# Telegraph flash.
	var enemy := get_first_node_in_group("sector_enemies") as SectorEnemy
	enemy._flash_telegraph(0.3); await _frames(4)
	_check(enemy.sprite.modulate != Color.WHITE, "enemy wind-up flashes")

	if failures.is_empty(): print("SECTOR07_ZERO_ROUTE_SMOKE: PASS"); quit(0)
	else: print("SECTOR07_ZERO_ROUTE_SMOKE: FAIL (", failures.size(), ")"); quit(1)
