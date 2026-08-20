class_name DialogueTrigger
extends Area2D
signal triggered(message: String)
@export_multiline var message := ""
@export var once := true
var consumed := false
func _ready() -> void:
	collision_layer = 0; collision_mask = 1; body_entered.connect(_on_body)
	var collision := CollisionShape2D.new(); var shape := RectangleShape2D.new(); shape.size = Vector2(150, 120); collision.shape = shape; add_child(collision)
func _on_body(body: Node) -> void:
	if body is GuanditoPlayer and not consumed: consumed = once; triggered.emit(message)
