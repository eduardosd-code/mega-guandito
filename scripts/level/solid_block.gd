class_name SolidBlock
extends StaticBody2D
# Self-drawing world geometry (walls, chimneys) that stays visible even when the
# environment art pass hides Sector07's debug _draw().

@export var size := Vector2(32, 128)
@export var body_color := Color("#1d282c")
@export var edge_color := Color("#8a9b75")

func _ready() -> void:
	collision_layer = 16; collision_mask = 0; z_index = 2
	var collision := CollisionShape2D.new(); var shape := RectangleShape2D.new()
	shape.size = size; collision.shape = shape; collision.position = size * 0.5; add_child(collision)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), body_color)
	draw_rect(Rect2(Vector2.ZERO, size), edge_color, false, 2.0)
	# Wall-jump grip marks so climbable faces read at a glance.
	for y in range(10, int(size.y) - 6, 14):
		draw_line(Vector2(2, y), Vector2(7, y + 5), Color("#5d7c3a"), 2.0)
		draw_line(Vector2(size.x - 2, y), Vector2(size.x - 7, y + 5), Color("#5d7c3a"), 2.0)
