class_name GuanditoVisual
extends Node2D

var facing := 1.0
var action: StringName = &"idle"
var action_time := 0.0

func _process(delta: float) -> void:
	action_time += delta
	queue_redraw()

func set_action(value: StringName, look_direction: float) -> void:
	action = value
	facing = look_direction
	action_time = 0.0
	modulate = Color.WHITE if value != &"dead" else Color("#596265")

func _draw() -> void:
	var green := Color("#456b24")
	var lime := Color("#93e22b")
	var graphite := Color("#11181b")
	var metal := Color("#d9ddd5")
	var outline := Color("#071011")
	var orange := Color("#ff7138")
	var bob := sin(Time.get_ticks_msec() * 0.007) if action == &"idle" else 0.0
	var lean := 4.0 * facing if action in [&"run", &"dash", &"dodge_startup", &"dodge_evade"] else 0.0

	# Energy trail makes evade visually distinct from the offensive dash.
	if action == &"dodge_evade":
		for index in range(3):
			var trail_x := -facing * float(11 + index * 8)
			draw_circle(Vector2(trail_x, -3), 12.0 - index * 2.5, Color(0.45, 1.0, 0.2, 0.2 - index * 0.04))
	if action == &"dash":
		draw_line(Vector2(-facing * 10, 3), Vector2(-facing * 30, 3), Color(0.55, 0.9, 0.3, 0.55), 3)

	# Cable, large boots, agile limbs, reactor and visor from the official concept.
	draw_polyline(PackedVector2Array([Vector2(-4, -23), Vector2(-14 * facing, -32), Vector2(-18 * facing, -24)]), graphite, 3.0)
	draw_circle(Vector2(-18 * facing, -24), 2.5, lime)
	draw_rect(Rect2(-12 + lean, 13, 10, 8), outline)
	draw_rect(Rect2(-11 + lean, 14, 9, 6), green)
	draw_rect(Rect2(3 + lean, 13, 11, 8), outline)
	draw_rect(Rect2(4 + lean, 14, 9, 6), green)
	draw_line(Vector2(-6 + lean, 2), Vector2(-7 + lean, 14), graphite, 6)
	draw_line(Vector2(6 + lean, 2), Vector2(8 + lean, 14), graphite, 6)
	draw_circle(Vector2(lean, -2 + bob), 11, outline)
	draw_circle(Vector2(lean, -2 + bob), 9, green)
	draw_circle(Vector2(lean, -2 + bob), 4, metal)
	var reactor_color := orange if action == &"dodge_exposed" else lime
	draw_circle(Vector2(lean, -2 + bob), 2.4, reactor_color)
	draw_line(Vector2(-9 + lean, -6), Vector2(-14 + lean, 5), graphite, 6)
	draw_line(Vector2(9 + lean, -6), Vector2(15 + lean, 3), graphite, 6)
	draw_circle(Vector2(15 + lean, 4), 4, metal)
	draw_rect(Rect2(-13 + lean, -24 + bob, 26, 17), outline)
	draw_rect(Rect2(-11 + lean, -22 + bob, 22, 13), metal)
	draw_rect(Rect2(-10 + lean, -18 + bob, 20, 8), graphite)
	draw_circle(Vector2(-4 + lean, -14 + bob), 1.7, lime)
	draw_circle(Vector2(4 + lean, -14 + bob), 1.7, lime)
	draw_line(Vector2(10 + lean, -22 + bob), Vector2(12 + lean, -31 + bob), metal, 2)
	draw_circle(Vector2(12 + lean, -32 + bob), 1.5, lime)

	# Kinetic Pulse Hammer placeholder: industrial head plus green pulse chamber.
	if action in [&"attack", &"heavy"]:
		var hammer_center := Vector2(29 * facing + lean, -7 if action == &"attack" else -17)
		draw_line(Vector2(13 * facing + lean, 1), hammer_center, graphite, 5)
		draw_rect(Rect2(hammer_center - Vector2(8, 6), Vector2(16, 12)), outline)
		draw_rect(Rect2(hammer_center - Vector2(6, 4), Vector2(12, 8)), metal)
		draw_circle(hammer_center + Vector2(4 * facing, 0), 3.0, lime)
		var arc_radius := 22.0 if action == &"attack" else 28.0
		draw_arc(Vector2(11 * facing + lean, -4), arc_radius, -1.2 if facing > 0 else 1.94, 1.2 if facing > 0 else 4.34, 14, lime, 4)
	if action == &"dodge_exposed":
		draw_arc(Vector2(lean, -2), 14, 0, TAU, 18, orange, 2)
		draw_line(Vector2(-3, -35), Vector2(3, -29), orange, 2)
		draw_line(Vector2(3, -35), Vector2(-3, -29), orange, 2)
