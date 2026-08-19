class_name DashState
extends PlayerState

var player: GuanditoPlayer = null
var dash_elapsed: float = 0.0

func _ready() -> void:
state_name = "dash"

func enter(previous_state: String) -> void:
player = get_owner() as GuanditoPlayer
dash_elapsed = 0.0

# Check for dash attack
if player.can_dash_attack():
player.perform_attack("dash")

func physics_update(delta: float) -> void:
if not player:
return

dash_elapsed += delta

# Check for attack during dash
if Input.is_action_just_pressed("attack_light"):
player.perform_attack("dash")

# Dash duration check
if dash_elapsed >= player.dash_duration:
# Determine next state
if player.is_on_floor():
var speed = abs(player.velocity.x)
if speed > 10:
player.state_machine.change_state("run")
else:
player.state_machine.change_state("idle")
else:
if player.velocity.y > 0:
player.state_machine.change_state("fall")
else:
player.state_machine.change_state("jump")
