class_name VLR03Hound
extends CharacterBody2D

const EnemySprites := preload("res://scripts/enemies/sector07_enemy_sprite_library.gd")
const CHARGE_FX := preload("res://scenes/effects/hound_charge_trail_fx.tscn")
const POUNCE_FX := preload("res://scenes/effects/hound_pounce_impact_fx.tscn")
const CLAW_FX := preload("res://scenes/effects/hound_claw_slash_fx.tscn")
const BURST_FX := preload("res://scenes/effects/hound_energy_burst_fx.tscn")
const DESTROY_FX := preload("res://scenes/effects/hound_destroy_fx.tscn")
const GROUND_Y := 24.0
const BALANCE := preload("res://resources/enemies/hound_balance.tres")
const PHASE2_TINT := Color(1.25, 0.8, 0.75)

signal defeated
signal phase_changed(phase: int)
signal audio_hook(event_name: StringName, world_position: Vector2)
@export var max_health := 850
@onready var health: HealthComponent = $HealthComponent
@onready var hitbox: HitboxComponent = $AttackHitbox
@onready var sprite: AnimatedSprite2D = $Sprite
var team: StringName = &"enemy"
var player: GuanditoPlayer
var facing := -1.0
var state: StringName = &"dormant"
var cooldown := 1.2
var hitstun := 0.0
var attack_data: AttackData
var last_attack: StringName = &""
var stagger_damage := 0
var stagger_window_left := 0.0
var stagger_threshold := 110
var phase := 1  # boss phase (1 or 2), read by the HUD
var tempo := 1.0  # cooldown multiplier; phase 2 attacks come faster

# --- Action FSM --------------------------------------------------------------
# An action is data: {id, cooldown, finish?, steps}. Each step is
# {state, time, enter?} where `enter` is a method name called on entry.
# `action_phase` is the current step's state and `action_left` its countdown,
# ticked in _physics_process. Every step change deactivates the hitbox, and a
# stagger or death calls _cancel_action(): nothing pending can resume later.
var action: Dictionary = {}
var action_step := -1
var action_phase: StringName = &""
var action_left := 0.0
var death_left := -1.0

func _ready() -> void:
	add_to_group("boss")
	player = get_tree().get_first_node_in_group("player")
	max_health = BALANCE.max_health; health.max_health = max_health; health.current_health = max_health
	$Hurtbox.hit_received.connect(_on_hit); health.died.connect(_on_died)
	attack_data = AttackData.new(); attack_data.hitstop = 0.06
	sprite.sprite_frames = EnemySprites.build(&"hound"); _update_visual()

func _update_visual() -> void:
	var animation: StringName = &"idle"
	if state == &"dead": animation = &"death"
	elif hitstun > 0.0 or state == &"stagger": animation = &"hit"
	elif state in [&"charge_warning", &"charge"]: animation = &"charge"
	elif state in [&"leap_warning", &"leap"]: animation = &"pounce"
	elif state in [&"claw_warning", &"claw"]: animation = &"claw_combo"
	elif state in [&"burst_warning", &"burst"]: animation = &"energy_burst"
	elif absf(velocity.x) > 2.0: animation = &"walk_prowl"
	if sprite.animation != animation: sprite.play(animation)
	sprite.flip_h = facing < 0.0

func activate() -> void:
	if state == &"dormant": state = &"idle"

func _physics_process(delta: float) -> void:
	if state == &"dead":
		if death_left > 0.0:
			death_left -= delta
			if death_left <= 0.0:
				if is_instance_valid(player): player.add_xp(BALANCE.xp_reward)
				defeated.emit(); queue_free()
		return
	if state == &"dormant": return
	# Action timers run in real time, also during light hitstun (as the old timers did).
	_tick_action(delta)
	if not is_on_floor(): velocity.y = minf(600.0, velocity.y + 900.0 * delta)
	stagger_window_left = maxf(0.0, stagger_window_left - delta)
	if stagger_window_left == 0.0: stagger_damage = 0
	if hitstun > 0.0:
		hitstun -= delta; velocity.x = move_toward(velocity.x, 0.0, 180.0 * delta)
		if hitstun <= 0.0 and state == &"stagger": state = &"idle"; cooldown = 0.8
		move_and_slide(); _update_visual(); return
	cooldown -= delta / tempo
	if is_instance_valid(player) and state not in [&"charge", &"leap", &"claw", &"burst"]: facing = signf(player.global_position.x - global_position.x)
	if phase == 1 and health.current_health <= max_health / 2 and state == &"idle":
		_enter_phase_two(); move_and_slide(); _update_visual(); return
	if cooldown <= 0.0 and state == &"idle":
		_choose_attack()
	if state == &"charge": velocity.x = facing * BALANCE.charge_speed * (1.15 if phase == 2 else 1.0)
	move_and_slide(); _update_visual()

