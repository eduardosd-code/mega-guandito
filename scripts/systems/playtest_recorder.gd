class_name PlaytestRecorder
extends Node

const AUTOSAVE_INTERVAL := 20.0
const MAX_TIMELINE_EVENTS := 800
const DASH_CANCEL_WINDOW := 0.45

var enabled := true
var autosave_enabled := true
var export_dir_override := ""

var elapsed := 0.0
var session_id := ""
var last_saved_path := ""

var dashes_total := 0
var dash_cancels := 0
var dash_light_distances: Array = []
var dash_light_durations: Array = []

var dodges_started := 0
var perfect_evades := 0
var x2_exposed_hit_count := 0

var heavies_started := 0
var heavies_completed := 0
var heavies_interrupted := 0
var heavy_interrupt_progress: Array = []

var light_ignored_recovery := 0
var light_ignored_dodging := 0
var light_ignored_air_spent := 0
var light_ignored_other := 0

var dash_rejected_air := 0
var dash_rejected_cooldown := 0
var dash_rejected_busy := 0

var dodge_rejected_locked := 0
var dodge_rejected_air := 0
var dodge_rejected_cooldown := 0
var dodge_rejected_busy := 0

var jump_buffers_expired := 0
var attack_buffers_expired := 0

var _player: GuanditoPlayer
var _signals_connected := false
var _timeline: Array = []
var _damage_events: Array = []
var _health_before := -1
var _autosave_left := AUTOSAVE_INTERVAL

var _prev_dash_left := 0.0
var _prev_dodge_phase: StringName = &"normal"
var _prev_attacking := false
var _prev_current_attack: StringName = &""
var _prev_combo_step := 0
var _prev_buffer_left := 0.0
var _prev_buffered := false
var _prev_jump_buffer := 0.0
var _pending_cancel_until := -1.0
var _dash_start_pos := Vector2.ZERO
var _dash_start_time := 0.0
var _dash_facing := 1.0
var _maneuver_active := false
var _heavy_active := false
var _heavy_start_time := 0.0


func _ready() -> void:
	session_id = Time.get_datetime_string_from_system(false, true).replace(":", "").replace("-", "").replace(" ", "")
	add_to_group("playtest_recorder")
	process_mode = Node.PROCESS_MODE_ALWAYS


func _physics_process(delta: float) -> void:
	if not enabled:
		return
	elapsed += delta
	_acquire_player()
	if _player == null or not is_instance_valid(_player):
		return
	if _health_before < 0:
		_health_before = _player.health.current_health
	_connect_player_signals()
	_track_input_outcomes()
	_track_state_transitions()
	_track_buffers()
	_health_before = _player.health.current_health
	if autosave_enabled:
		_autosave_left -= delta
		if _autosave_left <= 0.0:
			_autosave_left = AUTOSAVE_INTERVAL
			save_report(false)


func _exit_tree() -> void:
	if enabled and _player != null and elapsed > 1.0:
		save_report(true)


func _acquire_player() -> void:
	if _player != null and is_instance_valid(_player):
		return
	_player = get_tree().get_first_node_in_group("player") as GuanditoPlayer


func _connect_player_signals() -> void:
	if _signals_connected:
		return
	_signals_connected = true
	var hurtbox := _player.get_node_or_null("Hurtbox") as HurtboxComponent
	if hurtbox:
		hurtbox.hit_received.connect(_on_hit_received)
	_player.health.died.connect(_on_died)
	_player.module_status.connect(func(text: String): _timeline_event("module_" + text.to_lower().replace(" ", "_")))
	_player.experience.level_changed.connect(func(level: int): _timeline_event("level_up_%d" % level))


func _track_input_outcomes() -> void:
	var p := _player
	var stunned := p.input_lock_left > 0.0 or p.hitstun_left > 0.0 or p.hitstop_left > 0.0
	if Input.is_action_just_pressed(&"dash"):
		if stunned:
			dash_rejected_busy += 1
		elif not p.is_on_floor():
			dash_rejected_air += 1
		elif p.dash_cooldown_left > 0.0:
			dash_rejected_cooldown += 1
		elif p.attacking or p.dash_left > 0.0 or p.dodge_phase != &"normal":
			dash_rejected_busy += 1
	if Input.is_action_just_pressed(&"dodge"):
		if not p.modules.has_effect(&"unlock_dodge"):
			dodge_rejected_locked += 1
		elif stunned:
			dodge_rejected_busy += 1
		elif not p.is_on_floor():
			dodge_rejected_air += 1
		elif p.dodge_cooldown_left > 0.0:
			dodge_rejected_cooldown += 1
		elif p.attacking or p.dash_left > 0.0 or p.dodge_phase != &"normal":
			dodge_rejected_busy += 1
	if Input.is_action_just_pressed(&"attack_light"):
		if stunned:
			light_ignored_other += 1
		elif p.attacking:
			if p.current_attack in [&"light_1", &"light_2", &"dash_light"]:
				pass
			else:
				light_ignored_recovery += 1
		elif p.dodge_phase != &"normal":
			light_ignored_dodging += 1
		elif p.dash_left > 0.0:
			pass
		elif not p.is_on_floor():
			if p.air_attack_spent:
				light_ignored_air_spent += 1
		elif p.combo_step == 0 or p.combo_left > 0.0:
			pass
		else:
			light_ignored_other += 1


