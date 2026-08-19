extends PlayerStateMachine

func initialize_states() -> void:
# Create and register all player states
var idle = IdleState.new()
var run = RunState.new()
var jump = JumpState.new()
var fall = FallState.new()
var dash = DashState.new()
var hit = HitState.new()
var dead = DeadState.new()

add_state("idle", idle)
add_state("run", run)
add_state("jump", jump)
add_state("fall", fall)
add_state("dash", dash)
add_state("hit", hit)
add_state("dead", dead)
