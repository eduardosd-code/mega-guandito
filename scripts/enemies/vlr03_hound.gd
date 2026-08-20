class_name VLR03Hound
extends CharacterBody2D

const EnemySprites := preload("res://scripts/enemies/sector07_enemy_sprite_library.gd")

signal defeated
@export var max_health := 420
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

func _ready() -> void:
	add_to_group("boss")
	player = get_tree().get_first_node_in_group("player")
	health.max_health = max_health; health.current_health = max_health
	$Hurtbox.hit_received.connect(_on_hit); health.died.connect(_on_died)
	attack_data = AttackData.new(); attack_data.hitstop = 0.06
	sprite.sprite_frames = EnemySprites.build(&"hound"); _update_visual()

func _update_visual() -> void:
	var animation: StringName = &"idle"
	if state == &"dead": animation = &"death"
	elif hitstun > 0.0: animation = &"hit"
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
	if hitstun > 0.0:
		hitstun -= delta; velocity.x = move_toward(velocity.x, 0.0, 180.0 * delta); move_and_slide(); _update_visual(); return
	cooldown -= delta
	if is_instance_valid(player): facing = signf(player.global_position.x - global_position.x)
	if cooldown <= 0.0 and state == &"idle":
		pattern_index = (pattern_index + 1) % 4
		match pattern_index:
			0: _charge()
			1: _leap_slam()
			2: _claw()
			3: _burst()
	if state == &"charge": velocity.x = facing * 225.0
	move_and_slide(); _update_visual()

func _telegraph(duration: float, label: StringName) -> bool:
	state = label; velocity.x = 0.0; queue_redraw()
	await get_tree().create_timer(duration, false).timeout
	return state != &"dead"

func _charge() -> void:
	if not await _telegraph(0.65, &"charge_warning"): return
	state = &"charge"; _set_attack(24, Vector2(260, -70), Vector2(55, 0), Vector2(75, 42)); hitbox.activate(attack_data, facing)
	await get_tree().create_timer(0.7, false).timeout
	hitbox.deactivate(); if state == &"dead": return
	state = &"idle"; cooldown = 1.0

func _leap_slam() -> void:
	if not await _telegraph(0.75, &"leap_warning"): return
	state = &"leap"; velocity = Vector2(facing * 90, -330)
	await get_tree().create_timer(0.62, false).timeout
	_set_attack(28, Vector2(170, -150), Vector2(0, 22), Vector2(110, 36)); hitbox.activate(attack_data, facing)
	await get_tree().create_timer(0.18, false).timeout
	hitbox.deactivate(); if state == &"dead": return
	state = &"idle"; cooldown = 1.15

func _claw() -> void:
	if not await _telegraph(0.36, &"claw_warning"): return
	state = &"claw"; _set_attack(18, Vector2(190, -55), Vector2(46, -4), Vector2(58, 42)); hitbox.activate(attack_data, facing)
	await get_tree().create_timer(0.18, false).timeout
	hitbox.deactivate(); if state == &"dead": return
	state = &"idle"; cooldown = 0.85

func _burst() -> void:
	if not await _telegraph(0.8, &"burst_warning"): return
	state = &"burst"
	for angle_index in range(-2, 3):
		var shot := EnemyProjectile.new(); get_parent().add_child(shot)
		shot.global_position = global_position + Vector2(facing * 26, -18 + angle_index * 4)
		shot.setup(facing, 135.0 + abs(angle_index) * 10, 12)
	if state == &"dead": return
	state = &"idle"; cooldown = 1.35

func _set_attack(damage: int, knockback: Vector2, offset: Vector2, size: Vector2) -> void:
	attack_data.damage = damage; attack_data.knockback = knockback; attack_data.hitstun = 0.32
	attack_data.hitbox_offset = offset; attack_data.hitbox_size = size

func _on_hit(data: AttackData, direction: float, attacker: Node) -> void:
	if state in [&"dead", &"dormant"]: return
	health.take_damage(data.damage); velocity += Vector2(data.knockback.x * direction * 0.32, data.knockback.y * 0.28)
	hitstun = minf(data.hitstun, 0.12)
	if attacker and attacker.has_method("apply_hitstop"): attacker.apply_hitstop(data.hitstop)
	queue_redraw()

func _on_died() -> void:
	state = &"dead"; hitbox.deactivate(); $Hurtbox.set_deferred("monitorable", false); defeated.emit(); _update_visual()

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
