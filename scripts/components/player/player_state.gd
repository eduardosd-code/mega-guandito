class_name PlayerState
extends RefCounted

var state_name: String = ""

func enter(previous_state: String) -> void:
	pass

func exit(next_state: String) -> void:
	pass

func update(delta: float) -> void:
	pass

func physics_update(delta: float) -> void:
	pass

func handle_input(event: InputEvent) -> void:
	pass

func get_state_name() -> String:
	return state_name
