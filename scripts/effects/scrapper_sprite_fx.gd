class_name ScrapperSpriteFX
extends Node2D

@export_enum("impact_fx", "charge_trail_fx", "sparks_fx") var fx_name := "impact_fx"
@onready var sprite: AnimatedSprite2D = $Sprite

const SPECS := {
	"impact_fx": [Vector2i(64, 64), 4, 18.0],
	"charge_trail_fx": [Vector2i(96, 64), 5, 20.0],
	"sparks_fx": [Vector2i(64, 64), 4, 22.0]
}

func _ready() -> void:
	var spec: Array = SPECS[fx_name]
	var frames := SpriteFrames.new(); frames.remove_animation(&"default"); frames.add_animation(&"play")
	frames.set_animation_loop(&"play", false); frames.set_animation_speed(&"play", spec[2])
	var texture := load("res://assets/enemies/sector_07/scrapper/fx/%s.png" % fx_name) as Texture2D
	for index: int in range(spec[1]):
		var frame := AtlasTexture.new(); frame.atlas = texture
		frame.region = Rect2(index * spec[0].x, 0, spec[0].x, spec[0].y); frames.add_frame(&"play", frame)
	sprite.sprite_frames = frames; sprite.play(&"play"); sprite.animation_finished.connect(queue_free)
