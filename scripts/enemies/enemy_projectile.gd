class_name EnemyProjectile
extends Area2D

var velocity := Vector2.ZERO
var damage_data: AttackData
var lifetime := 3.0

func setup(direction: float, speed: float, damage: int) -> void:
	velocity = Vector2(direction * speed, 0.0)
	damage_data = AttackData.new()
	damage_data.damage = damage
	damage_data.knockback = Vector2(115, -35)
	damage_data.hitstun = 0.2
	damage_data.hitstop = 0.025

func _ready() -> void:
	collision_layer = 8
	collision_mask = 1
	area_entered.connect(_on_area_entered)
	var shape_node := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 4.0
	shape_node.shape = shape
	add_child(shape_node)

func _physics_process(delta: float) -> void:
	position += velocity * delta
	lifetime -= delta
	queue_redraw()
	if lifetime <= 0.0:
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area.has_method("receive_hit"):
		area.receive_hit(damage_data, signf(velocity.x), self)
		queue_free()

func _draw() -> void:
	draw_circle(Vector2.ZERO, 5, Color("#ff8a35"))
	draw_circle(Vector2.ZERO, 2, Color("#fff1a0"))
	draw_line(Vector2(-signf(velocity.x) * 5, 0), Vector2(-signf(velocity.x) * 14, 0), Color(1, 0.4, 0.1, 0.5), 3)
