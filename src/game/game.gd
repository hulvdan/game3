extends Node

static var _async_scene_loaded = false

func _physics_process(_delta: float) -> void:
	if Meta.async_data_loaded and not _async_scene_loaded:
		_async_scene_loaded = true
		var r = load("res://assets/async_data.tscn")
		@warning_ignore('unsafe_method_access')
		var n: Node = r.instantiate()
		add_child(n)
