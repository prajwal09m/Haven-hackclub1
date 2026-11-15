class_name ProcAudio
extends RefCounted
## Tiny procedurally generated sound effects (no audio files needed).

const RATE := 22050
static var _cache: Dictionary = {}


static func get_sound(sound_name: String) -> AudioStreamWAV:
	if not _cache.has(sound_name):
		_cache[sound_name] = _make_wav(_generate(sound_name))
	return _cache[sound_name]


static func _make_wav(samples: PackedFloat32Array) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		data.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32000.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.stereo = false
	wav.data = data
	return wav


static func _generate(sound_name: String) -> PackedFloat32Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1989
	var out := PackedFloat32Array()
	match sound_name:
		"knock":
			out.resize(int(RATE * 0.28))
			for i in out.size():
				var t := float(i) / RATE
				out[i] = (sin(TAU * 85.0 * t) * 0.8 + rng.randf_range(-1.0, 1.0) * 0.25) * exp(-t * 22.0)
		"scratch":
			out.resize(int(RATE * 2.6))
			var last := 0.0
			for i in out.size():
				var t := float(i) / RATE
				var raw := rng.randf_range(-1.0, 1.0)
				var hp := raw - last
				last = raw
				var gate := maxf(0.0, sin(TAU * 3.2 * t)) * (0.5 + 0.5 * sin(TAU * 13.0 * t))
				out[i] = hp * gate * 0.55 * (1.0 - t / 2.6)
		"chime":
			out.resize(int(RATE * 0.5))
			for i in out.size():
				var t := float(i) / RATE
				out[i] = (sin(TAU * 880.0 * t) + 0.5 * sin(TAU * 1320.0 * t)) * 0.35 * exp(-t * 7.0)
		"shot":
			out.resize(int(RATE * 0.5))
			for i in out.size():
				var t := float(i) / RATE
				out[i] = (rng.randf_range(-1.0, 1.0) * 0.9 + sin(TAU * 60.0 * t) * 0.5) * exp(-t * 9.0)
		"click":
			out.resize(int(RATE * 0.06))
			for i in out.size():
				var t := float(i) / RATE
				out[i] = rng.randf_range(-1.0, 1.0) * 0.4 * exp(-t * 80.0)
		"shriek":
			out.resize(int(RATE * 1.1))
			var phase := 0.0
			for i in out.size():
				var t := float(i) / RATE
				phase += TAU * (300.0 + 700.0 * t) / RATE
				out[i] = (fmod(phase, TAU) / PI - 1.0) * 0.3 * (1.0 - t / 1.1) + rng.randf_range(-0.12, 0.12)
		"growl":
			out.resize(int(RATE * 1.4))
			var low := 0.0
			for i in out.size():
				var t := float(i) / RATE
				low += (rng.randf_range(-1.0, 1.0) - low) * 0.06
				out[i] = low * 2.4 * (0.6 + 0.4 * sin(TAU * 28.0 * t)) * sin(PI * t / 1.4)
		"wind":
			# 4 s loopable low-passed noise with a slow swell (whole modulation cycles).
			out.resize(RATE * 4)
			var low_wind := 0.0
			for i in out.size():
				var t := float(i) / RATE
				low_wind += (rng.randf_range(-1.0, 1.0) - low_wind) * 0.03
				out[i] = low_wind * 5.0 * (0.55 + 0.45 * sin(TAU * 0.5 * t))
		"static":
			out.resize(int(RATE * 1.5))
			for i in out.size():
				out[i] = rng.randf_range(-1.0, 1.0) * 0.35
		_:
			out.resize(1)
	return out


## Plays a non-positional sound that frees itself.
static func play(owner_node: Node, sound_name: String, volume_db: float = 0.0, loop: bool = false) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	var stream := get_sound(sound_name)
	if loop:
		stream = stream.duplicate() as AudioStreamWAV
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_end = stream.data.size() / 2
	player.stream = stream
	player.volume_db = volume_db
	player.process_mode = Node.PROCESS_MODE_ALWAYS
	owner_node.add_child(player)
	player.play()
	if not loop:
		player.finished.connect(player.queue_free)
	return player


## Plays a positional sound at a world position that frees itself.
static func play_at(owner_node: Node, sound_name: String, world_position: Vector3, volume_db: float = 0.0) -> AudioStreamPlayer3D:
	var player := AudioStreamPlayer3D.new()
	player.stream = get_sound(sound_name)
	player.volume_db = volume_db
	player.unit_size = 6.0
	owner_node.add_child(player)
	player.global_position = world_position
	player.play()
	player.finished.connect(player.queue_free)
	return player
