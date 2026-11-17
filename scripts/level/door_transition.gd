class_name DoorTransition
extends StaticBody2D
@export_enum("maintenance", "security", "industrial") var door_style := "maintenance"
var opened := false
const DOOR_ATLAS := preload("res://art/environment/sector07/source_pack/doors/doors_source_atlas.png")
const CLEANUP := preload("res://art/environment/sector07/source_alpha_cutoff.tres")
var visual_sprite: Sprite2D
func _ready() -> void:
	collision_layer = 16; collision_mask = 0
	var regions := {"maintenance": Rect2(7,3,100,91), "security": Rect2(109,3,109,91), "industrial": Rect2(220,3,162,91)}
	var atlas := AtlasTexture.new(); atlas.atlas = DOOR_ATLAS; atlas.region = regions[door_style]
	visual_sprite = Sprite2D.new(); visual_sprite.texture = atlas; visual_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST; visual_sprite.material = CLEANUP
	visual_sprite.position.y = -10.0; visual_sprite.scale.y = 1.55; add_child(visual_sprite); queue_redraw()
func open() -> void:
	opened = true; $CollisionShape2D.set_deferred("disabled", true); if is_instance_valid(visual_sprite): visual_sprite.visible = false; queue_redraw()
func close() -> void:
	opened = false; $CollisionShape2D.set_deferred("disabled", false); if is_instance_valid(visual_sprite): visual_sprite.visible = true; queue_redraw()
func _draw() -> void:
	if opened or is_instance_valid(visual_sprite): return
	var width := 34.0 if door_style == "industrial" else 26.0
	var accent := Color("#dc3d30") if door_style == "security" else Color("#d47a2d")
	draw_rect(Rect2(-width*0.5,-74,width,148),Color("#121a1e")); draw_rect(Rect2(-width*0.5+4,-69,width-8,138),Color("#394448"))
	for y in range(-58,59,28): draw_line(Vector2(-width*0.5+5,y),Vector2(width*0.5-5,y),Color("#1e292d"),3)
	draw_line(Vector2(0,-67),Vector2(0,67),Color("#69716e"),2); draw_rect(Rect2(-7,-7,14,14),Color("#151d20")); draw_circle(Vector2.ZERO,3,accent)