func _start_action(next: Dictionary) -> void:
	action = next; action_step = -1; _advance_step()

func _advance_step() -> void:
	hitbox.deactivate()
	action_step += 1
	var steps: Array = action["steps"]
	if action_step >= steps.size():
		var finished := action
		_cancel_action(); state = &"idle"; cooldown = finished["cooldown"]
		if finished.has("finish"): call(finished["finish"])
		return
	var step: Dictionary = steps[action_step]
	action_phase = step["state"]; action_left = step["time"]; state = action_phase
	if String(state).ends_with("warning"): velocity.x = 0.0; queue_redraw()
	if step.has("enter"): call(step["enter"])

func _tick_action(delta: float) -> void:
	if action.is_empty(): return
	action_left -= delta
	while not action.is_empty() and action_left <= 0.0:
		_advance_step()

func _cancel_action() -> void:
	action = {}; action_step = -1; action_phase = &""; action_left = 0.0; hitbox.deactivate()

func _choose_attack() -> void:
	if not is_instance_valid(player): return
	var distance := absf(player.global_position.x - global_position.x)
	if phase == 2:
		# Phase 2 mixes in two new patterns and never repeats the same one twice.
		if distance > 200.0: _start_action(_fan_burst() if last_attack == &"double_charge" else _double_charge())
		elif distance > 105.0: _start_action(_fan_burst() if last_attack == &"pounce" else _leap_slam())
		else: _start_action(_leap_slam() if last_attack == &"claw" else _claw())
		return
	if distance > 230.0: _start_action(_burst() if last_attack == &"charge" else _charge())
	elif distance > 105.0: _start_action(_burst() if last_attack == &"pounce" else _leap_slam())
	else: _start_action(_reposition() if last_attack == &"claw" else _claw())

# --- Attack data ---------------------------------------------------------------

func _reposition() -> Dictionary:
	return {"id": &"reposition", "cooldown": 0.45, "finish": &"_stop_moving", "steps": [
		{"state": &"reposition", "time": 0.35, "enter": &"_back_off"},
	]}

func _charge() -> Dictionary:
	return {"id": &"charge", "cooldown": BALANCE.attack_1_recovery, "steps": [
		{"state": &"charge_warning", "time": BALANCE.attack_1_startup},
		{"state": &"charge", "time": 0.7, "enter": &"_charge_first_strike"},
	]}

func _leap_slam() -> Dictionary:
	return {"id": &"pounce", "cooldown": BALANCE.attack_2_recovery, "steps": [
		{"state": &"leap_warning", "time": BALANCE.attack_2_startup},
		{"state": &"leap", "time": 0.62, "enter": &"_leap_takeoff"},
		{"state": &"leap", "time": 0.18, "enter": &"_leap_land"},
	]}

const CLAW_RECOVER_STEP := 4
func _claw() -> Dictionary:
	return {"id": &"claw", "cooldown": 0.75, "steps": [
		{"state": &"claw_warning", "time": BALANCE.attack_3_startup},
		{"state": &"claw", "time": 0.1, "enter": &"_claw_first_strike"},
		{"state": &"claw", "time": 0.16},
		{"state": &"claw", "time": 0.1, "enter": &"_claw_strike"},
		{"state": &"recover", "time": BALANCE.attack_3_recovery},
	]}

func _burst() -> Dictionary:
	return {"id": &"burst", "cooldown": 1.2, "steps": [
		{"state": &"burst_warning", "time": 0.8},
		{"state": &"burst", "time": 0.0, "enter": &"_fire_burst"},
	]}

