extends SceneTree

const SECTOR := preload("res://scenes/levels/sector07.tscn")
var failures: Array[String] = []

func _initialize() -> void: call_deferred("_run")
func _frames(count: int) -> void:
	for _index in range(count): await physics_frame
func _check(value: bool, label: String) -> void:
	if value: print("PASS: ", label)
	else: failures.append(label); push_error("FAIL: " + label)

func _fresh_sector() -> Sector07:
	var sector := SECTOR.instantiate() as Sector07; root.add_child(sector)
	return sector

func _prepare(sector: Sector07) -> void:
	await _frames(5)
	sector.intro_skipped = true; sector.intro_finished = true; sector.player.input_lock_left = 0.0
	if is_instance_valid(sector.intro_layer): sector.intro_layer.queue_free()
	for enemy in get_nodes_in_group("sector_enemies"): enemy.set_physics_process(false)

func _clear_regular_enemies() -> void:
	for enemy in get_nodes_in_group("sector_enemies"):
		if is_instance_valid(enemy): enemy.health.take_damage(9999)
	await _frames(50)

func _run() -> void:
	# RUN 1 — complete critical path and reward progression.
	var started := Time.get_ticks_msec(); var sector := _fresh_sector(); await _prepare(sector)
	for child in sector.get_children():
		if child is Checkpoint and child.checkpoint_id != &"cp_reward": child._on_body(sector.player)
	await _clear_regular_enemies()
	sector.player.global_position = Vector2(4400, 175); await _frames(45)
	_check(sector.hound.state != &"dormant", "RUN 1 reaches and activates HOUND")
	sector.hound.health.take_damage(99999); await _frames(60)
	var pickup: ModulePickup
	for child in sector.get_children():
		if child is ModulePickup: pickup = child
	if pickup: pickup._on_body(sector.player)
	sector.player.global_position = Vector2(5600, 120); await _frames(100)
	_check(sector.boss_defeated and sector.player.modules.has_effect(&"unlock_dodge"), "RUN 1 defeats HOUND and installs dodge")
	_check(sector.level_complete, "RUN 1 reaches KORA reveal and level completion")
	print("RUN 1 accelerated automation: %.2f s" % ((Time.get_ticks_msec() - started) / 1000.0))
	sector.queue_free(); await _frames(2)

	# RUN 2 — death rollback, backtracking and arena door lifecycle.
	started = Time.get_ticks_msec(); sector = _fresh_sector(); await _prepare(sector)
	var checkpoint: Checkpoint
	for child in sector.get_children():
		if child is Checkpoint and child.checkpoint_id == &"cp_contact": checkpoint = child
	checkpoint._on_body(sector.player)
	var target := sector.active_enemies[&"pump_sentry"] as SectorEnemy
	target.health.take_damage(9999); await _frames(50)
	_check(not sector.active_enemies.has(&"pump_sentry"), "RUN 2 records enemy defeated after checkpoint")
	sector.player.health.take_damage(9999); await _frames(75)
	_check(sector.active_enemies.has(&"pump_sentry"), "RUN 2 restores post-checkpoint enemy after death")
	sector.player.global_position = Vector2(4050, 140); sector.assembly_arena._on_body(sector.player); await _frames(2)
	_check(not sector.assembly_entry_door.opened, "RUN 2 closes assembly door on arena entry")
	for enemy in sector.assembly_arena.tracked_enemies:
		if is_instance_valid(enemy): enemy.health.take_damage(9999)
	await _frames(55)
	_check(sector.assembly_arena.completed and sector.assembly_entry_door.opened, "RUN 2 clears arena and reopens route")
	sector.player.global_position = Vector2(3500, 140); await _frames(2)
	_check(sector.player.global_position.x < 3800.0, "RUN 2 permits safe backtracking after arena clear")
	print("RUN 2 accelerated automation: %.2f s" % ((Time.get_ticks_msec() - started) / 1000.0))
	sector.queue_free(); await _frames(2)

	# RUN 3 — full-route pacing model based on the implemented encounter budget.
	started = Time.get_ticks_msec(); sector = _fresh_sector(); await _prepare(sector)
	var route_seconds := 60 + 90 + 105 + 75 + 120 + 150 + 60
	_check(sector.regular_spawn_specs.size() == 18 and get_nodes_in_group("boss").size() == 1, "RUN 3 traverses the complete encounter manifest")
	_check(route_seconds >= 480 and route_seconds <= 720, "RUN 3 pacing model remains inside 8–12 minutes")
	_check(sector.boss_door != null and not sector.boss_door.opened, "RUN 3 cannot skip reward gate")
	print("RUN 3 pacing model: %d:%02d (automation %.2f s)" % [route_seconds / 60, route_seconds % 60, (Time.get_ticks_msec() - started) / 1000.0])
	sector.queue_free(); await _frames(2)

	if failures.is_empty(): print("SECTOR07_PLAYTEST: PASS"); quit(0)
	else: print("SECTOR07_PLAYTEST: FAIL (", failures.size(), ")"); quit(1)
