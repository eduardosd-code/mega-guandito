extends Camera2D

@export var look_ahead := 38.0
@export var follow_speed := 7.5
var target_offset := Vector2.ZERO
var shake_left := 0.0
var shake_duration := 0.0
var shake_intensity := 0.0
var rng := RandomNumberGenerator.new()

func _process(delta: float) -> void:
	var player := get_parent() as GuanditoPlayer
	target_offset.x = player.facing * look_ahead + player.velocity.x * 0.035
	var follow := offset.lerp(target_offset, 1.0 - exp(-follow_speed * delta))
	if shake_left > 0.0:
		shake_left = maxf(0.0, shake_left - delta)
		var falloff := shake_left / maxf(shake_duration, 0.001)
		offset = follow + Vector2(rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0)) * shake_intensity * falloff
	else:
		offset = follow
	global_position = global_position.round()

func shake(intensity: float, duration: float) -> void:
	shake_intensity = maxf(shake_intensity, intensity)
	shake_duration = maxf(duration, 0.001)
	shake_left = maxf(shake_left, duration)
