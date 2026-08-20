class_name GuanditoActionFX
extends Node2D

@export_enum("impact_light", "kinetic_pulse", "heavy_impact", "dash_trail", "dodge_trail", "exposed", "module_install") var kind := "impact_light"
@export var lifetime := 0.24
var elapsed := 0.0
var facing := 1.0

func setup(look_direction: float = 1.0) -> void:
	facing = signf(look_direction) if look_direction != 0.0 else 1.0
	queue_redraw()

func _process(delta: float) -> void:
	elapsed += delta
	queue_redraw()
	if elapsed >= lifetime:
		queue_free()

func _draw() -> void:
	var progress := clampf(elapsed / maxf(lifetime, 0.001), 0.0, 1.0)
	var alpha := 1.0 - progress
	var lime := Color(0.58, 1.0, 0.2, alpha)
	var orange := Color(1.0, 0.3, 0.12, alpha)
	match kind:
		"impact_light":
			for angle in range(0, 360, 60):
				var direction := Vector2.RIGHT.rotated(deg_to_rad(angle))
				draw_line(direction * 3, direction * lerpf(8, 18, progress), lime, 2.0)
		"kinetic_pulse":
			draw_arc(Vector2.ZERO, lerpf(7, 30, progress), -1.2 if facing > 0 else 1.94, 1.2 if facing > 0 else 4.34, 20, lime, 4.0)
		"heavy_impact":
			draw_arc(Vector2.ZERO, lerpf(5, 38, progress), 0, TAU, 28, lime, 4.0)
			for x in [-18.0, -8.0, 9.0, 20.0]: draw_line(Vector2(x, 2), Vector2(x * 1.25, -lerpf(3, 17, progress)), lime, 2.0)
		"dash_trail":
			for index in range(4): draw_line(Vector2(-facing * (8 + index * 7), index - 2), Vector2(-facing * (24 + index * 9), index - 2), Color(lime, alpha * (0.8 - index * 0.14)), 3.0)
		"dodge_trail":
			for index in range(3): draw_circle(Vector2(-facing * (10 + index * 9), 0), 11.0 - index * 2.5, Color(0.4, 1.0, 0.25, alpha * (0.3 - index * 0.06)))
		"exposed":
			draw_arc(Vector2.ZERO, 15 + sin(elapsed * 24.0) * 2, 0, TAU, 20, orange, 2.0)
			for angle in [0.3, 2.2, 4.0, 5.4]: draw_line(Vector2.RIGHT.rotated(angle) * 10, Vector2.RIGHT.rotated(angle) * 19, orange, 1.5)
		"module_install":
			draw_arc(Vector2.ZERO, lerpf(26, 8, progress), 0, TAU, 24, lime, 3.0)
			draw_arc(Vector2.ZERO, lerpf(8, 25, progress), 0, TAU, 24, Color(lime, alpha * 0.55), 1.0)
