extends SceneTree

const ENEMY := preload("res://scenes/enemies/sector_enemy.tscn")
const HOUND := preload("res://scenes/enemies/vlr03_hound.tscn")
const VISUAL_TEST := preload("res://scenes/levels/enemy_visual_test.tscn")
var failures: Array[String] = []

func _initialize() -> void: call_deferred("_run")
func _check(value: bool, label: String) -> void:
	if value: print("PASS: ", label)
	else: failures.append(label); push_error("FAIL: " + label)

func _run() -> void:
	var expected := {
		0: [&"idle", &"run", &"attack_1", &"attack_2", &"hit", &"death"],
		1: [&"idle", &"walk", &"attack_hammer_fist", &"attack_charge", &"attack_backhand", &"hit", &"death"],
		2: [&"hover_idle", &"move", &"pulse_shot", &"triple_pulse", &"hit", &"death"]
	}
	for role: int in expected:
		var enemy := ENEMY.instantiate() as SectorEnemy; enemy.role = role; root.add_child(enemy); await process_frame
		for animation: StringName in expected[role]: _check(enemy.sprite.sprite_frames.has_animation(animation), "role %d animation %s" % [role, animation])
		_check(enemy.get_node("Hurtbox").get_parent() == enemy and enemy.get_node("AttackHitbox").get_parent() == enemy, "role %d keeps collisions independent" % role)
		enemy.facing = -1; enemy._update_visual(); _check(enemy.sprite.flip_h, "role %d flips left" % role); enemy.queue_free(); await process_frame
	var hound := HOUND.instantiate() as VLR03Hound; root.add_child(hound); await process_frame
	for animation: StringName in [&"idle", &"walk_prowl", &"charge", &"pounce", &"claw_combo", &"energy_burst", &"hit", &"death"]: _check(hound.sprite.sprite_frames.has_animation(animation), "HOUND animation " + animation)
	_check(hound.sprite.sprite_frames.get_frame_texture(&"idle", 0).get_size() == Vector2(160, 96), "HOUND keeps a large 160x96 canvas")
	var gallery := VISUAL_TEST.instantiate(); _check(gallery != null and gallery.get_child_count() == 5, "EnemyVisualTest contains Guandito and four enemies"); gallery.free(); hound.free()
	if failures.is_empty(): print("PHASE6_ENEMY_VISUAL_SMOKE: PASS"); quit(0)
	else: print("PHASE6_ENEMY_VISUAL_SMOKE: FAIL (", failures.size(), ")"); quit(1)