func _track_state_transitions() -> void:
	var p := _player
	if p.dash_left > 0.0 and _prev_dash_left <= 0.0:
		dashes_total += 1
		_pending_cancel_until = elapsed + DASH_CANCEL_WINDOW
		_dash_start_pos = p.global_position
		_dash_start_time = elapsed
		_dash_facing = p.facing
		_timeline_event("dash")
	if p.dodge_phase == &"startup" and _prev_dodge_phase == &"normal":
		dodges_started += 1
		_timeline_event("dodge")
	var attack_now: StringName = p.current_attack
	if attack_now != &"" and attack_now != _prev_current_attack:
		_on_attack_started(attack_now)
	if _prev_attacking and not p.attacking:
		_on_attack_sequence_ended()
	_prev_dash_left = p.dash_left
	_prev_dodge_phase = p.dodge_phase
	_prev_attacking = p.attacking
	_prev_current_attack = attack_now
	_prev_combo_step = p.combo_step


func _track_buffers() -> void:
	var p := _player
	if _prev_buffered and not p.attack_buffered and p.attack_buffer_left <= 0.0 and _prev_buffer_left > 0.0 \
			and p.current_attack == _prev_current_attack and p.combo_step == _prev_combo_step and p.attacking:
		attack_buffers_expired += 1
		_timeline_event("attack_buffer_expired")
	if _prev_jump_buffer > 0.0 and p.jump_buffer_left <= 0.0 and p.is_on_floor():
		jump_buffers_expired += 1
		_timeline_event("jump_buffer_expired")
	_prev_jump_buffer = p.jump_buffer_left


func _on_attack_started(id: StringName) -> void:
	if id == &"dash_light" and elapsed <= _pending_cancel_until:
		dash_cancels += 1
		_maneuver_active = true
		_timeline_event("dash_to_light")
	if id == &"heavy":
		heavies_started += 1
		_heavy_active = true
		_heavy_start_time = elapsed
	_timeline_event("attack_" + String(id))


func _on_attack_sequence_ended() -> void:
	if _maneuver_active:
		_maneuver_active = false
		var displacement := (_player.global_position.x - _dash_start_pos.x) * _dash_facing
		if displacement > 0.0:
			dash_light_distances.append(snappedf(displacement, 0.1))
			dash_light_durations.append(snappedf(elapsed - _dash_start_time, 0.001))
	if _heavy_active:
		_heavy_active = false
		heavies_completed += 1
		_timeline_event("heavy_completed")


func _on_hit_received(data: AttackData, _direction: float, _attacker: Node) -> void:
	var hp_after := _player.health.current_health
	var dealt := _health_before - hp_after
	if dealt <= 0:
		perfect_evades += 1
		_timeline_event("perfect_evade")
	else:
		var base := maxi(1, int(round(data.damage)))
		var multiplier := snappedf(float(dealt) / float(base), 0.01)
		_damage_events.append({
			"t": snappedf(elapsed, 0.001),
			"damage": dealt,
			"base": base,
			"multiplier": multiplier,
			"exposed": multiplier >= 1.95,
		})
		if multiplier >= 1.95:
			x2_exposed_hit_count += 1
		_timeline_event("damage_%d" % dealt)
	if _heavy_active:
		_heavy_active = false
		heavies_interrupted += 1
		var heavy_data: AttackData = _player.ATTACKS[&"heavy"]
		heavy_interrupt_progress.append(clampf((elapsed - _heavy_start_time) / maxf(heavy_data.startup, 0.001), 0.0, 1.0))
		_timeline_event("heavy_interrupted")
	_health_before = hp_after


func _on_died() -> void:
	_heavy_active = false
	_maneuver_active = false
	_timeline_event("death")


func _timeline_event(event: String) -> void:
	_timeline.append({"t": snappedf(elapsed, 0.001), "event": event})
	while _timeline.size() > MAX_TIMELINE_EVENTS:
		_timeline.pop_front()


