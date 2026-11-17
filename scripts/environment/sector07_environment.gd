class_name Sector07Environment
extends Node2D

const STRUCTURE := preload("res://art/environment/sector07/tiles/Sector07TileSet.tres")
const LAYER_SCRIPT := preload("res://scripts/environment/sector07_environment_layer.gd")
const GENERATED_DECALS_PATH := "res://art/environment/sector07/generated/sector07_foreground_decals_v1.png"
const PROP_SCENES := {
	"pump": preload("res://scenes/environment/sector07/IndustrialPump.tscn"),
	"generator": preload("res://scenes/environment/sector07/Generator.tscn"),
	"tank": preload("res://scenes/environment/sector07/LargeTank.tscn"),
	"pipes": preload("res://scenes/environment/sector07/PipeCluster.tscn"),
	"assembly": preload("res://scenes/environment/sector07/AssemblyMachine.tscn"),
	"control": preload("res://scenes/environment/sector07/ControlStation.tscn")
}
const AMBIENT_SCENES := {
	"steam": preload("res://scenes/environment/sector07/SteamVent.tscn"),
	"fan": preload("res://scenes/environment/sector07/IndustrialFan.tscn"),
	"light": preload("res://scenes/environment/sector07/FlickeringLight.tscn"),
	"sparks": preload("res://scenes/environment/sector07/SparkEmitter.tscn"),
	"drip": preload("res://scenes/environment/sector07/WaterDrip.tscn"),
	"conveyor": preload("res://scenes/environment/sector07/ConveyorBelt.tscn"),
	"cable": preload("res://scenes/environment/sector07/HangingCable.tscn")
}

var containers: Dictionary = {}

func _ready() -> void:
	z_index = -30
	_create_layers()
	_build_gameplay_tiles()
	_populate_props()
	_populate_generated_decals()
	_populate_ambient_motion()
	queue_redraw()

func _create_layers() -> void:
	_add_draw_layer("ParallaxFar", "far", -20)
	_add_draw_layer("ParallaxMid", "mid", -10)
	for layer_data in [["BackgroundProps",0],["GameplayTiles",10],["GameplayProps",12],["Interactive",20],["FX",35]]:
		var layer := Node2D.new(); layer.name = layer_data[0]; layer.z_index = layer_data[1]; add_child(layer); containers[layer.name] = layer
	_add_draw_layer("Foreground", "foreground", 40)
	var lighting := Node2D.new(); lighting.name = "Lighting"; lighting.z_index = 25; add_child(lighting); containers[lighting.name] = lighting

func _add_draw_layer(layer_name: String, kind: String, order: int) -> void:
	var layer := Node2D.new(); layer.name = layer_name; layer.set_script(LAYER_SCRIPT); layer.layer_kind = kind; layer.z_index = order; add_child(layer); containers[layer_name] = layer

func _build_gameplay_tiles() -> void:
	var surfaces := [
		[Rect2(0,220,1420,60),0], [Rect2(1420,190,780,90),2], [Rect2(2320,205,1040,75),0],
		[Rect2(3360,185,900,95),1], [Rect2(4260,215,790,65),3], [Rect2(5050,170,700,110),2],
		[Rect2(2500,145,130,12),3], [Rect2(2690,105,130,12),3], [Rect2(2880,145,160,12),3], [Rect2(3550,125,120,12),1], [Rect2(3790,105,140,12),1]
	]
	for surface_data in surfaces:
		var rect: Rect2 = surface_data[0]; var variant: int = surface_data[1]
		var layer := TileMapLayer.new(); layer.tile_set = STRUCTURE; layer.position = Vector2(rect.position.x, rect.position.y - 32.0)
		for cell_x in range(int(ceil(rect.size.x / 32.0))): layer.set_cell(Vector2i(cell_x,0),0,Vector2i(variant,0),0)
		containers["GameplayTiles"].add_child(layer)

