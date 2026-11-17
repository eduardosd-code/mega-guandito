class_name SpikeStrip
extends Area2D
# Floor spikes: heavy damage and a pop upward. Placed under platforms so the
# safe route uses the Zero kit (platforms, air dash).

@export var width := 96.0
@export var damage := 30
@export var bounce := -300.0
var cooldowns: Dictionary = {}

func _ready() -> void:
	collision_layer = 0; collision_mask = 1; z_index = 3
	var collision := CollisionShape2D.new(); var shape := RectangleShape2D.new()
	shape.size = Vector2(width, 10); collision.shape = shape; collision.position = Vector2(width * 0.5, -5); add_child(collision)
	body_entered.connect(_hurt)

func _process(delta: float) -> void:
	for body in cooldowns.keys():
		cooldowns[body] = maxf(0.0, cooldowns[body] - delta)
		if cooldowns[body] == 0.0 and overlaps_body(body): _hurt(body)

func _hurt(body: Node) -> void:
	if not body is GuanditoPlayer or cooldowns.get(body, 0.0) > 0.0: return
	if body.health.current_health <= 0: return
	cooldowns[body] = 0.9
	body.health.take_damage(damage)
	body.velocity.y = bounce
	var manager := get_tree().get_first_node_in_group("game_manager")
	if manager: manager.screen_shake(3.0, 0.15)

func _draw() -> void:
	draw_rect(Rect2(0, -3, width, 3), Color("#3a2a28"))
	for x in range(0, int(width), 8):
		draw_colored_polygon(PackedVector2Array([Vector2(x, 0), Vector2(x + 4, -10), Vector2(x + 8, 0)]), Color("#c8483a"))
		draw_line(Vector2(x + 4, -10), Vector2(x + 4, -6), Color("#f0d2a0"), 1.0)
