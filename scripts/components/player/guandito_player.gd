class_name GuanditoPlayer
extends CharacterBody2D

signal module_status(text: String)
signal perfect_evade(total: int)

@export_group("Ground Movement")
@export var walk_speed := 125.0
@export var run_speed := 175.0
@export var acceleration := 2800.0
@export var turn_acceleration := 4200.0
@export var deceleration := 3200.0
@export var jump_force := -330.0
@export var gravity := 850.0
@export var rise_gravity_multiplier := 0.88
@export var fall_gravity_multiplier := 1.18
@export var max_fall_speed := 440.0
@export var coyote_time := 0.11
@export var jump_buffer_time := 0.12

@export_group("Air Control")
@export var air_acceleration := 1000.0
@export var air_turn_acceleration := 1600.0
@export var air_deceleration := 240.0
@export var air_max_speed := 145.0

@export_group("Ground Dash")
@export var dash_speed := 265.0
@export var dash_duration := 0.14
@export var dash_cooldown := 0.38

@export_group("Attack Buffer")
@export var attack_buffer_time := 0.22

@export_group("Overdrive Evasion")
@export var dodge_startup := 0.035
@export var dodge_iframes := 0.13
@export var dodge_exposed_time := 0.24
@export var dodge_cooldown := 0.85
@export var dodge_speed := 225.0
@export var exposed_damage_multiplier := 2.0

const ATTACKS := {
	&"light_1": preload("res://resources/data/attack_light_1.tres"),
	&"light_2": preload("res://resources/data/attack_light_2.tres"),
	&"light_3": preload("res://resources/data/attack_light_3.tres"),
	&"heavy": preload("res://resources/data/attack_heavy.tres"),
	&"air": preload("res://resources/data/attack_air.tres"),
	&"dash_light": preload("res://resources/data/attack_dash.tres")
}
const LEGS_MODULE := preload("res://resources/modules/legs_module_mk1.tres")
const EVASION_MODULE := preload("res://resources/modules/overdrive_evasion_mk1.tres")

@onready var health: HealthComponent = $HealthComponent
@onready var experience: ExperienceComponent = $ExperienceComponent
@onready var modules: ModuleComponent = $ModuleComponent
@onready var state_machine: PlayerStateMachine = $StateMachine
@onready var hitbox: HitboxComponent = $AttackHitbox
@onready var visual: GuanditoVisual = $Visual

var team: StringName = &"player"
var facing := 1.0
var hitstop_left := 0.0
var hitstun_left := 0.0
var dash_left := 0.0
var dash_cooldown_left := 0.0
var coyote_left := 0.0
var jump_buffer_left := 0.0
var attacking := false
var current_attack: StringName = &""
var combo_step := 0
var combo_left := 0.0
var attack_buffered := false
var attack_buffer_left := 0.0
var attack_token := 0
var air_attack_spent := false
var dodge_phase: StringName = &"normal"
var dodge_phase_left := 0.0
var dodge_cooldown_left := 0.0
var perfect_evade_count := 0
var base_max_health := 100
var base_reactor := 10
var base_walk := 125.0
var base_run := 175.0
var base_dash := 265.0
var was_airborne := false
var input_lock_left := 0.0
var dash_jumped_this_frame := false

func _ready() -> void:
	add_to_group("player")
	base_walk = walk_speed
	base_run = run_speed
	base_dash = dash_speed
	$Hurtbox.hit_received.connect(_on_hit)
	health.died.connect(_on_died)
	experience.level_changed.connect(_on_level_up)
	modules.modules_changed.connect(_apply_module_stats)
	modules.unlock(LEGS_MODULE)
	modules.energy_changed.emit(modules.energy_used(), modules.reactor_capacity)
	visual.set_action(&"idle", facing)

func _physics_process(delta: float) -> void:
	dash_jumped_this_frame = false
	if hitstop_left > 0.0:
		hitstop_left = maxf(0.0, hitstop_left - delta)
		return
	_tick_timers(delta)
	if health.current_health <= 0:
		return
	if input_lock_left > 0.0:
		_apply_gravity(delta)
		velocity.x = move_toward(velocity.x, 0.0, deceleration * delta)
		move_and_slide()
		_update_ground_state()
		return
	if hitstun_left > 0.0:
		hitstun_left -= delta
		state_machine.change(&"hit")
		_apply_gravity(delta)
		move_and_slide()
		return
	_handle_actions()
	if dodge_phase in [&"startup", &"evade"]:
		velocity = Vector2(facing * dodge_speed, 0.0)
	elif dash_left > 0.0:
		state_machine.change(&"dash")
		velocity = Vector2(facing * dash_speed, 0.0)
	elif not dash_jumped_this_frame:
		_handle_movement(delta)
	_apply_gravity(delta)
	move_and_slide()
	_update_ground_state()

