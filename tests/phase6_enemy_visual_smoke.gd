extends SceneTree

const ENEMY := preload("res://scenes/enemies/sector_enemy.tscn")
const HOUND := preload("res://scenes/enemies/vlr03_hound.tscn")
const VISUAL_TEST := preload("res://scenes/levels/enemy_visual_test.tscn")
const SCRAPPER_FX := [
	"res://scenes/effects/scrapper_impact_fx.tscn",
	"res://scenes/effects/scrapper_charge_trail_fx.tscn",
	"res://scenes/effects/scrapper_sparks_fx.tscn"
]
const BULWARK_FX := [
	"res://scenes/effects/bulwark_heavy_impact_fx.tscn",
	"res://scenes/effects/bulwark_charge_trail_fx.tscn",
	"res://scenes/effects/bulwark_backhand_arc_fx.tscn"
]
const SENTRY_FX := [
	"res://scenes/effects/sentry_projectile_fx.tscn",
	"res://scenes/effects/sentry_muzzle_flash_fx.tscn",
	"res://scenes/effects/sentry_hit_sparks_fx.tscn"
]
const HOUND_FX := [
	"res://scenes/effects/hound_charge_trail_fx.tscn", "res://scenes/effects/hound_pounce_impact_fx.tscn",
	"res://scenes/effects/hound_claw_slash_fx.tscn", "res://scenes/effects/hound_energy_projectile_fx.tscn",
	"res://scenes/effects/hound_energy_burst_fx.tscn", "res://scenes/effects/hound_destroy_fx.tscn"
]
var failures: Array[String] = []

func _initialize() -> void: call_deferred("_run")
func _check(value: bool, label: String) -> void:
	if value: print("PASS: ", label)
	else: failures.append(label); push_error("FAIL: " + label)

func _animation_frames_are_unique(frames: SpriteFrames, animation: StringName) -> bool:
	var seen: Array[PackedByteArray] = []
	for frame_index: int in range(frames.get_frame_count(animation)):
		var pixels := frames.get_frame_texture(animation, frame_index).get_image().get_data()
		for previous: PackedByteArray in seen:
			if pixels == previous:
				return false
		seen.append(pixels)
	return true

