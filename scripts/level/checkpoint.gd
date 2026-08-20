class_name Checkpoint
extends Area2D
signal activated(checkpoint: Checkpoint)
@export var checkpoint_id: StringName
var active := false
func _ready() -> void:
	collision_layer = 0; collision_mask = 1; body_entered.connect(_on_body)
	var collision := CollisionShape2D.new(); var shape := RectangleShape2D.new(); shape.size = Vector2(26, 58); collision.shape = shape; add_child(collision)
func _on_body(body: Node) -> void:
	if not active and body is GuanditoPlayer: active = true; activated.emit(self); queue_redraw()
func _draw() -> void:
	draw_rect(Rect2(-8, -28, 16, 50), Color("#172024")); draw_circle(Vector2(0, -17), 6, Color("#75e830") if active else Color("#8a562b")); draw_line(Vector2(0,-10),Vector2(0,17),Color("#657477"),3)