func _tick_timers(delta: float) -> void:
	var dash_was_active := dash_left > 0.0
	dash_left = maxf(0.0, dash_left - delta)
	if dash_was_active and dash_left == 0.0 and not attacking:
		visual.set_action(&"dash_end", facing)
	input_lock_left = maxf(0.0, input_lock_left - delta)
	dash_cooldown_left = maxf(0.0, dash_cooldown_left - delta)
	dodge_cooldown_left = maxf(0.0, dodge_cooldown_left - delta)
	jump_buffer_left = maxf(0.0, jump_buffer_left - delta)
	combo_left = maxf(0.0, combo_left - delta)
	attack_buffer_left = maxf(0.0, attack_buffer_left - delta)
	if attack_buffer_left == 0.0:
		attack_buffered = false
	if combo_left == 0.0 and not attacking:
		combo_step = 0
	if not is_on_floor():
		coyote_left = maxf(0.0, coyote_left - delta)
	_tick_dodge_phase(delta)

func _handle_actions() -> void:
	if Input.is_action_just_pressed("jump"):
		jump_buffer_left = jump_buffer_time
	if Input.is_action_just_pressed("dash") and is_on_floor() and dash_cooldown_left <= 0.0 and not attacking and dodge_phase == &"normal":
		_update_facing_from_input()
		_start_dash()
	if jump_buffer_left > 0.0 and (is_on_floor() or coyote_left > 0.0) and (_can_move() or dash_left > 0.0):
		if dash_left > 0.0:
			velocity.x = facing * dash_speed
			dash_left = 0.0
			dash_jumped_this_frame = true
		velocity.y = jump_force
		jump_buffer_left = 0.0
		coyote_left = 0.0
		state_machine.change(&"jump")
		visual.set_action(&"jump_start", facing)
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= 0.48
	if Input.is_action_just_pressed("dodge"):
		_update_facing_from_input()
		_try_start_dodge()
	if Input.is_action_just_pressed("attack_light"):
		_handle_light_input()
	if Input.is_action_just_pressed("attack_heavy") and is_on_floor() and not attacking and dash_left <= 0.0 and dodge_phase == &"normal":
		_start_attack(&"heavy")
	if Input.is_action_just_pressed("toggle_module"):
		_toggle_module(LEGS_MODULE)
	if Input.is_action_just_pressed("toggle_evasion_module"):
		_toggle_module(EVASION_MODULE)

func _handle_light_input() -> void:
	if attacking:
		if current_attack in [&"light_1", &"light_2", &"dash_light"]:
			attack_buffered = true
			attack_buffer_left = attack_buffer_time
		return
	if dodge_phase != &"normal":
		return
	if dash_left > 0.0:
		# Only explicit cancel currently allowed: ground Dash -> Light 1.
		dash_left = 0.0
		velocity.x *= ATTACKS[&"dash_light"].momentum_retention
		combo_step = 1
		_start_attack(&"dash_light")
	elif not is_on_floor():
		if not air_attack_spent:
			air_attack_spent = true
			_start_attack(&"air")
	elif combo_step == 0 or combo_left > 0.0:
		combo_step = (combo_step % 3) + 1
		_start_attack(StringName("light_%d" % combo_step))

func _handle_movement(delta: float) -> void:
	var axis := Input.get_axis("move_left", "move_right")
	if axis != 0.0:
		facing = signf(axis)
		if is_on_floor():
			var target := axis * (run_speed if Input.is_action_pressed("run") else walk_speed)
			var ground_response := turn_acceleration if velocity.x != 0.0 and signf(velocity.x) != signf(axis) else acceleration
			velocity.x = move_toward(velocity.x, target, ground_response * delta)
			if not attacking:
				state_machine.change(&"run")
				_set_visual_action(&"run")
		else:
			var air_response := air_turn_acceleration if velocity.x != 0.0 and signf(velocity.x) != signf(axis) else air_acceleration
			var carried_speed := maxf(air_max_speed, absf(velocity.x)) if signf(velocity.x) == signf(axis) else air_max_speed
			velocity.x = move_toward(velocity.x, axis * carried_speed, air_response * delta)
	elif is_on_floor():
		velocity.x = move_toward(velocity.x, 0.0, deceleration * delta)
		if not attacking:
			state_machine.change(&"idle")
			_set_visual_action(&"idle")
	else:
		velocity.x = move_toward(velocity.x, 0.0, air_deceleration * delta)
		if not attacking and dodge_phase == &"normal":
			_set_visual_action(&"jump" if velocity.y < 0.0 else &"fall")
	visual.facing = facing