func _double_charge() -> Dictionary:
	# Skid, turn toward the player and go again: punish with a wall jump over it.
	return {"id": &"double_charge", "cooldown": BALANCE.attack_1_recovery, "steps": [
		{"state": &"charge_warning", "time": BALANCE.attack_1_startup * 0.85},
		{"state": &"charge", "time": 0.55, "enter": &"_double_charge_first_strike"},
		{"state": &"charge_warning", "time": 0.32},
		{"state": &"charge", "time": 0.55, "enter": &"_double_charge_second_strike"},
	]}

func _fan_burst() -> Dictionary:
	return {"id": &"fan_burst", "cooldown": 1.0, "steps": [
		{"state": &"burst_warning", "time": 0.7},
		{"state": &"burst", "time": 0.0, "enter": &"_fire_fan_burst"},
	]}

func _phase_shift() -> Dictionary:
	return {"id": &"phase_shift", "cooldown": 0.3, "finish": &"_apply_phase2_tint", "steps": [
		{"state": &"phase_shift", "time": 1.1},
	]}

# --- Step callbacks ------------------------------------------------------------

func _back_off() -> void: velocity.x = -facing * BALANCE.move_speed
func _stop_moving() -> void: velocity.x = 0.0
func _apply_phase2_tint() -> void: sprite.modulate = PHASE2_TINT

func _charge_strike() -> void:
	audio_hook.emit(&"hound_charge", global_position)
	_set_attack(BALANCE.attack_1_damage, Vector2(280, -75), Vector2(55, 0), Vector2(78, 44)); hitbox.activate(attack_data, facing)
	_spawn_ground_fx(CHARGE_FX, -facing * 36.0)

func _charge_first_strike() -> void: last_attack = &"charge"; _charge_strike()
func _double_charge_first_strike() -> void: last_attack = &"double_charge"; _charge_strike()
func _double_charge_second_strike() -> void:
	if is_instance_valid(player): facing = signf(player.global_position.x - global_position.x)
	_charge_strike()

func _leap_takeoff() -> void: last_attack = &"pounce"; velocity = Vector2(facing * 125, -350)
func _leap_land() -> void:
	_set_attack(BALANCE.attack_2_damage, Vector2(180, -155), Vector2(0, 22), Vector2(112, 38)); hitbox.activate(attack_data, facing)
	audio_hook.emit(&"hound_pounce", global_position); _spawn_ground_fx(POUNCE_FX)

func _claw_first_strike() -> void:
	last_attack = &"claw"; _set_attack(BALANCE.attack_3_damage, Vector2(175, -45), Vector2(46, -4), Vector2(60, 42)); _claw_strike()

func _claw_strike() -> void:
	# A hit that lands mid-combo drops the remaining strikes and goes to recovery.
	if hitstun > 0.0:
		action_step = CLAW_RECOVER_STEP; action_phase = &"recover"; state = &"recover"; action_left = BALANCE.attack_3_recovery; return
	hitbox.activate(attack_data, facing); _spawn_ground_fx(CLAW_FX, facing * 42.0); audio_hook.emit(&"enemy_attack", global_position)

func _fire_burst() -> void:
	last_attack = &"burst"; _spawn_ground_fx(BURST_FX, facing * 46.0)
	var shot := EnemyProjectile.new(); get_parent().add_child(shot); shot.global_position = global_position + Vector2(facing * 34, -18)
	shot.setup(facing, BALANCE.projectile_speed, 25); shot.use_hound_visual(); audio_hook.emit(&"projectile_fire", global_position)

func _fire_fan_burst() -> void:
	last_attack = &"burst"; _spawn_ground_fx(BURST_FX, facing * 46.0); audio_hook.emit(&"projectile_fire", global_position)
	# Three shots: flat, rising and falling. Gaps let a dash or jump slip through.
	for angle in [0.0, -0.32, 0.22]:
		var shot := EnemyProjectile.new(); get_parent().add_child(shot); shot.global_position = global_position + Vector2(facing * 34, -18)
		shot.setup(facing, BALANCE.projectile_speed, 20); shot.velocity = Vector2(facing * BALANCE.projectile_speed, 0.0).rotated(angle * facing); shot.use_hound_visual()

