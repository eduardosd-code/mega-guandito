extends AudioStreamPlayer

var playback: AudioStreamGeneratorPlayback
var phase := 0.0

func _ready() -> void:
	var generator := AudioStreamGenerator.new(); generator.mix_rate = 22050.0; generator.buffer_length = 0.35
	stream = generator; volume_db = -28.0; play(); playback = get_stream_playback() as AudioStreamGeneratorPlayback

func _process(_delta: float) -> void:
	if not playback: return
	var available := mini(playback.get_frames_available(),512)
	for index in range(available):
		phase += 1.0 / 22050.0
		var hum := sin(TAU*43.0*phase)*0.08 + sin(TAU*86.0*phase)*0.025
		var machine := sin(TAU*2.1*phase)*sin(TAU*118.0*phase)*0.018
		var sample := hum + machine
		playback.push_frame(Vector2(sample,sample))

func _exit_tree() -> void:
	stop()
	playback = null
