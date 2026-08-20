extends Node2D

func _draw() -> void:
	draw_rect(Rect2(-40, -20, 900, 300), Color("#091116"))
	draw_colored_polygon(PackedVector2Array([Vector2(600, 198), Vector2(625, 20), Vector2(650, 198)]), Color("#14252a"))
	draw_line(Vector2(625, 22), Vector2(625, -10), Color("#71ba36"), 2)
	for x in range(20, 820, 90):
		draw_rect(Rect2(x, 80 + (x % 70), 58, 120), Color("#101d22"))
		draw_rect(Rect2(x + 8, 95 + (x % 70), 7, 35), Color("#31543b"))
	draw_line(Vector2(-20, 68), Vector2(840, 68), Color("#263a3d"), 9)
	draw_line(Vector2(-20, 68), Vector2(840, 68), Color("#44615b"), 2)
	for x in range(0, 850, 48):
		draw_circle(Vector2(x, 68), 5, Color("#162326"))
	draw_rect(Rect2(-40, 218, 900, 70), Color("#11191c"))
	draw_rect(Rect2(-40, 215, 900, 4), Color("#52615b"))
	for x in range(0, 840, 40):
		draw_line(Vector2(x, 220), Vector2(x + 18, 270), Color("#1c292c"), 2)
	draw_string(ThemeDB.fallback_font, Vector2(18, 205), "SECTOR K-01 // PATIO DE ENSAYO", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("#6fa53a"))
