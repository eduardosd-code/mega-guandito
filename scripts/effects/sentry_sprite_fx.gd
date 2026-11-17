class_name SentrySpriteFX
extends Node2D

@export_enum("projectile", "muzzle_flash_fx", "hit_sparks_fx") var fx_name := "muzzle_flash_fx"
@export var loop := false
@onready var sprite: AnimatedSprite2D = $Sprite

const SPECS := {
	"projectile": [Vector2i(32, 32), 4, 16.0],
	"muzzle_flash_fx": [Vector2i(48, 48), 4, 22.0],
	"hit_sparks_fx": [Vector2i(64, 64), 4, 20.0]
}

static func build_frames(effect_name: String, should_loop := false) -> SpriteFrames:
	var spec: Array = SPECS[effect_name]
	var frames := SpriteFrames.new(); frames.remove_animation(&"default"); frames.add_animation(&"play")
	frames.set_animation_loop(&"play", should_loop); frames.set_animation_speed(&"play", spec[2])
	var texture := load("res://assets/enemies/sector_07/sentry/fx/%s.png" % effect_name) as Texture2D
	for index: int in range(spec[1]):
		var frame := AtlasTexture.new(); frame.atlas = texture
		frame.region = Rect2(index * spec[0].x, 0, spec[0].x, spec[0].y); frames.add_frame(&"play", frame)
	return frames

func _ready() -> void:
	sprite.sprite_frames = build_frames(fx_name, loop); sprite.play(&"play")
	if not loop: sprite.animation_finished.connect(queue_free)
