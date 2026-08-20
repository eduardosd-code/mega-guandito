class_name GuanditoVisual
extends Node2D

signal animation_changed(animation_name: StringName)

const FRAME_SIZE := Vector2i(64, 64)
const FOOT_PIVOT := Vector2(0, 0)
const SPRITE_LIBRARY := preload("res://scripts/components/player/guandito_sprite_library.gd")
const LOOPING := [&"idle", &"run", &"jump_up", &"fall", &"dash", &"dodge_invulnerable"]
const SUPPORTED_ANIMATIONS := [
	&"idle", &"run", &"jump_start", &"jump_up", &"fall", &"land",
	&"dash_start", &"dash", &"dash_end", &"light_1", &"light_2", &"light_3",
	&"heavy_start", &"heavy_attack", &"heavy_recovery", &"air_light",
	&"dodge_start", &"dodge_invulnerable", &"dodge_exposed", &"hit", &"death",
	&"module_install"
]

var facing := 1.0
var action: StringName = &"idle"
var action_time := 0.0
var visor_expression: StringName = &"neutral"
var reactor_state: StringName = &"normal"
@onready var sprite: AnimatedSprite2D = $Sprite

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.sprite_frames = SPRITE_LIBRARY.build()
	sprite.play(&"idle")
	queue_redraw()

func _process(delta: float) -> void:
	action_time += delta
	sprite.flip_h = facing < 0.0
	_update_automatic_phase()
	queue_redraw()

func set_action(value: StringName, look_direction: float) -> void:
	value = _normalize_legacy_action(value)
	if action == &"jump_start" and action_time < 0.08 and value == &"jump_up":
		return
	if action == &"land" and action_time < 0.07 and value in [&"idle", &"run"]:
		return
	if action == &"dash_end" and action_time < 0.05 and value in [&"idle", &"run"]:
		return
	if value not in SUPPORTED_ANIMATIONS:
		push_warning("Guandito visual placeholder has no animation named %s" % value)
		value = &"idle"
	facing = signf(look_direction) if look_direction != 0.0 else facing
	if action == value:
		return
	action = value
	action_time = 0.0
	_update_feedback_layers()
	if sprite.sprite_frames.has_animation(action):
		sprite.play(action)
	_request_fx_for_action()
	animation_changed.emit(action)
	queue_redraw()

func set_visor_expression(value: StringName) -> void:
	visor_expression = value
	queue_redraw()

func set_reactor_state(value: StringName) -> void:
	reactor_state = value
	queue_redraw()

func available_animations() -> Array[StringName]:
	return SUPPORTED_ANIMATIONS.duplicate()

func _normalize_legacy_action(value: StringName) -> StringName:
	match value:
		&"jump": return &"jump_up"
		&"attack": return &"light_1"
		&"heavy": return &"heavy_attack"
		&"dodge_startup": return &"dodge_start"
		&"dodge_evade": return &"dodge_invulnerable"
		&"dead": return &"death"
		_: return value

func _update_automatic_phase() -> void:
	if action == &"jump_start" and action_time >= 0.08:
		set_action(&"jump_up", facing)
	elif action == &"dash_start" and action_time >= 0.035:
		set_action(&"dash", facing)
	elif action in [&"land", &"dash_end"] and action_time >= (0.07 if action == &"land" else 0.05):
		set_action(&"idle", facing)
	elif action == &"module_install" and action_time >= 0.65:
		set_action(&"idle", facing)

func _update_feedback_layers() -> void:
	visor_expression = &"angry" if action in [&"light_1", &"light_2", &"light_3", &"heavy_start", &"heavy_attack", &"air_light"] else &"neutral"
	if action == &"dodge_invulnerable":
		reactor_state = &"dodge"
	elif action == &"dodge_exposed":
		reactor_state = &"exposed"
	elif action == &"module_install":
		reactor_state = &"module_install"
	elif action == &"light_3":
		reactor_state = &"kinetic_charge"
	else:
		reactor_state = &"normal"

