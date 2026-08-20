class_name ElevatorTransition
extends Area2D
signal used
@export var destination_offset := Vector2(220, -80)
var busy := false
func _ready() -> void:
	collision_layer = 0; collision_mask = 1; body_entered.connect(_on_body)
	if get_child_count() == 0:
		var collision := CollisionShape2D.new(); var shape := RectangleShape2D.new(); shape.size = Vector2(80,50); collision.shape = shape; add_child(collision)
func _on_body(body: Node) -> void:
	if body is GuanditoPlayer and not busy:
		busy = true; body.set_physics_process(false)
		var tween := create_tween(); tween.tween_property(body,"global_position",body.global_position+destination_offset,0.9).set_trans(Tween.TRANS_SINE)
		await tween.finished; body.set_physics_process(true); busy = false; used.emit()
func _draw() -> void:
	draw_rect(Rect2(-42,18,84,10),Color("#3c4848")); draw_rect(Rect2(-36,18,72,3),Color("#8ac43d")); draw_line(Vector2(-38,-28),Vector2(-38,18),Color("#576462"),3); draw_line(Vector2(38,-28),Vector2(38,18),Color("#576462"),3)
