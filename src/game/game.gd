extends Node

static var _async_scene_loaded = false

@export var container_creatures: Node
@export var elements: Array[Node3D]

@export var camera: Camera3D
@export var camera_distance: float
@export var camera_angle: float

@export var creature_player: CreatureData
@export var mobs_to_spawn: Array[MobToSpawn]

@export var collectibles: Array[Collectible]

@export var packed_creature: PackedScene

var player: Node3D


func _make_creature(data: CreatureData, pos: Vector2) -> Node3D:
	var creature: Creature = packed_creature.instantiate()
	creature.transform.origin.x = pos.x
	creature.transform.origin.z = pos.y
	creature.data = data
	creature.sprite.texture = creature.data.texture

	elements.append(creature)
	return creature


func _ready() -> void:
	for c: Node in container_creatures.get_children():
		container_creatures.remove_child(c)
	assert(camera)
	assert(camera_distance > 0)
	assert(camera_angle > 0)

	player = _make_creature(creature_player, Vector2(0, 0))
	for mob in mobs_to_spawn:
		_make_creature(mob.data, mob.pos)

	for element: Node3D in elements:
		assert(element)


func _physics_process(delta: float) -> void:
	if Meta.async_data_loaded and not _async_scene_loaded:
		_async_scene_loaded = true
		var r = load("res://assets/async_data.tscn")
		@warning_ignore("unsafe_method_access")
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
