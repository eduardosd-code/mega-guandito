class_name GameManager
extends Node

signal debug_mode_toggled(enabled: bool)

var _debug_mode: bool = true

func _ready() -> void:
pass

func _input(event: InputEvent) -> void:
if not _debug_mode:
return

if event is InputEventKey and event.pressed:
match event.physical_keycode:
KEY_F1:
toggle_hitboxes()
KEY_F2:
give_xp(50)
KEY_F3:
heal_player()

func toggle_hitboxes() -> void:
var tree = get_tree()
for node in tree.get_nodes_in_group("hitboxes"):
if node is CollisionShape2D:
node.visible = not node.visible
for node in tree.get_nodes_in_group("hurtboxes"):
if node is CollisionShape2D:
node.visible = not node.visible

func give_xp(amount: int) -> void:
var player = get_tree().get_first_node_in_group("player")
if player and player.has_method("add_xp"):
player.add_xp(amount)

func heal_player() -> void:
var player = get_tree().get_first_node_in_group("player")
if player and player.has_node("HealthComponent"):
var health = player.get_node("HealthComponent") as HealthComponent
if health:
health.heal(100)
