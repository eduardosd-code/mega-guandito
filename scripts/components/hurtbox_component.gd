class_name HurtboxComponent
extends Area2D

signal hit_received(attack_data: Dictionary, hit_direction: Vector2)

var _is_invincible: bool = false
var _hitstop_handler: Callable

func _ready() -> void:
	monitorable = true
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func set_invincible(invincible: bool) -> void:
	_is_invincible = invincible

func is_invincible() -> bool:
	return _is_invincible

func _on_body_entered(body: Node) -> void:
	pass

func _on_area_entered(area: Area2D) -> void:
	if _is_invincible:
		return
	
	if area is HitboxComponent:
		var hitbox = area as HitboxComponent
		if hitbox.is_active() and not hitbox.has_hit():
			hitbox._has_hit = true
			
			var attack_data = hitbox.get_attack_data()
			var hit_direction = (global_position - area.global_position).normalized()
			if hit_direction == Vector2.ZERO:
				hit_direction = Vector2.RIGHT
			
			hit_received.emit(attack_data, hit_direction)
