class_name SectorEnemy
extends CharacterBody2D

const EnemySprites := preload("res://scripts/enemies/sector07_enemy_sprite_library.gd")
const SCRAPPER_IMPACT_FX := preload("res://scenes/effects/scrapper_impact_fx.tscn")
const SCRAPPER_CHARGE_FX := preload("res://scenes/effects/scrapper_charge_trail_fx.tscn")
const SCRAPPER_SPARKS_FX := preload("res://scenes/effects/scrapper_sparks_fx.tscn")
const BULWARK_HEAVY_FX := preload("res://scenes/effects/bulwark_heavy_impact_fx.tscn")
const BULWARK_CHARGE_FX := preload("res://scenes/effects/bulwark_charge_trail_fx.tscn")
const BULWARK_BACKHAND_FX := preload("res://scenes/effects/bulwark_backhand_arc_fx.tscn")
const SENTRY_MUZZLE_FX := preload("res://scenes/effects/sentry_muzzle_flash_fx.tscn")
const SENTRY_HIT_FX := preload("res://scenes/effects/sentry_hit_sparks_fx.tscn")
const GROUND_Y := 21.0
const BALANCE := [preload("res://resources/enemies/scrapper_balance.tres"), preload("res://resources/enemies/bulwark_balance.tres"), preload("res://resources/enemies/sentry_balance.tres")]

signal defeated(enemy: SectorEnemy)
signal audio_hook(event_name: StringName, world_position: Vector2)
signal armor_broken(enemy: SectorEnemy)
enum Role { SCRAPPER, BULWARK, SENTRY }

@export var role := Role.SCRAPPER
@export var patrol_radius := 100.0
@export var balance_override: EnemyBalanceData
@onready var health: HealthComponent = $HealthComponent
@onready var hitbox: HitboxComponent = $AttackHitbox
@onready var sprite: AnimatedSprite2D = $Sprite
var team: StringName = &"enemy"
var player: GuanditoPlayer
var balance: EnemyBalanceData
var spawn_position := Vector2.ZERO
var facing := -1.0
var state: StringName = &"idle"
var cooldown := 0.45
var hitstun := 0.0
var armor_broken_left := 0.0
var backhand_cooldown := 0.0
var charge_cooldown := 0.0
var retreat_available := true
var action_token := 0
var attack_data: AttackData
static var shared_melee_slot_until := 0

func _ready() -> void:
	add_to_group("enemies"); add_to_group("sector_enemies")
	spawn_position = global_position; player = get_tree().get_first_node_in_group("player")
	$Hurtbox.hit_received.connect(_on_hit); health.died.connect(_on_died)
	balance = balance_override if balance_override else BALANCE[role]
	health.max_health = balance.max_health; health.current_health = balance.max_health
	_configure_visual(); _update_visual()

func _configure_visual() -> void:
	var visual_role: StringName = [&"scrapper", &"bulwark", &"sentry"][role]
	sprite.sprite_frames = EnemySprites.build(visual_role)
	sprite.position = Vector2(0, -22 if role == Role.SENTRY else (-27 if role == Role.BULWARK else -11))

func _physics_process(delta: float) -> void:
	if state == &"dead": return
	cooldown = maxf(0.0, cooldown - delta); backhand_cooldown = maxf(0.0, backhand_cooldown - delta)
	charge_cooldown = maxf(0.0, charge_cooldown - delta); armor_broken_left = maxf(0.0, armor_broken_left - delta)
	if hitstun > 0.0:
		hitstun -= delta; state = &"hit"; velocity.x = move_toward(velocity.x, 0.0, 900.0 * delta)
		if hitstun <= 0.0: state = &"idle"
		move_and_slide(); _update_visual(); return
	if not is_instance_valid(player): player = get_tree().get_first_node_in_group("player"); return
	var dx := player.global_position.x - global_position.x
	if dx != 0.0: facing = signf(dx)
	if role == Role.SENTRY: _tick_sentry(delta, dx)
	else: _tick_ground_enemy(delta, dx)
	move_and_slide(); _update_visual()

