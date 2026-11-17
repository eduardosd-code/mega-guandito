extends SceneTree
# Zero-style kit: wall slide, wall jump, air dash, charged hammer, trauma shake.

const ARENA := preload("res://scenes/levels/test_arena.tscn")
var failures: Array[String] = []

func _initialize() -> void: call_deferred("_run")
func _frames(count: int) -> void:
	for _index in range(count): await physics_frame
func _check(value: bool, label: String) -> void:
	if value: print("PASS: ", label)
	else: failures.append(label); push_error("FAIL: " + label)
func _release_all() -> void:
	for action in [&"move_left", &"move_right", &"jump", &"dash", &"attack_light"]: Input.action_release(action)

func _run() -> void:
	var arena := ARENA.instantiate(); root.add_child(arena); await _frames(5)
	var player := get_first_node_in_group("player") as GuanditoPlayer
	for enemy in get_nodes_in_group("enemies"): enemy.set_physics_process(false)

	# Wall slide against the left wall.
	player.global_position = Vector2(20, 80); player.velocity = Vector2.ZERO
	Input.action_press(&"move_left"); await _frames(25)
	_check(player.wall_sliding, "pressing into a wall while airborne starts a wall slide")
	_check(player.velocity.y <= player.wall_slide_speed + 0.5, "wall slide caps fall speed")
	Input.action_press(&"jump"); await _frames(2)
	_check(player.velocity.x > 0.0 and player.velocity.y < 0.0, "wall jump kicks away from the wall and up")
	_release_all(); await _frames(4)

	# Air dash once per airtime.
	player.dash_cooldown_left = 0.0
	Input.action_press(&"move_right"); Input.action_press(&"dash"); await _frames(2)
	_check(player.air_dash_spent and player.dash_left > 0.0, "air dash triggers in the air")
	_check(absf(player.velocity.y) < 1.0, "air dash holds altitude")
	_release_all()
	for _index in range(90):
		if player.is_on_floor(): break
		await physics_frame
	_check(player.is_on_floor() and not player.air_dash_spent, "landing restores the air dash")

	# Charged hammer.
	await _frames(10)
	Input.action_press(&"attack_light")
	await _frames(int(ceil((player.charge_time + 0.6) * 60.0)))
	_check(player.charge_ready, "holding attack charges the hammer")
	Input.action_release(&"attack_light"); await _frames(2)
	_check(player.current_attack == &"charged", "releasing a full charge fires the charged attack")
	await _frames(40)

	# Trauma camera.
	var camera := player.get_node("Camera2D")
	camera.add_trauma(0.6); await _frames(2)
	_check(camera.trauma > 0.0 and camera.trauma < 0.6, "trauma decays over time")
	await _frames(60)
	_check(camera.trauma == 0.0 and camera.offset == Vector2.ZERO, "camera settles after shake")

	if failures.is_empty(): print("ZERO_KIT_SMOKE: PASS"); quit(0)
	else: print("ZERO_KIT_SMOKE: FAIL (", failures.size(), ")"); quit(1)
