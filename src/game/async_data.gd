extends Node

@export var music_default: Array[AudioStream] = []
@export var audio: AudioStreamPlayer


func _ready() -> void:
	assert(audio)
	if music_default:
		audio.bus = "Music"
		audio.stream = music_default[0]
		audio.play()