func _tick_ground_enemy(delta: float, dx: float) -> void:
	if not is_on_floor(): velocity.y = minf(500.0, velocity.y + 850.0 * delta)
	if state in [&"attack_2", &"charge"]: return
	if state not in [&"idle", &"chase", &"walk"]:
		velocity.x = move_toward(velocity.x, 0.0, 1500.0 * delta); return
	if absf(dx) > balance.detection_range:
		state = &"idle"; velocity.x = move_toward(velocity.x, 0.0, 700.0 * delta); return
	if absf(dx) > balance.preferred_range:
		state = &"chase" if role == Role.SCRAPPER else &"walk"
		velocity.x = move_toward(velocity.x, facing * balance.move_speed + _separation_velocity(), 650.0 * delta)
	elif cooldown <= 0.0 and _claim_melee_slot():
		_begin_position(dx)
	else: velocity.x = move_toward(velocity.x, _separation_velocity(), 1100.0 * delta)

func _tick_sentry(delta: float, dx: float) -> void:
	velocity.y = move_toward(velocity.y, sin(Time.get_ticks_msec() * 0.004) * 14.0, 80.0 * delta)
	if state == &"retreat": velocity.x = -facing * balance.move_speed
	elif state not in [&"hover", &"idle", &"position"]: velocity.x = move_toward(velocity.x, 0.0, 500.0 * delta)
	elif absf(dx) < 92.0 and retreat_available:
		state = &"retreat"; retreat_available = false; _finish_retreat()
	elif absf(dx) > balance.preferred_range + 55.0:
		state = &"position"; velocity.x = move_toward(velocity.x, facing * balance.move_speed, 420.0 * delta)
	elif absf(dx) < balance.preferred_range - 45.0:
		state = &"position"; velocity.x = move_toward(velocity.x, -facing * balance.move_speed * 0.55, 420.0 * delta)
	elif cooldown <= 0.0: _shoot_sequence(balance.enable_alternate_attack)
	else: state = &"hover"; velocity.x = move_toward(velocity.x, 0.0, 500.0 * delta)

func _begin_position(dx: float) -> void:
	state = &"position"; velocity.x = 0.0; action_token += 1; var token := action_token
	await get_tree().create_timer(balance.position_time, false).timeout
	if token != action_token or state == &"dead" or hitstun > 0.0: return
	if role == Role.SCRAPPER:
		if absf(dx) > 34.0 and charge_cooldown <= 0.0: _scrapper_charge()
		else: _scrapper_quick()
	else:
		if absf(dx) < 42.0 and backhand_cooldown <= 0.0: _bulwark_backhand()
		elif absf(dx) > 78.0 and charge_cooldown <= 0.0: _bulwark_charge()
		else: _bulwark_hammer()

func _scrapper_quick() -> void:
	state = &"attack_1"; _flash_telegraph(balance.attack_1_startup); audio_hook.emit(&"enemy_attack", global_position); await get_tree().create_timer(balance.attack_1_startup, false).timeout
	if not _action_valid(&"attack_1"): return
	attack_data = _attack(&"scrapper_quick", balance.attack_1_damage, Vector2(110, -35), Vector2(26, -2), Vector2(38, 34), 0.18, 0.03)
	hitbox.activate(attack_data, facing); _spawn_ground_fx(SCRAPPER_IMPACT_FX, facing * 30.0); await get_tree().create_timer(0.09, false).timeout
	hitbox.deactivate(); await _recover(balance.attack_1_recovery)

func _scrapper_charge() -> void:
	state = &"attack_2"; charge_cooldown = 2.2; _flash_telegraph(balance.attack_2_startup); audio_hook.emit(&"enemy_attack", global_position); await get_tree().create_timer(balance.attack_2_startup, false).timeout
	if not _action_valid(&"attack_2"): return
	attack_data = _attack(&"scrapper_charge", balance.attack_2_damage, Vector2(175, -55), Vector2(30, -1), Vector2(48, 36), 0.24, 0.04)
	hitbox.activate(attack_data, facing); _spawn_ground_fx(SCRAPPER_CHARGE_FX, -facing * 24.0); velocity.x = facing * balance.charge_speed
	await get_tree().create_timer(0.34, false).timeout; hitbox.deactivate(); velocity.x = 0.0; await _recover(balance.attack_2_recovery)

