extends SceneTree

const PLAYER := preload("res://scenes/player/guandito.tscn")
const REQUIRED := [
	&"idle", &"run", &"jump_start", &"jump_up", &"fall", &"land",
	&"dash_start", &"dash", &"dash_end", &"light_1", &"light_2", &"light_3",
	&"heavy_start", &"heavy_attack", &"heavy_recovery", &"air_light",
	&"dodge_start", &"dodge_invulnerable", &"dodge_exposed", &"hit", &"death",
	&"module_install"
]
const FX_PATHS := [
	"res://scenes/effects/impact_light_fx.tscn",
	"res://scenes/effects/kinetic_pulse_fx.tscn",
	"res://scenes/effects/heavy_impact_fx.tscn",
	"res://scenes/effects/dash_trail_fx.tscn",
	"res://scenes/effects/dodge_trail_fx.tscn",
	"res://scenes/effects/exposed_fx.tscn",
	"res://scenes/effects/module_install_fx.tscn"
]

var failures: Array[String] = []

func _initialize() -> void: call_deferred("_run")
func _check(value: bool, label: String) -> void:
	if value: print("PASS: ", label)
	else: failures.append(label); push_error("FAIL: " + label)

func _run() -> void:
	var player := PLAYER.instantiate() as GuanditoPlayer
	root.add_child(player)
	await process_frame
	var visual := player.visual
	_check(visual.FRAME_SIZE == Vector2i(64, 64), "visual pipeline uses a 64x64 logical frame")
	_check(visual.FOOT_PIVOT == Vector2.ZERO and visual.position == Vector2(0, 20), "visual origin is aligned to physics feet")
	for animation_name in REQUIRED:
		_check(animation_name in visual.available_animations(), "animation registered: " + animation_name)
		_check(visual.sprite.sprite_frames.has_animation(animation_name), "SpriteFrames contains: " + animation_name)
		_check(visual.sprite.sprite_frames.get_frame_count(animation_name) > 0, "PNG frames load: " + animation_name)
	var heavy_recovery_first := visual.sprite.sprite_frames.get_frame_texture(&"heavy_recovery", 0) as AtlasTexture
	_check(heavy_recovery_first != null and heavy_recovery_first.atlas.resource_path.ends_with("heavy_attack.png") and heavy_recovery_first.region.position.x == 128.0, "heavy recovery starts from the impact pose")
	visual.set_visor_expression(&"system_active")
	visual.set_reactor_state(&"kinetic_charge")
	_check(visual.visor_expression == &"system_active", "visor expression layer is independent")
	_check(visual.reactor_state == &"kinetic_charge", "reactor feedback layer is independent")
	_check(player.get_node("Hurtbox").get_parent() == player, "hurtbox remains independent from visual")
	_check(player.get_node("AttackHitbox").get_parent() == player, "attack hitbox remains independent from visual")
	_check(ProjectSettings.get_setting("rendering/textures/canvas_textures/default_texture_filter") == 0, "nearest texture filtering is enabled")
	_check(ProjectSettings.get_setting("rendering/2d/snap/snap_2d_transforms_to_pixel"), "2D transform pixel snapping is enabled")
	for path in FX_PATHS:
		var scene := load(path) as PackedScene
		var instance := scene.instantiate() if scene else null
		_check(instance is Node2D, "reusable FX loads: " + path.get_file())
		if instance: instance.free()
	player.free()
	if failures.is_empty(): print("PHASE4_VISUAL_SMOKE: PASS"); quit(0)
	else: print("PHASE4_VISUAL_SMOKE: FAIL (", failures.size(), ")"); quit(1)
