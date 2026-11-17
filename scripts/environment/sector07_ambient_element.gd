class_name Sector07AmbientElement
extends Node2D

@export_enum("steam", "fan", "light", "sparks", "drip", "conveyor", "cable") var kind := "steam"
@export var accent := Color("#d9782b")
var elapsed := 0.0
const GENERATED_ATLAS_PATH := "res://art/environment/sector07/generated/sector07_animated_fx_v1.png"
const GENERATED_REGIONS := {
	"fan": [Rect2(42,24,92,86),Rect2(137,24,92,86),Rect2(232,24,92,86),Rect2(327,24,92,86)],
	"light": [Rect2(39,124,68,66),Rect2(116,124,68,66),Rect2(193,124,68,66),Rect2(270,124,68,66)],
	"steam": [Rect2(39,512,78,102),Rect2(145,512,78,102),Rect2(252,512,84,102),Rect2(396,512,76,102)],
	"sparks": [Rect2(520,512,84,102),Rect2(626,512,84,102),Rect2(732,512,84,102),Rect2(838,512,84,102)],
	"drip": [Rect2(39,610,72,68),Rect2(145,610,72,68),Rect2(250,610,86,68),Rect2(356,610,86,68)],
	"conveyor": [Rect2(42,445,184,70),Rect2(246,445,184,70),Rect2(448,445,142,70),Rect2(592,445,142,70)],
	"cable": [Rect2(43,674,137,76),Rect2(210,674,153,76),Rect2(379,674,181,76)]
}
var source_sprite: Sprite2D
var source_texture: AtlasTexture

func _ready() -> void:
	var regions: Array = GENERATED_REGIONS.get(kind, [])
	if regions.is_empty(): return
	var image := Image.load_from_file(ProjectSettings.globalize_path(GENERATED_ATLAS_PATH))
	if image == null or image.is_empty(): return
	var generated_atlas := ImageTexture.create_from_image(image)
	source_texture = AtlasTexture.new(); source_texture.atlas = generated_atlas; source_texture.region = regions[0]
	source_sprite = Sprite2D.new(); source_sprite.texture = source_texture; source_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	source_sprite.scale = Vector2.ONE * (0.58 if kind in ["fan","conveyor"] else 0.50)
	add_child(source_sprite)

func _process(delta: float) -> void:
	var camera := get_viewport().get_camera_2d()
	var nearby := camera == null or absf(camera.global_position.x - global_position.x) < 720.0
	visible = nearby
	if nearby:
		elapsed += delta
		if source_texture != null:
			var regions: Array = GENERATED_REGIONS.get(kind, [])
			source_texture.region = regions[int(elapsed * (7.0 if kind != "cable" else 2.0)) % regions.size()]
		queue_redraw()

func _draw() -> void:
	if source_sprite != null: return
	match kind:
		"steam":
			draw_rect(Rect2(-15,-4,30,7),Color("#39484a"))
			for i in range(3): draw_circle(Vector2(-8+i*8,-12-fmod(elapsed*(24+i*5)+i*13,42)),5+i*2,Color(0.65,0.82,0.78,0.18))
		"fan":
			draw_circle(Vector2.ZERO,24,Color("#202b30")); draw_arc(Vector2.ZERO,22,0,TAU,28,Color("#65706e"),3)
			for i in range(4): draw_line(Vector2.ZERO,Vector2.RIGHT.rotated(elapsed*1.3+i*PI/2.0)*17,Color("#77807a"),7)
			draw_circle(Vector2.ZERO,5,accent)
		"light":
			var glow := 0.45 + sin(elapsed*6.0)*0.25; draw_rect(Rect2(-8,-5,16,10),Color("#252e30")); draw_circle(Vector2.ZERO,4,Color(accent,glow))
		"sparks":
			if fmod(elapsed,2.2)<0.35:
				for i in range(5): draw_line(Vector2.ZERO,Vector2(cos(i*1.7),sin(i*1.7))*float(5+i*2),accent,2)
		"drip": draw_line(Vector2.ZERO,Vector2(0,fmod(elapsed*38.0,36.0)),Color("#43aeca"),2)
		"conveyor":
			draw_rect(Rect2(-48,-8,96,16),Color("#303b3d")); draw_line(Vector2(-45+fmod(elapsed*24.0,16.0),-3),Vector2(43,-3),accent,3)
			for x in range(-40,41,16): draw_circle(Vector2(x,4),4,Color("#12191c"))
		"cable":
			var points := PackedVector2Array()
			for x in range(-50,51,10): points.append(Vector2(x,12+cos(float(x)*0.055+elapsed*0.7)*6))
			draw_polyline(points,Color("#171d20"),4)