func _bulwark_hammer() -> void:
	state = &"hammer_fist"; _flash_telegraph(balance.attack_1_startup); audio_hook.emit(&"enemy_attack", global_position); await get_tree().create_timer(balance.attack_1_startup, false).timeout
	if not _action_valid(&"hammer_fist"): return
	attack_data = _attack(&"bulwark_hammer", balance.attack_1_damage, Vector2(240, -95), Vector2(34, 4), Vector2(58, 42), 0.32, 0.065)
	hitbox.activate(attack_data, facing); _spawn_ground_fx(BULWARK_HEAVY_FX, facing * 42.0); await get_tree().create_timer(0.13, false).timeout
	hitbox.deactivate(); await _recover(balance.attack_1_recovery)

func _bulwark_charge() -> void:
	state = &"charge"; charge_cooldown = 3.8; _flash_telegraph(balance.attack_2_startup); audio_hook.emit(&"enemy_attack", global_position); await get_tree().create_timer(balance.attack_2_startup, false).timeout
	if not _action_valid(&"charge"): return
	attack_data = _attack(&"bulwark_charge", balance.attack_2_damage, Vector2(290, -65), Vector2(40, 0), Vector2(70, 48), 0.3, 0.055)
	hitbox.activate(attack_data, facing); _spawn_ground_fx(BULWARK_CHARGE_FX, -facing * 30.0); velocity.x = facing * balance.charge_speed
	await get_tree().create_timer(0.52, false).timeout; hitbox.deactivate(); velocity.x = 0.0; await _recover(balance.attack_2_recovery)

func _bulwark_backhand() -> void:
	state = &"backhand"; backhand_cooldown = 4.5; _flash_telegraph(balance.attack_3_startup); audio_hook.emit(&"enemy_attack", global_position); await get_tree().create_timer(balance.attack_3_startup, false).timeout
	if not _action_valid(&"backhand"): return
	attack_data = _attack(&"bulwark_backhand", balance.attack_3_damage, Vector2(230, -40), Vector2(30, -7), Vector2(62, 48), 0.24, 0.045)
	hitbox.activate(attack_data, facing); _spawn_ground_fx(BULWARK_BACKHAND_FX, facing * 34.0); await get_tree().create_timer(0.12, false).timeout
	hitbox.deactivate(); await _recover(balance.attack_3_recovery)

func _shoot_sequence(triple: bool) -> void:
	state = &"triple_pulse" if triple else &"pulse_shot"; cooldown = balance.attack_cooldown
	_flash_telegraph(balance.attack_2_startup if triple else balance.attack_1_startup); await get_tree().create_timer(balance.attack_2_startup if triple else balance.attack_1_startup, false).timeout
	if state == &"dead" or hitstun > 0.0: return
	var count := 3 if triple else 1
	for index in range(count):
		_fire_sentry_projectile()
		if index < count - 1: await get_tree().create_timer(0.16, false).timeout
	retreat_available = true; await _recover(balance.attack_2_recovery if triple else balance.attack_1_recovery)

func _fire_sentry_projectile() -> void:
	_spawn_fx(SENTRY_MUZZLE_FX, Vector2(facing * 25.0, -8.0)); audio_hook.emit(&"projectile_fire", global_position)
	var shot := EnemyProjectile.new(); get_parent().add_child(shot); shot.global_position = global_position + Vector2(facing * 22, -8)
	shot.setup(facing, balance.projectile_speed, balance.attack_1_damage); shot.use_sentry_visual()

func _finish_retreat() -> void:
	await get_tree().create_timer(0.38, false).timeout
	if state == &"retreat": state = &"hover"; velocity.x = 0.0; cooldown = 0.12

func _recover(duration: float) -> void:
	state = &"recover"; await get_tree().create_timer(duration, false).timeout
	if state != &"dead": state = &"idle" if role != Role.SENTRY else &"hover"; cooldown = balance.attack_cooldown

func _attack(id: StringName, damage: int, knockback: Vector2, offset: Vector2, size: Vector2, stun: float, stop: float) -> AttackData:
	var data := AttackData.new(); data.id = id; data.damage = damage; data.knockback = knockback; data.hitbox_offset = offset
	data.hitbox_size = size; data.hitstun = stun; data.hitstop = stop; return data

func _action_valid(expected: StringName) -> bool: return state == expected and hitstun <= 0.0 and health.current_health > 0

func _claim_melee_slot() -> bool:
	var now := Time.get_ticks_msec()
	if now < shared_melee_slot_until: return false
	shared_melee_slot_until = now + 260; return true