func _apply_gravity(delta: float) -> void:
	if not is_on_floor() and dash_left <= 0.0 and dodge_phase not in [&"startup", &"evade"]:
		var gravity_multiplier := rise_gravity_multiplier if velocity.y < 0.0 and Input.is_action_pressed("jump") else fall_gravity_multiplier
		velocity.y = minf(max_fall_speed, velocity.y + gravity * gravity_multiplier * delta)

func _update_facing_from_input() -> void:
	var axis := Input.get_axis("move_left", "move_right")
	if not is_zero_approx(axis):
		facing = signf(axis)
		visual.facing = facing

func _update_ground_state() -> void:
	if is_on_floor():
		if was_airborne and not attacking and dodge_phase == &"normal":
			visual.set_action(&"land", facing)
		coyote_left = coyote_time
		air_attack_spent = false
	elif velocity.y > 0.0 and not attacking and dash_left <= 0.0 and dodge_phase == &"normal":
		state_machine.change(&"fall")
		_set_visual_action(&"fall")
	was_airborne = not is_on_floor()

func _can_move() -> bool:
	return dash_left <= 0.0 and dodge_phase == &"normal" and not attacking

func _start_dash() -> void:
	dash_left = dash_duration
	dash_cooldown_left = dash_cooldown
	state_machine.change(&"dash")
	visual.set_action(&"dash_start", facing)

func _start_attack(id: StringName) -> void:
	if attacking:
		return
	attacking = true
	current_attack = id
	attack_buffered = false
	attack_buffer_left = 0.0
	attack_token += 1
	var token := attack_token
	var data: AttackData = ATTACKS[id]
	state_machine.change(&"attack")
	var visual_action: StringName = id
	if id == &"heavy": visual_action = &"heavy_start"
	elif id == &"air": visual_action = &"air_light"
	elif id == &"dash_light": visual_action = &"light_1"
	visual.set_action(visual_action, facing)
	await get_tree().create_timer(data.startup, false).timeout
	if token != attack_token or health.current_health <= 0:
		return
	hitbox.activate(data, facing)
	if id == &"heavy":
		visual.set_action(&"heavy_attack", facing)
	await get_tree().create_timer(data.active_time, false).timeout
	if token != attack_token:
		return
	hitbox.deactivate()
	if id == &"heavy":
		visual.set_action(&"heavy_recovery", facing)
	await get_tree().create_timer(data.recovery, false).timeout
	if token != attack_token:
		return
	attacking = false
	current_attack = &""
	var chains := id in [&"light_1", &"light_2", &"dash_light"]
	combo_left = data.combo_window if chains else 0.0
	if chains and attack_buffered and attack_buffer_left > 0.0 and combo_step < 3:
		attack_buffered = false
		combo_step += 1
		_start_attack(StringName("light_%d" % combo_step))
	else:
		_set_visual_action(&"idle" if is_on_floor() else (&"jump" if velocity.y < 0.0 else &"fall"))

func _interrupt_attack() -> void:
	attack_token += 1
	attacking = false
	current_attack = &""
	attack_buffered = false
	attack_buffer_left = 0.0
	combo_step = 0
	combo_left = 0.0
	hitbox.deactivate()

func _try_start_dodge() -> void:
	if not modules.has_effect(&"unlock_dodge"):
		module_status.emit("ESQUIVA REQUIERE SOBRECARGA EVASIVA")
		return
	if not is_on_floor() or dodge_cooldown_left > 0.0 or attacking or dash_left > 0.0 or dodge_phase != &"normal":
		return
	dodge_phase = &"startup"
	dodge_phase_left = dodge_startup
	dodge_cooldown_left = dodge_cooldown
	state_machine.change(&"dodge_startup")
	visual.set_action(&"dodge_start", facing)

func _tick_dodge_phase(delta: float) -> void:
	if dodge_phase == &"normal":
		return
	dodge_phase_left -= delta
	if dodge_phase_left > 0.0:
		return
	match dodge_phase:
		&"startup":
			dodge_phase = &"evade"
			dodge_phase_left = dodge_iframes
			state_machine.change(&"dodge_evade")
			visual.set_action(&"dodge_invulnerable", facing)
		&"evade":
			dodge_phase = &"exposed"
			dodge_phase_left = dodge_exposed_time
			state_machine.change(&"dodge_exposed")
			visual.set_action(&"dodge_exposed", facing)
		&"exposed":
			dodge_phase = &"normal"
			dodge_phase_left = 0.0
			visual.set_action(&"idle", facing)

