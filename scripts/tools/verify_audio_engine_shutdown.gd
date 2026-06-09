extends Node

var failures: Array[String] = []


func _ready() -> void:
	var is_headless := DisplayServer.get_name() == "headless"
	if is_headless:
		_verify_headless_audio_disabled()
		_finish()
		return

	AudioEngine.play_success()
	await get_tree().process_frame

	var players: Array = AudioEngine.get("_players")
	var streams: Dictionary = AudioEngine.get("_streams")
	_expect(not players.is_empty(), "audio player pool exists")
	_expect(not streams.is_empty(), "procedural streams are generated")

	var had_stream_ref := false
	for player in players:
		if player is AudioStreamPlayer and player.stream != null:
			had_stream_ref = true
			break
	_expect(had_stream_ref, "playback assigns a stream before shutdown")

	AudioEngine.prepare_for_shutdown()

	streams = AudioEngine.get("_streams")
	var active_players: Array = AudioEngine.get("_players")
	_expect(streams.is_empty(), "shutdown clears generated stream cache")
	_expect(active_players.is_empty(), "shutdown clears audio player pool")
	for player in players:
		_expect(not is_instance_valid(player), "shutdown frees old audio players")

	_finish()


func _verify_headless_audio_disabled() -> void:
	var players: Array = AudioEngine.get("_players")
	var streams: Dictionary = AudioEngine.get("_streams")
	_expect(players.is_empty(), "headless mode does not create audio players")
	_expect(streams.is_empty(), "headless mode does not generate procedural streams")

	AudioEngine.play_success()
	AudioEngine.prepare_for_shutdown()

	players = AudioEngine.get("_players")
	streams = AudioEngine.get("_streams")
	_expect(players.is_empty(), "headless playback remains a no-op")
	_expect(streams.is_empty(), "headless shutdown has no retained streams")


func _finish() -> void:
	if failures.is_empty():
		print("Audio engine shutdown regression passed.")
		get_tree().quit(0)
	else:
		for failure in failures:
			push_error(failure)
		get_tree().quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
