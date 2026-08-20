class_name Sector07EnemySpriteLibrary
extends RefCounted

const DEFINITIONS := {
	&"scrapper": {"size": Vector2i(64, 64), "animations": {&"idle": 6, &"run": 8, &"attack_1": 4, &"attack_2": 5, &"hit": 3, &"death": 6}},
	&"bulwark": {"size": Vector2i(96, 96), "animations": {&"idle": 6, &"walk": 6, &"attack_hammer_fist": 5, &"attack_charge": 6, &"attack_backhand": 4, &"hit": 3, &"death": 7}},
	&"sentry": {"size": Vector2i(64, 64), "animations": {&"hover_idle": 6, &"move": 4, &"pulse_shot": 5, &"triple_pulse": 7, &"hit": 3, &"death": 6}},
	&"hound": {"size": Vector2i(160, 96), "animations": {&"idle": 6, &"walk_prowl": 6, &"charge": 5, &"pounce": 6, &"claw_combo": 6, &"energy_burst": 8, &"hit": 3, &"death": 8}}
}

const LOOPING := [&"idle", &"run", &"walk", &"hover_idle", &"move", &"walk_prowl"]

static func build(enemy: StringName) -> SpriteFrames:
	var library := SpriteFrames.new()
	library.remove_animation(&"default")
	var definition: Dictionary = DEFINITIONS[enemy]
	var frame_size: Vector2i = definition["size"]
	var animations: Dictionary = definition["animations"]
	for animation_name: StringName in animations:
		library.add_animation(animation_name)
		library.set_animation_loop(animation_name, animation_name in LOOPING)
		library.set_animation_speed(animation_name, 10.0)
		var texture := load("res://assets/enemies/sector_07/%s/sprites/%s.png" % [enemy, animation_name]) as Texture2D
		for frame_index: int in range(animations[animation_name]):
			var frame := AtlasTexture.new()
			frame.atlas = texture
			frame.region = Rect2(frame_index * frame_size.x, 0, frame_size.x, frame_size.y)
			library.add_frame(animation_name, frame)
	return library
