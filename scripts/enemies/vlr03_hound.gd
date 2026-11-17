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

signal defeated
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
var pattern_index := 0
var attack_data: AttackData
var last_attack: StringName = &""
var stagger_damage := 0
var stagger_window_left := 0.0
var stagger_threshold := 110
var attack_token := 0

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
	if state in [&"dormant", &"dead"]: return
	if not is_on_floor(): velocity.y = minf(600.0, velocity.y + 900.0 * delta)
	stagger_window_left = maxf(0.0, stagger_window_left - delta)
	if stagger_window_left == 0.0: stagger_damage = 0
	if hitstun > 0.0:
		hitstun -= delta; velocity.x = move_toward(velocity.x, 0.0, 180.0 * delta)
		if hitstun <= 0.0 and state == &"stagger": state = &"idle"; cooldown = 0.8
		move_and_slide(); _update_visual(); return
	cooldown -= delta
	if is_instance_valid(player) and state not in [&"charge", &"leap", &"claw", &"burst"]: facing = signf(player.global_position.x - global_position.x)
	if cooldown <= 0.0 and state == &"idle":
		_choose_attack()
	if state == &"charge": velocity.x = facing * BALANCE.charge_speed
	move_and_slide(); _update_visual()

func _telegraph(duration: float, label: StringName) -> bool:
	state = label; velocity.x = 0.0; attack_token += 1; var token := attack_token; queue_redraw()
	await get_tree().create_timer(duration, false).timeout
	return state != &"dead" and token == attack_token

func _choose_attack() -> void:
	if not is_instance_valid(player): return
	var distance := absf(player.global_position.x - global_position.x)
	if distance > 230.0:
		if last_attack == &"charge": _burst()
		else: _charge()
	elif distance > 105.0:
		if last_attack == &"pounce": _burst()
		else: _leap_slam()
	else:
		if last_attack == &"claw": _reposition()
		else: _claw()

func _reposition() -> void:
	state = &"reposition"; velocity.x = -facing * BALANCE.move_speed
	await get_tree().create_timer(0.35, false).timeout
	if state != &"dead": velocity.x = 0.0; state = &"idle"; cooldown = 0.45

func _charge() -> void:
	if not await _telegraph(BALANCE.attack_1_startup, &"charge_warning"): return
	last_attack = &"charge"; state = &"charge"; audio_hook.emit(&"hound_charge", global_position)
	_set_attack(BALANCE.attack_1_damage, Vector2(280, -75), Vector2(55, 0), Vector2(78, 44)); hitbox.activate(attack_data, facing)
	_spawn_ground_fx(CHARGE_FX, -facing * 36.0)
	await get_tree().create_timer(0.7, false).timeout
	hitbox.deactivate(); if state == &"dead": return
	state = &"idle"; cooldown = BALANCE.attack_1_recovery

func _leap_slam() -> void:
	if not await _telegraph(BALANCE.attack_2_startup, &"leap_warning"): return
	last_attack = &"pounce"; state = &"leap"; var committed_facing := facing; velocity = Vector2(committed_facing * 125, -350)
	await get_tree().create_timer(0.62, false).timeout
	_set_attack(BALANCE.attack_2_damage, Vector2(180, -155), Vector2(0, 22), Vector2(112, 38)); hitbox.activate(attack_data, committed_facing)
	audio_hook.emit(&"hound_pounce", global_position)
	_spawn_ground_fx(POUNCE_FX)
	await get_tree().create_timer(0.18, false).timeout
	hitbox.deactivate(); if state == &"dead": return
	state = &"idle"; cooldown = BALANCE.attack_2_recovery

func _claw() -> void:
	if not await _telegraph(BALANCE.attack_3_startup, &"claw_warning"): return
	last_attack = &"claw"; state = &"claw"; _set_attack(BALANCE.attack_3_damage, Vector2(175, -45), Vector2(46, -4), Vector2(60, 42))
	for strike in range(2):
		if state == &"dead" or hitstun > 0.0: return
		hitbox.activate(attack_data, facing); _spawn_ground_fx(CLAW_FX, facing * 42.0); audio_hook.emit(&"enemy_attack", global_position)
		await get_tree().create_timer(0.1, false).timeout; hitbox.deactivate()
		if strike == 0: await get_tree().create_timer(0.16, false).timeout
	if state == &"dead": return
	state = &"recover"; await get_tree().create_timer(BALANCE.attack_3_recovery, false).timeout; state = &"idle"; cooldown = 0.75

func _burst() -> void:
	if not await _telegraph(0.8, &"burst_warning"): return
	last_attack = &"burst"; state = &"burst"
	_spawn_ground_fx(BURST_FX, facing * 46.0)
	var shot := EnemyProjectile.new(); get_parent().add_child(shot); shot.global_position = global_position + Vector2(facing * 34, -18)
	shot.setup(facing, BALANCE.projectile_speed, 25); shot.use_hound_visual(); audio_hook.emit(&"projectile_fire", global_position)
	if state == &"dead": return
	state = &"idle"; cooldown = 1.2

func _set_attack(damage: int, knockback: Vector2, offset: Vector2, size: Vector2) -> void:
	attack_data.damage = damage; attack_data.knockback = knockback; attack_data.hitstun = 0.32
	attack_data.hitbox_offset = offset; attack_data.hitbox_size = size

func _on_hit(data: AttackData, direction: float, attacker: Node) -> void:
	if state in [&"dead", &"dormant"]: return
	health.take_damage(data.damage); velocity += Vector2(data.knockback.x * direction * 0.42, data.knockback.y * 0.36)
	if health.current_health <= 0: return
	stagger_window_left = 1.4; stagger_damage += data.damage
	var super_armor := state == &"charge"
	if not super_armor: hitstun = minf(data.hitstun, 0.14)
	if stagger_damage >= stagger_threshold and not super_armor:
		state = &"stagger"; hitstun = 0.65; stagger_damage = 0; attack_token += 1; hitbox.deactivate()
	if attacker and attacker.has_method("apply_hitstop"): attacker.apply_hitstop(data.hitstop)
	queue_redraw()

func _on_died() -> void:
	state = &"dead"; attack_token += 1; hitbox.deactivate(); $Hurtbox.set_deferred("monitorable", false); _spawn_ground_fx(DESTROY_FX)
	audio_hook.emit(&"hound_destroy", global_position); _update_visual()
	await get_tree().create_timer(0.85, false).timeout
	if is_instance_valid(player): player.add_xp(BALANCE.xp_reward)
	defeated.emit(); queue_free()

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
