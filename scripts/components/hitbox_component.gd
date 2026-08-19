class_name HitboxComponent
extends Area2D

@export var damage: int = 10
@export var knockback_vector: Vector2 = Vector2.RIGHT * 200
@export var hitstun_duration: float = 0.3
@export var attacker_hitstop: float = 0.05
@export var defender_hitstop: float = 0.1
@export var is_launcher: bool = false
@export var launch_force: float = 0.0

var _is_active: bool = false
var _has_hit: bool = false

func _ready() -> void:
	monitoring = false
	monitorable = true

func activate() -> void:
	_is_active = true
	_has_hit = false
	monitoring = true

func deactivate() -> void:
	_is_active = false
	monitoring = false

func reset_hit() -> void:
	_has_hit = false

func is_active() -> bool:
	return _is_active

func has_hit() -> bool:
	return _has_hit

func get_attack_data() -> Dictionary:
	return {
		"damage": damage,
		"knockback_vector": knockback_vector,
		"hitstun_duration": hitstun_duration,
		"attacker_hitstop": attacker_hitstop,
		"defender_hitstop": defender_hitstop,
		"is_launcher": is_launcher,
		"launch_force": launch_force
	}