func _on_hit(data: AttackData, direction: float, _attacker: Node) -> void:
	if dodge_phase == &"evade":
		perfect_evade_count += 1
		perfect_evade.emit(perfect_evade_count)
		var manager := get_tree().get_first_node_in_group("game_manager")
		if manager:
			manager.spawn_impact(global_position, "perfect")
		return
	_interrupt_attack()
	dash_left = 0.0
	var multiplier := exposed_damage_multiplier if dodge_phase == &"exposed" else 1.0
	dodge_phase = &"normal"
	dodge_phase_left = 0.0
	health.take_damage(int(round(data.damage * multiplier)))
	velocity = Vector2(data.knockback.x * direction, data.knockback.y)
	hitstun_left = data.hitstun
	apply_hitstop(data.hitstop)
	visual.set_action(&"hit", facing)

func on_attack_connected(data: AttackData, hit_position: Vector2) -> void:
	if data.air_hit_vertical_damping < 1.0 and not is_on_floor():
		velocity.y *= data.air_hit_vertical_damping
	var manager := get_tree().get_first_node_in_group("game_manager")
	if manager:
		manager.spawn_impact(hit_position, data.impact_fx)
		if data.shake_intensity > 0.0:
			manager.screen_shake(data.shake_intensity, data.shake_duration)

func apply_hitstop(duration: float) -> void:
	hitstop_left = maxf(hitstop_left, duration)

func _toggle_module(module: ModuleData) -> void:
	if not modules.is_unlocked(module.id):
		module_status.emit("MODULO NO ADQUIRIDO")
		return
	var was_equipped := modules.equipped.has(module.id)
	var success := modules.toggle(module)
	if not success:
		module_status.emit("ENERGIA DE REACTOR INSUFICIENTE")
		return
	module_status.emit("%s: %s" % [module.display_name.to_upper(), "RETIRADO" if was_equipped else "EQUIPADO"])
	if was_equipped and module.unlock_dodge and dodge_phase != &"normal":
		dodge_phase = &"normal"
		dodge_phase_left = 0.0

func _set_visual_action(next: StringName) -> void:
	if visual.action != next:
		visual.set_action(next, facing)

func _on_level_up(level: int) -> void:
	var expected := base_max_health + (level - 1) * 8
	if health.max_health < expected:
		health.increase_max_health(expected - health.max_health)
	modules.reactor_capacity = base_reactor + (level - 1)
	modules.energy_changed.emit(modules.energy_used(), modules.reactor_capacity)

func _apply_module_stats() -> void:
	walk_speed = base_walk * (1.0 + modules.modifier(&"speed"))
	run_speed = base_run * (1.0 + modules.modifier(&"speed"))
	dash_speed = base_dash * (1.0 + modules.modifier(&"dash_speed"))

func _on_died() -> void:
	_interrupt_attack()
	dodge_phase = &"normal"
	state_machine.change(&"dead")
	velocity = Vector2.ZERO
	visual.set_action(&"death", facing)

func add_xp(amount: int) -> void:
	experience.add_xp(amount)

func unlock_evasion_module(auto_equip: bool = true) -> void:
	modules.unlock(EVASION_MODULE)
	if auto_equip and not modules.equipped.has(EVASION_MODULE.id):
		modules.equip(EVASION_MODULE)
	module_status.emit("SOBRECARGA EVASIVA Mk-I INSTALADA")
	input_lock_left = 0.65
	velocity.x = 0.0
	visual.set_action(&"module_install", facing)

func respawn_at(world_position: Vector2) -> void:
	global_position = world_position
	velocity = Vector2.ZERO
	var camera := get_node_or_null("Camera2D")
	if camera != null and camera.has_method("reset_to_target"):
		camera.reset_to_target()
	health.current_health = health.max_health
	health.health_changed.emit(health.current_health, health.max_health)
	hitstun_left = 0.0
	hitstop_left = 0.0
	dash_left = 0.0
	dodge_phase = &"normal"
	_interrupt_attack()
	state_machine.change(&"idle")
	visual.set_action(&"idle", facing)
	visual.modulate = Color.WHITE

func dodge_debug_status() -> String:
	if not modules.has_effect(&"unlock_dodge"):
		return "LOCKED"
	if dodge_cooldown_left > 0.0:
		return "COOLDOWN %.2f" % dodge_cooldown_left
	return "READY"
