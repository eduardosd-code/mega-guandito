extends SceneTree
# HOUND boss: phase 2 at half health, roar is invulnerable, new patterns run.

const ARENA := preload("res://scenes/levels/test_arena.tscn")
const HOUND := preload("res://scenes/enemies/vlr03_hound.tscn")
var failures: Array[String] = []

func _initialize() -> void: call_deferred("_run")
func _frames(count: int) -> void:
	for _index in range(count): await physics_frame
func _check(value: bool, label: String) -> void:
	if value: print("PASS: ", label)
	else: failures.append(label); push_error("FAIL: " + label)

func _run() -> void:
	var arena := ARENA.instantiate(); root.add_child(arena); await _frames(3)
	for enemy in get_nodes_in_group("enemies"): enemy.queue_free()
	var player := get_first_node_in_group("player") as GuanditoPlayer
	player.global_position = Vector2(150, 190)
	var hound := HOUND.instantiate() as VLR03Hound; arena.add_child(hound); hound.global_position = Vector2(600, 190)
	await _frames(10)
	var phases: Array[int] = []
	hound.phase_changed.connect(func(p): phases.append(p))
	hound.activate()
	hound.health.current_health = hound.max_health / 2
	await _frames(5)
	_check(hound.phase == 2 and phases == [2], "HOUND enters phase 2 at half health")
	_check(hound.state == &"phase_shift", "phase change starts with a roar")
	var hp := hound.health.current_health
	var hit := AttackData.new(); hit.damage = 50
	hound._on_hit(hit, 1.0, null)
	_check(hound.health.current_health == hp, "roar is invulnerable")
	await _frames(90)
	_check(hound.state != &"phase_shift" and hound.tempo < 1.0, "phase 2 resumes faster")
	player.health.max_health = 9999; player.health.current_health = 9999
	var seen := {}
	for _index in range(900):
		await physics_frame
		seen[hound.last_attack] = true
		if hound.state == &"dead": break
	_check(seen.has(&"double_charge") or seen.has(&"burst"), "phase 2 uses its new patterns (%s)" % [seen.keys()])
	if failures.is_empty(): print("HOUND_PHASE_SMOKE: PASS"); quit(0)
	else: print("HOUND_PHASE_SMOKE: FAIL (", failures.size(), ")"); quit(1)
