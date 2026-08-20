class_name GameManager
extends Node

const IMPACT_FX := preload("res://scripts/effects/impact_fx.gd")
const ACTION_FX := {
	"light": preload("res://scenes/effects/impact_light_fx.tscn"),
	"kinetic": preload("res://scenes/effects/kinetic_pulse_fx.tscn"),
	"heavy": preload("res://scenes/effects/heavy_impact_fx.tscn"),
	"dash_trail": preload("res://scenes/effects/dash_trail_fx.tscn"),
	"dodge_trail": preload("res://scenes/effects/dodge_trail_fx.tscn"),
	"exposed": preload("res://scenes/effects/exposed_fx.tscn"),
	"module_install": preload("res://scenes/effects/module_install_fx.tscn")
}
var debug_shapes := false
var debug_hud_visible := true

func _ready() -> void:
	add_to_group("game_manager")
	process_mode = Node.PROCESS_MODE_ALWAYS

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		get_tree().paused = not get_tree().paused
		return
	if not OS.is_debug_build():
		return
	if event.is_action_pressed("debug_hitboxes"):
		debug_shapes = not debug_shapes
		for node in get_tree().get_nodes_in_group("debug_shapes"):
			node.visible = debug_shapes and node.monitoring
	elif event.is_action_pressed("debug_xp"):
		var player := get_tree().get_first_node_in_group("player") as GuanditoPlayer
		if player:
			player.add_xp(50)
	elif event.is_action_pressed("debug_heal"):
		var player := get_tree().get_first_node_in_group("player") as GuanditoPlayer
		if player:
			player.health.heal(player.health.max_health)
	elif event.is_action_pressed("debug_combat_hud"):
		debug_hud_visible = not debug_hud_visible
		for node in get_tree().get_nodes_in_group("combat_debug_hud"):
			node.visible = debug_hud_visible

func spawn_impact(world_position: Vector2, kind: String) -> void:
	if ACTION_FX.has(kind):
		var action_effect: Node2D = ACTION_FX[kind].instantiate() as Node2D
		get_parent().add_child(action_effect)
		action_effect.global_position = world_position
		action_effect.setup()
		return
	var effect := IMPACT_FX.new() as ImpactFX
	get_parent().add_child(effect)
	effect.global_position = world_position
	effect.setup(kind)

func spawn_player_fx(world_position: Vector2, kind: String, facing: float) -> void:
	if not ACTION_FX.has(kind):
		return
	var effect: Node2D = ACTION_FX[kind].instantiate() as Node2D
	get_parent().add_child(effect)
	effect.global_position = world_position
	effect.setup(facing)

func screen_shake(intensity: float, duration: float) -> void:
	var camera := get_viewport().get_camera_2d()
	if camera and camera.has_method("shake"):
		camera.shake(intensity, duration)
