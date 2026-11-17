extends SceneTree

const ARENA := preload("res://scenes/levels/test_arena.tscn")
const ENEMY_ATTACK := preload("res://resources/data/training_bot_attack.tres")
const RECORDER_DIR := "user://playtest_smoke"

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if condition:
		print("PASS: ", message)
	else:
		failures.append(message)
		push_error("FAIL: " + message)

func _frames(count: int) -> void:
	for _index in range(count):
		await physics_frame

func _until_attack_ends(player: GuanditoPlayer, limit: int) -> void:
	var guard := 0
	while player.attacking and guard < limit:
		guard += 1
		await physics_frame

func _receive_hit(player: GuanditoPlayer, bot: TrainingBot) -> void:
	(player.get_node("Hurtbox") as HurtboxComponent).receive_hit(ENEMY_ATTACK, -1.0, bot)

func _run() -> void:
	var arena := ARENA.instantiate()
	root.add_child(arena)
	await _frames(5)
	var player := get_first_node_in_group("player") as GuanditoPlayer
	var bot := get_first_node_in_group("enemies") as TrainingBot
	if not player or not bot:
		quit(1)
		return
	for enemy in get_nodes_in_group("enemies"):
		enemy.set_physics_process(false)

	var recorder := PlaytestRecorder.new()
	recorder.autosave_enabled = false
	recorder.export_dir_override = RECORDER_DIR
	arena.add_child(recorder)
	await _frames(2)

	# A hit received during evade i-frames registers as Perfect Evade without damage.
	player.dodge_phase = &"evade"
	var health_before := player.health.current_health
	_receive_hit(player, bot)
	_check(player.health.current_health == health_before, "perfect evade deals no damage")
	_check(recorder.perfect_evades == 1, "recorder registers Perfect Evade")

	# An exposed hit is stored as an x2 damage event.
	player.hitstun_left = 0.0
	player.dodge_phase = &"exposed"
	player.health.heal(player.health.max_health)
	_receive_hit(player, bot)
	var report := recorder.build_report(true)
	_check(int(report["evasion"]["x2_exposed_hits"]) == 1, "exposure records one x2 damage event")
	_check(int(report["evasion"]["total_damage_taken"]) == int(ENEMY_ATTACK.damage) * 2, "damage totals use the x2 amount")

	# Dash -> Light measures forward travel across the whole maneuver.
	player.health.heal(player.health.max_health)
	player.hitstun_left = 0.0
	await _frames(20)
	player.global_position += Vector2(160.0, 0.0)
	player.dash_cooldown_left = 0.0
	player._start_dash()
	await _frames(2)
	player._handle_light_input()
	_check(player.current_attack == &"dash_light", "dash cancels into Light for telemetry")
	await _until_attack_ends(player, 90)
	await _frames(2)
	report = recorder.build_report(true)
	_check(int(report["movement"]["dashes"]) == 1, "dash start is counted")
	_check(int(report["movement"]["dash_to_light_cancels"]) == 1, "Dash -> Light cancel is counted")
	var distance := float(report["movement"]["dash_light_distance_avg_px"])
	_check(distance > 3.0 and distance < 200.0, "Dash -> Light distance is measured (%.0f px)" % distance)

	# Damage during Heavy startup marks the attempt as punishable.
	player.health.heal(player.health.max_health)
	player.hitstun_left = 0.0
	await _frames(10)
	player._start_attack(&"heavy")
	await _frames(3)
	_receive_hit(player, bot)
	_check(not player.attacking, "Heavy interrupts on damage")
	report = recorder.build_report(true)
	_check(int(report["heavy"]["started"]) == 1 and int(report["heavy"]["interrupted"]) == 1, "punished Heavy is recorded")
	var progress := float(report["heavy"]["interrupt_progress_avg"])
	_check(progress > 0.0 and progress < 1.0, "Heavy interruption keeps startup progress (%.0f%%)" % [progress * 100.0])

	# An uninterrupted Heavy completes instead of counting as punished.
	player.health.heal(player.health.max_health)
	player.hitstun_left = 0.0
	await _frames(10)
	player._start_attack(&"heavy")
	await _until_attack_ends(player, 90)
	await _frames(2)
	report = recorder.build_report(true)
	_check(int(report["heavy"]["completed"]) == 1, "clean Heavy completion is recorded")
	_check(int(report["evasion"]["hits_taken"]) == 2, "only damaging hits enter the damage log")

	# The session exports as readable JSON on disk.
	var path := recorder.save_report(true)
	_check(path != "" and FileAccess.file_exists(path), "playtest report file written")
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	_check(parsed is Dictionary and parsed.has("movement"), "report parses as JSON dictionary")
	if parsed is Dictionary:
		_check(int(parsed["heavy"]["interrupted"]) == 1 and int(parsed["evasion"]["perfect_evades"]) == 1,
			"exported report preserves counters")

	if failures.is_empty():
		print("PLAYTEST_RECORDER_SMOKE: PASS")
		quit(0)
	else:
		print("TIMELINE: ", JSON.stringify(recorder._timeline))
		print("ATTACK_STATE attacking=", player.attacking, " current=", player.current_attack,
			" hitstop=", player.hitstop_left, " hitstun=", player.hitstun_left)
		print("PLAYTEST_RECORDER_SMOKE: FAIL (", failures.size(), ")")
		quit(1)
