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
@export var max_shake_offset := 9.0
@export var trauma_decay := 2.2
@export var noise_speed := 38.0
var trauma := 0.0
var noise_time := 0.0
var noise := FastNoiseLite.new()
@onready var player := get_parent() as GuanditoPlayer

func _ready() -> void:
	# Keep the camera independent from the player's transform. Following a moving
	# parent while also rewriting global_position can accumulate a visible lag.
	top_level = true
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = 0.3
	noise.seed = randi()
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

	# Trauma shake: offset scales with trauma^2 and uses smooth noise, so small hits
	# stay subtle and stacked hits build up without turning into white noise.
	if trauma > 0.0:
		trauma = maxf(0.0, trauma - trauma_decay * delta)
		noise_time += delta * noise_speed
		var amount := trauma * trauma
		offset = Vector2(noise.get_noise_2d(noise_time, 0.0), noise.get_noise_2d(0.0, noise_time)) * max_shake_offset * amount
		offset = offset.round()
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
	# Legacy API: map (intensity px, duration s) onto trauma.
	add_trauma(clampf(intensity / 6.0 + duration, 0.0, 1.0))

func add_trauma(amount: float) -> void:
	trauma = clampf(trauma + amount, 0.0, 1.0)
