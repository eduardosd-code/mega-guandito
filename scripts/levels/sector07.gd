class_name Sector07
extends Node2D

const ENEMY := preload("res://scenes/enemies/sector_enemy.tscn")
const HOUND := preload("res://scenes/enemies/vlr03_hound.tscn")
const INDUSTRIAL_HAZARD := preload("res://scripts/level/industrial_hazard.gd")
@onready var player: GuanditoPlayer = $Guandito
var checkpoint_position := Vector2(110, 185)
var hound: VLR03Hound
var boss_started := false
var boss_defeated := false
var elapsed := 0.0
var boss_door: DoorTransition
var assembly_arena: CombatArena
var assembly_entry_door: DoorTransition
var regular_spawn_specs: Array[Dictionary] = []
var active_enemies: Dictionary = {}
var defeated_enemy_ids: Dictionary = {}
var checkpoint_defeated_ids: Dictionary = {}
var checkpoint_segment := 0
var checkpoint_xp := 0
var checkpoint_level := 1
var respawning := false
var intro_finished := false
var intro_skipped := false
var intro_layer: CanvasLayer
var level_complete := false
var run_time := 0.0
var damage_taken := 0
var deaths := 0
var kills := 0

func _ready() -> void:
	_build_geometry()
	_build_progression()
	_spawn_encounters()
	_configure_assembly_arena()
	player.health.died.connect(_on_player_died)
	player.health.damaged.connect(func(amount: int): damage_taken += amount)
	var camera := player.get_node("Camera2D") as Camera2D
	camera.limit_left = 0; camera.limit_right = 5750; camera.limit_top = 0; camera.limit_bottom = 300
	player.module_status.emit("SECTOR 07 // INSTALACION ABANDONADA")
	_start_wakeup_sequence()

func _process(delta: float) -> void:
	elapsed += delta; queue_redraw()
	if intro_finished and not level_complete: run_time += delta
	if not boss_started and not boss_defeated and player.global_position.x > 4310:
		_start_hound_encounter()
	if not level_complete and boss_defeated and player.global_position.x > 5580:
		_complete_level()
	if player.global_position.y > 340 and player.health.current_health > 0:
		player.respawn_at(checkpoint_position)

func _build_geometry() -> void:
	_add_floor(Vector2(0,220),Vector2(1420,60))
	_add_floor(Vector2(1420,190),Vector2(780,90))
	_add_floor(Vector2(2320,205),Vector2(1040,75))
	_add_floor(Vector2(3360,185),Vector2(900,95))
	_add_floor(Vector2(4260,215),Vector2(790,65))
	_add_floor(Vector2(5050,170),Vector2(700,110))
	# Service walkways and optional secret route.
	for platform in [Rect2(2500,145,130,12),Rect2(2690,105,130,12),Rect2(2880,145,160,12),Rect2(3550,125,120,12),Rect2(3790,105,140,12)]: _add_platform(platform)
	_add_moving_platform(Vector2(2225,190),Vector2(105,-55),2.6)
	_add_moving_platform(Vector2(3150,165),Vector2(90,0),2.1)
	# Zone 4 chimney: a hanging wall and a tall barrier 52 px apart. The only way
	# over is wall-jumping between them (or wall jump + air dash).
	_add_block(Vector2(2400,20),Vector2(24,130))
	_add_block(Vector2(2476,95),Vector2(26,110))
	var spikes := SpikeStrip.new(); spikes.position = Vector2(2504,205); spikes.width = 136.0; add_child(spikes)
	for hazard_position in [Vector2(1605,190), Vector2(1875,160), Vector2(2350,175)]:
		var hazard: Area2D = INDUSTRIAL_HAZARD.new(); hazard.position = hazard_position; add_child(hazard)

