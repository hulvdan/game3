extends Node

static var _async_scene_loaded = false

@export var player: Transform3D
@export var camera: Camera3D

@export var camera_distance: float
@export var camera_angle: float

@export var elements: Array[Node]


func _physics_process(_delta: float) -> void:
	if Meta.async_data_loaded and not _async_scene_loaded:
		_async_scene_loaded = true
		var r = load("res://assets/async_data.tscn")
		@warning_ignore('unsafe_method_access')
		var n: Node = r.instantiate()
		add_child(n)

	const player_move_direction = Input.get_vector("move_l", "move_r", "move_u", "move_d")
	player.origin += player_move_direction


func _process(_delta: float) -> void:
	camera.transform = camera.transform.looking_at(player.origin)