func _request_fx_for_action() -> void:
	var kind := ""
	match action:
		&"dash_start": kind = "dash_trail"
		&"dodge_invulnerable": kind = "dodge_trail"
		&"dodge_exposed": kind = "exposed"
		&"module_install": kind = "module_install"
	if kind.is_empty():
		return
	var manager := get_tree().get_first_node_in_group("game_manager")
	if manager and manager.has_method("spawn_player_fx"):
		manager.spawn_player_fx(global_position + Vector2(0, -22), kind, facing)

func _draw() -> void:
	if is_instance_valid(sprite) and sprite.visible:
		return
	# Technical 64x64 placeholder. Origin is the center of the feet; runtime art
	# can replace this renderer without changing gameplay nodes or hitboxes.
	var green := Color("#456b24")
	var dark_green := Color("#263d1c")
	var lime := Color("#93e22b")
	var graphite := Color("#11181b")
	var metal := Color("#d9ddd5")
	var metal_shadow := Color("#747c76")
	var outline := Color("#071011")
	var orange := Color("#ff7138")
	var red := Color("#df3f32")
	var phase := action_time * (10.0 if action == &"run" else 5.0)
	var bob: float = round(sin(phase)) if action in [&"idle", &"run"] else 0.0
	var lean := 0.0
	if action in [&"run", &"dash_start", &"dash", &"dodge_start", &"dodge_invulnerable"]:
		lean = 3.0 * facing
	elif action in [&"heavy_start", &"heavy_recovery"]:
		lean = -2.0 * facing
	var crouch := 4.0 if action in [&"jump_start", &"land", &"dash_start", &"dodge_start"] else 0.0
	var body_origin := Vector2(lean, -22 + bob + crouch)

	# Rear cables are silhouette elements, never collision geometry.
	draw_polyline(PackedVector2Array([body_origin + Vector2(-5 * facing, -8), body_origin + Vector2(-17 * facing, -13), body_origin + Vector2(-23 * facing, -7)]), outline, 3.0)
	draw_polyline(PackedVector2Array([body_origin + Vector2(-5 * facing, -6), body_origin + Vector2(-15 * facing, -2), body_origin + Vector2(-20 * facing, 4)]), dark_green, 2.0)
	draw_circle(body_origin + Vector2(-23 * facing, -7), 2.0, lime)

	# Heavy boots and segmented legs.
	var stride: float = round(sin(phase) * 3.0) if action == &"run" else 0.0
	_draw_boot(Vector2(-7 + stride, -2), green, metal, outline)
	_draw_boot(Vector2(7 - stride, -2), green, metal, outline)
	draw_line(body_origin + Vector2(-5, 8), Vector2(-7 + stride, -7), graphite, 6.0)
	draw_line(body_origin + Vector2(5, 8), Vector2(7 - stride, -7), graphite, 6.0)
	draw_rect(Rect2(body_origin + Vector2(-9, 5), Vector2(7, 6)), metal_shadow)
	draw_rect(Rect2(body_origin + Vector2(2, 5), Vector2(7, 6)), metal_shadow)

	# Industrial torso armor and independent reactor layer.
	draw_circle(body_origin, 12.0, outline)
	draw_circle(body_origin, 10.0, green)
	draw_rect(Rect2(body_origin + Vector2(-8, -8), Vector2(16, 5)), dark_green)
	draw_circle(body_origin + Vector2(0, 1), 5.0, metal)
	var reactor_color := lime
	if reactor_state == &"exposed": reactor_color = orange
	elif reactor_state == &"low_health": reactor_color = red
	elif reactor_state in [&"dodge", &"module_install", &"kinetic_charge"]: reactor_color = Color("#c8ff68")
	var pulse := 0.6 + sin(action_time * 12.0) * 0.2
	draw_circle(body_origin + Vector2(0, 1), 3.0 + pulse, Color(reactor_color, 0.22))
	draw_circle(body_origin + Vector2(0, 1), 2.5, reactor_color)

	# Arms and official kinetic pulse hammer placeholder.
	draw_line(body_origin + Vector2(-9, -5), body_origin + Vector2(-14, 6), graphite, 6.0)
	draw_line(body_origin + Vector2(9, -5), body_origin + Vector2(14, 6), graphite, 6.0)
	draw_rect(Rect2(body_origin + Vector2(-18, 2), Vector2(7, 10)), metal)
	draw_rect(Rect2(body_origin + Vector2(11, 2), Vector2(7, 10)), metal)
	if action in [&"light_1", &"light_2", &"light_3", &"heavy_start", &"heavy_attack", &"heavy_recovery", &"air_light"]:
		_draw_hammer(body_origin, lime, graphite, metal, outline)

	# Helmet, side sensors and visor are a separate readable layer.
	var head := body_origin + Vector2(0, -17)
	draw_circle(head, 13.0, outline)
	draw_circle(head, 11.0, dark_green)
	draw_rect(Rect2(head + Vector2(-10, -10), Vector2(20, 8)), metal)
	draw_rect(Rect2(head + Vector2(-10, -4), Vector2(20, 10)), graphite)
	draw_circle(head + Vector2(-12, 0), 4.0, metal_shadow)
	draw_circle(head + Vector2(12, 0), 4.0, metal_shadow)
	draw_circle(head + Vector2(-12, 0), 2.0, lime)
	draw_circle(head + Vector2(12, 0), 2.0, lime)
	_draw_visor_expression(head, lime)
	draw_line(head + Vector2(8, -10), head + Vector2(10, -17), metal, 2.0)
	draw_circle(head + Vector2(10, -18), 1.5, lime)

	# Unit marking, exposed warning and death readability.
	draw_string(ThemeDB.fallback_font, body_origin + Vector2(5, -7), "01", HORIZONTAL_ALIGNMENT_LEFT, -1, 5, metal)
	if action == &"dodge_exposed":
		draw_arc(body_origin, 15, 0, TAU, 20, orange, 2.0)
		draw_line(head + Vector2(-3, -18), head + Vector2(3, -12), orange, 2.0)
		draw_line(head + Vector2(3, -18), head + Vector2(-3, -12), orange, 2.0)
	if action == &"death":
		modulate = Color("#596265")
	else:
		modulate = Color.WHITE