func _build_progression() -> void:
	_message_trigger(Vector2(160,150),"SISTEMAS GND-01 RESTAURADOS // A/D MOVER // SPACE SALTAR")
	_message_trigger(Vector2(720,150),"FIRMA HOSTIL // J: MARTILLO DE PULSO")
	_message_trigger(Vector2(1560,120),"SALA DE BOMBEO // L: DASH // DASH + J: CANCEL")
	_message_trigger(Vector2(2330,150),"CHIMENEA // EMPUJA CONTRA LA PARED Y SALTA // L EN EL AIRE: DASH")
	_message_trigger(Vector2(2560,90),"CONDUCTOS: RUTAS SECUNDARIAS // MANTEN J PARA CARGAR")
	_message_trigger(Vector2(3490,115),"ENSAMBLAJE // UNIDADES PESADAS: USE HEAVY")
	_message_trigger(Vector2(5090,105),"Q: SOBRECARGA EVASIVA // EVITE EL IMPACTO, NO LA EXPOSICION")
	_message_trigger(Vector2(5580,100),"SECTOR 07 COMPLETADO // KORA // LA AGUJA")
	for data in [[1250,185,"cp_contact"],[3040,170,"cp_service"],[4250,180,"cp_boss"],[5020,135,"cp_reward"]]:
		var checkpoint := Checkpoint.new(); checkpoint.position = Vector2(data[0],data[1]); checkpoint.checkpoint_id = data[2]; add_child(checkpoint); checkpoint.activated.connect(_on_checkpoint)
	var secret_a := SecretArea.new(); secret_a.position = Vector2(2760,75); add_child(secret_a); secret_a.discovered.connect(func(_s): player.module_status.emit("SECRETO: NUCLEO DE DATOS +35 XP"))
	var secret_b := SecretArea.new(); secret_b.position = Vector2(3920,75); secret_b.xp_reward = 50; add_child(secret_b); secret_b.discovered.connect(func(_s): player.module_status.emit("SECRETO: CELDA DE REACTOR +50 XP"))
	_add_elevator(Vector2(1355,180),Vector2(185,-28),"ELEVADOR DE BOMBEO")
	_add_elevator(Vector2(3270,170),Vector2(150,-18),"MONTACARGAS DE ENSAMBLAJE")
	_add_camera_zone(Vector2(5280,80),Vector2(260,180),Vector2(0.88,0.88))
	boss_door = _add_door(Vector2(5005,140), "security")
	_add_arena(Vector2(930,155),Vector2(560,180),&"first_contact")
	assembly_entry_door = _add_door(Vector2(3790,140), "industrial"); assembly_entry_door.open()
	assembly_arena = _add_arena(Vector2(4020,135),Vector2(450,200),&"assembly_final")

