class_name ModuleComponent
extends Node

signal modules_changed
signal energy_changed(used: int, maximum: int)

@export var reactor_capacity: int = 10
var equipped: Dictionary = {}

func equip(module: ModuleData) -> bool:
	if not module or equipped.has(module.id) or energy_used() + module.energy_cost > reactor_capacity:
		return false
	equipped[module.id] = module
	modules_changed.emit()
	energy_changed.emit(energy_used(), reactor_capacity)
	return true

func unequip(module_id: StringName) -> bool:
	if not equipped.has(module_id):
		return false
	equipped.erase(module_id)
	modules_changed.emit()
	energy_changed.emit(energy_used(), reactor_capacity)
	return true

func toggle(module: ModuleData) -> bool:
	return unequip(module.id) if equipped.has(module.id) else equip(module)

func energy_used() -> int:
	var total := 0
	for value in equipped.values():
		var module := value as ModuleData
		total += module.energy_cost
	return total

func modifier(stat_name: StringName) -> float:
	var total := 0.0
	for value in equipped.values():
		var module := value as ModuleData
		total += float(module.stat_modifiers.get(stat_name, 0.0))
	return total

func has_effect(effect_id: StringName) -> bool:
	for value in equipped.values():
		var module := value as ModuleData
		if module.special_effect_id == effect_id:
			return true
	return false
