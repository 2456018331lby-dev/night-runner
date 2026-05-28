extends Node
## AudioEngine: procedural SFX synthesizer.
##
## Generates all game sound effects from scratch using PCM waveforms.
## No external audio files needed. Each sound is a short AudioStreamWAV
## created at runtime with sine waves, noise bursts, and frequency sweeps.
##
## Boundary: AudioEngine only plays sounds. Game logic calls play_*() methods.

var _streams: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
const POOL_SIZE := 16


func _ready() -> void:
	_generate_all_sounds()
	for i in POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.bus = "Master"
		add_child(player)
		_players.append(player)


func play_attack() -> void:
	_play("attack")


func play_hit() -> void:
	_play("hit")


func play_dash() -> void:
	_play("dash")


func play_land() -> void:
	_play("land")


func play_core_collect() -> void:
	_play("core_collect")


func play_combo(count: int) -> void:
	if count >= 6:
		_play("combo_high")
	elif count >= 3:
		_play("combo_mid")


func play_damage() -> void:
	_play("damage")


func play_extraction_unlock() -> void:
	_play("extraction_unlock")


func play_enemy_defeat() -> void:
	_play("enemy_defeat")


func play_stalker_warn() -> void:
	_play("stalker_warn")


func play_phantom_dive() -> void:
	_play("phantom_dive")


func play_bastion_shock() -> void:
	_play("bastion_shock")


func play_hazard_warn() -> void:
	_play("hazard_warn")


func play_fail() -> void:
	_play("fail")


func play_success() -> void:
	_play("success")


func _play(sound_name: String) -> void:
	if not _streams.has(sound_name):
		return
	for player in _players:
		if not player.playing:
			player.stream = _streams[sound_name]
			player.volume_db = -6.0
			player.pitch_scale = 1.0
			player.play()
			return


func _generate_all_sounds() -> void:
	_streams["attack"] = _make_sweep(0.08, 320.0, 180.0, 0.6)
	_streams["hit"] = _make_noise_burst(0.06, 0.8)
	_streams["dash"] = _make_sweep(0.1, 200.0, 400.0, 0.35)
	_streams["land"] = _make_thump(0.06, 80.0, 0.4)
	_streams["core_collect"] = _make_chime(0.18, 880.0, 1320.0, 0.5)
	_streams["combo_mid"] = _make_rising_tone(0.14, 440.0, 660.0, 0.45)
	_streams["combo_high"] = _make_rising_tone(0.2, 520.0, 1040.0, 0.55)
	_streams["damage"] = _make_thump(0.12, 60.0, 0.7)
	_streams["extraction_unlock"] = _make_chime(0.35, 660.0, 1320.0, 0.6)
	_streams["enemy_defeat"] = _make_sweep(0.1, 500.0, 200.0, 0.35)
	_streams["stalker_warn"] = _make_sweep(0.3, 180.0, 120.0, 0.4)
	_streams["phantom_dive"] = _make_sweep(0.15, 600.0, 300.0, 0.45)
	_streams["bastion_shock"] = _make_noise_burst(0.18, 0.7)
	_streams["hazard_warn"] = _make_sweep(0.12, 400.0, 300.0, 0.3)
	_streams["fail"] = _make_sweep(0.4, 440.0, 110.0, 0.5)
	_streams["success"] = _make_chime(0.4, 520.0, 1040.0, 0.55)


func _make_sweep(duration: float, freq_start: float, freq_end: float, amplitude: float) -> AudioStreamWAV:
	var sample_rate := 11025
	var num_samples := int(duration * sample_rate)
	var data := PackedByteArray()
	data.resize(num_samples * 2)
	for i in num_samples:
		var t := float(i) / float(sample_rate)
		var progress := float(i) / float(num_samples)
		var freq := lerpf(freq_start, freq_end, progress)
		var phase := TAU * freq * t
		var envelope := _envelope(progress, 0.08, 0.15)
		var sample := sin(phase) * amplitude * envelope
		var packed := int(clampf(sample, -1.0, 1.0) * 32767.0)
		data[i * 2] = packed & 0xFF
		data[i * 2 + 1] = (packed >> 8) & 0xFF
	return _make_wav(sample_rate, data)


