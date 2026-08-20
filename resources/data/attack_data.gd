class_name AttackData
extends Resource

@export var id: StringName
@export var damage: int = 10
@export var knockback: Vector2 = Vector2(120, -35)
@export var hitstun: float = 0.18
@export var hitstop: float = 0.035
@export var startup: float = 0.05
@export var active_time: float = 0.08
@export var recovery: float = 0.12
@export var combo_window: float = 0.26
@export var hitbox_offset: Vector2 = Vector2(24, 0)
@export var hitbox_size: Vector2 = Vector2(34, 30)
@export var launcher: bool = false
@export_group("Feedback")
@export_enum("light", "kinetic", "heavy") var impact_fx: String = "light"
@export var shake_intensity: float = 0.0
@export var shake_duration: float = 0.0
@export var air_hit_vertical_damping: float = 1.0
@export var momentum_retention: float = 0.0
