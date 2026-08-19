class_name HealthComponent
extends Node

signal health_changed(current: int, max_health: int)
signal died()

@export var max_health: int = 100
@export var current_health: int = 100
@export var invincibility_duration: float = 0.5

var _is_invincible: bool = false
var _invincibility_timer: float = 0.0

func _ready() -> void:
	current_health = max_health

func _process(delta: float) -> void:
	if _is_invincible:
		_invincibility_timer -= delta
		if _invincibility_timer <= 0:
			_is_invincible = false

func take_damage(amount: int, hitstop_time: float = 0.0) -> void:
	if _is_invincible or current_health <= 0:
		return
	
	current_health = max(0, current_health - amount)
	_is_invincible = true
	_invincibility_timer = invincibility_duration
	
	health_changed.emit(current_health, max_health)
	
	if current_health <= 0:
		died.emit()

func heal(amount: int) -> void:
	if current_health <= 0:
		return
	
	current_health = min(max_health, current_health + amount)
	health_changed.emit(current_health, max_health)

func is_alive() -> bool:
	return current_health > 0

func is_invincible() -> bool:
	return _is_invincible

func get_health_percent() -> float:
	if max_health == 0:
		return 0.0
	return float(current_health) / float(max_health)
