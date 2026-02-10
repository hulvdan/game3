extends Node

class_name Game

static var _async_scene_loaded = false

@export var elements: Array[Node3D]

@export var camera_distance: float
@export var camera_angle: float

@export var creature_player: ResCreature

@export var packed_creature: PackedScene
@export var packed_floor_tile: PackedScene
@export var packed_collider_tile: PackedScene

var player: Creature

@onready var camera: Camera3D = $_camera
@onready var container_creatures: Node = $_container_creatures
@onready var container_floor: Node = $_container_floor


func _make_creature(res: ResCreature, pos: Vector2) -> Node3D:
	assert(res)
	var creature: Creature = packed_creature.instantiate()
	creature.transform.origin.x = pos.x
	creature.transform.origin.z = pos.y
	creature.res = res
	creature.node_sprite.texture = creature.res.texture

	elements.append(creature.node_rotate)
	container_creatures.add_child(creature)
	return creature


func _ready() -> void:
	assert(camera)
	assert(container_creatures)
	bf.clear_children(container_creatures)
	assert(camera_distance > 0)
	assert(camera_angle > 0)

	player = _make_creature(creature_player, Vector2(0, 0))
	for mob in glib.v.get_mobs_to_spawn():
		var r: ResCreature = load(mob.get_res())
		_make_creature(r, glib.ToV2(mob.get_pos()))

	for element in elements:
		assert(element)

	bf.clear_children(container_floor)
	var room = glib.v.get_rooms()[1]
	var size = glib.ToV2i(room.get_size())
	var room_offset = -Vector2(size) / 2
	var tiles = room.get_tiles()
	for y in range(size.y):
		for x in range(size.x):
			var pos = Vector2(x, y) + room_offset
			var t = y * size.x + x
			var node: Node3D
			if tiles[t]:
				node = packed_floor_tile.instantiate()
			else:
				node = packed_collider_tile.instantiate()
			node.transform.origin.x = pos.x
			node.transform.origin.z = pos.y
			container_floor.add_child(node)


func _move_body_with_speed(body: RigidBody3D, direction: Vector2, speed: float) -> void:
	var offset: Vector2 = direction * speed
	body.apply_central_force(
		Vector3(offset.x, 0, offset.y) * body.linear_damp * body.mass,
	)


func _physics_process(_dt: float) -> void:
	if Meta.async_data_loaded and not _async_scene_loaded:
		_async_scene_loaded = true
		var r = load("res://assets/async_data.tscn")
		@warning_ignore("unsafe_method_access")
		var n: Node = r.instantiate()
		add_child(n)

	_move_body_with_speed(
		player.node_body,
		Input.get_vector("move_l", "move_r", "move_u", "move_d"),
		glib.v.get_player_speed(),
	)

	var camera_dir = Vector3(0, sin(camera_angle), cos(camera_angle))
	camera.transform.origin = player.transform.origin + camera_dir * camera_distance
	camera.transform = camera.transform.looking_at(player.node_body.transform.origin)

	for element: Node3D in elements:
		element.transform.basis = camera.transform.basis


func _process(_delta: float) -> void:
	pass
