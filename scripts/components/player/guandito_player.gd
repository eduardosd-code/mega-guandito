class_name GuanditoPlayer
extends CharacterBody2D

signal attack_performed(attack_type: String)

# Movement Configuration
@export_group("Movement")
@export var walk_speed: float = 120.0
@export var run_speed: float = 200.0
@export var acceleration: float = 800.0
@export var deceleration: float = 1000.0
@export var air_acceleration: float = 400.0
@export var friction: float = 0.85

@export_group("Jump")
@export var jump_force: float = -300.0
@export var gravity: float = 900.0
@export var max_fall_speed: float = 600.0
@export var coyote_time: float = 0.1
@export var jump_buffer_time: float = 0.1

@export_group("Dash")
@export var dash_speed: float = 450.0
@export var dash_duration: float = 0.15
@export var dash_cooldown: float = 0.5
@export var air_dash_allowed: bool = true
@export var dash_attack_window: float = 0.15

@export_group("Combat")
@export var combo_window: float = 0.25

# Component References
@onready var state_machine: PlayerStateMachine = $StateMachine
@onready var hurtbox: HurtboxComponent = $Hurtbox
@onready var health: HealthComponent = $HealthComponent
@onready var experience: ExperienceComponent = $ExperienceComponent
@onready var modules: ModuleComponent = $ModuleComponent
@onready var attack_hitbox: HitboxComponent = $AttackHitbox
@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

# State Variables
var _facing_right: bool = true
var _is_attacking: bool = false
var _combo_count: int = 0
var _combo_timer: float = 0.0
var _can_dash: bool = true
var _dash_timer: float = 0.0
var _coyote_timer: float = 0.0
var _jump_buffer_timer: float = 0.0
var _is_dashing: bool = false
var _dash_attack_available: bool = false
var _hitstop_remaining: float = 0.0

# Base stats (before modifiers)
var _base_walk_speed: float = 120.0
var _base_run_speed: float = 200.0
var _base_jump_force: float = -300.0
var _base_dash_speed: float = 450.0

func _ready() -> void:
_base_walk_speed = walk_speed
_base_run_speed = run_speed
_base_jump_force = jump_force
_base_dash_speed = dash_speed

# Connect signals
if health:
health.died.connect(_on_death)
if modules:
modules.stats_updated.connect(_update_stats_from_modules)
if hurtbox:
hurtbox.hit_received.connect(_on_hit_received)

_update_stats_from_modules()

func _input(event: InputEvent) -> void:
state_machine.handle_input(event)

func _process(delta: float) -> void:
if _hitstop_remaining > 0:
return

# Timers
if _combo_timer > 0:
_combo_timer -= delta
else:
_combo_count = 0

if _dash_timer > 0:
_dash_timer -= delta
else:
_can_dash = true

if _coyote_timer > 0:
_coyote_timer -= delta

if _jump_buffer_timer > 0:
_jump_buffer_timer -= delta

if _dash_attack_available and _dash_timer <= 0:
_dash_attack_available = false

state_machine.update(delta)

func _physics_process(delta: float) -> void:
if _hitstop_remaining > 0:
_hitstop_remaining -= delta
return

state_machine.physics_update(delta)

# Gravity
if not is_on_floor():
velocity.y += gravity * delta
velocity.y = min(velocity.y, max_fall_speed)

# Coyote time
if is_on_floor():
_coyote_timer = coyote_time
else:
_coyote_timer = 0.0

# Apply velocity
move_and_slide()

func _update_stats_from_modules() -> void:
if not modules:
return

walk_speed = _base_walk_speed * (1.0 + modules.get_total_stat_modifier("speed"))
run_speed = _base_run_speed * (1.0 + modules.get_total_stat_modifier("speed"))
jump_force = _base_jump_force * (1.0 + modules.get_total_stat_modifier("jump"))
dash_speed = _base_dash_speed * (1.0 + modules.get_total_stat_modifier("dash_speed"))

func face_direction(direction: float) -> void:
if direction > 0:
_facing_right = true
sprite.flip_h = false
elif direction < 0:
_facing_right = false
sprite.flip_h = true

func get_facing_direction() -> float:
return 1.0 if _facing_right else -1.0

func perform_attack(attack_type: String) -> void:
if _is_attacking:
return

_is_attacking = true
attack_performed.emit(attack_type)

var attack_data: AttackData = null
match attack_type:
"light_1":
attack_data = load("res://resources/data/attack_light_1.tres")
_combo_count = 1
"light_2":
attack_data = load("res://resources/data/attack_light_2.tres")
_combo_count = 2
"light_3":
attack_data = load("res://resources/data/attack_light_3.tres")
_combo_count = 0
"heavy":
attack_data = load("res://resources/data/attack_heavy.tres")
_combo_count = 0
"air":
attack_data = load("res://resources/data/attack_air.tres")
_combo_count = 0
"dash":
attack_data = load("res://resources/data/attack_dash.tres")
_combo_count = 0
_dash_attack_available = false

if attack_data:
_setup_attack_hitbox(attack_data)
_combo_timer = attack_data.combo_window

func _setup_attack_hitbox(data: AttackData) -> void:
if not attack_hitbox:
return

attack_hitbox.damage = data.damage
attack_hitbox.knockback_vector = data.knockback_vector
attack_hitbox.hitstun_duration = data.hitstun_duration
attack_hitbox.attacker_hitstop = data.attacker_hitstop
attack_hitbox.defender_hitstop = data.defender_hitstop
attack_hitbox.is_launcher = data.is_launcher
attack_hitbox.launch_force = data.launch_force

attack_hitbox.activate()
await get_tree().create_timer(data.active_frames / 60.0).timeout
attack_hitbox.deactivate()

_is_attacking = false

func perform_dash() -> void:
if not _can_dash:
return

_is_dashing = true
_can_dash = false
_dash_timer = dash_duration
_dash_attack_available = true

var dash_direction = Vector2(get_facing_direction(), 0)
velocity = dash_direction * dash_speed

# Trigger hitstop effect visually
Engine.time_scale = 1.0

await get_tree().create_timer(dash_duration).timeout
_is_dashing = false

func trigger_hitstop(duration: float) -> void:
_hitstop_remaining = duration

func _on_hit_received(attack_data: Dictionary, hit_direction: Vector2) -> void:
if _is_dashing:
return

var damage = attack_data["damage"] as int
var knockback = attack_data["knockback_vector"] as Vector2
var hitstun = attack_data["hitstun_duration"] as float
var defender_hitstop = attack_data["defender_hitstop"] as float

# Apply knockback based on hit direction
knockback.x *= sign(hit_direction.x)
velocity = knockback

# Take damage
if health:
health.take_damage(damage, defender_hitstop)

# Trigger hitstop
trigger_hitstop(defender_hitstop)

# Enter hit state
if state_machine:
state_machine.change_state("hit")

# Reset combo
_combo_count = 0

func _on_death() -> void:
if state_machine:
state_machine.change_state("dead")

func add_xp(amount: int) -> void:
if experience:
experience.add_xp(amount)

func get_combo_count() -> int:
return _combo_count

func can_start_combo() -> bool:
return _combo_count == 0 or (_combo_timer > 0 and _combo_count < 3)

func is_dashing() -> bool:
return _is_dashing

func can_dash_attack() -> bool:
return _dash_attack_available and _dash_timer > 0