func _draw_boot(center: Vector2, green: Color, metal: Color, outline: Color) -> void:
	draw_rect(Rect2(center + Vector2(-6, -7), Vector2(11, 8)), outline)
	draw_rect(Rect2(center + Vector2(-5, -6), Vector2(9, 6)), green)
	draw_rect(Rect2(center + Vector2(-3, -6), Vector2(5, 3)), metal)

func _draw_hammer(body_origin: Vector2, lime: Color, graphite: Color, metal: Color, outline: Color) -> void:
	var raised := action in [&"heavy_start", &"heavy_attack"]
	var center := body_origin + Vector2((24 if not raised else 18) * facing, -9 if not raised else -22)
	draw_line(body_origin + Vector2(12 * facing, 4), center, graphite, 5.0)
	draw_rect(Rect2(center - Vector2(8, 6), Vector2(16, 12)), outline)
	draw_rect(Rect2(center - Vector2(6, 4), Vector2(12, 8)), metal)
	draw_rect(Rect2(center + Vector2(-1 if facing > 0 else -5, -3), Vector2(6, 6)), lime)

func _draw_visor_expression(head: Vector2, lime: Color) -> void:
	match visor_expression:
		&"alert":
			draw_rect(Rect2(head + Vector2(-5, -1), Vector2(3, 4)), lime)
			draw_rect(Rect2(head + Vector2(2, -1), Vector2(3, 4)), lime)
		&"angry":
			draw_line(head + Vector2(-6, -2), head + Vector2(-2, 1), lime, 2.0)
			draw_line(head + Vector2(6, -2), head + Vector2(2, 1), lime, 2.0)
		&"surprised":
			draw_circle(head + Vector2(-4, 0), 2.0, lime)
			draw_circle(head + Vector2(4, 0), 2.0, lime)
		&"happy":
			draw_arc(head + Vector2(-4, 1), 2.5, PI, TAU, 5, lime, 1.5)
			draw_arc(head + Vector2(4, 1), 2.5, PI, TAU, 5, lime, 1.5)
		&"system_active":
			draw_line(head + Vector2(-7, 0), head + Vector2(7, 0), lime, 2.0)
			draw_line(head + Vector2(0, -3), head + Vector2(0, 3), lime, 1.0)
		_:
			draw_rect(Rect2(head + Vector2(-6, -1), Vector2(4, 3)), lime)
			draw_rect(Rect2(head + Vector2(2, -1), Vector2(4, 3)), lime)
