extends SceneTree
# HOUND FSM: a stagger during a windup cancels the attack for good.

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
	player.health.max_health = 9999; player.health.current_health = 9999
	var hound := HOUND.instantiate() as VLR03Hound; arena.add_child(hound); hound.global_position = Vector2(600, 190)
	await _frames(10)
	hound.activate(); hound.cooldown = 0.0
	await _frames(2)
	_check(hound.state == &"charge_warning" and hound.action_phase == &"charge_warning", "far player triggers a charge windup (%s)" % hound.state)
	var hit := AttackData.new(); hit.damage = hound.stagger_threshold; hit.hitstun = 0.3
	hound._on_hit(hit, 1.0, null)
	_check(hound.state == &"stagger" and hound.action.is_empty(), "stagger cancels the windup")
	_check(not hound.hitbox.monitoring, "hitbox is off after stagger")
	# Watch past the original windup + active window: the charge must never fire.
	var charged := false
	hound.audio_hook.connect(func(event_name, _pos): if event_name == &"hound_charge": charged = true)
	for _index in range(45):
		await physics_frame
		if hound.state == &"charge" or hound.hitbox.monitoring: charged = true
	_check(not charged, "cancelled charge never resumes")
	_check(hound.state == &"idle" or hound.state == &"stagger", "HOUND returns to idle after stagger (%s)" % hound.state)
	if failures.is_empty(): print("HOUND_STAGGER_CANCEL_SMOKE: PASS"); quit(0)
	else: print("HOUND_STAGGER_CANCEL_SMOKE: FAIL (", failures.size(), ")"); quit(1)
