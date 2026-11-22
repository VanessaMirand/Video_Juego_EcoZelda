extends Node

var sfx_player: AudioStreamPlayer
var music_player: AudioStreamPlayer

var sfx_sounds: Dictionary = {
	"collect_trash": preload("res://Assets/Audio/SFX/collect.wav"),
	"enemy_hit": preload("res://Assets/Audio/SFX/hit.wav"),
	"pinza_action": preload("res://Assets/Audio/SFX/pinza.wav"),
	"zone_purified": preload("res://Assets/Audio/SFX/purify.wav"),
	"recycle_success": preload("res://Assets/Audio/SFX/recycle.wav"),
}

var music_tracks: Dictionary = {
	"clean_forest": preload("res://Assets/Audio/Music/clean_forest.ogg"),
	"dirty_forest": preload("res://Assets/Audio/Music/dirty_forest.ogg"),
}

func _ready() -> void:
	sfx_player = AudioStreamPlayer.new()
	sfx_player.name = "SFXPlayer"
	add_child(sfx_player)

	music_player = AudioStreamPlayer.new()
	music_player.name = "MusicPlayer"
	music_player.volume_db = -10.0
	add_child(music_player)

	play_music("dirty_forest", -10.0)

func play_sfx(sound_name: String, pitch_randomness: float = 0.05) -> void:
	if not sfx_sounds.has(sound_name) or sfx_sounds[sound_name] == null:
		push_warning("SFX no encontrado o nulo: " + sound_name)
		return
	sfx_player.stream = sfx_sounds[sound_name]
	sfx_player.pitch_scale = randf_range(1.0 - pitch_randomness, 1.0 + pitch_randomness)
	sfx_player.play()
	print("[SoundManager] Reproduciendo SFX: ", sound_name)

func play_music(track_name: String, volume_db: float = -10.0) -> void:
	if not music_tracks.has(track_name) or music_tracks[track_name] == null:
		push_warning("Música no encontrada o nula: " + track_name)
		return
	var target_stream: AudioStream = music_tracks[track_name]
	if music_player.stream == target_stream and music_player.playing:
		return
	music_player.stop()
	music_player.stream = target_stream
	music_player.volume_db = volume_db
	music_player.play()
	print("[SoundManager] Reproduciendo música: ", track_name, " | playing: ", music_player.playing)
