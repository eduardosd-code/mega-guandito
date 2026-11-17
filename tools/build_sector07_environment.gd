extends SceneTree

const OUTPUT_DIR := "res://art/environment/sector07/tiles"
const SOURCE_GRID := "res://art/environment/sector07/source_pack/tiles/structure_32_grid.png"

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	var source_image := Image.load_from_file(SOURCE_GRID)
	if source_image.get_size() != Vector2i(512,352):
		push_error("Unexpected Sector 07 grid size: %s" % source_image.get_size()); quit(1); return
	source_image.save_png(OUTPUT_DIR + "/sector07_structure.png")
	var texture := load(SOURCE_GRID) as Texture2D
	var atlas := TileSetAtlasSource.new(); atlas.texture = texture; atlas.texture_region_size = Vector2i(32, 32)
	for tile_y in range(11):
		for tile_x in range(16): atlas.create_tile(Vector2i(tile_x, tile_y))
	var tile_set := TileSet.new(); tile_set.tile_size = Vector2i(32, 32); tile_set.add_source(atlas, 0)
	for terrain_index in range(3):
		tile_set.add_terrain_set(terrain_index)
		tile_set.set_terrain_set_mode(terrain_index, TileSet.TERRAIN_MODE_MATCH_CORNERS_AND_SIDES)
		tile_set.add_terrain(terrain_index, 0)
		tile_set.set_terrain_name(terrain_index, 0, ["FLOOR", "WALL", "PLATFORM"][terrain_index])
	ResourceSaver.save(tile_set, OUTPUT_DIR + "/Sector07TileSet.tres")
	print("SECTOR07_ENVIRONMENT_BUILD: PASS // 176 source tiles")
	quit(0)
