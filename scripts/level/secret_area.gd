class_name SecretArea
extends Area2D
signal discovered(secret: SecretArea)
@export var xp_reward := 35
var consumed := false
func _ready() -> void:
	collision_layer = 0; collision_mask = 1; body_entered.connect(_on_body)
	var collision := CollisionShape2D.new(); var shape := RectangleShape2D.new(); shape.size = Vector2(90, 80); collision.shape = shape; add_child(collision)
func _on_body(body: Node) -> void:
	if body is GuanditoPlayer and not consumed: consumed = true; body.add_xp(xp_reward); discovered.emit(self); queue_redraw()
func _draw() -> void:
	if not consumed: draw_circle(Vector2.ZERO, 7, Color("#75e830")); draw_arc(Vector2.ZERO, 13, 0, TAU, 16, Color(0.4,1,0.3,0.45), 2)