func _spawn_encounters() -> void:
	regular_spawn_specs = [
		# Zone 2: one Scrapper, breathing room, then a pair.
		{"id": &"contact_1", "position": Vector2(760,185), "role": SectorEnemy.Role.SCRAPPER, "segment": 0},
		{"id": &"contact_2a", "position": Vector2(1030,185), "role": SectorEnemy.Role.SCRAPPER, "segment": 0},
		{"id": &"contact_2b", "position": Vector2(1135,185), "role": SectorEnemy.Role.SCRAPPER, "segment": 0},
		# Zone 3: readable Sentry introduction, then melee plus ranged pressure.
		{"id": &"pump_sentry", "position": Vector2(1740,150), "role": SectorEnemy.Role.SENTRY, "segment": 1},
		{"id": &"pump_scrapper", "position": Vector2(2070,155), "role": SectorEnemy.Role.SCRAPPER, "segment": 1},
		{"id": &"pump_mix_sentry", "position": Vector2(2190,145), "role": SectorEnemy.Role.SENTRY, "segment": 1},
		# Zone 4: optional-route guardian.
		{"id": &"service_optional", "position": Vector2(2860,170), "role": SectorEnemy.Role.SCRAPPER, "segment": 1},
		# Zone 5: solo Bulwark, mixed drill, positioning drill, final arena.
		{"id": &"assembly_bulwark", "position": Vector2(3425,150), "role": SectorEnemy.Role.BULWARK, "segment": 2},
		{"id": &"assembly_mix_b", "position": Vector2(3585,150), "role": SectorEnemy.Role.BULWARK, "segment": 2},
		{"id": &"assembly_mix_s", "position": Vector2(3675,150), "role": SectorEnemy.Role.SCRAPPER, "segment": 2},
		{"id": &"assembly_position_s1", "position": Vector2(3820,150), "role": SectorEnemy.Role.SCRAPPER, "segment": 2},
		{"id": &"assembly_position_s2", "position": Vector2(3890,150), "role": SectorEnemy.Role.SCRAPPER, "segment": 2},
		{"id": &"assembly_position_r", "position": Vector2(3970,140), "role": SectorEnemy.Role.SENTRY, "segment": 2},
		{"id": &"assembly_final_s1", "position": Vector2(4020,150), "role": SectorEnemy.Role.SCRAPPER, "segment": 2, "arena": true},
		{"id": &"assembly_final_s2", "position": Vector2(4090,150), "role": SectorEnemy.Role.SCRAPPER, "segment": 2, "arena": true},
		{"id": &"assembly_final_b", "position": Vector2(4160,150), "role": SectorEnemy.Role.BULWARK, "segment": 2, "arena": true},
		{"id": &"assembly_final_r", "position": Vector2(4220,140), "role": SectorEnemy.Role.SENTRY, "segment": 2, "arena": true},
		# Zone 7: safe dodge practice after the reward.
		{"id": &"dodge_tutorial", "position": Vector2(5310,135), "role": SectorEnemy.Role.SENTRY, "segment": 4}
	]
	for spec in regular_spawn_specs: _spawn_from_spec(spec)
	_spawn_hound()

func _spawn_enemy(where: Vector2, role: int) -> SectorEnemy:
	var enemy := ENEMY.instantiate() as SectorEnemy; enemy.role = role; add_child(enemy); enemy.position = where; return enemy

func _spawn_from_spec(spec: Dictionary) -> SectorEnemy:
	var enemy := _spawn_enemy(spec["position"], spec["role"])
	var spawn_id: StringName = spec["id"]
	enemy.set_meta(&"spawn_id", spawn_id)
	enemy.defeated.connect(_on_regular_enemy_defeated)
	active_enemies[spawn_id] = enemy
	return enemy

func _spawn_hound() -> void:
	if boss_defeated: return
	hound = HOUND.instantiate() as VLR03Hound; add_child(hound); hound.position = Vector2(4660,175); hound.defeated.connect(_on_hound_defeated)

func _add_floor(top_left: Vector2, size: Vector2) -> void:
	var body := StaticBody2D.new(); body.collision_layer = 16; body.collision_mask = 0; body.position = top_left + size * 0.5
	var collision := CollisionShape2D.new(); var shape := RectangleShape2D.new(); shape.size = size; collision.shape = shape; body.add_child(collision); add_child(body)

func _add_block(top_left: Vector2, size: Vector2) -> void:
	var block := SolidBlock.new(); block.position = top_left; block.size = size; add_child(block)

func _add_platform(rect: Rect2) -> void:
	_add_floor(rect.position,rect.size)

func _add_moving_platform(where: Vector2, travel: Vector2, duration: float) -> void:
	var platform := MovingPlatform.new(); platform.position = where; platform.travel = travel; platform.cycle_duration = duration
	var collision := CollisionShape2D.new(); var shape := RectangleShape2D.new(); shape.size = Vector2(76,12); collision.shape = shape; platform.add_child(collision); add_child(platform)

func _message_trigger(where: Vector2, text: String) -> void:
	var trigger := DialogueTrigger.new(); trigger.position = where; trigger.message = text; add_child(trigger); trigger.triggered.connect(func(message): player.module_status.emit(message))

func _add_elevator(where: Vector2, offset: Vector2, label: String) -> void:
	var elevator := ElevatorTransition.new(); elevator.position = where; elevator.destination_offset = offset; add_child(elevator)
	elevator.used.connect(func(): player.module_status.emit(label); var manager := get_tree().get_first_node_in_group("game_manager"); if manager: manager.spawn_impact(player.global_position,"kinetic"))