func _enter_phase_two() -> void:
	# Roar: brief invulnerable pause that clearly announces the new phase.
	_cancel_action(); phase = 2; tempo = 0.68; stagger_threshold = 150
	velocity.x = 0.0; phase_changed.emit(2)
	audio_hook.emit(&"hound_roar", global_position)
	var manager := get_tree().get_first_node_in_group("game_manager")
	if manager: manager.screen_shake(5.0, 0.6); manager.spawn_impact(global_position, "heavy")
	var tween := create_tween().set_loops(4)
	tween.tween_property(sprite, "modulate", Color(2.0, 0.5, 0.4), 0.12); tween.tween_property(sprite, "modulate", Color.WHITE, 0.12)
	_start_action(_phase_shift())

func _set_attack(damage: int, knockback: Vector2, offset: Vector2, size: Vector2) -> void:
	attack_data.damage = damage; attack_data.knockback = knockback; attack_data.hitstun = 0.32
	attack_data.hitbox_offset = offset; attack_data.hitbox_size = size

func _on_hit(data: AttackData, direction: float, attacker: Node) -> void:
	if state in [&"dead", &"dormant", &"phase_shift"]: return
	health.take_damage(data.damage)
	var base_tint := PHASE2_TINT if phase == 2 else Color.WHITE
	sprite.modulate = Color(2.5, 2.5, 2.5)
	create_tween().tween_property(sprite, "modulate", base_tint, 0.1); velocity += Vector2(data.knockback.x * direction * 0.42, data.knockback.y * 0.36)
	if health.current_health <= 0: return
	stagger_window_left = 1.4; stagger_damage += data.damage
	var super_armor := state == &"charge"
	if not super_armor: hitstun = minf(data.hitstun, 0.14)
	if stagger_damage >= stagger_threshold and not super_armor:
		_cancel_action(); state = &"stagger"; hitstun = 0.65; stagger_damage = 0
	if attacker and attacker.has_method("apply_hitstop"): attacker.apply_hitstop(data.hitstop)
	queue_redraw()

func _on_died() -> void:
	_cancel_action(); state = &"dead"; $Hurtbox.set_deferred("monitorable", false); _spawn_ground_fx(DESTROY_FX)
	audio_hook.emit(&"hound_destroy", global_position); _update_visual(); death_left = 0.85

func _spawn_fx(scene: PackedScene, local_offset: Vector2) -> void:
	var effect := scene.instantiate() as Node2D
	get_parent().add_child(effect); effect.global_position = global_position + local_offset
	var effect_sprite := effect.get_node("Sprite") as AnimatedSprite2D
	if effect_sprite: effect_sprite.flip_h = facing < 0.0

func _spawn_ground_fx(scene: PackedScene, local_x: float = 0.0) -> void:
	_spawn_fx(scene, Vector2(local_x, GROUND_Y))

func _draw() -> void:
	if is_instance_valid(sprite) and sprite.sprite_frames != null: return
	var dark := Color("#15191c"); var steel := Color("#747b79"); var red := Color("#d54532"); var white := Color("#d9d7cd")
	if state == &"dead": draw_rect(Rect2(-42, 10, 84, 14), dark); return
	# Quadruped industrial silhouette based on the Sector 07 concept sheet.
	draw_rect(Rect2(-38, -22, 72, 34), dark); draw_rect(Rect2(-31, -18, 58, 25), steel)
	draw_circle(Vector2(-5, -5), 11, dark); draw_circle(Vector2(-5, -5), 6, red)
	draw_colored_polygon(PackedVector2Array([Vector2(30 * facing, -17), Vector2(53 * facing, -12), Vector2(57 * facing, 4), Vector2(31 * facing, 7)]), white)
	draw_circle(Vector2(48 * facing, -5), 3, Color("#ff5838"))
	for leg_x in [-25, 18]:
		draw_line(Vector2(leg_x, 7), Vector2(leg_x - 8, 26), dark, 9); draw_rect(Rect2(leg_x - 15, 22, 20, 7), steel)
	if String(state).ends_with("warning"):
		var warning_color := Color("#ff5c35") if state != &"burst_warning" else Color("#78e52f")
		draw_arc(Vector2.ZERO, 48, 0, TAU, 28, warning_color, 3)
		draw_line(Vector2(-8, -40), Vector2(8, -40), warning_color, 3)
