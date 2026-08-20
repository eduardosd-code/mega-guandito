extends CanvasLayer

@onready var player: GuanditoPlayer = get_tree().get_first_node_in_group("player")
@onready var health_bar: ProgressBar = %HealthBar
@onready var xp_bar: ProgressBar = %XPBar
@onready var level_label: Label = %LevelLabel
@onready var reactor_label: Label = %ReactorLabel
@onready var module_label: Label = %ModuleLabel
@onready var combat_debug_text: Label = %CombatDebugText
@onready var boss_panel: PanelContainer = %BossPanel
@onready var boss_bar: ProgressBar = %BossBar
@onready var context_label: Label = %ContextLabel
@onready var context_panel: PanelContainer = %ContextPanel
var perfect_message_left := 0.0

func _ready() -> void:
	if not player:
		return
	player.health.health_changed.connect(_on_health)
	player.experience.experience_changed.connect(_on_xp)
	player.experience.level_changed.connect(_on_level)
	player.modules.energy_changed.connect(_on_energy)
	player.module_status.connect(_on_module_status)
	player.perfect_evade.connect(_on_perfect_evade)
	%CombatDebugPanel.add_to_group("combat_debug_hud")
	%CombatDebugPanel.visible = OS.is_debug_build()
	_on_health(player.health.current_health, player.health.max_health)
	_on_xp(player.experience.current_xp, player.experience.xp_for_next_level())
	_on_level(player.experience.current_level)
	_on_energy(player.modules.energy_used(), player.modules.reactor_capacity)
	boss_panel.visible = false
	context_panel.visible = false

func _process(delta: float) -> void:
	if not player:
		return
	var boss := get_tree().get_first_node_in_group("boss") as VLR03Hound
	if boss and boss.state not in [&"dormant", &"dead"]:
		boss_panel.visible = true; boss_bar.max_value = boss.health.max_health; boss_bar.value = boss.health.current_health
	else:
		boss_panel.visible = false
	if not OS.is_debug_build():
		return
	perfect_message_left = maxf(0.0, perfect_message_left - delta)
	var exposure := "EXPOSED x%.1f" % player.exposed_damage_multiplier if player.dodge_phase == &"exposed" else "NORMAL"
	combat_debug_text.text = "STATE: %s\nCOMBO: %d / 3\nATTACK BUFFER: %s\nGROUNDED: %s\nDODGE: %s\nEXPOSURE: %s\nPERFECT EVADE: %d%s" % [
		String(player.state_machine.current).to_upper(),
		player.combo_step,
		"TRUE" if player.attack_buffered else "FALSE",
		"TRUE" if player.is_on_floor() else "FALSE",
		player.dodge_debug_status(),
		exposure,
		player.perfect_evade_count,
		"  PERFECT!" if perfect_message_left > 0.0 else ""
	]

func _on_health(current: int, maximum: int) -> void:
	health_bar.max_value = maximum
	health_bar.value = current
	%HealthText.text = "HP %d / %d" % [current, maximum]

func _on_xp(current: int, required: int) -> void:
	xp_bar.max_value = required
	xp_bar.value = current
	%XPText.text = "XP %d / %d" % [current, required]

func _on_level(level: int) -> void:
	level_label.text = "GND-01  NIVEL %d" % level

func _on_energy(used: int, maximum: int) -> void:
	reactor_label.text = "REACTOR %d / %d" % [used, maximum]

func _on_module_status(text: String) -> void:
	context_label.text = text
	context_panel.visible = true
	var tween := create_tween()
	context_label.modulate.a = 1.0
	tween.tween_interval(1.6)
	tween.tween_property(context_label, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func(): context_panel.visible = false)

func _on_perfect_evade(_total: int) -> void:
	perfect_message_left = 0.8
