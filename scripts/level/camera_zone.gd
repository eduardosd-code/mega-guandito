class_name CameraZone
extends Area2D
@export var zoom := Vector2.ONE
func _ready() -> void:
	collision_layer = 0; collision_mask = 1; body_entered.connect(_on_body)
func _on_body(body: Node) -> void:
	if body is GuanditoPlayer:
		var camera := body.get_node("Camera2D") as Camera2D
		create_tween().tween_property(camera,"zoom",zoom,0.45)
