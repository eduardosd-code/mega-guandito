class_name HitboxComponent
extends Area2D

var attack_data: AttackData
var direction: float = 1.0
var _already_hit: Dictionary = {}

func _ready() -> void:
	monitoring = false
	visible = false
	add_to_group("debug_shapes")
	area_entered.connect(_on_area_entered)

func activate(data: AttackData, facing: float) -> void:
	attack_data = data
	direction = facing
	_already_hit.clear()
	position = Vector2(data.hitbox_offset.x * facing, data.hitbox_offset.y)
	($CollisionShape2D.shape as RectangleShape2D).size = data.hitbox_size
	monitoring = true
	var manager := get_tree().get_first_node_in_group("game_manager")
	visible = manager.debug_shapes if manager else false
	queue_redraw()
	await get_tree().physics_frame
	for area in get_overlapping_areas():
		_try_hit(area)

func deactivate() -> void:
	monitoring = false
	visible = false

func _draw() -> void:
	if not attack_data:
		return
	var rect := Rect2(-attack_data.hitbox_size * 0.5, attack_data.hitbox_size)
	draw_rect(rect, Color(0.2, 1.0, 0.25, 0.3), true)
	draw_rect(rect, Color(0.45, 1.0, 0.5, 0.95), false, 1.0)

func _on_area_entered(area: Area2D) -> void:
	_try_hit(area)

func _try_hit(area: Area2D) -> void:
	if not monitoring or not attack_data or not area.has_method("receive_hit"):
		return
	var id := area.get_instance_id()
	if _already_hit.has(id):
		return
	_already_hit[id] = true
	area.receive_hit(attack_data, direction, get_parent())
	var attacker := get_parent()
	if attacker and attacker.has_method("on_attack_connected"):
		attacker.on_attack_connected(attack_data, area.global_position)
