class_name DeadState
extends PlayerState

var player: GuanditoPlayer = null

func _ready() -> void:
state_name = "dead"

func enter(previous_state: String) -> void:
player = get_owner() as GuanditoPlayer
# Stop all movement
player.velocity = Vector2.ZERO

func physics_update(delta: float) -> void:
if not player:
return

# Stay dead - no state transitions from here in this prototype
pass
