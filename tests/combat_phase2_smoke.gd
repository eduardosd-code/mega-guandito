extends SceneTree

const ARENA := preload("res://scenes/levels/test_arena.tscn")
const EVASION := preload("res://resources/modules/overdrive_evasion_mk1.tres")
const ENEMY_ATTACK := preload("res://resources/data/training_bot_attack.tres")
const HEAVY := preload("res://resources/data/attack_heavy.tres")

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

func _tap(action: StringName) -> void:
	Input.action_press(action)
	await physics_frame
	Input.action_release(action)

func _run() -> void:
	var arena := ARENA.instantiate()
	root.add_child(arena)
	await _frames(5)
	var player := get_first_node_in_group("player") as GuanditoPlayer
	var bot := get_first_node_in_group("enemies") as TrainingBot
	_check(player != null and bot != null, "arena instantiates player and TrainingBot")
	if not player or not bot:
		quit(1)
		return
	for enemy in get_nodes_in_group("enemies"):
		enemy.set_physics_process(false)

	# Starting movement: run, jump, partial air control and land without stuck states.
	var start_x := player.global_position.x
	Input.action_press(&"move_right")
	Input.action_press(&"run")
	await _frames(12)
	Input.action_release(&"run")
	_check(player.global_position.x > start_x + 8.0, "Run moves Guandito responsively")
	await _tap(&"jump")
	await _frames(1)
	_check(player.velocity.y < 0.0 and not player.is_on_floor(), "Jump leaves the floor")
	var air_x := player.global_position.x
	await _frames(8)
	Input.action_release(&"move_right")
	_check(player.global_position.x > air_x, "air control changes horizontal trajectory")
	player.dash_cooldown_left = 0.0
	await _tap(&"dash")
	_check(player.dash_left == 0.0, "air dash is unavailable")
	await _frames(80)
	_check(player.is_on_floor(), "Guandito lands and exits airborne state")

	# Dodge is absent from the starting kit.
	await _tap(&"dodge")
	_check(player.dodge_phase == &"normal", "dodge input is ignored without module")
	_check(player.modules.equip(EVASION), "Overdrive Evasion equips through reactor rules")
	_check(player.modules.has_effect(&"unlock_dodge"), "module unlocks dodge effect")
	player.dodge_cooldown_left = 0.0
	await _tap(&"dodge")
	await _frames(1)
	_check(player.dodge_phase in [&"startup", &"evade"], "equipped dodge enters startup/evade")
	await _frames(4)
	_check(player.dodge_phase == &"evade", "dodge reaches configured i-frame phase")
	await _frames(10)
	_check(player.dodge_phase == &"exposed", "dodge enters exposed recovery")
	await _frames(16)
	_check(player.dodge_phase == &"normal", "dodge exits exposure without a stuck state")

	# Perfect evade: an otherwise valid hit causes zero damage and is registered.
	player.dodge_phase = &"evade"
	var health_before := player.health.current_health
	player._on_hit(ENEMY_ATTACK, -1.0, bot)
	_check(player.health.current_health == health_before, "evade i-frames prevent all damage")
	_check(player.perfect_evade_count == 1, "attack during i-frames registers Perfect Evade")

	# Exposure applies exactly x2 once and cannot leak after the hit.
	player.dodge_phase = &"exposed"
	player._on_hit(ENEMY_ATTACK, -1.0, bot)
	_check(player.health.current_health == health_before - ENEMY_ATTACK.damage * 2, "exposed hit applies x2 damage")
	_check(player.dodge_phase == &"normal", "exposure clears immediately after receiving damage")
	var after_exposed := player.health.current_health
	player._on_hit(ENEMY_ATTACK, -1.0, bot)
	_check(player.health.current_health == after_exposed - ENEMY_ATTACK.damage, "later hits return to normal damage")
	player.health.heal(player.health.max_health)
	player.hitstun_left = 0.0

	# Ground dash is offensive, vulnerable, and only Light can cancel it.
	await _frames(3)
	player._start_dash()
	var dash_health := player.health.current_health
	player._on_hit(ENEMY_ATTACK, -1.0, bot)
	_check(player.health.current_health == dash_health - ENEMY_ATTACK.damage, "ground dash has no invulnerability")
	player.health.heal(player.health.max_health)
	player.hitstun_left = 0.0
	player.dash_cooldown_left = 0.0
	player._start_dash()
	player._handle_light_input()
	_check(player.dash_left == 0.0 and player.current_attack == &"dash_light", "Dash -> Light cancels immediately")
	player._interrupt_attack()

	# Input during Light 1 recovery is buffered into Light 2.
	player.combo_step = 1
	player._start_attack(&"light_1")
	await _frames(4)
	player._handle_light_input()
	_check(player.attack_buffered, "early Light input enters attack buffer")
	await _frames(20)
	_check(player.combo_step >= 2, "buffered input advances the combo")
	player._interrupt_attack()

	player._start_attack(&"heavy")
	await _frames(2)
	_check(player.attacking and player.current_attack == &"heavy", "Heavy startup commits the player")
	player._on_hit(ENEMY_ATTACK, -1.0, bot)
	_check(not player.attacking and player.current_attack == &"", "damage interrupts Heavy startup cleanly")
	player.health.heal(player.health.max_health)
	player.hitstun_left = 0.0

	# Heavy is the launcher and air Heavy stays unavailable.
	bot._on_hit(HEAVY, 1.0, player)
	_check(bot.velocity.y < -200.0 and HEAVY.launcher, "Heavy launches TrainingBot vertically")
	player.global_position.y -= 60.0
	await _frames(2)
	player._handle_actions()
	Input.action_press(&"attack_heavy")
	await physics_frame
	Input.action_release(&"attack_heavy")
	_check(not player.attacking, "Heavy attack is unavailable in the air")

	_check(player.modules.unequip(EVASION.id), "evasion module unequips cleanly")
	_check(not player.modules.has_effect(&"unlock_dodge"), "unequip removes dodge ability")
	player.health.current_health = 10
	player.dodge_phase = &"exposed"
	player._on_hit(ENEMY_ATTACK, -1.0, bot)
	_check(player.health.current_health == 0 and player.state_machine.current == &"dead", "death during exposure exits all combat states")
	_check(player.dodge_phase == &"normal", "death cannot leave exposure multiplier active")

	if failures.is_empty():
		print("COMBAT_PHASE2_SMOKE: PASS")
		quit(0)
	else:
		print("COMBAT_PHASE2_SMOKE: FAIL (", failures.size(), ")")
		quit(1)