func _separation_velocity() -> float:
	var separation := 0.0
	for other in get_tree().get_nodes_in_group("sector_enemies"):
		if other == self or not is_instance_valid(other): continue
		var gap: float = global_position.x - other.global_position.x
		if absf(gap) < 38.0: separation += signf(gap if gap != 0.0 else float(get_instance_id() - other.get_instance_id())) * 26.0
	return separation

func _on_hit(data: AttackData, direction: float, attacker: Node) -> void:
	if state == &"dead": return
	var heavy_break := role == Role.BULWARK and (data.id == &"heavy" or data.launcher)
	if heavy_break and armor_broken_left <= 0.0:
		armor_broken_left = balance.armor_break_duration; state = &"armor_broken"; hitstun = 0.3; action_token += 1; hitbox.deactivate()
		armor_broken.emit(self); audio_hook.emit(&"armor_break", global_position); _spawn_fx(SCRAPPER_SPARKS_FX, Vector2.ZERO)
	else:
		var armored := role == Role.BULWARK and armor_broken_left <= 0.0
		var super_armored := role == Role.BULWARK and state == &"charge"
		if not armored and not super_armored: hitstun = data.hitstun; state = &"hit"; action_token += 1; hitbox.deactivate()
	var resistance := 0.28 if role == Role.BULWARK else (0.65 if role == Role.SENTRY else 1.0)
	health.take_damage(data.damage); velocity += Vector2(data.knockback.x * direction * resistance, data.knockback.y * resistance)
	if attacker and attacker.has_method("apply_hitstop"): attacker.apply_hitstop(data.hitstop)
	if role == Role.SCRAPPER: _spawn_fx(SCRAPPER_SPARKS_FX, Vector2(0, -14))
	elif role == Role.SENTRY: _spawn_fx(SENTRY_HIT_FX, Vector2(0, -10))
	audio_hook.emit(&"enemy_hit", global_position); _update_visual()

func _on_died() -> void:
	state = &"dead"; action_token += 1; hitbox.deactivate(); $Hurtbox.set_deferred("monitorable", false); audio_hook.emit(&"enemy_death", global_position)
	if is_instance_valid(player): player.add_xp(balance.xp_reward)
	defeated.emit(self); _update_visual(); await get_tree().create_timer(0.65, false).timeout; queue_free()

func _spawn_fx(scene: PackedScene, local_offset: Vector2) -> void:
	var effect := scene.instantiate() as Node2D; get_parent().add_child(effect); effect.global_position = global_position + local_offset
	var effect_sprite := effect.get_node("Sprite") as AnimatedSprite2D
	if effect_sprite: effect_sprite.flip_h = facing < 0.0

func _spawn_ground_fx(scene: PackedScene, local_x: float = 0.0) -> void:
	_spawn_fx(scene, Vector2(local_x, GROUND_Y))

func _update_visual() -> void:
	if not is_instance_valid(sprite) or sprite.sprite_frames == null: return
	var animation: StringName
	if state == &"dead": animation = &"death"
	elif state in [&"hit", &"armor_broken"]: animation = &"hit"
	elif role == Role.SCRAPPER: animation = &"attack_2" if state == &"attack_2" else (&"attack_1" if state == &"attack_1" else (&"run" if absf(velocity.x) > 2.0 else &"idle"))
	elif role == Role.BULWARK: animation = &"attack_charge" if state == &"charge" else (&"attack_backhand" if state == &"backhand" else (&"attack_hammer_fist" if state == &"hammer_fist" else (&"walk" if absf(velocity.x) > 2.0 else &"idle")))
	else: animation = &"triple_pulse" if state == &"triple_pulse" else (&"pulse_shot" if state == &"pulse_shot" else (&"move" if absf(velocity.x) > 2.0 else &"hover_idle"))
	if sprite.animation != animation: sprite.play(animation)
	sprite.flip_h = facing < 0.0

# Readable wind-up: the body pulses white->warning red during startup so every
# attack can be reacted to (Zero-style enemies always announce their swings).
func _flash_telegraph(duration: float) -> void:
	if not is_instance_valid(sprite): return
	var tween := create_tween()
	var half := maxf(duration * 0.5, 0.02)
	tween.tween_property(sprite, "modulate", Color(2.2, 2.2, 2.2), half * 0.5)
	tween.tween_property(sprite, "modulate", Color(1.8, 0.45, 0.35), half * 0.5)
	tween.tween_property(sprite, "modulate", Color(1.6, 0.6, 0.5), half)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.08)