func _run() -> void:
	var expected := {
		0: [&"idle", &"run", &"attack_1", &"attack_2", &"hit", &"death"],
		1: [&"idle", &"walk", &"attack_hammer_fist", &"attack_charge", &"attack_backhand", &"hit", &"death"],
		2: [&"hover_idle", &"move", &"pulse_shot", &"triple_pulse", &"hit", &"death"]
	}
	for role: int in expected:
		var enemy := ENEMY.instantiate() as SectorEnemy; enemy.role = role; root.add_child(enemy); await process_frame
		for animation: StringName in expected[role]: _check(enemy.sprite.sprite_frames.has_animation(animation), "role %d animation %s" % [role, animation])
		if role == SectorEnemy.Role.SCRAPPER:
			_check(enemy.sprite.sprite_frames.get_frame_texture(&"idle", 0).get_size() == Vector2(64, 64), "Scrapper locomotion uses 64x64 frames")
			_check(enemy.sprite.sprite_frames.get_frame_texture(&"attack_1", 0).get_size() == Vector2(96, 64), "Scrapper attacks preserve weapon reach in 96x64 frames")
			_check(enemy.sprite.position.y == -11.0, "Scrapper visible feet align with grounded collision")
		elif role == SectorEnemy.Role.BULWARK:
			_check(enemy.sprite.sprite_frames.get_frame_texture(&"idle", 0).get_size() == Vector2(96, 96), "Bulwark locomotion uses 96x96 frames")
			_check(enemy.sprite.sprite_frames.get_frame_texture(&"attack_charge", 0).get_size() == Vector2(128, 96), "Bulwark attacks preserve heavy reach in 128x96 frames")
			_check(enemy.sprite.position.y == -27.0, "Bulwark visible feet align with grounded collision")
		elif role == SectorEnemy.Role.SENTRY:
			_check(enemy.sprite.sprite_frames.get_frame_texture(&"hover_idle", 0).get_size() == Vector2(64, 64), "Sentry uses a centered 64x64 floating canvas")
			_check(enemy.sprite.sprite_frames.get_frame_texture(&"death", 0).get_size() == Vector2(96, 64), "Sentry death preserves fragments in a 96x64 canvas")
		_check(enemy.get_node("Hurtbox").get_parent() == enemy and enemy.get_node("AttackHitbox").get_parent() == enemy, "role %d keeps collisions independent" % role)
		enemy.facing = -1; enemy._update_visual(); _check(enemy.sprite.flip_h, "role %d flips left" % role); enemy.queue_free(); await process_frame
	var hound := HOUND.instantiate() as VLR03Hound; root.add_child(hound); await process_frame
	for animation: StringName in [&"idle", &"walk_prowl", &"charge", &"pounce", &"claw_combo", &"energy_burst", &"hit", &"death"]: _check(hound.sprite.sprite_frames.has_animation(animation), "HOUND animation " + animation)
	_check(hound.sprite.sprite_frames.get_frame_texture(&"idle", 0).get_size() == Vector2(160, 96), "HOUND keeps a large 160x96 canvas")
	_check(hound.sprite.position.y == -24.0, "HOUND visible feet align with grounded collision")
	_check(hound.sprite.sprite_frames.get_frame_count(&"energy_burst") == 8 and hound.sprite.sprite_frames.get_frame_count(&"death") == 8, "HOUND cleanup preserves production frame counts")
	for animation: StringName in [&"energy_burst", &"hit", &"death"]:
		_check(_animation_frames_are_unique(hound.sprite.sprite_frames, animation), "HOUND %s uses distinct production frames" % animation)
	for effect_index: int in range(SCRAPPER_FX.size()):
		var path: String = SCRAPPER_FX[effect_index]
		var effect := (load(path) as PackedScene).instantiate(); root.add_child(effect); await process_frame
		var effect_sprite := effect.get_node("Sprite") as AnimatedSprite2D
		_check(effect_sprite.sprite_frames.get_frame_count(&"play") == [4, 5, 4][effect_index], "Scrapper FX loads: " + path.get_file())
		if effect_index < 2:
			_check(effect_sprite.position.y == -32.0, "Scrapper ground FX uses a bottom pivot: " + path.get_file())
		effect.queue_free(); await process_frame
	for effect_index: int in range(BULWARK_FX.size()):
		var path: String = BULWARK_FX[effect_index]
		var effect := (load(path) as PackedScene).instantiate(); root.add_child(effect); await process_frame
		var effect_sprite := effect.get_node("Sprite") as AnimatedSprite2D
		_check(effect_sprite.sprite_frames.get_frame_count(&"play") == [5, 6, 4][effect_index], "Bulwark FX loads: " + path.get_file())
		_check(effect_sprite.position.y == [-48.0, -32.0, -48.0][effect_index], "Bulwark ground FX uses a bottom pivot: " + path.get_file())
		effect.queue_free(); await process_frame
	for path: String in SENTRY_FX:
		var effect := (load(path) as PackedScene).instantiate(); root.add_child(effect); await process_frame
		var effect_sprite := effect.get_node("Sprite") as AnimatedSprite2D
		_check(effect_sprite.sprite_frames.get_frame_count(&"play") == 4, "Sentry FX loads: " + path.get_file())
		effect.queue_free(); await process_frame
	for effect_index: int in range(HOUND_FX.size()):
		var path: String = HOUND_FX[effect_index]
		var effect := (load(path) as PackedScene).instantiate(); root.add_child(effect); await process_frame
		var effect_sprite := effect.get_node("Sprite") as AnimatedSprite2D
		_check(effect_sprite.sprite_frames.get_frame_count(&"play") == [5, 5, 6, 4, 8, 8][effect_index], "HOUND FX loads: " + path.get_file())
		if effect_index != 3:
			_check(effect_sprite.position.y == -48.0, "HOUND ground FX uses a bottom pivot: " + path.get_file())
		effect.queue_free(); await process_frame
	var gallery := VISUAL_TEST.instantiate(); _check(gallery != null and gallery.get_child_count() == 5, "EnemyVisualTest contains Guandito and four enemies"); gallery.free(); hound.free()
	if failures.is_empty(): print("PHASE6_ENEMY_VISUAL_SMOKE: PASS"); quit(0)
	else: print("PHASE6_ENEMY_VISUAL_SMOKE: FAIL (", failures.size(), ")"); quit(1)
