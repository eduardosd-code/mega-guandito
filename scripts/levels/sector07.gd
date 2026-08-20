class_name Sector07
extends Node2D

const ENEMY := preload("res://scenes/enemies/sector_enemy.tscn")
const HOUND := preload("res://scenes/enemies/vlr03_hound.tscn")
@onready var player: GuanditoPlayer = $Guandito
var checkpoint_position := Vector2(110, 185)
var hound: VLR03Hound
var boss_started := false
var boss_defeated := false
var elapsed := 0.0
var boss_door: DoorTransition

func _ready() -> void:
	_build_geometry()
	_build_progression()
	_spawn_encounters()
	player.health.died.connect(_on_player_died)
	var camera := player.get_node("Camera2D") as Camera2D
	camera.limit_left = 0; camera.limit_right = 5750; camera.limit_top = 0; camera.limit_bottom = 300
	player.module_status.emit("SECTOR 07 // INSTALACION ABANDONADA")

func _process(delta: float) -> void:
	elapsed += delta; queue_redraw()
	if not boss_started and player.global_position.x > 4310:
		boss_started = true; hound.activate(); player.module_status.emit("ALERTA: UNIDAD VLR-03 HOUND")
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

func _build_progression() -> void:
	_message_trigger(Vector2(160,150),"SISTEMAS GND-01 RESTAURADOS // A/D MOVER // SPACE SALTAR")
	_message_trigger(Vector2(720,150),"FIRMA HOSTIL // J: MARTILLO DE PULSO")
	_message_trigger(Vector2(1560,120),"SALA DE BOMBEO // L: DASH // DASH + J: CANCEL")
	_message_trigger(Vector2(2530,90),"CONDUCTOS: RUTAS SECUNDARIAS DETECTADAS")
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
	boss_door = _add_door(Vector2(5005,140))
	_add_arena(Vector2(930,155),Vector2(560,180),&"first_contact")
	_add_arena(Vector2(3800,135),Vector2(820,200),&"assembly")

func _spawn_encounters() -> void:
	# Zone 2: organic melee introduction.
	_spawn_enemy(Vector2(820,185),SectorEnemy.Role.SCRAPPER); _spawn_enemy(Vector2(1060,185),SectorEnemy.Role.SCRAPPER)
	# Zone 3: ranged pressure around moving machinery.
	_spawn_enemy(Vector2(1720,155),SectorEnemy.Role.SCRAPPER); _spawn_enemy(Vector2(1990,155),SectorEnemy.Role.SENTRY); _spawn_enemy(Vector2(2390,170),SectorEnemy.Role.SENTRY)
	# Zone 4 optional guardians.
	_spawn_enemy(Vector2(2860,170),SectorEnemy.Role.SCRAPPER)
	# Zone 5 assembly arena mixes all roles.
	_spawn_enemy(Vector2(3470,150),SectorEnemy.Role.SCRAPPER); _spawn_enemy(Vector2(3690,150),SectorEnemy.Role.BULWARK)
	_spawn_enemy(Vector2(3950,150),SectorEnemy.Role.SENTRY); _spawn_enemy(Vector2(4120,150),SectorEnemy.Role.SCRAPPER)
	hound = HOUND.instantiate() as VLR03Hound; add_child(hound); hound.position = Vector2(4660,175); hound.defeated.connect(_on_hound_defeated)
	# Zone 7 confirms dodge through a highly visible ranged telegraph.
	_spawn_enemy(Vector2(5310,135),SectorEnemy.Role.SENTRY)

func _spawn_enemy(where: Vector2, role: int) -> SectorEnemy:
	var enemy := ENEMY.instantiate() as SectorEnemy; enemy.role = role; add_child(enemy); enemy.position = where; return enemy

func _add_floor(top_left: Vector2, size: Vector2) -> void:
	var body := StaticBody2D.new(); body.collision_layer = 16; body.collision_mask = 0; body.position = top_left + size * 0.5
	var collision := CollisionShape2D.new(); var shape := RectangleShape2D.new(); shape.size = size; collision.shape = shape; body.add_child(collision); add_child(body)

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

func _add_door(where: Vector2) -> DoorTransition:
	var door := DoorTransition.new(); door.position = where
	var collision := CollisionShape2D.new(); collision.name = "CollisionShape2D"; var shape := RectangleShape2D.new(); shape.size = Vector2(24,148); collision.shape = shape; door.add_child(collision); add_child(door); return door

func _add_arena(where: Vector2, size: Vector2, id: StringName) -> void:
	var arena := CombatArena.new(); arena.position = where; arena.bounds = Rect2(-size*0.5,size); arena.arena_id = id; add_child(arena)
	arena.entered.connect(func(value): player.module_status.emit("ARENA // %s" % value.arena_id.to_upper()))

func _on_checkpoint(checkpoint: Checkpoint) -> void:
	checkpoint_position = checkpoint.global_position; player.module_status.emit("CHECKPOINT // %s" % checkpoint.checkpoint_id.to_upper())

func _on_player_died() -> void:
	await get_tree().create_timer(1.0, false).timeout
	player.respawn_at(checkpoint_position)

func _on_hound_defeated() -> void:
	boss_defeated = true; player.add_xp(120); player.module_status.emit("VLR-03 DESACTIVADO // MODULO DETECTADO")
	var pickup := ModulePickup.new(); pickup.position = Vector2(4780,180); add_child(pickup)
	pickup.collected.connect(func(): player.module_status.emit("SOBRECARGA EVASIVA INSTALADA // Q / RB"); boss_door.open())

func _draw() -> void:
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
