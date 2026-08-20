class_name HurtboxComponent
extends Area2D

signal hit_received(data: AttackData, direction: float, attacker: Node)
@export var team: StringName = &"neutral"

func _ready() -> void:
	add_to_group("debug_shapes")
	visible = false

func receive_hit(data: AttackData, direction: float, attacker: Node) -> void:
	if attacker and attacker.get("team") == team:
		return
	hit_received.emit(data, direction, attacker)

func _draw() -> void:
	var shape := $CollisionShape2D.shape as RectangleShape2D
	var rect := Rect2(-shape.size * 0.5, shape.size)
	var color := Color(0.2, 0.65, 1.0, 0.3) if team == &"player" else Color(1.0, 0.45, 0.15, 0.3)
	draw_rect(rect, color, true)
	draw_rect(rect, Color(color, 0.95), false, 1.0)
