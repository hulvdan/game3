extends Node

static var _async_scene_loaded = false

@export var container_creatures: Node

var player: Node3D
@export var camera: Camera3D

@export var camera_distance: float
@export var camera_angle: float

@export var elements: Array[Node3D]

@export var temp_mobs: Array[Vector2]
@export var temp_creature_to_spawn1: Creature
@export var temp_creature_to_spawn: CreatureData


func _make_creature(_data: CreatureData, _pos: Vector2) -> void:
	#data.new
	pass
	
	
func _ready() -> void:
	for c: Node in container_creatures.get_children():
		container_creatures.remove_child(c)
	assert(camera)
	assert(camera_distance > 0)
	assert(camera_angle > 0)
	
	_make_creature(temp_creature_to_spawn, Vector2(0,0))
	
	for element: Node3D in elements:
		assert(element)


func _physics_process(delta: float) -> void:
	if Meta.async_data_loaded and not _async_scene_loaded:
		_async_scene_loaded = true
		var r = load("res://assets/async_data.tscn")
		@warning_ignore('unsafe_method_access')
		var n: Node = r.instantiate()
		add_child(n)

	var player_move_direction = Input.get_vector("move_l", "move_r", "move_u", "move_d")
	var offset = player_move_direction * delta
	player.transform.origin.x += offset.x
	player.transform.origin.z += offset.y

	var camera_dir = Vector3(0, sin(camera_angle), cos(camera_angle))
	camera.transform.origin = player.transform.origin + camera_dir * camera_distance
	camera.transform = camera.transform.looking_at(player.transform.origin)

	for element: Node3D in elements:
		element.transform.basis = camera.transform.basis


func _process(_delta: float) -> void:
	pass