func _populate_props() -> void:
	var props := [
		["pipes",Vector2(310,205),Color("#925126")],["generator",Vector2(500,220),Color("#8d4d25")],
		["control",Vector2(920,220),Color("#a66b28")],["pipes",Vector2(1270,205),Color("#7d572d")],
		["tank",Vector2(1540,190),Color("#2a898d")],["pump",Vector2(1820,190),Color("#38a4a0")],["pump",Vector2(2140,190),Color("#32918e")],
		["pipes",Vector2(2550,205),Color("#667132")],["fan",Vector2(0,0),Color.WHITE],
		["generator",Vector2(2980,205),Color("#687b31")],["pipes",Vector2(3240,200),Color("#61732f")],
		["assembly",Vector2(3450,185),Color("#cf7424")],["assembly",Vector2(3740,185),Color("#d37a29")],["generator",Vector2(4140,185),Color("#be6125")],
		["control",Vector2(4420,215),Color("#d13c30")],["pipes",Vector2(4890,210),Color("#9e302b")],
		["control",Vector2(5200,170),Color("#4e8da7")]
	]
	for entry in props:
		if entry[0] == "fan": continue
		var prop := PROP_SCENES[entry[0]].instantiate() as Node2D; prop.position = entry[1]; prop.accent = entry[2]; containers["BackgroundProps"].add_child(prop)

func _populate_ambient_motion() -> void:
	var ambient := [
		["light",Vector2(180,72),Color("#c5572b")],["steam",Vector2(580,220),Color.WHITE],
		["sparks",Vector2(900,105),Color("#ee7b2d")],["light",Vector2(1240,70),Color("#d3762d")],
		["drip",Vector2(1510,75),Color("#3aa8b7")],["fan",Vector2(1810,105),Color("#2d9fa1")],["steam",Vector2(2180,190),Color.WHITE],
		["fan",Vector2(2580,78),Color("#617b32")],["cable",Vector2(2920,55),Color.WHITE],["drip",Vector2(3180,82),Color("#41a7ba")],
		["conveyor",Vector2(3490,174),Color("#d27829")],["sparks",Vector2(3890,70),Color("#dc7127")],["conveyor",Vector2(4160,174),Color("#c85f25")],
		["light",Vector2(4390,68),Color("#e13631")],["light",Vector2(4700,68),Color("#e13631")],["sparks",Vector2(4970,95),Color("#d93c31")],
		["cable",Vector2(5270,48),Color.WHITE],["light",Vector2(5480,58),Color("#75a9c8")]
	]
	for entry in ambient:
		var element := AMBIENT_SCENES[entry[0]].instantiate() as Node2D; element.position = entry[1]; element.accent = entry[2]; containers["FX"].add_child(element)

func _populate_generated_decals() -> void:
	var image := Image.load_from_file(ProjectSettings.globalize_path(GENERATED_DECALS_PATH))
	if image == null or image.is_empty(): return
	var texture := ImageTexture.create_from_image(image)
	var placements := [
		[Vector2(930,126),Rect2(36,578,82,92)], [Vector2(1700,124),Rect2(294,578,102,92)],
		[Vector2(2870,124),Rect2(431,578,100,92)], [Vector2(3930,124),Rect2(568,578,100,92)],
		[Vector2(4670,124),Rect2(700,578,100,92)]
	]
	for placement in placements:
		var atlas := AtlasTexture.new(); atlas.atlas = texture; atlas.region = placement[1]
		var sprite := Sprite2D.new(); sprite.texture = atlas; sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.position = placement[0]; sprite.scale = Vector2.ONE * 0.36; sprite.modulate.a = 0.78
		containers["GameplayProps"].add_child(sprite)

func _draw() -> void:
	# Zone overlays keep a shared charcoal base while giving each area a restrained identity.
	var zones := [
		[Rect2(0,0,690,280),Color(0.20,0.07,0.035,0.18)], [Rect2(690,0,730,280),Color(0.22,0.13,0.05,0.12)],
		[Rect2(1420,0,1060,280),Color(0.03,0.32,0.34,0.14)], [Rect2(2480,0,880,280),Color(0.20,0.28,0.10,0.11)],
		[Rect2(3360,0,900,280),Color(0.48,0.20,0.035,0.13)], [Rect2(4260,0,790,280),Color(0.50,0.025,0.025,0.15)],
		[Rect2(5050,0,700,280),Color(0.12,0.34,0.48,0.15)]
	]
	for zone in zones: draw_rect(zone[0],zone[1])
	for x in range(60,5050,290): draw_rect(Rect2(x,82,72,105),Color("#121d21")); draw_rect(Rect2(x+8,91,56,5),Color("#344145"))
	for label in [[80,"07 // BASEMENT"],[760,"MAINTENANCE"],[1500,"PUMP CONTROL"],[2540,"SERVICE"],[3410,"ASSEMBLY"],[4340,"SECURITY"],[5150,"SURFACE"]]:
		draw_string(ThemeDB.fallback_font,Vector2(label[0],35),label[1],HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("#a68145"))
