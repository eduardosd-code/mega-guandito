class_name HoundSpriteFX
extends Node2D

@export_enum("charge_trail_fx", "pounce_impact_fx", "claw_slash_fx", "energy_projectile", "energy_burst_fx", "destroy_fx") var fx_name := "charge_trail_fx"
@export var loop := false
@onready var sprite: AnimatedSprite2D = $Sprite

const SPECS := {
	"charge_trail_fx": [Vector2i(160, 96), 5, 18.0], "pounce_impact_fx": [Vector2i(160, 96), 5, 16.0],
	"claw_slash_fx": [Vector2i(160, 96), 6, 20.0], "energy_projectile": [Vector2i(48, 48), 4, 18.0],
	"energy_burst_fx": [Vector2i(192, 96), 8, 20.0], "destroy_fx": [Vector2i(160, 96), 8, 14.0]
}

static func build_frames(effect_name: String, should_loop := false) -> SpriteFrames:
	var spec: Array = SPECS[effect_name]
	var frames := SpriteFrames.new(); frames.remove_animation(&"default"); frames.add_animation(&"play")
	frames.set_animation_loop(&"play", should_loop); frames.set_animation_speed(&"play", spec[2])
	var texture := load("res://assets/enemies/sector_07/hound/fx/%s.png" % effect_name) as Texture2D
	for index: int in range(spec[1]):
		var frame := AtlasTexture.new(); frame.atlas = texture
		frame.region = Rect2(index * spec[0].x, 0, spec[0].x, spec[0].y); frames.add_frame(&"play", frame)
	return frames

func _ready() -> void:
	sprite.sprite_frames = build_frames(fx_name, loop); sprite.play(&"play")
	if not loop: sprite.animation_finished.connect(queue_free)
