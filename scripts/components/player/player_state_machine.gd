class_name PlayerStateMachine
extends Node

signal state_changed(current: StringName, previous: StringName)
var current: StringName = &"idle"

func change(next: StringName) -> void:
	if next == current:
		return
	var previous := current
	current = next
	state_changed.emit(current, previous)

func is_state(value: StringName) -> bool:
	return current == value

