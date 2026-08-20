extends SceneTree

const ARENA := preload("res://scenes/levels/test_arena.tscn")

func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	var arena := ARENA.instantiate()
	root.add_child(arena)
	var player := arena.get_node("Guandito") as GuanditoPlayer
	player.global_position = Vector2(240, 214)
	player.set_physics_process(false)
	player.visual.set_action(&"idle", 1.0)
	for _index in range(4): await process_frame
	var image := root.get_texture().get_image()
	var error := image.save_png("res://artifacts/phase4_guandito_preview.png")
	print("PHASE4_CAPTURE: ", "PASS" if error == OK else "FAIL")
	quit(0 if error == OK else 1)
