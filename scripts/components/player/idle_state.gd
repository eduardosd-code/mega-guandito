class_name IdleState
extends PlayerState

var player: GuanditoPlayer = null

func _ready() -> void:
state_name = "idle"

func enter(previous_state: String) -> void:
player = get_owner() as GuanditoPlayer

func physics_update(delta: float) -> void:
if not player:
return

var input_dir = Input.get_axis("move_left", "move_right")

# Check for attack input
if Input.is_action_just_pressed("attack_light"):
if player.can_start_combo():
var combo = player.get_combo_count()
if combo == 0:
player.perform_attack("light_1")
elif combo == 1:
player.perform_attack("light_2")
elif combo == 2:
player.perform_attack("light_3")
return

if Input.is_action_just_pressed("attack_heavy"):
player.perform_attack("heavy")
return

# Check for dash
if Input.is_action_just_pressed("dash"):
player.perform_dash()
return

# Movement
if input_dir != 0:
player.face_direction(input_dir)
var target_speed = input_dir * player.run_speed if Input.is_key_pressed(KEY_SHIFT) else input_dir * player.walk_speed
player.velocity.x = move_toward(player.velocity.x, target_speed, player.acceleration * delta)

if abs(player.velocity.x) > 10:
player.state_machine.change_state("run")
return

# Jump
if Input.is_action_just_pressed("jump"):
player._jump_buffer_timer = player.jump_buffer_time

# Apply friction when idle
if abs(player.velocity.x) < 5:
player.velocity.x = move_toward(player.velocity.x, 0, player.deceleration * delta)
else:
player.velocity.x *= player.friction

# Check for fall
if not player.is_on_floor() and player.velocity.y > 0:
player.state_machine.change_state("fall")
