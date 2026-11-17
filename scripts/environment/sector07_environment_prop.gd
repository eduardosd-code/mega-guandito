class_name Sector07EnvironmentProp
extends Node2D

@export_enum("pump", "generator", "tank", "pipes", "assembly", "control") var kind := "pump"
@export var accent := Color("#b46b28")
const MACHINERY := preload("res://art/environment/sector07/source_pack/machinery/machinery_source_atlas.png")
const PIPES := preload("res://art/environment/sector07/source_pack/pipes/pipes_cables_source_atlas.png")
const INTERACTIVES := preload("res://art/environment/sector07/source_pack/interactive/interactives_source_atlas.png")
const CLEANUP := preload("res://art/environment/sector07/source_alpha_cutoff.tres")
const SOURCE_REGIONS := {
	"pump": [MACHINERY, Rect2(126,16,112,110)],
	"generator": [MACHINERY, Rect2(367,16,118,108)],
	"tank": [MACHINERY, Rect2(12,10,115,116)],
	"pipes": [PIPES, Rect2(14,8,158,72)],
	"assembly": [MACHINERY, Rect2(282,132,132,120)],
	"control": [INTERACTIVES, Rect2(12,5,48,96)]
}
var source_sprite: Sprite2D

func _ready() -> void:
	var data: Array = SOURCE_REGIONS.get(kind, [])
	if not data.is_empty():
		var atlas := AtlasTexture.new(); atlas.atlas = data[0]; atlas.region = data[1]
		source_sprite = Sprite2D.new(); source_sprite.texture = atlas; source_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		source_sprite.material = CLEANUP; source_sprite.position.y = -data[1].size.y * 0.5; add_child(source_sprite)
	queue_redraw()

func _draw() -> void:
	if is_instance_valid(source_sprite): return
	match kind:
		"pump":
			draw_rect(Rect2(-34,-48,68,48),Color("#182329")); draw_rect(Rect2(-28,-42,56,35),Color("#344447")); draw_circle(Vector2.ZERO-Vector2(0,24),12,Color("#11191d")); draw_circle(Vector2(0,-24),5,accent); _feet(25)
		"generator":
			draw_rect(Rect2(-30,-55,60,55),Color("#202b2e")); draw_rect(Rect2(-24,-48,48,39),Color("#4b5045")); draw_rect(Rect2(-15,-39,30,18),Color("#151c1f")); draw_line(Vector2(-11,-30),Vector2(11,-30),accent,3); _feet(22)
		"tank":
			draw_rect(Rect2(-27,-64,54,58),Color("#303b3c")); draw_arc(Vector2(0,-61),27,PI,TAU,20,Color("#68716c"),4); draw_line(Vector2(-24,-39),Vector2(24,-39),Color("#8a582f"),3); _feet(19)
		"pipes":
			draw_line(Vector2(-55,-44),Vector2(28,-44),Color("#3c4949"),14); draw_line(Vector2(28,-44),Vector2(28,0),Color("#3c4949"),14); draw_arc(Vector2(28,-44),10,0,PI/2.0,10,Color("#707773"),3); draw_circle(Vector2(-15,-44),12,Color("#222d30")); draw_circle(Vector2(-15,-44),7,accent)
		"assembly":
			draw_rect(Rect2(-45,-50,90,50),Color("#202a2d")); draw_rect(Rect2(-35,-43,70,30),Color("#3e4642")); draw_line(Vector2(-38,-9),Vector2(38,-9),accent,4); draw_line(Vector2(-28,-50),Vector2(-6,-78),Color("#68706c"),7); draw_line(Vector2(-6,-78),Vector2(20,-56),Color("#68706c"),7); _feet(35)
		"control":
			draw_rect(Rect2(-22,-47,44,47),Color("#242f32")); draw_rect(Rect2(-16,-41,32,22),Color("#0d1719")); draw_rect(Rect2(-12,-37,24,14),Color(0.1,0.65,0.64,0.45)); draw_line(Vector2(-9,-31),Vector2(8,-31),accent,2); _feet(15)

func _feet(width: float) -> void:
	draw_rect(Rect2(-width,-7,width*2.0,7),Color("#101719")); draw_rect(Rect2(-width-4,-3,9,5),Color("#5d625d")); draw_rect(Rect2(width-5,-3,9,5),Color("#5d625d"))
