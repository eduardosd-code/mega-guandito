class_name ModuleData
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""

enum ModuleCategory { HEAD, TORSO, ARMS, LEGS, CORE }
@export var category: ModuleCategory = ModuleCategory.CORE

@export var energy_cost: int = 1
@export var icon: Texture2D = null

@export_group("Stat Modifiers")
@export var max_health_modifier: int = 0
@export var health_regen_modifier: float = 0.0
@export var damage_modifier: float = 0.0
@export var speed_modifier: float = 0.0
@export var jump_modifier: float = 0.0
@export var dash_speed_modifier: float = 0.0
@export var dash_cooldown_modifier: float = 0.0
@export var energy_capacity_modifier: int = 0

@export var special_effect_id: String = ""
