class_name Sector07EnvironmentLayer
extends Node2D

@export_enum("far", "mid", "foreground") var layer_kind := "far"
var camera_origin := 0.0
const BG_FAR := preload("res://art/environment/sector07/source_pack/backgrounds/bg_far.png")
const BG_MID := preload("res://art/environment/sector07/source_pack/backgrounds/bg_mid.png")
const BG_NEAR := preload("res://art/environment/sector07/source_pack/backgrounds/bg_near.png")
const GENERATED_FOREGROUND_PATH := "res://art/environment/sector07/generated/sector07_foreground_decals_v1.png"
var source_sprites: Array[Sprite2D] = []

func _ready() -> void:
	if layer_kind in ["far","mid"]:
		var texture := BG_FAR if layer_kind == "far" else BG_MID
		_add_repeated_background(texture, 104.0 if layer_kind == "far" else 140.0, 0.82 if layer_kind == "far" else 0.92)
		if layer_kind == "mid": _add_repeated_background(BG_NEAR, 196.0, 0.34)
	elif layer_kind == "foreground":
		_add_generated_foreground()
	queue_redraw()

func _add_generated_foreground() -> void:
	var image := Image.load_from_file(ProjectSettings.globalize_path(GENERATED_FOREGROUND_PATH))
	if image == null or image.is_empty(): return
	var generated_foreground := ImageTexture.create_from_image(image)
	var placements := [
		[Vector2(260,48),Rect2(31,35,48,160)], [Vector2(1320,48),Rect2(113,35,55,160)],
		[Vector2(2470,56),Rect2(211,61,49,134)], [Vector2(3310,54),Rect2(707,35,40,160)],
		[Vector2(5000,55),Rect2(1058,105,92,92)]
	]
	for placement in placements:
		var atlas := AtlasTexture.new(); atlas.atlas = generated_foreground; atlas.region = placement[1]
		var sprite := Sprite2D.new(); sprite.texture = atlas; sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.position = placement[0]; sprite.scale = Vector2.ONE * 0.56; sprite.modulate.a = 0.62
		add_child(sprite); source_sprites.append(sprite)

func _add_repeated_background(texture: Texture2D, center_y: float, opacity: float) -> void:
	for x in range(-522,6265,522):
		var sprite := Sprite2D.new(); sprite.texture = texture; sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.position = Vector2(x + texture.get_width()*0.5,center_y); sprite.modulate.a = opacity; add_child(sprite); source_sprites.append(sprite)
func _process(_delta: float) -> void:
	var camera := get_viewport().get_camera_2d()
	if camera and layer_kind != "foreground":
		position.x = camera.global_position.x * (0.02 if layer_kind == "far" else 0.01)

func _draw() -> void:
	if not source_sprites.is_empty() and layer_kind != "foreground": return
	if layer_kind == "far":
		draw_rect(Rect2(-900,-80,7600,360),Color("#081014"))
		for x in range(-800,6600,170):
			var h := 80 + posmod(x,110); draw_rect(Rect2(x,220-h,115,h),Color("#101b20")); draw_line(Vector2(x+18,220-h),Vector2(x+18,220),Color("#1c2b30"),5)
		for x in range(5050,6500,70): draw_rect(Rect2(x,80+posmod(x,55),48,150),Color("#17272f"))
		# La Aguja remains an intentionally abstract silhouette pending approved clean art.
		draw_colored_polygon(PackedVector2Array([Vector2(5510,220),Vector2(5560,-95),Vector2(5610,220)]),Color("#263943")); draw_line(Vector2(5560,-70),Vector2(5560,190),Color("#5e8f54"),2)
	elif layer_kind == "mid":
		for x in range(-300,5200,260):
			draw_line(Vector2(x,55+posmod(x,45)),Vector2(x+190,55+posmod(x,45)),Color("#28383a"),12); draw_line(Vector2(x+24,35),Vector2(x+24,190),Color("#1d2a2e"),8)
		for x in range(1500,2450,220): draw_circle(Vector2(x,125),38,Color("#152d31")); draw_arc(Vector2(x,125),34,0,TAU,24,Color("#2b6265"),5)
	elif layer_kind == "foreground":
		if not source_sprites.is_empty(): return
		for x in [260.0,1320.0,2470.0,3310.0,5000.0]:
			draw_line(Vector2(x,-10),Vector2(x,75),Color(0.05,0.08,0.09,0.5),18); draw_line(Vector2(x,70),Vector2(x+58,70),Color(0.05,0.08,0.09,0.45),18)
