class_name TrainingBot
extends CharacterBody2D

enum State { IDLE, CHASE, ATTACK, HIT, AIRBORNE, RECOVER, DEAD }
@export var move_speed := 42.0
@export var detection_range := 210.0
@export var stop_distance := 42.0
@export var attack_cooldown := 1.25
@export var xp_reward := 55
@export var attack_data: AttackData
@onready var health: HealthComponent = $HealthComponent
@onready var hitbox: HitboxComponent = $AttackHitbox
@onready var player: GuanditoPlayer = get_tree().get_first_node_in_group("player")

var team: StringName = &"enemy"
var state := State.IDLE
var cooldown := 0.4
var hitstun := 0.0
var hitstop := 0.0
var facing := -1.0
var dead_left := 0.0
var recovery_left := 0.0
var flash_left := 0.0
var spawn_position := Vector2.ZERO

func _ready() -> void:
	add_to_group("enemies")
	spawn_position = global_position
	$Hurtbox.hit_received.connect(_on_hit)
	health.died.connect(_on_died)
	queue_redraw()

func _physics_process(delta: float) -> void:
	if hitstop > 0.0:
		hitstop -= delta
		return
	flash_left = maxf(0.0, flash_left - delta)
	modulate = Color("#fff2b2") if flash_left > 0.0 else Color.WHITE
	if not is_on_floor():
		velocity.y = minf(420.0, velocity.y + 850.0 * delta)
	if state == State.DEAD:
		dead_left -= delta
		velocity.x = move_toward(velocity.x, 0.0, 380.0 * delta)
		move_and_slide()
		if dead_left <= 0.0:
			_respawn()
		return
	if hitstun > 0.0:
		hitstun -= delta
		state = State.HIT
		velocity.x = move_toward(velocity.x, 0.0, 240.0 * delta)
		move_and_slide()
		return
	if state in [State.HIT, State.AIRBORNE]:
		if not is_on_floor():
			state = State.AIRBORNE
			move_and_slide()
			return
		state = State.RECOVER
		recovery_left = 0.16
	if state == State.RECOVER:
		recovery_left -= delta
		velocity.x = move_toward(velocity.x, 0.0, 360.0 * delta)
		move_and_slide()
		if recovery_left <= 0.0:
			state = State.IDLE
		return
	cooldown = maxf(0.0, cooldown - delta)
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
		return
	var distance := player.global_position.x - global_position.x
	facing = signf(distance) if distance != 0.0 else facing
	if absf(distance) > detection_range:
		state = State.IDLE
		velocity.x = move_toward(velocity.x, 0.0, 300.0 * delta)
	elif absf(distance) > stop_distance:
		state = State.CHASE
		velocity.x = move_toward(velocity.x, facing * move_speed, 260.0 * delta)
	elif cooldown <= 0.0:
		_attack()
	else:
		state = State.IDLE
		velocity.x = move_toward(velocity.x, 0.0, 400.0 * delta)
	move_and_slide()
	queue_redraw()

func _attack() -> void:
	state = State.ATTACK
	cooldown = attack_cooldown
	await get_tree().create_timer(attack_data.startup, false).timeout
	if state == State.ATTACK:
		hitbox.activate(attack_data, facing)
		await get_tree().create_timer(attack_data.active_time, false).timeout
		hitbox.deactivate()
	if state == State.ATTACK:
		await get_tree().create_timer(attack_data.recovery, false).timeout
		if state == State.ATTACK:
			state = State.IDLE

func _on_hit(data: AttackData, direction: float, attacker: Node) -> void:
	if state == State.DEAD:
		return
	health.take_damage(data.damage)
	velocity = Vector2(data.knockback.x * direction, data.knockback.y)
	hitstun = data.hitstun
	hitstop = data.hitstop
	flash_left = 0.1
	if attacker and attacker.has_method("apply_hitstop"):
		attacker.apply_hitstop(data.hitstop)
	queue_redraw()

func _on_died() -> void:
	state = State.DEAD
	dead_left = 3.0
	$Hurtbox.set_deferred("monitorable", false)
	if is_instance_valid(player):
		player.add_xp(xp_reward)
	queue_redraw()

func _respawn() -> void:
	health.current_health = health.max_health
	health.health_changed.emit(health.current_health, health.max_health)
	global_position = spawn_position
	$Hurtbox.monitorable = true
	state = State.IDLE
	queue_redraw()

func _draw() -> void:
	var dark := Color("#171d21")
	var steel := Color("#737f82")
	var warning := Color("#d68d32")
	var eye := Color("#ff533d")
	if state == State.DEAD:
		draw_rect(Rect2(-17, 10, 34, 9), dark)
		return
	draw_rect(Rect2(-13, -18, 26, 25), dark)
	draw_rect(Rect2(-10, -15, 20, 18), steel)
	draw_rect(Rect2(-8, -11, 16, 6), dark)
	draw_circle(Vector2(4 * facing, -8), 2.2, eye)
	draw_circle(Vector2.ZERO, 5, warning)
	draw_line(Vector2(-8, 5), Vector2(-10, 17), dark, 6)
	draw_line(Vector2(8, 5), Vector2(10, 17), dark, 6)
	draw_rect(Rect2(-15, 15, 11, 5), steel)
	draw_rect(Rect2(4, 15, 11, 5), steel)
	draw_line(Vector2(12 * facing, -5), Vector2(19 * facing, 2), warning, 5)
