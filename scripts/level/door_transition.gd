class_name DoorTransition
extends StaticBody2D
var opened := false
func _ready() -> void:
	collision_layer = 16; collision_mask = 0
func open() -> void:
	opened = true; $CollisionShape2D.set_deferred("disabled", true); queue_redraw()
func close() -> void:
	opened = false; $CollisionShape2D.set_deferred("disabled", false); queue_redraw()
func _draw() -> void:
	if opened: return
	draw_rect(Rect2(-12,-74,24,148),Color("#20292c")); draw_rect(Rect2(-8,-68,16,136),Color("#465052")); draw_line(Vector2(-8,0),Vector2(8,0),Color("#e26f32"),3)