func _add_camera_zone(where: Vector2, size: Vector2, target_zoom: Vector2) -> void:
	var zone := CameraZone.new(); zone.position = where; zone.zoom = target_zoom
	var collision := CollisionShape2D.new(); var shape := RectangleShape2D.new(); shape.size = size; collision.shape = shape; zone.add_child(collision); add_child(zone)

func _add_door(where: Vector2, style: String = "maintenance") -> DoorTransition:
	var door := DoorTransition.new(); door.position = where; door.door_style = style
	var collision := CollisionShape2D.new(); collision.name = "CollisionShape2D"; var shape := RectangleShape2D.new(); shape.size = Vector2(24,148); collision.shape = shape; door.add_child(collision); add_child(door); return door

func _add_arena(where: Vector2, size: Vector2, id: StringName) -> CombatArena:
	var arena := CombatArena.new(); arena.position = where; arena.bounds = Rect2(-size*0.5,size); arena.arena_id = id; add_child(arena)
	arena.entered.connect(func(value): player.module_status.emit("ARENA // %s" % value.arena_id.to_upper()))
	arena.cleared.connect(func(value): player.module_status.emit("AREA DESPEJADA // %s" % value.arena_id.to_upper()))
	return arena

func _on_checkpoint(checkpoint: Checkpoint) -> void:
	checkpoint_position = checkpoint.global_position
	checkpoint_segment = {&"cp_contact": 1, &"cp_service": 2, &"cp_boss": 3, &"cp_reward": 4}.get(checkpoint.checkpoint_id, checkpoint_segment)
	checkpoint_defeated_ids = defeated_enemy_ids.duplicate()
	checkpoint_xp = player.experience.current_xp
	checkpoint_level = player.experience.current_level
	player.module_status.emit("CHECKPOINT // %s" % checkpoint.checkpoint_id.to_upper())

func _on_player_died() -> void:
	if respawning: return
	respawning = true
	deaths += 1
	await get_tree().create_timer(1.0, false).timeout
	_restore_checkpoint_state()
	player.respawn_at(checkpoint_position)
	respawning = false

func _on_hound_defeated() -> void:
	boss_defeated = true; boss_started = false; player.module_status.emit("VLR-03 DESACTIVADO // COMPONENTE DETECTADO")
	var pickup := ModulePickup.new(); pickup.position = Vector2(4780,180); add_child(pickup)
	pickup.collected.connect(_on_module_collected)

func _on_regular_enemy_defeated(enemy: SectorEnemy) -> void:
	var spawn_id: StringName = enemy.get_meta(&"spawn_id", &"")
	if spawn_id != &"":
		if not defeated_enemy_ids.has(spawn_id): kills += 1
		defeated_enemy_ids[spawn_id] = true
		active_enemies.erase(spawn_id)

func _configure_assembly_arena() -> void:
	var final_enemies: Array[Node] = []
	for spec in regular_spawn_specs:
		if spec.get("arena", false):
			var enemy: Node = active_enemies.get(spec["id"])
			if is_instance_valid(enemy): final_enemies.append(enemy)
	assembly_arena.configure(final_enemies, [assembly_entry_door])

func _restore_checkpoint_state() -> void:
	player.experience.current_level = checkpoint_level
	player.experience.current_xp = checkpoint_xp
	player.experience._emit_all()
	defeated_enemy_ids = checkpoint_defeated_ids.duplicate()
	for enemy in get_tree().get_nodes_in_group("sector_enemies"):
		enemy.get_parent().remove_child(enemy); enemy.queue_free()
	active_enemies.clear()
	for spec in regular_spawn_specs:
		if not defeated_enemy_ids.has(spec["id"]): _spawn_from_spec(spec)
	if assembly_arena:
		_configure_assembly_arena()
	if not boss_defeated:
		if is_instance_valid(hound): hound.get_parent().remove_child(hound); hound.queue_free()
		_spawn_hound(); boss_started = false
	for projectile in get_tree().get_nodes_in_group("enemy_projectiles"): projectile.queue_free()

