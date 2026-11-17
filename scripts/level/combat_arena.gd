class_name CombatArena
extends Area2D
signal entered(arena: CombatArena)
signal cleared(arena: CombatArena)
@export var arena_id: StringName
@export var bounds := Rect2(-200,-120,400,240)
var active := false
var completed := false
var tracked_enemies: Array[Node] = []
var doors: Array[DoorTransition] = []
func _ready() -> void:
	collision_layer = 0; collision_mask = 1; body_entered.connect(_on_body)
	var collision := CollisionShape2D.new(); var shape := RectangleShape2D.new(); shape.size = bounds.size; collision.position = bounds.get_center(); collision.shape = shape; add_child(collision)
func _on_body(body: Node) -> void:
	if body is GuanditoPlayer and not active and not completed:
		active = true
		for door in doors: door.close()
		entered.emit(self)
func configure(enemies: Array[Node], arena_doors: Array[DoorTransition]) -> void:
	tracked_enemies = enemies
	doors = arena_doors
	for enemy in tracked_enemies:
		if enemy.has_signal("defeated") and not enemy.defeated.is_connected(_on_enemy_defeated):
			enemy.defeated.connect(_on_enemy_defeated.unbind(1))
func _on_enemy_defeated() -> void:
	call_deferred("_evaluate_tracked")
func _evaluate_tracked() -> void:
	tracked_enemies = tracked_enemies.filter(func(enemy): return is_instance_valid(enemy) and not enemy.is_queued_for_deletion() and enemy.get("state") != &"dead")
	evaluate(tracked_enemies)
func evaluate(enemies: Array[Node]) -> void:
	if active and enemies.is_empty():
		active = false; completed = true
		for door in doors: door.open()
		cleared.emit(self)
func reset(new_enemies: Array[Node]) -> void:
	active = false; completed = false
	configure(new_enemies, doors)
	for door in doors: door.open()
