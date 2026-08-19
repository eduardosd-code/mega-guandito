class_name AttackData
extends Resource

@export_group("Damage")
@export var damage: int = 10
@export var knockback_vector: Vector2 = Vector2.RIGHT * 200
@export var hitstun_duration: float = 0.3

@export_group("Timing")
@export var active_frames: int = 4
@export var startup_frames: int = 3
@export var recovery_frames: int = 8

@export_group("Hitstop")
@export var attacker_hitstop: float = 0.05
@export var defender_hitstop: float = 0.1

@export_group("Properties")
@export var can_combo: bool = true
@export var combo_window: float = 0.25
@export var is_launcher: bool = false
@export var launch_force: float = 0.0

@export_group("Visual")
@export var hitstop_scale: float = 1.0
