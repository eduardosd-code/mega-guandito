extends SceneTree

const SECTOR := preload("res://scenes/levels/sector07.tscn")
var failures: Array[String] = []

func _initialize() -> void: call_deferred("_run")
func _check(value: bool, label: String) -> void:
	if value: print("PASS: ",label)
	else: failures.append(label); push_error("FAIL: "+label)
func _frames(count: int) -> void:
	for _index in range(count): await physics_frame

func _run() -> void:
	var sector := SECTOR.instantiate() as Sector07; root.add_child(sector); await _frames(6)
	var player := get_first_node_in_group("player") as GuanditoPlayer
	_check(player != null,"Sector 07 instantiates Guandito")
	_check(get_nodes_in_group("sector_enemies").size() == 11,"level contains planned regular enemy encounters")
	var roles := {}; for enemy in get_nodes_in_group("sector_enemies"): roles[enemy.role] = true; enemy.set_physics_process(false)
	_check(roles.has(SectorEnemy.Role.SCRAPPER),"Scrapper is present")
	_check(roles.has(SectorEnemy.Role.BULWARK),"Bulwark is present")
	_check(roles.has(SectorEnemy.Role.SENTRY),"Sentry is present")
	_check(get_nodes_in_group("boss").size() == 1,"VLR-03 HOUND is present")
	_check(not player.modules.is_unlocked(&"overdrive_evasion_mk1"),"evasion is locked at level start")

	# A fast horizontal displacement must never leave the player behind.
	var camera := player.get_node("Camera2D") as Camera2D
	var start_position := player.global_position
	player.set_physics_process(false)
	player.global_position += Vector2(700.0, 0.0)
	await process_frame
	await process_frame
	_check(camera.global_position.distance_to(camera.desired_follow_position()) <= 1.5,"camera catches fast movement to the right")
	var camera_x_before_turn := camera.global_position.x
	player.facing = -1
	await process_frame
	await process_frame
	_check(absf(camera.global_position.x - camera_x_before_turn) < 20.0,"camera eases direction changes without snapping")
	player.global_position = start_position
	player.facing = 1
	camera.reset_to_target()
	player.set_physics_process(true)

	var checkpoints: Array[Checkpoint] = []
	var secrets: Array[SecretArea] = []
	var platforms: Array[MovingPlatform] = []
	for child in sector.get_children():
		if child is Checkpoint: checkpoints.append(child)
		elif child is SecretArea: secrets.append(child)
		elif child is MovingPlatform: platforms.append(child)
	_check(checkpoints.size() == 4,"four checkpoints are connected")
	_check(secrets.size() == 2,"two optional secret rewards exist")
	_check(platforms.size() == 2,"pumping/service zones use moving platforms")

	# Checkpoint restores life and position after death.
	checkpoints[1]._on_body(player); var expected := checkpoints[1].global_position
	player.health.take_damage(999); await _frames(70)
	_check(player.health.current_health == player.health.max_health,"checkpoint restores health")
	_check(absf(player.global_position.x - expected.x) < 16.0 and absf(player.global_position.y - expected.y) < 32.0,"checkpoint restores player position")

	# Boss gate and reward enforce progression.
	player.global_position = Vector2(4400,175); await _frames(2)
	var hound := get_first_node_in_group("boss") as VLR03Hound
	_check(hound.state != &"dormant","boss activates on arena approach")
	_check(not sector.boss_door.opened,"surface door stays locked before reward")
	hound.health.take_damage(9999); await _frames(2)
	var pickup: ModulePickup
	for child in sector.get_children(): if child is ModulePickup: pickup = child
	_check(pickup != null,"boss defeat spawns Overdrive Evasion pickup")
	if pickup: pickup._on_body(player)
	await _frames(2)
	_check(player.modules.is_unlocked(&"overdrive_evasion_mk1"),"pickup unlocks Overdrive Evasion")
	_check(player.modules.has_effect(&"unlock_dodge"),"reward auto-equips dodge module")
	_check(sector.boss_door.opened,"collecting reward opens surface route")

	if failures.is_empty(): print("SECTOR07_SMOKE: PASS"); quit(0)
	else: print("SECTOR07_SMOKE: FAIL (",failures.size(),")"); quit(1)
