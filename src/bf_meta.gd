extends Node

var lang: String


func _ready() -> void:
	if !WebBus.is_init:
		await WebBus.inited

	WebBus.ready()
	lang = WebBus.get_language()