func _make_noise_burst(duration: float, amplitude: float) -> AudioStreamWAV:
	var sample_rate := 11025
	var num_samples := int(duration * sample_rate)
	var data := PackedByteArray()
	data.resize(num_samples * 2)
	for i in num_samples:
		var progress := float(i) / float(num_samples)
		var envelope := _envelope(progress, 0.02, 0.1)
		var noise := randf_range(-1.0, 1.0) * amplitude * envelope
		var packed := int(clampf(noise, -1.0, 1.0) * 32767.0)
		data[i * 2] = packed & 0xFF
		data[i * 2 + 1] = (packed >> 8) & 0xFF
	return _make_wav(sample_rate, data)


func _make_thump(duration: float, freq: float, amplitude: float) -> AudioStreamWAV:
	var sample_rate := 11025
	var num_samples := int(duration * sample_rate)
	var data := PackedByteArray()
	data.resize(num_samples * 2)
	for i in num_samples:
		var t := float(i) / float(sample_rate)
		var progress := float(i) / float(num_samples)
		var envelope := _envelope(progress, 0.01, 0.05)
		var freq_decay := freq * (1.0 - progress * 0.7)
		var sample := sin(TAU * freq_decay * t) * amplitude * envelope
		var noise := randf_range(-0.15, 0.15) * envelope
		var packed := int(clampf(sample + noise, -1.0, 1.0) * 32767.0)
		data[i * 2] = packed & 0xFF
		data[i * 2 + 1] = (packed >> 8) & 0xFF
	return _make_wav(sample_rate, data)


func _make_chime(duration: float, freq_low: float, freq_high: float, amplitude: float) -> AudioStreamWAV:
	var sample_rate := 11025
	var num_samples := int(duration * sample_rate)
	var data := PackedByteArray()
	data.resize(num_samples * 2)
	for i in num_samples:
		var t := float(i) / float(sample_rate)
		var progress := float(i) / float(num_samples)
		var envelope := _envelope(progress, 0.1, 0.2)
		var s1 := sin(TAU * freq_low * t) * 0.5
		var s2 := sin(TAU * freq_high * t) * 0.35
		var s3 := sin(TAU * freq_low * 1.5 * t) * 0.15
		var sample := (s1 + s2 + s3) * amplitude * envelope
		var packed := int(clampf(sample, -1.0, 1.0) * 32767.0)
		data[i * 2] = packed & 0xFF
		data[i * 2 + 1] = (packed >> 8) & 0xFF
	return _make_wav(sample_rate, data)


func _make_rising_tone(duration: float, freq_start: float, freq_end: float, amplitude: float) -> AudioStreamWAV:
	var sample_rate := 11025
	var num_samples := int(duration * sample_rate)
	var data := PackedByteArray()
	data.resize(num_samples * 2)
	for i in num_samples:
		var t := float(i) / float(sample_rate)
		var progress := float(i) / float(num_samples)
		var freq := lerpf(freq_start, freq_end, progress * progress)
		var envelope := _envelope(progress, 0.1, 0.25)
		var sample := sin(TAU * freq * t) * amplitude * envelope
		var packed := int(clampf(sample, -1.0, 1.0) * 32767.0)
		data[i * 2] = packed & 0xFF
		data[i * 2 + 1] = (packed >> 8) & 0xFF
	return _make_wav(sample_rate, data)


func _envelope(progress: float, attack: float, release: float) -> float:
	if progress < attack:
		return progress / attack
	if progress > 1.0 - release:
		return (1.0 - progress) / release
	return 1.0


func _make_wav(sample_rate: int, pcm_data: PackedByteArray) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = pcm_data
	return wav