func build_report(final: bool = false) -> Dictionary:
	return {
		"meta": {
			"session_id": session_id,
			"elapsed_seconds": snappedf(elapsed, 0.01),
			"scene": _scene_name(),
			"engine": Engine.get_version_info().get("string", ""),
			"final": final,
		},
		"movement": {
			"dashes": dashes_total,
			"dash_to_light_cancels": dash_cancels,
			"cancel_ratio": _ratio(dash_cancels, dashes_total),
			"dash_light_distance_avg_px": _avg(dash_light_distances),
			"dash_light_distance_max_px": _max_of(dash_light_distances),
			"dash_light_duration_avg_s": _avg(dash_light_durations),
		},
		"evasion": {
			"dodges": dodges_started,
			"perfect_evades": perfect_evades,
			"perfect_ratio": _ratio(perfect_evades, dodges_started),
			"x2_exposed_hits": x2_exposed_hit_count,
			"hits_taken": _damage_events.size(),
			"total_damage_taken": _total_damage(),
		},
		"heavy": {
			"started": heavies_started,
			"completed": heavies_completed,
			"interrupted": heavies_interrupted,
			"punish_ratio": _ratio(heavies_interrupted, heavies_started),
			"interrupt_progress_avg": _avg(heavy_interrupt_progress),
		},
		"input_failures": {
			"light_ignored_recovery": light_ignored_recovery,
			"light_ignored_dodging": light_ignored_dodging,
			"light_ignored_air_spent": light_ignored_air_spent,
			"light_ignored_other": light_ignored_other,
			"dash_rejected_air": dash_rejected_air,
			"dash_rejected_cooldown": dash_rejected_cooldown,
			"dodge_rejected_locked": dodge_rejected_locked,
			"dodge_rejected_air": dodge_rejected_air,
			"dodge_rejected_cooldown": dodge_rejected_cooldown,
			"dodge_rejected_busy": dodge_rejected_busy,
			"jump_buffer_expired": jump_buffers_expired,
			"attack_buffer_expired": attack_buffers_expired,
		},
		"damage_events": _damage_events,
		"timeline": _timeline,
	}


func save_report(final: bool = false) -> String:
	var report := build_report(final)
	var dir := export_dir_override
	if dir.is_empty():
		dir = ProjectSettings.globalize_path("res://artifacts/playtest")
	DirAccess.make_dir_recursive_absolute(dir)
	var path := dir.path_join("playtest_%s.json" % session_id)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("PlaytestRecorder no pudo escribir %s" % path)
		return ""
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	last_saved_path = path
	_print_summary(report, path)
	return path


func _print_summary(report: Dictionary, path: String) -> void:
	var movement: Dictionary = report["movement"]
	var evasion: Dictionary = report["evasion"]
	var heavy: Dictionary = report["heavy"]
	var input_failures: Dictionary = report["input_failures"]
	var lost_inputs: int = int(input_failures["light_ignored_recovery"]) + int(input_failures["light_ignored_dodging"]) \
		+ int(input_failures["light_ignored_air_spent"]) + int(input_failures["light_ignored_other"]) \
		+ int(input_failures["dash_rejected_air"]) + int(input_failures["dash_rejected_cooldown"]) \
		+ int(input_failures["dodge_rejected_air"]) + int(input_failures["dodge_rejected_cooldown"]) \
		+ int(input_failures["dodge_rejected_busy"]) + int(input_failures["jump_buffer_expired"]) \
		+ int(input_failures["attack_buffer_expired"])
	print("=== PLAYTEST %s (%s%s) ===" % [session_id, _meta_scene(report), ", FINAL" if report["meta"]["final"] else ""])
	print("Tiempo: %.0fs | Entradas perdidas: %d | Danio recibido: %d en %d golpes (x2: %d)" % [
		float(report["meta"]["elapsed_seconds"]), lost_inputs,
		int(evasion["total_damage_taken"]), int(evasion["hits_taken"]), int(evasion["x2_exposed_hits"]),
	])
	print("Movimiento: %d dashes, %d cancelados a Light (%.0f%%), distancia Dash-Light media %.0f px" % [
		int(movement["dashes"]), int(movement["dash_to_light_cancels"]),
		float(movement["cancel_ratio"]) * 100.0, float(movement["dash_light_distance_avg_px"]),
	])
	print("Evasion: %d esquivas, %d perfectos (%.0f%%)" % [
		int(evasion["dodges"]), int(evasion["perfect_evades"]), float(evasion["perfect_ratio"]) * 100.0,
	])
	print("Heavy: %d iniciados, %d castigados (%.0f%%) a %.0f%% del startup" % [
		int(heavy["started"]), int(heavy["interrupted"]), float(heavy["punish_ratio"]) * 100.0,
		float(heavy["interrupt_progress_avg"]) * 100.0,
	])
	print("Informe: %s" % path)


func _meta_scene(report: Dictionary) -> String:
	return String(report["meta"].get("scene", "?"))


func _scene_name() -> String:
	var scene := get_tree().current_scene
	if scene == null or scene.scene_file_path.is_empty():
		var node: Node = self
		while node != null and node.scene_file_path.is_empty():
			node = node.get_parent()
		if node != null:
			return node.scene_file_path.get_file()
		return "unknown"
	return scene.scene_file_path.get_file()


static func _ratio(part: int, total: int) -> float:
	return float(part) / float(total) if total > 0 else 0.0


static func _avg(values: Array) -> float:
	if values.is_empty():
		return 0.0
	var sum := 0.0
	for value in values:
		sum += float(value)
	return sum / values.size()


static func _max_of(values: Array) -> float:
	if values.is_empty():
		return 0.0
	var best := -INF
	for value in values:
		best = maxf(best, float(value))
	return best


func _total_damage() -> int:
	var total := 0
	for event in _damage_events:
		total += int(event["damage"])
	return total
