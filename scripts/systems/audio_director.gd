extends Node
## Autoload that voices gameplay from the outside: it listens to `audio_hook` signals,
## enemy hurtboxes and polled player state, so gameplay scripts never reference audio.
## Every SFX is a procedurally generated placeholder (AudioStreamWAV) until real assets land.

signal sound_played(event_name: StringName)

const MIX_RATE := 22050
const POOL_SIZE := 12
const DUCK_BUSES: Array[StringName] = [&"Ambience", &"Music"]
const DUCK_DB := -9.0

# name: [freq_start, freq_end, seconds, noise 0..1, volume_db, wave("sine"/"square"/"saw"), pitch_jitter]
const RECIPES := {
	&"hammer_light": [320.0, 140.0, 0.10, 0.45, -8.0, "square", 0.08],
	&"hammer_heavy": [150.0, 55.0, 0.22, 0.55, -4.0, "square", 0.06],
	&"hammer_charged": [220.0, 40.0, 0.38, 0.6, -2.0, "saw", 0.04],
	&"charge_ready": [660.0, 1320.0, 0.16, 0.0, -12.0, "sine", 0.0],
	&"dash": [900.0, 300.0, 0.12, 0.8, -14.0, "sine", 0.1],
	&"wall_jump": [380.0, 620.0, 0.08, 0.35, -13.0, "square", 0.08],
	&"land": [120.0, 70.0, 0.07, 0.7, -16.0, "sine", 0.12],
	&"player_hurt": [480.0, 160.0, 0.2, 0.3, -6.0, "saw", 0.05],
	&"enemy_attack": [260.0, 420.0, 0.14, 0.2, -12.0, "saw", 0.08],
	&"enemy_hit": [240.0, 110.0, 0.09, 0.5, -10.0, "square", 0.1],
	&"enemy_death": [200.0, 35.0, 0.35, 0.75, -6.0, "saw", 0.06],
	&"armor_break": [700.0, 180.0, 0.18, 0.7, -8.0, "square", 0.06],
	&"projectile_fire": [1100.0, 520.0, 0.09, 0.15, -14.0, "square", 0.1],
	&"projectile_hit": [500.0, 200.0, 0.07, 0.6, -15.0, "sine", 0.1],
	&"hound_charge": [90.0, 180.0, 0.4, 0.5, -6.0, "saw", 0.03],
	&"hound_pounce": [160.0, 380.0, 0.2, 0.45, -7.0, "saw", 0.05],
	&"hound_roar": [110.0, 70.0, 0.9, 0.55, -3.0, "saw", 0.02],
	&"hound_destroy": [180.0, 25.0, 1.2, 0.85, -2.0, "saw", 0.0],
}
# Events heavy enough to briefly pull ambience and music down.
const DUCK_EVENTS: Array[StringName] = [&"hammer_heavy", &"hammer_charged", &"hound_roar", &"hound_destroy", &"enemy_death"]

var streams := {}
var pool: Array[AudioStreamPlayer] = []
var next_voice := 0
var duck_tween: Tween
var rng := RandomNumberGenerator.new()

var _player: Node
var _prev_charge_ready := false
var _prev_dash_left := 0.0
var _prev_on_floor := true

func _ready() -> void:
	add_to_group("audio_director")
	process_mode = Node.PROCESS_MODE_ALWAYS
	for event_name in RECIPES:
		streams[event_name] = _synthesize(RECIPES[event_name])
	for index in range(POOL_SIZE):
		var voice := AudioStreamPlayer.new()
		voice.bus = &"SFX"
		add_child(voice)
		pool.append(voice)
	get_tree().node_added.connect(_on_node_added)
	for node in get_tree().root.find_children("*", "", true, false):
		_on_node_added(node)

func play(event_name: StringName, _world_position := Vector2.ZERO) -> bool:
	if not streams.has(event_name):
		return false
	var recipe: Array = RECIPES[event_name]
	var voice := pool[next_voice]
	next_voice = (next_voice + 1) % pool.size()
	voice.stream = streams[event_name]
	var jitter: float = recipe[6]
	voice.pitch_scale = 1.0 + rng.randf_range(-jitter, jitter)
	voice.volume_db = float(recipe[4]) + rng.randf_range(-1.5, 0.0)
	voice.play()
	if event_name in DUCK_EVENTS:
		duck()
	sound_played.emit(event_name)
	return true

