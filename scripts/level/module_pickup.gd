class_name ModulePickup
extends Area2D
signal collected
var collected_once := false
func _ready() -> void:
	collision_layer = 0; collision_mask = 1; body_entered.connect(_on_body)
	var collision := CollisionShape2D.new(); var shape := CircleShape2D.new(); shape.radius = 18; collision.shape = shape; add_child(collision)
func _on_body(body: Node) -> void:
	if body is GuanditoPlayer and not collected_once: collected_once = true; body.unlock_evasion_module(true); collected.emit(); visible = false; set_deferred("monitoring", false)
func _draw() -> void:
	draw_rect(Rect2(-12,-16,24,32),Color("#1b2724")); draw_rect(Rect2(-8,-12,16,24),Color("#527c2a")); draw_circle(Vector2.ZERO,5,Color("#9aff38"))
