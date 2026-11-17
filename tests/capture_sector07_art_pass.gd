extends SceneTree

const SECTOR := preload("res://scenes/levels/sector07.tscn")
const OUTPUT := "res://artifacts/sector07_art_pass"

func _initialize() -> void: call_deferred("_run")
func _frames(count: int) -> void:
	for _index in range(count): await process_frame

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	var sector := SECTOR.instantiate() as Sector07; root.add_child(sector); await _frames(8)
	sector.intro_skipped = true; sector.intro_finished = true; sector.player.input_lock_left = 0.0
	if is_instance_valid(sector.intro_layer): sector.intro_layer.queue_free()
	sector.player.set_physics_process(false)
	for enemy in get_nodes_in_group("enemies"): enemy.set_physics_process(false)
	sector.get_node("HUD/CombatDebugPanel").visible = false
	var camera := sector.player.get_node("Camera2D") as Camera2D
	var shots := [
		["01_awakening",Vector2(240,185)], ["02_first_contact",Vector2(900,185)], ["03_pumping",Vector2(1820,155)],
		["04_service_ducts",Vector2(2780,120)], ["05_assembly",Vector2(3670,145)], ["06_hound_arena",Vector2(4600,175)],
		["07_surface_exit",Vector2(5450,125)]
	]
	for shot in shots:
		if shot[0] == "07_surface_exit":
			sector.boss_defeated = true
			if is_instance_valid(sector.hound): sector.hound.queue_free()
			sector.boss_door.open()
		sector.player.global_position = shot[1]; camera.reset_to_target(); await _frames(4)
		var image := root.get_viewport().get_texture().get_image()
		var error := image.save_png(OUTPUT + "/" + shot[0] + ".png")
		if error != OK: push_error("Capture failed: " + shot[0]); quit(1); return
		print("CAPTURED: ", shot[0])
	print("SECTOR07_ART_CAPTURE: PASS")
	quit(0)
