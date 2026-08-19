class_name PlayerStateMachine
extends Node

signal state_changed(new_state: String, old_state: String)

@export var initial_state: String = "idle"

var _states: Dictionary = {}
var _current_state: PlayerState = null
var _previous_state_name: String = ""
var _current_state_name: String = ""

var owner_node: Node = null

func _ready() -> void:
	owner_node = get_parent()
	await get_tree().process_frame
	initialize_states()
	change_state(initial_state)

func initialize_states() -> void:
	pass

func add_state(state_name: String, state: PlayerState) -> void:
	state.state_name = state_name
	_states[state_name] = state

func get_state(state_name: String) -> PlayerState:
	if state_name in _states:
		return _states[state_name]
	return null

func change_state(new_state_name: String) -> void:
	if new_state_name not in _states:
		push_warning("PlayerStateMachine: State '%s' does not exist" % new_state_name)
		return
	
	if _current_state != null:
		_current_state.exit(new_state_name)
	
	_previous_state_name = _current_state_name
	_current_state = _states[new_state_name]
	_current_state_name = new_state_name
	
	_current_state.enter(_previous_state_name)
	state_changed.emit(_current_state_name, _previous_state_name)

func update(delta: float) -> void:
	if _current_state != null:
		_current_state.update(delta)

func physics_update(delta: float) -> void:
	if _current_state != null:
		_current_state.physics_update(delta)

func handle_input(event: InputEvent) -> void:
	if _current_state != null:
		_current_state.handle_input(event)

func get_current_state_name() -> String:
	return _current_state_name

func get_previous_state_name() -> String:
	return _previous_state_name

func is_in_state(state_name: String) -> bool:
	return _current_state_name == state_name

func is_in_any_state(states: Array) -> bool:
	for state in states:
		if _current_state_name == state:
			return true
	return false
