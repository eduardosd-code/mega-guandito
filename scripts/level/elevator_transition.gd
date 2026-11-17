class_name ElevatorTransition
extends Area2D
signal used
@export var destination_offset := Vector2(220, -80)
var busy := false
const INTERACTIVE_ATLAS := preload("res://art/environment/sector07/source_pack/interactive/interactives_source_atlas.png")
const CLEANUP := preload("res://art/environment/sector07/source_alpha_cutoff.tres")
var visual_sprite: Sprite2D
func _ready() -> void:
	collision_layer = 0; collision_mask = 1; body_entered.connect(_on_body)
	if get_child_count() == 0:
		var collision := CollisionShape2D.new(); var shape := RectangleShape2D.new(); shape.size = Vector2(80,50); collision.shape = shape; add_child(collision)
	var atlas := AtlasTexture.new(); atlas.atlas = INTERACTIVE_ATLAS; atlas.region = Rect2(320,0,110,190)
	visual_sprite = Sprite2D.new(); visual_sprite.texture = atlas; visual_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST; visual_sprite.material = CLEANUP; visual_sprite.position.y = -45; visual_sprite.scale = Vector2(0.72,0.72); add_child(visual_sprite)
func _on_body(body: Node) -> void:
	if body is GuanditoPlayer and not busy:
		busy = true; body.set_physics_process(false)
		var tween := create_tween(); tween.tween_property(body,"global_position",body.global_position+destination_offset,0.9).set_trans(Tween.TRANS_SINE)
		await tween.finished; body.set_physics_process(true); busy = false; used.emit()
func _draw() -> void:
	if is_instance_valid(visual_sprite): return
	draw_rect(Rect2(-44,15,88,12),Color("#182125")); draw_rect(Rect2(-39,17,78,5),Color("#68716e"))
	for x in range(-34,35,14): draw_line(Vector2(x,18),Vector2(x+7,22),Color("#cf762a"),3)
	draw_line(Vector2(-40,-34),Vector2(-40,17),Color("#53605f"),5); draw_line(Vector2(40,-34),Vector2(40,17),Color("#53605f"),5)
	draw_rect(Rect2(-45,-39,90,7),Color("#202b2e")); draw_circle(Vector2(31,-28),3,Color("#79bd40"))
