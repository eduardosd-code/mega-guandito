class_name ModuleData
extends Resource

enum Category { HEAD, TORSO, ARMS, LEGS, CORE }

@export var id: StringName
@export var display_name: String
@export_multiline var description: String
@export var category: Category
@export var energy_cost: int = 1
@export var icon: Texture2D
@export var stat_modifiers: Dictionary = {}
@export var special_effect_id: StringName
@export var unlock_dodge: bool = false
