extends SceneTree

const LAB := preload("res://scenes/levels/combat_lab.tscn")
const MIXED := preload("res://resources/encounters/combat_lab_mixed.tres")
const LIGHT := preload("res://resources/data/attack_light_1.tres")
const HEAVY := preload("res://resources/data/attack_heavy.tres")
var failures: Array[String] = []

func _initialize() -> void: call_deferred("_run")
func _frames(count: int) -> void:
	for _index in range(count): await physics_frame
func _check(value: bool, label: String) -> void:
	if value: print("PASS: ", label)
	else: failures.append(label); push_error("FAIL: " + label)

func _run() -> void:
	var lab := LAB.instantiate() as CombatLab; root.add_child(lab); await _frames(8)
	_check(lab.player != null and lab.player.modules.has_effect(&"unlock_dodge"), "Combat Lab starts with Guandito and Overdrive Evasion")

	# TEST 1 — Guandito vs Scrapper.
	var scrapper := lab.spawn_role(SectorEnemy.Role.SCRAPPER); await _frames(2)
	_check(scrapper.balance.max_health == 45 and scrapper.balance.attack_1_damage == 8 and scrapper.balance.attack_2_damage == 12, "TEST 1 Scrapper pressure balance")
	lab.clear_enemies(); await _frames(2)

	# TEST 2 — Guandito vs 3 Scrappers.
	for offset in [-130.0, 0.0, 130.0]: lab.spawn_role(SectorEnemy.Role.SCRAPPER, Vector2(480 + offset, 205))
	await _frames(2)
	_check(get_nodes_in_group("sector_enemies").size() == 3, "TEST 2 three Scrappers spawn")
	lab.clear_enemies(); await _frames(2)

	# TEST 3 — Guandito vs Sentry.
	var sentry := lab.spawn_role(SectorEnemy.Role.SENTRY); await _frames(2); sentry._fire_sentry_projectile(); await _frames(2)
	_check(sentry.balance.max_health == 35 and get_nodes_in_group("enemy_projectiles").size() == 1, "TEST 3 Sentry uses independent projectile")
	lab.clear_enemies(); await _frames(2)

	# TEST 4 — Scrapper + Sentry.
	lab.spawn_role(SectorEnemy.Role.SCRAPPER, Vector2(360, 205)); lab.spawn_role(SectorEnemy.Role.SENTRY, Vector2(650, 155)); await _frames(2)
	_check(get_nodes_in_group("sector_enemies").size() == 2, "TEST 4 mixed pressure and ranged pair")
	lab.clear_enemies(); await _frames(2)

	# TEST 5 — Bulwark: Light damages without full hitstun; Heavy breaks Armor.
	var bulwark := lab.spawn_role(SectorEnemy.Role.BULWARK); await _frames(2); var hp_before := bulwark.health.current_health
	bulwark._on_hit(LIGHT, 1.0, lab.player)
	_check(bulwark.health.current_health == hp_before - LIGHT.damage and bulwark.hitstun == 0.0, "TEST 5 Light damages Armor without full hitstun")
	bulwark._on_hit(HEAVY, 1.0, lab.player)
	_check(bulwark.armor_broken_left > 1.0 and bulwark.state == &"armor_broken", "TEST 5 Heavy triggers Armor Break")
	lab.clear_enemies(); await _frames(2)

	# TEST 6 — Bulwark + 2 Scrappers.
	lab.spawn_role(SectorEnemy.Role.BULWARK, Vector2(600, 205)); lab.spawn_role(SectorEnemy.Role.SCRAPPER, Vector2(330, 205)); lab.spawn_role(SectorEnemy.Role.SCRAPPER, Vector2(430, 205)); await _frames(2)
	_check(get_nodes_in_group("sector_enemies").size() == 3, "TEST 6 Bulwark and two Scrappers")
	lab.clear_enemies(); await _frames(2)

	# TEST 7 — canonical encounter preset.
	lab.spawn_encounter(MIXED); await _frames(2)
	var roles := {}; for enemy in get_nodes_in_group("sector_enemies"): roles[enemy.role] = int(roles.get(enemy.role, 0)) + 1
	_check(roles.get(0, 0) == 2 and roles.get(1, 0) == 1 and roles.get(2, 0) == 1, "TEST 7 preset creates 2 Scrappers + Bulwark + Sentry")
	lab.clear_enemies(); await _frames(2)

	# TEST 8 — HOUND miniboss configuration and contextual selection.
	var hound := lab.spawn_hound(); await _frames(2)
	_check(hound.max_health == 850 and hound.state != &"dormant", "TEST 8 HOUND activates with miniboss health")
	hound.global_position.x = lab.player.global_position.x + 300.0; hound.state = &"idle"; hound.last_attack = &"charge"; hound._choose_attack(); await _frames(1)
	_check(hound.state == &"burst_warning", "TEST 8 far HOUND avoids repeated Charge")
	lab.clear_enemies(); await _frames(2)

	_check(lab.status_label.text.contains("PLAYER") and lab.status_label.text.contains("ENEMIES"), "Combat Lab debug HUD reports combat state")
	if failures.is_empty(): print("PHASE7_COMBAT_LAB_SMOKE: PASS"); quit(0)
	else: print("PHASE7_COMBAT_LAB_SMOKE: FAIL (", failures.size(), ")"); quit(1)
