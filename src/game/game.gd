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
@export var packed_door: PackedScene
@export var packed_room: PackedScene

var player: Creature
var current_room_pos: Vector2i = Vector2i(-1, -1)
var rooms: Array[RoomData] = []

var room_node: Node
var room: Room

@onready var camera: Camera3D = $_camera


class RoomData:
	var directions: int = 0


func _make_creature(res: ResCreature, pos: Vector2) -> Node3D:
	assert(res)
	var creature: Creature = packed_creature.instantiate()
	bf.set_pos_2d(creature, pos)
	creature.res = res
	creature.node_sprite.texture = creature.res.texture

	elements.append(creature.node_rotate)
	room.container_creatures.add_child(creature)
	return creature


func _on_player_entered_door(_body: Node3D) -> void:
	if _body == player:
		print('player entered door')


func _ready() -> void:
	var ws: Vector2i = glib.ToV2i(glib.v.get_world_size())
	for y in range(ws.y):
		for x in range(ws.x):
			rooms.append(RoomData.new())

	if room:
		remove_child(room)
	room = packed_room.instantiate()
	add_child(room)

	assert(room.container_creatures)
	bf.clear_children(room.container_creatures)
	assert(camera_distance > 0)
	assert(camera_angle > 0)

	var g_room = glib.v.get_rooms()[1]
	var size: Vector2i = glib.ToV2i(g_room.get_size())

	player = _make_creature(creature_player, Vector2(size) / 2)
	for mob in glib.v.get_mobs_to_spawn():
		var r: ResCreature = load(mob.get_res())
		_make_creature(r, glib.ToV2(mob.get_pos()) + Vector2(size) / 2)

	for element in elements:
		assert(element)

	bf.clear_children(room.container_floor)
	var tiles = g_room.get_tiles()
	for y in range(size.y):
		for x in range(size.x):
			var t = y * size.x + x
			var node: Node3D
			if tiles[t]:
				node = packed_floor_tile.instantiate()
			else:
				node = packed_collider_tile.instantiate()
			bf.set_pos_2d(node, Vector2(x, y))
			room.container_floor.add_child(node)

	for door in g_room.get_doors():
		var door_node: Area3D = packed_door.instantiate()
		bf.scale_2d(door_node, glib.ToV2(door.get_size()))
		bf.set_pos_2d(door_node, glib.ToV2(door.get_center_pos()))
		room.container_doors.add_child(door_node)
		door_node.body_entered.connect(_on_player_entered_door)


func _physics_process(_dt: float) -> void:
	if Meta.async_data_loaded and not _async_scene_loaded:
		_async_scene_loaded = true
		var r = load("res://assets/async_data.tscn")
		@warning_ignore("unsafe_method_access")
		var n: Node = r.instantiate()
		add_child(n)

	bf.move_body_with_speed(
		player.node_body,
		Input.get_vector("move_l", "move_r", "move_u", "move_d"),
		glib.v.get_player_speed(),
	)

	var camera_dir = Vector3(0, sin(camera_angle), cos(camera_angle))
	camera.transform.origin = player.transform.origin + camera_dir * camera_distance
	camera.transform = camera.transform.looking_at(player.node_body.transform.origin)

	for element in elements:
		element.transform.basis = camera.transform.basis


func _process(_dt: float) -> void:
	pass
