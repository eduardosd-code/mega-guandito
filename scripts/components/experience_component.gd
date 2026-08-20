class_name ExperienceComponent
extends Node

signal experience_changed(current: int, required: int)
signal level_changed(level: int)

@export var current_level: int = 1
@export var max_level: int = 5
@export var base_xp_required: int = 100
@export var xp_growth: float = 1.45
var current_xp: int = 0

func _ready() -> void:
	_emit_all()

func add_xp(amount: int) -> void:
	if current_level >= max_level:
		return
	current_xp += maxi(0, amount)
	while current_level < max_level and current_xp >= xp_for_next_level():
		current_xp -= xp_for_next_level()
		current_level += 1
		level_changed.emit(current_level)
	if current_level >= max_level:
		current_xp = 0
	_emit_all()

func xp_for_next_level() -> int:
	return int(round(base_xp_required * pow(xp_growth, current_level - 1)))

func _emit_all() -> void:
	experience_changed.emit(current_xp, xp_for_next_level())
	level_changed.emit(current_level)

