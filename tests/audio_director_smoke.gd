extends SceneTree

const DIRECTOR := preload("res://scripts/systems/audio_director.gd")
var failures: Array[String] = []

class HookEmitter extends Node2D:
	signal audio_hook(event_name: StringName, world_position: Vector2)

func _initialize() -> void: call_deferred("_run")
func _check(value: bool, label: String) -> void:
	if value: print("PASS: ", label)
	else: failures.append(label); push_error("FAIL: " + label)

func _run() -> void:
	for bus_name in ["Master", "Music", "SFX", "Ambience", "UI"]:
		_check(AudioServer.get_bus_index(bus_name) >= 0, "bus %s exists" % bus_name)
	for bus_name in ["Music", "SFX", "Ambience", "UI"]:
		var index := AudioServer.get_bus_index(bus_name)
		_check(index >= 0 and AudioServer.get_bus_send(index) == &"Master", "%s routes to Master" % bus_name)
	var director := get_first_node_in_group("audio_director")
	if director == null:
		director = DIRECTOR.new(); root.add_child(director)
	await process_frame
	_check(director.streams.size() >= 17, "placeholder SFX were synthesized")
	var heard: Array[StringName] = []
	director.sound_played.connect(func(event_name: StringName): heard.append(event_name))
	var emitter := HookEmitter.new(); root.add_child(emitter)
	await process_frame
	emitter.audio_hook.emit(&"hound_roar", Vector2(10, 20))
	_check(heard.has(&"hound_roar"), "audio_hook on a new node is voiced")
	var playing := false
	for voice in director.pool:
		if voice.playing and voice.bus == &"SFX": playing = true
	_check(playing, "a pooled SFX voice is playing")
	var ambience := AudioServer.get_bus_index("Ambience")
	_check(AudioServer.get_bus_volume_db(ambience) < -6.0, "heavy event ducks Ambience")
	_check(not director.play(&"no_such_sound"), "unknown events are ignored")
	if failures.is_empty(): print("ALL PASS"); quit(0)
	else: quit(1)
