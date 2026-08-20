extends Camera2D

@export var look_ahead := 38.0
@export var velocity_look_ahead := 0.035
@export var max_velocity_look_ahead := 16.0
@export var vertical_offset := -32.0
@export var follow_speed := 10.0
@export var direction_look_speed := 3.5
@export var max_follow_lag := 72.0

var current_look_ahead := 0.0
var last_player_position := Vector2.ZERO
var shake_left := 0.0
var shake_duration := 0.0
var shake_intensity := 0.0
var rng := RandomNumberGenerator.new()
@onready var player := get_parent() as GuanditoPlayer

func _ready() -> void:
	# Keep the camera independent from the player's transform. Following a moving
	# parent while also rewriting global_position can accumulate a visible lag.
	top_level = true
	current_look_ahead = player.facing * look_ahead
	last_player_position = player.global_position
	reset_to_target()

func _process(delta: float) -> void:
	if not is_instance_valid(player):
		return

	var look_weight := 1.0 - exp(-direction_look_speed * delta)
	current_look_ahead = lerpf(current_look_ahead, player.facing * look_ahead, look_weight)
	var target := desired_follow_position()
	var player_displacement := player.global_position.distance_to(last_player_position)
	last_player_position = player.global_position
	if player_displacement > max_follow_lag:
		global_position = target.round()
	else:
		var weight := 1.0 - exp(-follow_speed * delta)
		global_position = global_position.lerp(target, weight).round()

	if shake_left > 0.0:
		shake_left = maxf(0.0, shake_left - delta)
		var falloff := shake_left / maxf(shake_duration, 0.001)
		offset = Vector2(rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0)) * shake_intensity * falloff
	else:
		offset = Vector2.ZERO

func desired_follow_position() -> Vector2:
	var speed_lead := clampf(player.velocity.x * velocity_look_ahead, -max_velocity_look_ahead, max_velocity_look_ahead)
	return player.global_position + Vector2(current_look_ahead + speed_lead, vertical_offset)

func reset_to_target() -> void:
	if is_instance_valid(player):
		current_look_ahead = player.facing * look_ahead
		last_player_position = player.global_position
		global_position = desired_follow_position().round()
	offset = Vector2.ZERO

func shake(intensity: float, duration: float) -> void:
	shake_intensity = maxf(shake_intensity, intensity)
	shake_duration = maxf(duration, 0.001)
	shake_left = maxf(shake_left, duration)
