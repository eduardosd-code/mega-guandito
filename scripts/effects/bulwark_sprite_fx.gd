class_name BulwarkSpriteFX
extends Node2D

@export_enum("heavy_impact_fx", "charge_trail_fx", "backhand_arc_fx") var fx_name := "heavy_impact_fx"
@onready var sprite: AnimatedSprite2D = $Sprite

const SPECS := {
	"heavy_impact_fx": [Vector2i(128, 96), 5, 16.0],
	"charge_trail_fx": [Vector2i(128, 64), 6, 20.0],
	"backhand_arc_fx": [Vector2i(128, 96), 4, 18.0]
}

func _ready() -> void:
	var spec: Array = SPECS[fx_name]
	var frames := SpriteFrames.new(); frames.remove_animation(&"default"); frames.add_animation(&"play")
	frames.set_animation_loop(&"play", false); frames.set_animation_speed(&"play", spec[2])
	var texture := load("res://assets/enemies/sector_07/bulwark/fx/%s.png" % fx_name) as Texture2D
	for index: int in range(spec[1]):
		var frame := AtlasTexture.new(); frame.atlas = texture
		frame.region = Rect2(index * spec[0].x, 0, spec[0].x, spec[0].y); frames.add_frame(&"play", frame)
	sprite.sprite_frames = frames; sprite.play(&"play"); sprite.animation_finished.connect(queue_free)
