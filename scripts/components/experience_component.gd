class_name ExperienceComponent
extends Node

signal xp_changed(current: int, required: int)
signal level_up(new_level: int)
signal max_level_reached()

@export var base_xp_required: int = 100
@export var xp_growth_rate: float = 1.5
@export var max_level: int = 5

var current_xp: int = 0
var current_level: int = 1
var xp_required_for_next_level: int = 100

func _ready() -> void:
	_update_xp_required()

func add_xp(amount: int) -> void:
	if current_level >= max_level:
		max_level_reached.emit()
		return
	
	current_xp += amount
	
	while current_xp >= xp_required_for_next_level and current_level < max_level:
		current_xp -= xp_required_for_next_level
		current_level += 1
		_update_xp_required()
		level_up.emit(current_level)
		
		if current_level >= max_level:
			max_level_reached.emit()
			break
	
	xp_changed.emit(current_xp, xp_required_for_next_level)

func _update_xp_required() -> void:
	xp_required_for_next_level = int(base_xp_required * pow(xp_growth_rate, current_level - 1))

func get_level() -> int:
	return current_level

func get_xp_percent() -> float:
	if xp_required_for_next_level == 0:
		return 1.0
	return float(current_xp) / float(xp_required_for_next_level)

func is_max_level() -> bool:
	return current_level >= max_level
