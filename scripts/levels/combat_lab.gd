class_name CombatLab
extends Node2D

const PLAYER := preload("res://scenes/player/guandito.tscn")
const ENEMY := preload("res://scenes/enemies/sector_enemy.tscn")
const HOUND := preload("res://scenes/enemies/vlr03_hound.tscn")
const EVASION := preload("res://resources/modules/overdrive_evasion_mk1.tres")
const MIXED := preload("res://resources/encounters/combat_lab_mixed.tres")
@onready var manager: GameManager = $GameManager
@onready var status_label: Label = $DebugHUD/Panel/Status
var player: GuanditoPlayer
var debug_hitboxes := false

func _ready() -> void:
	player = PLAYER.instantiate() as GuanditoPlayer; add_child(player); player.position = Vector2(480, 205)
	player.modules.unlock(EVASION); player.modules.equip(EVASION)
	var camera := player.get_node("Camera2D") as Camera2D
	camera.limit_left = 0; camera.limit_right = 960; camera.limit_top = 0; camera.limit_bottom = 270; camera.reset_to_target()
	_update_hud(); queue_redraw()

func _process(_delta: float) -> void: _update_hud()

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	match event.keycode:
		KEY_F1: spawn_role(SectorEnemy.Role.SCRAPPER)
		KEY_F2: spawn_role(SectorEnemy.Role.BULWARK)
		KEY_F3: spawn_role(SectorEnemy.Role.SENTRY)
		KEY_F4: spawn_hound()
		KEY_F5: spawn_encounter(MIXED)
		KEY_F6: clear_enemies()
		KEY_F7: player.health.heal(player.health.max_health)
		KEY_F8: toggle_debug_hitboxes()
		KEY_F9: get_tree().reload_current_scene()

func spawn_role(role: int, world_position := Vector2.INF) -> SectorEnemy:
	var enemy := ENEMY.instantiate() as SectorEnemy; enemy.role = role; add_child(enemy)
	if world_position == Vector2.INF:
		var direction := player.facing if player.facing != 0.0 else 1.0
		world_position = player.global_position + Vector2(direction * 190.0, -45.0 if role == SectorEnemy.Role.SENTRY else 0.0)
	enemy.global_position = _valid_spawn(world_position, role == SectorEnemy.Role.SENTRY); return enemy

func spawn_hound() -> VLR03Hound:
	var existing := get_tree().get_first_node_in_group("boss") as VLR03Hound
	if is_instance_valid(existing): return existing
	var hound := HOUND.instantiate() as VLR03Hound; add_child(hound)
	hound.global_position = _valid_spawn(player.global_position + Vector2(player.facing * 270.0, 0.0), false); hound.activate(); return hound

func spawn_encounter(data: EncounterData) -> void:
	for index in range(mini(data.enemy_roles.size(), data.spawn_offsets.size())):
		spawn_role(data.enemy_roles[index], Vector2(480, 205) + data.spawn_offsets[index])

func clear_enemies() -> void:
	for node in get_tree().get_nodes_in_group("sector_enemies"): node.queue_free()
	for node in get_tree().get_nodes_in_group("boss"): node.queue_free()
	for node in get_tree().get_nodes_in_group("enemy_projectiles"): node.queue_free()

func toggle_debug_hitboxes() -> void:
	debug_hitboxes = not debug_hitboxes; manager.debug_shapes = debug_hitboxes
	for node in get_tree().get_nodes_in_group("debug_shapes"):
		node.visible = debug_hitboxes and (not node is Area2D or node.monitoring or node is HurtboxComponent)

func _valid_spawn(candidate: Vector2, floating: bool) -> Vector2:
	var x := clampf(candidate.x, 90.0, 870.0)
	if absf(x - player.global_position.x) < 110.0: x += 130.0 * signf(x - player.global_position.x if x != player.global_position.x else player.facing)
	return Vector2(clampf(x, 90.0, 870.0), 155.0 if floating else 205.0)

func _update_hud() -> void:
	if not is_instance_valid(player) or not is_instance_valid(status_label): return
	var enemies := get_tree().get_nodes_in_group("sector_enemies").size()
	var hound := get_tree().get_first_node_in_group("boss") as VLR03Hound
	var hound_text := ""
	if is_instance_valid(hound): hound_text = "   HOUND %d/%d" % [hound.health.current_health, hound.health.max_health]
	status_label.text = "PLAYER %d/%d   ENEMIES %d%s" % [player.health.current_health, player.health.max_health, enemies, hound_text]

func _draw() -> void:
	draw_rect(Rect2(0, 0, 960, 270), Color("#091317"))
	for x in range(0, 960, 64):
		draw_line(Vector2(x, 0), Vector2(x - 90, 220), Color("#102a2e"), 2.0)
	draw_rect(Rect2(0, 220, 960, 50), Color("#1d2d30")); draw_rect(Rect2(0, 218, 960, 4), Color("#75847b"))
	draw_line(Vector2(0, 165), Vector2(960, 165), Color("#6da129", 0.35), 2.0)
