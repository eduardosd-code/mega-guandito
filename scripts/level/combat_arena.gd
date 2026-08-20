class_name CombatArena
extends Area2D
signal entered(arena: CombatArena)
signal cleared(arena: CombatArena)
@export var arena_id: StringName
@export var bounds := Rect2(-200,-120,400,240)
var active := false
func _ready() -> void:
	collision_layer = 0; collision_mask = 1; body_entered.connect(_on_body)
	var collision := CollisionShape2D.new(); var shape := RectangleShape2D.new(); shape.size = bounds.size; collision.position = bounds.get_center(); collision.shape = shape; add_child(collision)
func _on_body(body: Node) -> void:
	if body is GuanditoPlayer and not active: active = true; entered.emit(self)
func evaluate(enemies: Array[Node]) -> void:
	if active and enemies.is_empty(): active = false; cleared.emit(self)
