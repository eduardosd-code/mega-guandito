class_name SectorEnemy
extends CharacterBody2D

const EnemySprites := preload("res://scripts/enemies/sector07_enemy_sprite_library.gd")

signal defeated(enemy: SectorEnemy)
enum Role { SCRAPPER, BULWARK, SENTRY }

@export var role := Role.SCRAPPER
@export var patrol_radius := 100.0
@onready var health: HealthComponent = $HealthComponent
@onready var hitbox: HitboxComponent = $AttackHitbox
@onready var sprite: AnimatedSprite2D = $Sprite
var team: StringName = &"enemy"
var player: GuanditoPlayer
var spawn_position := Vector2.ZERO
var facing := -1.0
var state: StringName = &"idle"
var cooldown := 0.5
var hitstun := 0.0
var vulnerable_left := 0.0
var attack_data: AttackData

func _ready() -> void:
	add_to_group("enemies")
	add_to_group("sector_enemies")
	spawn_position = global_position
	player = get_tree().get_first_node_in_group("player")
	$Hurtbox.hit_received.connect(_on_hit)
	health.died.connect(_on_died)
	_configure_role()
	_configure_visual()

func _configure_role() -> void:
	attack_data = AttackData.new()
	attack_data.hitstop = 0.035
	match role:
		Role.SCRAPPER:
			health.max_health = 45; health.current_health = 45
			attack_data.damage = 10; attack_data.knockback = Vector2(120, -45); attack_data.hitstun = 0.2
		Role.BULWARK:
			health.max_health = 125; health.current_health = 125
			attack_data.damage = 22; attack_data.knockback = Vector2(220, -80); attack_data.hitstun = 0.32
		Role.SENTRY:
			health.max_health = 32; health.current_health = 32

func _configure_visual() -> void:
	var visual_role: StringName = [&"scrapper", &"bulwark", &"sentry"][role]
	sprite.sprite_frames = EnemySprites.build(visual_role)
	sprite.position = Vector2(0, -22 if role == Role.SENTRY else (-48 if role == Role.BULWARK else -32))
	_update_visual()

func _update_visual() -> void:
	if not is_instance_valid(sprite) or sprite.sprite_frames == null: return
	var animation: StringName = &"idle"
	if state == &"dead": animation = &"death"
	elif state == &"hit": animation = &"hit"
	elif role == Role.SENTRY: animation = &"pulse_shot" if state in [&"telegraph", &"attack"] else (&"move" if absf(velocity.x) > 2.0 else &"hover_idle")
	elif role == Role.BULWARK: animation = &"attack_hammer_fist" if state in [&"telegraph", &"attack"] else (&"walk" if absf(velocity.x) > 2.0 else &"idle")
	else: animation = &"attack_1" if state in [&"telegraph", &"attack"] else (&"run" if absf(velocity.x) > 2.0 else &"idle")
	if sprite.animation != animation: sprite.play(animation)
	sprite.flip_h = facing < 0.0

func _physics_process(delta: float) -> void:
	if state == &"dead": return
	if not is_on_floor(): velocity.y = minf(500.0, velocity.y + 850.0 * delta)
	cooldown = maxf(0.0, cooldown - delta)
	vulnerable_left = maxf(0.0, vulnerable_left - delta)
	if hitstun > 0.0:
		hitstun -= delta; state = &"hit"; velocity.x = move_toward(velocity.x, 0.0, 260.0 * delta); move_and_slide(); _update_visual(); return
	if not is_instance_valid(player): return
	var dx := player.global_position.x - global_position.x
	facing = signf(dx) if dx != 0.0 else facing
	var engage := 300.0 if role == Role.SENTRY else 190.0
	if absf(dx) > engage:
		state = &"idle"; velocity.x = move_toward(velocity.x, 0.0, 250.0 * delta)
	elif role == Role.SENTRY:
		velocity.x = move_toward(velocity.x, 0.0, 300.0 * delta)
		if cooldown <= 0.0: _shoot()
	elif absf(dx) > (54.0 if role == Role.BULWARK else 38.0):
		state = &"chase"
		var speed := 30.0 if role == Role.BULWARK else 68.0
		velocity.x = move_toward(velocity.x, facing * speed, 300.0 * delta)
	elif cooldown <= 0.0:
		_melee_attack()
	else:
		velocity.x = move_toward(velocity.x, 0.0, 400.0 * delta)
	move_and_slide(); _update_visual()

func _melee_attack() -> void:
	state = &"telegraph"; cooldown = 1.5 if role == Role.BULWARK else 0.9; velocity.x = 0.0
	await get_tree().create_timer(0.42 if role == Role.BULWARK else 0.16, false).timeout
	if state == &"dead" or hitstun > 0.0: return
	state = &"attack"; hitbox.activate(attack_data, facing)
	await get_tree().create_timer(0.12, false).timeout
	hitbox.deactivate()
	if state == &"dead": return
	vulnerable_left = 0.65 if role == Role.BULWARK else 0.15; state = &"recover"
	_update_visual()

func _shoot() -> void:
	state = &"telegraph"; cooldown = 1.45
	await get_tree().create_timer(0.38, false).timeout
	if state == &"dead" or hitstun > 0.0: return
	var shot := EnemyProjectile.new()
	get_parent().add_child(shot); shot.global_position = global_position + Vector2(facing * 18, -8)
	shot.setup(facing, 155.0, 9); state = &"recover"; _update_visual()

func _on_hit(data: AttackData, direction: float, attacker: Node) -> void:
	if state == &"dead": return
	var amount := data.damage
	if role == Role.BULWARK and vulnerable_left <= 0.0 and data.damage < 25:
		amount = 3
	health.take_damage(amount)
	velocity = Vector2(data.knockback.x * direction, data.knockback.y)
	hitstun = data.hitstun
	if attacker and attacker.has_method("apply_hitstop"): attacker.apply_hitstop(data.hitstop)
	_update_visual()

func _on_died() -> void:
	state = &"dead"; $Hurtbox.set_deferred("monitorable", false); hitbox.deactivate()
	if is_instance_valid(player): player.add_xp(20 if role == Role.SCRAPPER else (45 if role == Role.BULWARK else 25))
	defeated.emit(self); _update_visual()
	await get_tree().create_timer(0.45, false).timeout
	queue_free()

func _draw() -> void:
	if is_instance_valid(sprite) and sprite.sprite_frames != null: return
	if state == &"dead": draw_rect(Rect2(-16, 10, 32, 7), Color("#202527")); return
	var dark := Color("#161c1f"); var steel := Color("#697477"); var amber := Color("#e67532")
	var scale_size := 1.35 if role == Role.BULWARK else 1.0
	draw_rect(Rect2(-13 * scale_size, -17 * scale_size, 26 * scale_size, 27 * scale_size), dark)
	draw_rect(Rect2(-10 * scale_size, -14 * scale_size, 20 * scale_size, 18 * scale_size), steel)
	draw_rect(Rect2(-8, -10, 16, 5), dark); draw_circle(Vector2(4 * facing, -8), 2.2, Color("#ff4938"))
	draw_circle(Vector2.ZERO, 4.5, amber)
	if role == Role.SENTRY:
		draw_rect(Rect2(-18, -6, 36, 14), dark); draw_circle(Vector2(15 * facing, 0), 5, amber)
	elif role == Role.BULWARK:
		draw_rect(Rect2(10 * facing, -13, 12 * facing, 25), Color("#3d494b"))
	if state == &"telegraph": draw_arc(Vector2.ZERO, 22, 0, TAU, 18, Color("#ff7838"), 2)