func duck(seconds := 0.45) -> void:
	if duck_tween and duck_tween.is_valid():
		duck_tween.kill()
	duck_tween = create_tween().set_parallel()
	for bus_name in DUCK_BUSES:
		var bus := AudioServer.get_bus_index(bus_name)
		if bus < 0:
			continue
		var base_db := _base_db(bus_name)
		AudioServer.set_bus_volume_db(bus, base_db + DUCK_DB)
		duck_tween.tween_method(func(db: float): AudioServer.set_bus_volume_db(bus, db), base_db + DUCK_DB, base_db, seconds).set_delay(0.08)

func _base_db(bus_name: StringName) -> float:
	return -6.0 if bus_name == &"Music" else -4.0

# --- Wiring -----------------------------------------------------------------

func _on_node_added(node: Node) -> void:
	if node.has_signal("audio_hook") and not node.is_connected("audio_hook", _on_audio_hook):
		node.connect("audio_hook", _on_audio_hook)
	if node is HurtboxComponent and not node.hit_received.is_connected(_on_enemy_hurtbox_hit):
		node.hit_received.connect(_on_enemy_hurtbox_hit.bind(node))

func _on_audio_hook(event_name: StringName, world_position: Vector2) -> void:
	play(event_name, world_position)

func _on_enemy_hurtbox_hit(data: AttackData, _direction: float, attacker: Node, hurtbox: HurtboxComponent) -> void:
	if hurtbox.team == &"player" or attacker == null or attacker.get("team") != &"player" or data == null:
		return
	var event_name := &"hammer_light"
	if data.id == &"charged":
		event_name = &"hammer_charged"
	elif data.impact_fx == "heavy":
		event_name = &"hammer_heavy"
	play(event_name, hurtbox.global_position)

func _process(_delta: float) -> void:
	if not is_instance_valid(_player):
		_attach_player(get_tree().get_first_node_in_group("player"))
		return
	# Observe the player from outside: edges in exported state become sounds.
	var charge_ready: bool = _player.get("charge_ready")
	if charge_ready and not _prev_charge_ready:
		play(&"charge_ready")
	_prev_charge_ready = charge_ready
	var dash_left: float = _player.get("dash_left")
	if dash_left > 0.0 and _prev_dash_left <= 0.0:
		play(&"dash")
	_prev_dash_left = dash_left
	if _player is CharacterBody2D:
		var on_floor := (_player as CharacterBody2D).is_on_floor()
		if on_floor and not _prev_on_floor and (_player as CharacterBody2D).velocity.y >= 0.0:
			play(&"land")
		_prev_on_floor = on_floor

func _attach_player(player: Node) -> void:
	_player = player
	if player == null:
		return
	_prev_on_floor = true
	var machine = player.get("state_machine")
	if machine and machine.has_signal("state_changed"):
		machine.state_changed.connect(_on_player_state_changed)
	var health = player.get("health")
	if health and health.has_signal("damaged"):
		health.damaged.connect(func(_amount: int): play(&"player_hurt"))

func _on_player_state_changed(current: StringName, previous: StringName) -> void:
	if current == &"jump" and previous == &"wall_slide":
		play(&"wall_jump")

# --- Synthesis --------------------------------------------------------------

func _synthesize(recipe: Array) -> AudioStreamWAV:
	var f0: float = recipe[0]
	var f1: float = recipe[1]
	var length: float = recipe[2]
	var noise_mix: float = recipe[3]
	var wave: String = recipe[5]
	var frames := int(length * MIX_RATE)
	var data := PackedByteArray()
	data.resize(frames * 2)
	var noise_rng := RandomNumberGenerator.new()
	noise_rng.seed = hash(recipe)
	var phase := 0.0
	var held_noise := 0.0
	for index in range(frames):
		var t := float(index) / frames
		phase = fmod(phase + lerpf(f0, f1, t) / MIX_RATE, 1.0)
		var tone := 0.0
		match wave:
			"square": tone = 1.0 if phase < 0.5 else -1.0
			"saw": tone = phase * 2.0 - 1.0
			_: tone = sin(TAU * phase)
		if index % 3 == 0:
			held_noise = noise_rng.randf_range(-1.0, 1.0)
		var attack := minf(1.0, float(index) / 60.0)
		var envelope := attack * pow(1.0 - t, 2.0)
		var sample := (tone * (1.0 - noise_mix) + held_noise * noise_mix) * envelope * 0.5
		data.encode_s16(index * 2, int(clampf(sample, -1.0, 1.0) * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.data = data
	return stream
