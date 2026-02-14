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
@export var packed_ui_minimap_room: PackedScene

var player: Creature
var current_room_pos: Vector2i = Vector2i(-1, -1)
var rooms: Array[RoomData] = []
var ui_minimap_rooms: Array[Sprite2D] = []

var room_node: Node
var room: Room

@onready var camera: Camera3D = $_camera
@onready var container_ui_minimap: Node2D = $_ui


class RoomData:
	# var directions: int = 0
	var gindex: int = -1


func _make_creature(res: ResCreature, pos: Vector2) -> Node3D:
	assert(res)
	var creature: Creature = packed_creature.instantiate()
	bf.set_pos_2d(creature, pos)
	creature.res = res
	creature.node_sprite.texture = creature.res.texture

	elements.append(creature.node_rotate)
	room.container_creatures.add_child(creature)
	return creature


func _room_index(pos: Vector2i) -> int:
	return pos.y * glib.v.get_world_size().get_x() + pos.x


func _on_player_entered_door(_body: Node3D, direction_index: int) -> void:
	if _body != player:
		return

	var mat: ShaderMaterial = ui_minimap_rooms[_room_index(current_room_pos)].material
	mat.set_shader_parameter('flash', Vector4(1, 1, 1, 0))

	current_room_pos += bf.DIRECTION_OFFSETS[direction_index]

	mat = ui_minimap_rooms[_room_index(current_room_pos)].material
	mat.set_shader_parameter('flash', Vector4(1, 1, 1, 0.66))

	var tween = create_tween()
	var r: Control = $TransitionRect
	tween.tween_property(r, "modulate:a", 1, 0.5)
	tween.tween_callback(Callable(self, "_remake_room"))
	tween.tween_property(r, "modulate:a", 0, 0.5)


func _remake_room() -> void:
	if room:
		room.queue_free()
		elements.clear()
	room = packed_room.instantiate()
	add_child(room)

	assert(room.container_creatures)
	bf.clear_children(room.container_creatures)
	assert(camera_distance > 0)
	assert(camera_angle > 0)

	var g_rooms = glib.v.get_rooms()
	var g_room = g_rooms[(current_room_pos.x + current_room_pos.y) % len(g_rooms)]
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
			bf.set_pos_2d(node, Vector2(x, y) + Vector2(0.5, 0.5))
			room.container_floor.add_child(node)

	var ws: Vector2i = glib.ToV2i(glib.v.get_world_size())
	var bounds = Rect2i(Vector2i(0, 0), ws)

	for door in g_room.get_doors():
		var offset = bf.DIRECTION_OFFSETS[door.get_direction()]
		var to_pos: Vector2i = current_room_pos + offset
		if !bounds.has_point(to_pos):
			continue

		var door_node: Area3D = packed_door.instantiate()
		bf.scale_2d(door_node, glib.ToV2(door.get_size()))
		bf.set_pos_2d(door_node, glib.ToV2(door.get_center_pos()))
		room.container_doors.add_child(door_node)

		var captured_dir: int = door.get_direction()
		door_node.body_entered.connect(func(x: Node3D): _on_player_entered_door(x, captured_dir))


func _ready() -> void:
	var transition_rect: ColorRect = $TransitionRect
	transition_rect.visible = true
	create_tween().tween_property(transition_rect, "modulate:a", 0, 0)

	var ws: Vector2i = glib.ToV2i(glib.v.get_world_size())
	current_room_pos = Vector2i(Vector2(ws) / 2.0)

	for y_ in range(ws.y):
		var y: int = ws.y - y_ - 1
		for x in range(ws.x):
			var room_data = RoomData.new()
			room_data.gindex = hash(_room_index(Vector2i(x, y))) % len(glib.v.get_rooms())
			rooms.append(room_data)

			var minimap_room: Sprite2D = packed_ui_minimap_room.instantiate()

			var scale: float = 1.0 / 3.0
			minimap_room.transform = minimap_room.transform.scaled(Vector2(1, 1) * scale)
			minimap_room.transform = minimap_room.transform.translated(Vector2(x + 1, y + 1) * 100 * scale)

			var mat = bf.duplicate_shader_material(minimap_room)

			var flash = Vector4(1, 1, 1, 0)
			if Vector2i(x, y) == current_room_pos:
				flash.w = 1
			mat.set_shader_parameter('flash', flash)

			ui_minimap_rooms.append(minimap_room)
			container_ui_minimap.add_child(minimap_room)

	_remake_room()


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
