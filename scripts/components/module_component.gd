class_name ModuleComponent
extends Node

signal module_equipped(module_id: String)
signal module_unequipped(module_id: String)
signal energy_changed(current: int, max_energy: int)
signal stats_updated()

@export var reactor_max_energy: int = 10
@export var reactor_current_energy: int = 6

var _equipped_modules: Dictionary = {}
var _current_energy_used: int = 0

func _ready() -> void:
	pass

func get_available_energy() -> int:
	return reactor_max_energy - _current_energy_used

func can_equip_module(module: ModuleData) -> bool:
	if module.id in _equipped_modules:
		return false
	return module.energy_cost <= get_available_energy()

func equip_module(module: ModuleData) -> bool:
	if not can_equip_module(module):
		return false
	
	_equipped_modules[module.id] = module
	_current_energy_used += module.energy_cost
	module_equipped.emit(module.id)
	stats_updated.emit()
	_update_energy_display()
	return true

func unequip_module(module_id: String) -> bool:
	if module_id not in _equipped_modules:
		return false
	
	var module = _equipped_modules[module_id] as ModuleData
	_current_energy_used -= module.energy_cost
	_equipped_modules.erase(module_id)
	module_unequipped.emit(module_id)
	stats_updated.emit()
	_update_energy_display()
	return true

func get_equipped_module(module_id: String) -> ModuleData:
	if module_id in _equipped_modules:
		return _equipped_modules[module_id] as ModuleData
	return null

func get_all_equipped_modules() -> Array:
	return _equipped_modules.values()

func get_total_stat_modifier(stat_name: String) -> float:
	var total: float = 0.0
	for module in _equipped_modules.values():
		var mod_data = module as ModuleData
		match stat_name:
			"speed":
				total += mod_data.speed_modifier
			"jump":
				total += mod_data.jump_modifier
			"dash_speed":
				total += mod_data.dash_speed_modifier
			"dash_cooldown":
				total += mod_data.dash_cooldown_modifier
			"damage":
				total += mod_data.damage_modifier
			"max_health":
				total += mod_data.max_health_modifier
	return total

func _update_energy_display() -> void:
	energy_changed.emit(reactor_max_energy - _current_energy_used, reactor_max_energy)

func get_energy_used() -> int:
	return _current_energy_used
