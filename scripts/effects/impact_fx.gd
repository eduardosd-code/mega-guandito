class_name ImpactFX
extends Node2D

var kind := "light"
var lifetime := 0.22
var elapsed := 0.0

func setup(effect_kind: String) -> void:
	kind = effect_kind
	match kind:
		"kinetic": lifetime = 0.32
		"heavy": lifetime = 0.4
		"perfect": lifetime = 0.45
		_: lifetime = 0.2
	_play_placeholder_tone()
	queue_redraw()

func _process(delta: float) -> void:
	elapsed += delta
	queue_redraw()
	if elapsed >= lifetime:
		queue_free()

func _draw() -> void:
	var progress := clampf(elapsed / lifetime, 0.0, 1.0)
	var alpha := 1.0 - progress
	var lime := Color(0.55, 1.0, 0.2, alpha)
	if kind == "light":
		for angle in range(0, 360, 72):
			var vector := Vector2.RIGHT.rotated(deg_to_rad(angle))
			draw_line(vector * 3, vector * (7 + progress * 8), lime, 1.5)
	elif kind in ["kinetic", "heavy"]:
		var radius := lerpf(4.0, 25.0 if kind == "kinetic" else 34.0, progress)
		draw_arc(Vector2.ZERO, radius, 0, TAU, 24, lime, 3.0 if kind == "heavy" else 2.0)
		if kind == "heavy":
			draw_circle(Vector2.ZERO, 8.0 * (1.0 - progress), Color(0.85, 1.0, 0.65, alpha * 0.65))
	else:
		draw_arc(Vector2.ZERO, lerpf(10.0, 27.0, progress), 0, TAU, 28, Color(0.4, 1.0, 0.9, alpha), 2.0)
		draw_string(ThemeDB.fallback_font, Vector2(-32, -24 - progress * 8), "PERFECT EVADE", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.7, 1.0, 0.85, alpha))

func _play_placeholder_tone() -> void:
	var stream := AudioStreamGenerator.new()
	stream.mix_rate = 22050.0
	stream.buffer_length = 0.18
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = -18.0 if kind == "light" else -13.0
	add_child(player)
	player.play()
	var playback := player.get_stream_playback() as AudioStreamGeneratorPlayback
	var frame_count := 1200 if kind == "light" else 1800
	var frequency := 260.0 if kind == "light" else (105.0 if kind == "heavy" else 165.0)
	var frames := PackedVector2Array()
	frames.resize(frame_count)
	for index in range(frame_count):
		var decay := 1.0 - float(index) / frame_count
		var sample := sin(TAU * frequency * index / stream.mix_rate) * decay * 0.22
		frames[index] = Vector2(sample, sample)
	playback.push_buffer(frames)
