class_name Checkpoint
extends Area2D
signal activated(checkpoint: Checkpoint)
@export var checkpoint_id: StringName
var active := false
const INTERACTIVE_ATLAS := preload("res://art/environment/sector07/source_pack/interactive/interactives_source_atlas.png")
const CLEANUP := preload("res://art/environment/sector07/source_alpha_cutoff.tres")
var visual_sprite: Sprite2D
func _ready() -> void:
	collision_layer = 0; collision_mask = 1; body_entered.connect(_on_body)
	var collision := CollisionShape2D.new(); var shape := RectangleShape2D.new(); shape.size = Vector2(26, 58); collision.shape = shape; add_child(collision)
	var atlas := AtlasTexture.new(); atlas.atlas = INTERACTIVE_ATLAS; atlas.region = Rect2(230,0,88,112)
	visual_sprite = Sprite2D.new(); visual_sprite.texture = atlas; visual_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST; visual_sprite.material = CLEANUP; visual_sprite.position.y = -28; visual_sprite.scale = Vector2(0.62,0.62); add_child(visual_sprite)
func _on_body(body: Node) -> void:
	if not active and body is GuanditoPlayer: active = true; activated.emit(self); if is_instance_valid(visual_sprite): visual_sprite.modulate = Color("#b9ff9a"); queue_redraw()
func _draw() -> void:
	if is_instance_valid(visual_sprite): return
	var energy := Color("#75e830") if active else Color("#6b472b")
	draw_rect(Rect2(-14,-31,28,54),Color("#11191d")); draw_rect(Rect2(-11,-28,22,48),Color("#303b3d"))
	draw_line(Vector2(-8,-22),Vector2(8,-22),Color("#68716b"),2); draw_circle(Vector2(0,-14),7,Color("#15201b")); draw_circle(Vector2(0,-14),4,energy)
	draw_rect(Rect2(-7,-2,14,11),Color("#141d20")); draw_line(Vector2(-4,2),Vector2(4,2),energy,2)
	draw_rect(Rect2(-17,19,34,5),Color("#202a2d")); draw_line(Vector2(-12,24),Vector2(-12,28),Color("#707773"),3); draw_line(Vector2(12,24),Vector2(12,28),Color("#707773"),3)