func _start_hound_encounter() -> void:
	boss_started = true
	player.module_status.emit("ALERTA DE SEGURIDAD // VLR-03")
	if is_instance_valid(hound): hound.activate()
	await get_tree().create_timer(0.7, false).timeout
	if is_instance_valid(hound):
		player.module_status.emit("VLR-03 HOUND // SECURITY UNIT")

func _on_module_collected() -> void:
	boss_door.open()
	player.module_status.emit("VLR ACTUATOR SYSTEM // COMPATIBILITY: 94%")
	await get_tree().create_timer(1.0, false).timeout
	player.module_status.emit("SOBRECARGA EVASIVA Mk-I // UNLOCKED // Q / RB")

func _start_wakeup_sequence() -> void:
	player.input_lock_left = 4.8
	intro_layer = CanvasLayer.new(); intro_layer.layer = 20; add_child(intro_layer)
	var darkness := ColorRect.new(); darkness.color = Color.BLACK; darkness.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); intro_layer.add_child(darkness)
	var label := Label.new(); label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; label.add_theme_color_override("font_color", Color("#9be84b")); label.add_theme_font_size_override("font_size", 15); intro_layer.add_child(label)
	var messages := ["GND-01", "POWER CORE... ONLINE", "MOTOR SYSTEMS... ONLINE", "MEMORY... ERROR", "CONTROL RESTORED"]
	for message in messages:
		if intro_skipped: return
		label.text = message
		player.module_status.emit(message)
		await get_tree().create_timer(0.8, false).timeout
	if intro_skipped: return
	var tween := create_tween(); tween.tween_property(intro_layer, "modulate:a", 0.0, 0.5); await tween.finished
	intro_layer.queue_free()
	intro_finished = true

func _complete_level() -> void:
	level_complete = true
	player.module_status.emit("KORA // EXTERIOR DETECTADO // LA AGUJA")
	await get_tree().create_timer(1.4, false).timeout
	player.module_status.emit("SECTOR 07 // ESCAPE COMPLETE")
	_show_mission_result()

func mission_points() -> int:
	return MissionRank.score(run_time, damage_taken, deaths, mini(kills, regular_spawn_specs.size()) + (1 if boss_defeated else 0), regular_spawn_specs.size() + 1)

