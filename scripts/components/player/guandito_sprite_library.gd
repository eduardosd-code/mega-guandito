class_name GuanditoSpriteLibrary
extends RefCounted

const TEXTURES := {
	&"idle": preload("res://assets/characters/guandito/sprites/runtime/idle.png"),
	&"run": preload("res://assets/characters/guandito/sprites/runtime/run.png"),
	&"jump_start": preload("res://assets/characters/guandito/sprites/runtime/jump_start.png"),
	&"jump_up": preload("res://assets/characters/guandito/sprites/runtime/jump_up.png"),
	&"fall": preload("res://assets/characters/guandito/sprites/runtime/fall.png"),
	&"land": preload("res://assets/characters/guandito/sprites/runtime/land.png"),
	&"dash_start": preload("res://assets/characters/guandito/sprites/runtime/dash_start.png"),
	&"dash": preload("res://assets/characters/guandito/sprites/runtime/dash.png"),
	&"dash_end": preload("res://assets/characters/guandito/sprites/runtime/dash_end.png"),
	&"light_1": preload("res://assets/characters/guandito/sprites/runtime/light_1.png"),
	&"light_2": preload("res://assets/characters/guandito/sprites/runtime/light_2.png"),
	&"light_3": preload("res://assets/characters/guandito/sprites/runtime/light_3.png"),
	&"heavy_start": preload("res://assets/characters/guandito/sprites/runtime/heavy_start.png"),
	&"heavy_attack": preload("res://assets/characters/guandito/sprites/runtime/heavy_attack.png"),
	&"heavy_recovery": preload("res://assets/characters/guandito/sprites/runtime/heavy_recovery.png"),
	&"air_light": preload("res://assets/characters/guandito/sprites/runtime/air_light.png"),
	&"dodge_start": preload("res://assets/characters/guandito/sprites/runtime/dodge_start.png"),
	&"dodge_invulnerable": preload("res://assets/characters/guandito/sprites/runtime/dodge_invulnerable.png"),
	&"dodge_exposed": preload("res://assets/characters/guandito/sprites/runtime/dodge_exposed.png"),
	&"hit": preload("res://assets/characters/guandito/sprites/runtime/hit.png"),
	&"death": preload("res://assets/characters/guandito/sprites/runtime/death.png"),
	&"module_install": preload("res://assets/characters/guandito/sprites/runtime/module_install.png")
}

const FRAME_COUNTS := {
	&"idle": 6, &"run": 8, &"jump_start": 3, &"jump_up": 3, &"fall": 3, &"land": 3,
	&"dash_start": 2, &"dash": 3, &"dash_end": 2,
	&"light_1": 4, &"light_2": 5, &"light_3": 6,
	&"heavy_start": 4, &"heavy_attack": 3, &"heavy_recovery": 5, &"air_light": 5,
	&"dodge_start": 2, &"dodge_invulnerable": 3, &"dodge_exposed": 4,
	&"hit": 3, &"death": 7, &"module_install": 8
}

const FPS := {
	&"idle": 7.5, &"run": 15.0, &"jump_start": 37.5, &"jump_up": 12.0, &"fall": 12.0, &"land": 42.0,
	&"dash_start": 57.0, &"dash": 28.0, &"dash_end": 40.0,
	&"light_1": 19.0, &"light_2": 21.7, &"light_3": 17.1,
	&"heavy_start": 21.0, &"heavy_attack": 25.0, &"heavy_recovery": 19.2, &"air_light": 15.6,
	&"dodge_start": 57.0, &"dodge_invulnerable": 23.0, &"dodge_exposed": 16.7,
	&"hit": 18.0, &"death": 8.0, &"module_install": 12.3
}

const LOOPS := [&"idle", &"run", &"jump_up", &"fall", &"dash", &"dodge_invulnerable"]

static func build() -> SpriteFrames:
	var library := SpriteFrames.new()
	library.remove_animation(&"default")
	for animation_name: StringName in FRAME_COUNTS:
		library.add_animation(animation_name)
		library.set_animation_loop(animation_name, animation_name in LOOPS)
		library.set_animation_speed(animation_name, FPS[animation_name])
		if animation_name == &"heavy_recovery":
			# The first two source poses look like a knockdown. Start at the
			# impact pose and recover through the three stable standing poses.
			_add_atlas_frame(library, animation_name, TEXTURES[&"heavy_attack"], 2)
			for frame_index: int in [2, 3, 4, 4]:
				_add_atlas_frame(library, animation_name, TEXTURES[animation_name], frame_index)
		else:
			for frame_index: int in range(FRAME_COUNTS[animation_name]):
				_add_atlas_frame(library, animation_name, TEXTURES[animation_name], frame_index)
	return library

static func _add_atlas_frame(library: SpriteFrames, animation_name: StringName, texture: Texture2D, frame_index: int) -> void:
	var frame := AtlasTexture.new()
	frame.atlas = texture
	frame.region = Rect2(frame_index * 64, 0, 64, 64)
	library.add_frame(animation_name, frame)
