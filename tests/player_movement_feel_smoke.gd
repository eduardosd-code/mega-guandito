extends SceneTree

const ARENA := preload("res://scenes/levels/test_arena.tscn")
var failures: Array[String] = []

func _initialize() -> void: call_deferred("_run")
func _frames(count: int) -> void:
	for _index in range(count): await physics_frame
func _check(value: bool, label: String) -> void:
	if value: print("PASS: ", label)
	else: failures.append(label); push_error("FAIL: " + label)

func _run() -> void:
	var arena := ARENA.instantiate(); root.add_child(arena); await _frames(5)
	var player := get_first_node_in_group("player") as GuanditoPlayer
	for enemy in get_nodes_in_group("enemies"): enemy.set_physics_process(false)
	for _index in range(60):
		if player.is_on_floor(): break
		await physics_frame
	_check(player.is_on_floor(), "player is grounded before movement measurements")
	Input.action_press(&"move_right"); Input.action_press(&"run"); await _frames(4)
	_check(player.velocity.x >= player.run_speed * 0.95, "ground movement reaches top speed within four frames")
	_check(player.run_speed >= 175.0, "run speed uses the faster movement target")
	_check(player.walk_speed >= 120.0, "normal movement feels agile without holding run")
	Input.action_release(&"move_right"); Input.action_release(&"run"); await _frames(4)
	_check(absf(player.velocity.x) <= 1.0, "ground movement stops without drift within four frames")
	Input.action_press(&"move_right"); await _frames(3); Input.action_release(&"move_right")
	Input.action_press(&"move_left"); await _frames(4)
	_check(player.velocity.x < -player.walk_speed * 0.7, "opposite input reverses direction decisively")
	Input.action_release(&"move_left")
	await _frames(6)
	Input.action_press(&"move_left"); Input.action_press(&"dash"); await _frames(2)
	_check(player.facing < 0.0 and player.velocity.x < -player.dash_speed * 0.9, "dash immediately follows fresh directional input")
	Input.action_release(&"dash"); Input.action_release(&"move_left"); await _frames(30)
	Input.action_press(&"move_right"); Input.action_press(&"dash"); Input.action_press(&"jump"); await _frames(2)
	_check(not player.is_on_floor() and player.velocity.y < 0.0, "jump cancels directly out of dash")
	_check(player.velocity.x >= player.dash_speed * 0.95, "dash jump preserves horizontal momentum")
	Input.action_release(&"dash"); Input.action_release(&"jump"); Input.action_release(&"move_right")
	for _index in range(60):
		if player.is_on_floor(): break
		await physics_frame
	var jump_origin := player.global_position.y
	Input.action_press(&"jump"); await _frames(20); Input.action_release(&"jump")
	var peak_y := player.global_position.y
	for _index in range(45):
		await physics_frame; peak_y = minf(peak_y, player.global_position.y)
	_check(jump_origin - peak_y >= 55.0, "full jump reaches the taller target height")
	if failures.is_empty(): print("PLAYER_MOVEMENT_FEEL_SMOKE: PASS"); quit(0)
	else: print("PLAYER_MOVEMENT_FEEL_SMOKE: FAIL (", failures.size(), ")"); quit(1)
