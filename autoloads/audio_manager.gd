extends Node
## Centralizes audio playback with SFX pooling and music fade transitions.

const MAX_SIMULTANEOUS_SFX: int = 12

var _sfx_players: Array[AudioStreamPlayer] = []

@onready var _music_player: AudioStreamPlayer = $MusicPlayer


func _ready() -> void:
	for i: int in MAX_SIMULTANEOUS_SFX:
		var player := AudioStreamPlayer.new()
		player.bus = "SFX"
		add_child(player)
		_sfx_players.append(player)


func play_sfx(stream: AudioStream, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	for player: AudioStreamPlayer in _sfx_players:
		if not player.playing:
			player.stream = stream
			player.volume_db = volume_db
			player.pitch_scale = pitch
			player.play()
			return


func play_music(stream: AudioStream, fade_duration: float = 1.0) -> void:
	if _music_player.playing:
		var tween := create_tween()
		tween.tween_property(_music_player, "volume_db", -40.0, fade_duration)
		await tween.finished
	_music_player.stream = stream
	_music_player.volume_db = -40.0
	_music_player.play()
	var fade_in := create_tween()
	fade_in.tween_property(_music_player, "volume_db", 0.0, fade_duration)


func stop_music(fade_duration: float = 1.0) -> void:
	if _music_player.playing:
		var tween := create_tween()
		tween.tween_property(_music_player, "volume_db", -40.0, fade_duration)
		await tween.finished
		_music_player.stop()


func set_bus_volume(bus_name: String, linear: float) -> void:
	var bus_idx := AudioServer.get_bus_index(bus_name)
	if bus_idx >= 0:
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(linear))