func _show_mission_result() -> void:
	var points := mission_points()
	var layer := CanvasLayer.new(); layer.layer = 25; layer.name = "MissionResult"; add_child(layer)
	var panel := ColorRect.new(); panel.color = Color(0.02, 0.05, 0.06, 0.88); panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); layer.add_child(panel)
	var label := Label.new(); label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color("#9be84b")); label.add_theme_font_size_override("font_size", 12)
	label.text = "MISION COMPLETADA // SECTOR 07\n\nTIEMPO  %d:%02d\nDANO RECIBIDO  %d\nREINICIOS  %d\nENEMIGOS  %d / %d\n\nPUNTOS  %d" % [int(run_time) / 60, int(run_time) % 60, damage_taken, deaths, kills + (1 if boss_defeated else 0), regular_spawn_specs.size() + 1, points]
	layer.add_child(label)
	var rank_label := Label.new(); rank_label.text = MissionRank.rank(points)
	rank_label.add_theme_font_size_override("font_size", 64); rank_label.add_theme_color_override("font_color", Color("#ffd34a"))
	rank_label.position = Vector2(360, 90); rank_label.scale = Vector2(2.5, 2.5); rank_label.pivot_offset = Vector2(20, 40)
	layer.add_child(rank_label)
	var tween := rank_label.create_tween(); tween.tween_property(rank_label, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _unhandled_input(event: InputEvent) -> void:
	if not intro_finished and event.is_pressed():
		intro_skipped = true; intro_finished = true; player.input_lock_left = 0.0
		if is_instance_valid(intro_layer): intro_layer.queue_free()
		return
	if not OS.is_debug_build() or not event is InputEventKey or not event.pressed: return
	match event.keycode:
		KEY_F2: player.health.heal(player.health.max_health)
		KEY_F3:
			var next_positions := [Vector2(1250,185), Vector2(3040,170), Vector2(4250,180), Vector2(5020,135)]
			player.respawn_at(next_positions[mini(checkpoint_segment, next_positions.size() - 1)])
		KEY_F4: player.respawn_at(Vector2(4380,175))
		KEY_F5: player.unlock_evasion_module(true)

func _draw() -> void:
	if get_node_or_null("Environment") != null: return
	draw_rect(Rect2(0,0,5750,280),Color("#080e12"))
	# Parallax-like industrial silhouettes, pipes and emergency fixtures.
	for x in range(0,5050,180):
		draw_rect(Rect2(x,45 + (x%70),110,180),Color("#111b1f")); draw_rect(Rect2(x+18,65+(x%70),12,65),Color("#263b35"))
	draw_line(Vector2(0,62),Vector2(5050,62),Color("#3a4947"),9); draw_line(Vector2(0,62),Vector2(5050,62),Color("#657054"),2)
	for x in range(90,5050,260):
		var pulse := 0.55 + sin(elapsed*2.0+x)*0.15; draw_circle(Vector2(x,74),5,Color(0.9,0.2,0.1,pulse))
	# Visible collision surfaces: steel decks, worn edges and drainage channels.
	var decks := [Rect2(0,220,1420,60),Rect2(1420,190,780,90),Rect2(2320,205,1040,75),Rect2(3360,185,900,95),Rect2(4260,215,790,65),Rect2(5050,170,700,110)]
	for deck in decks:
		draw_rect(deck,Color("#172125")); draw_rect(Rect2(deck.position,Vector2(deck.size.x,4)),Color("#66736b"))
		for groove in range(int(deck.position.x)+20,int(deck.end.x),48): draw_line(Vector2(groove,deck.position.y+8),Vector2(groove+18,deck.position.y+45),Color("#243033"),2)
	for platform in [Rect2(2500,145,130,12),Rect2(2690,105,130,12),Rect2(2880,145,160,12),Rect2(3550,125,120,12),Rect2(3790,105,140,12)]:
		draw_rect(platform,Color("#445050")); draw_line(platform.position,Vector2(platform.end.x,platform.position.y),Color("#8a9b75"),2)
	# Wake-up maintenance cradle and abandoned equipment.
	draw_rect(Rect2(55,125,95,94),Color("#11181c")); draw_rect(Rect2(67,138,70,68),Color("#263033")); draw_arc(Vector2(102,172),30,PI,TAU,20,Color("#66736b"),4)
	draw_rect(Rect2(420,180,42,39),Color("#22292b")); draw_circle(Vector2(431,191),4,Color("#8f3027")); draw_line(Vector2(450,180),Vector2(462,164),Color("#303b3d"),3)
	# Zone identifiers and environmental storytelling.
	var labels := [[70,"01  SOTANO // DESPERTAR"],[690,"02  PRIMER CONTACTO"],[1480,"03  SALA DE BOMBEO"],[2480,"04  CONDUCTOS"],[3400,"05  ENSAMBLAJE"],[4320,"06  VLR-03 HOUND"],[5070,"07  SALIDA // KORA"]]
	for item in labels: draw_string(ThemeDB.fallback_font,Vector2(item[0],35),item[1],HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("#83bd37"))
	# Surface reveal: KORA skyline and the monumental Aguja.
	draw_rect(Rect2(5050,0,700,170),Color("#101c22"))
	for x in range(5070,5750,55): draw_rect(Rect2(x,70+(x%45),38,100),Color("#1a282d"))
	draw_colored_polygon(PackedVector2Array([Vector2(5480,170),Vector2(5530,-55),Vector2(5580,170)]),Color("#26373b"))
	draw_line(Vector2(5530,-40),Vector2(5530,150),Color("#72ba34"),3)
	draw_string(ThemeDB.fallback_font,Vector2(5390,28),"KORA // LA AGUJA",HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("#a3df4a"))
