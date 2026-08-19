class_name FallState
extends PlayerState

var player: GuanditoPlayer = null
var has_performed_air_attack: bool = false

func _ready() -> void:
state_name = "fall"

func enter(previous_state: String) -> void:
player = get_owner() as GuanditoPlayer
has_performed_air_attack = false

func physics_update(delta: float) -> void:
if not player:
return

# Check for air attack (only once per jump arc)
if not has_performed_air_attack and Input.is_action_just_pressed("attack_light"):
player.perform_attack("air")
has_performed_air_attack = true
return

if Input.is_action_just_pressed("attack_heavy"):
player.perform_attack("heavy")
return

# Air dash
if Input.is_action_just_pressed("dash") and player.air_dash_allowed:
player.perform_dash()
return

# Horizontal movement in air
var input_dir = Input.get_axis("move_left", "move_right")
if input_dir != 0:
player.face_direction(input_dir)
var target_speed = input_dir * player.run_speed if Input.is_key_pressed(KEY_SHIFT) else input_dir * player.walk_speed
player.velocity.x = move_toward(player.velocity.x, target_speed, player.air_acceleration * delta)

# Check for landing
if player.is_on_floor():
# Handle jump buffer on landing
if player._jump_buffer_timer > 0:
player.state_machine.change_state("jump")
else:
var speed = abs(player.velocity.x)
if speed > 10:
player.state_machine.change_state("run")
else:
player.state_machine.change_state("idle")
