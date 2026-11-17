class_name IndustrialHazard
extends Area2D

@export var damage := 10
@export var push := 105.0
@export var active_time := 0.9
@export var rest_time := 1.4
var active := true
var timer := 0.0
var elapsed := 0.0
var victims: Dictionary = {}

func _ready() -> void:
	collision_layer = 0; collision_mask = 1
	var collision := CollisionShape2D.new(); var shape := RectangleShape2D.new()
	shape.size = Vector2(34, 58); collision.position = Vector2(0, -25); collision.shape = shape; add_child(collision)
	body_entered.connect(_on_body_entered)
	timer = active_time

func _process(delta: float) -> void:
	elapsed += delta; timer -= delta
	if timer <= 0.0:
		active = not active; timer = active_time if active else rest_time
		monitoring = active; queue_redraw()
	for body in victims.keys():
		victims[body] = maxf(0.0, victims[body] - delta)

func _on_body_entered(body: Node) -> void:
	if not active or not body is GuanditoPlayer or victims.get(body, 0.0) > 0.0: return
	victims[body] = 0.8
	body.health.take_damage(damage)
	body.velocity += Vector2(signf(body.global_position.x - global_position.x) * push, -75.0)

func _draw() -> void:
	draw_rect(Rect2(-18, -4, 36, 8), Color("#334246"))
	if not active: return
	for index in range(4):
		var y := -12.0 - fmod(elapsed * (32.0 + index * 5.0) + index * 13.0, 48.0)
		draw_circle(Vector2(-9.0 + index * 6.0, y), 5.0 + index, Color(0.55, 0.82, 0.72, 0.24))
