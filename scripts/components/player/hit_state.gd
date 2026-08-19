class_name HitState
extends PlayerState

var player: GuanditoPlayer = null
var hit_timer: float = 0.0

func _ready() -> void:
state_name = "hit"

func enter(previous_state: String) -> void:
player = get_owner() as GuanditoPlayer
hit_timer = 0.3  # Base hitstun duration

func physics_update(delta: float) -> void:
if not player:
return

hit_timer -= delta

# Apply friction during hitstun
player.velocity.x = move_toward(player.velocity.x, 0, player.deceleration * delta)

# Check if hitstun is over
if hit_timer <= 0:
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
