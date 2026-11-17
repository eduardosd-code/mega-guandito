class_name EnemyProjectile
extends Area2D

signal impacted(world_position: Vector2)
signal audio_hook(event_name: StringName, world_position: Vector2)

var velocity := Vector2.ZERO
var damage_data: AttackData
var lifetime := 3.0
var animated_visual := false

func setup(direction: float, speed: float, damage: int) -> void:
	velocity = Vector2(direction * speed, 0.0)
	damage_data = AttackData.new()
	damage_data.damage = damage
	damage_data.knockback = Vector2(115, -35)
	damage_data.hitstun = 0.2
	damage_data.hitstop = 0.025

func use_sentry_visual() -> void:
	animated_visual = true
	var sprite := AnimatedSprite2D.new()
	sprite.name = "SentryProjectileVisual"; sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.sprite_frames = SentrySpriteFX.build_frames("projectile", true); sprite.play(&"play")
	sprite.flip_h = velocity.x < 0.0; add_child(sprite); queue_redraw()

func use_hound_visual() -> void:
	animated_visual = true
	var sprite := AnimatedSprite2D.new()
	sprite.name = "HoundProjectileVisual"; sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.sprite_frames = HoundSpriteFX.build_frames("energy_projectile", true); sprite.play(&"play")
	sprite.flip_h = velocity.x < 0.0; add_child(sprite); queue_redraw()

func _ready() -> void:
	add_to_group("enemy_projectiles")
	collision_layer = 8
	collision_mask = 1
	area_entered.connect(_on_area_entered)
	var shape_node := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 4.0
	shape_node.shape = shape
	add_child(shape_node)

func _physics_process(delta: float) -> void:
	position += velocity * delta
	lifetime -= delta
	queue_redraw()
	if lifetime <= 0.0:
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area.has_method("receive_hit"):
		area.receive_hit(damage_data, signf(velocity.x), self)
		impacted.emit(global_position)
		audio_hook.emit(&"projectile_hit", global_position)
		queue_free()

func _draw() -> void:
	if animated_visual: return
	draw_circle(Vector2.ZERO, 5, Color("#ff8a35"))
	draw_circle(Vector2.ZERO, 2, Color("#fff1a0"))
	draw_line(Vector2(-signf(velocity.x) * 5, 0), Vector2(-signf(velocity.x) * 14, 0), Color(1, 0.4, 0.1, 0.5), 3)
