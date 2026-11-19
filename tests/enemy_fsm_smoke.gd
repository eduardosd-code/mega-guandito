extends SceneTree
# SectorEnemy FSM: windup -> active -> recover -> idle, and a hit during the
# windup cancels the attack for good (no stale awaits re-activating hitboxes).

const ARENA := preload("res://scenes/levels/test_arena.tscn")
const ENEMY := preload("res://scenes/enemies/sector_enemy.tscn")
var failures: Array[String] = []

func _initialize() -> void: call_deferred("_run")
func _frames(count: int) -> void:
	for _index in range(count): await physics_frame
func _check(value: bool, label: String) -> void:
	if value: print("PASS: ", label)
	else: failures.append(label); push_error("FAIL: " + label)

func _wait_phase(enemy: SectorEnemy, wanted: StringName, limit: int) -> bool:
	for _index in range(limit):
		if enemy.phase == wanted: return true
		await physics_frame
	return enemy.phase == wanted

func _run() -> void:
	var arena := ARENA.instantiate(); root.add_child(arena); await _frames(3)
	for bot in get_nodes_in_group("enemies"): bot.queue_free()
	await _frames(1)
	var player := get_first_node_in_group("player") as GuanditoPlayer
	player.health.max_health = 9999; player.health.current_health = 9999
	player.global_position = Vector2(300, 190)
	var enemy := ENEMY.instantiate() as SectorEnemy; enemy.role = SectorEnemy.Role.SCRAPPER
	arena.add_child(enemy); enemy.global_position = Vector2(330, 190)
	await _frames(5)

	# Full cycle.
	_check(await _wait_phase(enemy, &"windup", 120), "Scrapper reaches windup near the player")
	_check(await _wait_phase(enemy, &"active", 60), "windup leads to the active phase")
	_check(await _wait_phase(enemy, &"recover", 60), "active leads to recovery")
	_check(await _wait_phase(enemy, &"", 60) and enemy.state in [&"idle", &"chase"], "recovery returns to free movement")

	# Interrupt during windup.
	_check(await _wait_phase(enemy, &"windup", 180), "Scrapper winds up again")
	var hit := AttackData.new(); hit.damage = 1; hit.hitstun = 0.3; hit.knockback = Vector2.ZERO
	enemy._on_hit(hit, 1.0, null)
	_check(enemy.phase == &"" and enemy.state == &"hit", "hit cancels the windup")
	var reactivated := false
	for _index in range(15):
		await physics_frame
		if enemy.phase == &"active": reactivated = true
	_check(not reactivated, "cancelled attack never resumes during hitstun")

	if failures.is_empty(): print("ENEMY_FSM_SMOKE: PASS"); quit(0)
	else: print("ENEMY_FSM_SMOKE: FAIL (", failures.size(), ")"); quit(1)
