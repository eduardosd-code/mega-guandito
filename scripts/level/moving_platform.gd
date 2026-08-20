class_name MovingPlatform
extends AnimatableBody2D
@export var travel := Vector2(100, 0)
@export var cycle_duration := 2.4
var origin := Vector2.ZERO
var elapsed := 0.0
func _ready() -> void: origin = position; collision_layer = 16; collision_mask = 0
func _physics_process(delta: float) -> void:
	elapsed += delta
	var t := (sin(elapsed * TAU / cycle_duration - PI * 0.5) + 1.0) * 0.5
	position = origin + travel * t
func _draw() -> void:
	draw_rect(Rect2(-38,-6,76,12),Color("#323e40")); draw_rect(Rect2(-34,-4,68,4),Color("#68766e")); draw_circle(Vector2.ZERO,3,Color("#80df35"))
