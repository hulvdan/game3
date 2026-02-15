extends Node

class_name Game

static var async_scene_loaded = false

@export_category("Values")
@export var camera_distance: float
@export var camera_angle: float

@export_category("Resources")
@export var res_creature_player: ResCreature
@export var packed_creature: PackedScene
@export var packed_floor_tile: PackedScene
@export var packed_collider_tile: PackedScene
@export var packed_door: PackedScene
@export var packed_room: PackedScene
@export var packed_ui_minimap_room: PackedScene
@export var packed_ui_progression_entry: PackedScene
@export var packed_bow: PackedScene

var player: Creature
var player_bow: Node3D
var current_room_pos: Vector2i = Vector2i.MAX
var rooms: Array[RoomData] = []
var ui_minimap_rooms: Array[Sprite2D] = []

var room: Room
var player_is_entering_door := false

@onready var camera: Camera3D = %_camera
@onready var container_ui_minimap: Node2D = %_container_ui_minimap
@onready var container_ui_progression: Node2D = %_container_ui_progression


class RoomData:
	var gindex: int = -1


func make_creature(res: ResCreature, pos: Vector2) -> Creature:
	assert(res)
	var creature: Creature = packed_creature.instantiate()
	bf.set_pos_2d(creature, pos)
	creature.res = res
	creature.node_sprite.texture = creature.res.texture

	room.target_camera_elements.append(creature.node_target_camera)
	room.container_creatures.add_child(creature)
	return creature


func room_index(pos: Vector2i) -> int:
	return pos.y * glib.v.get_world_size().get_x() + pos.x


func on_player_entered_door(body: Node3D, direction_index: int) -> void:
	if player_is_entering_door:
		return
	if body != player:
		return

	var tween = create_tween()
	var r: Node = $_transition_rect
	player_is_entering_door = true
	tween.tween_property(r, "modulate:a", 1, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(remake_room.bind(current_room_pos + bf.DIRECTION_OFFSETS[direction_index], direction_index))
	tween.tween_property(r, "modulate:a", 0, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)


func remake_room(new_room_pos: Vector2i, player_direction_index: int) -> void:
	if current_room_pos != Vector2i.MAX:
		var s1: ShaderMaterial = ui_minimap_rooms[room_index(current_room_pos)].material
		s1.set_shader_parameter('flash', Vector4(1, 1, 1, 0))
	current_room_pos = new_room_pos
	var s2: ShaderMaterial = ui_minimap_rooms[room_index(current_room_pos)].material
	s2.set_shader_parameter('flash', Vector4(1, 1, 1, 0.6))

	player_is_entering_door = false
	if room:
		room.queue_free()
	room = packed_room.instantiate()
	add_child(room)

	assert(room.container_creatures)
	bf.clear_children(room.container_creatures)
	assert(camera_distance > 0)
	assert(camera_angle > 0)

	var g_rooms = glib.v.get_rooms()
	var g_room = g_rooms[(current_room_pos.x + current_room_pos.y) % len(g_rooms)]
	var size: Vector2i = glib.ToV2i(g_room.get_size())

	for element in room.target_camera_elements:
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

	var player_pos: Vector2 = Vector2(size) / 2

	for door in g_room.get_doors():
		var offset = bf.DIRECTION_OFFSETS[door.get_direction()]
		var to_pos: Vector2i = current_room_pos + offset
		if !bounds.has_point(to_pos):
			continue

		var door_node: Area3D = packed_door.instantiate()
		bf.scale_2d(door_node, glib.ToV2(door.get_size()))
		bf.set_pos_2d(door_node, glib.ToV2(door.get_center_pos()))
		room.container_doors.add_child(door_node)

		door_node.body_entered.connect(on_player_entered_door.bind(door.get_direction()))

		if (door.get_direction() + 2) % 4 == player_direction_index:
			player_pos = glib.ToV2(door.get_center_pos()) + Vector2(bf.DIRECTION_OFFSETS[player_direction_index]) * 2

	player = make_creature(res_creature_player, player_pos)
	player_bow = packed_bow.instantiate()
	player.add_child(player_bow)
	for mob in glib.v.get_mobs_to_spawn():
		var r: ResCreature = load(mob.get_res())
		make_creature(r, glib.ToV2(mob.get_pos()) + Vector2(size) / 2)


func _ready() -> void:
	var transition_rect: Control = %_transition_rect
	transition_rect.visible = true
	create_tween().tween_property(transition_rect, "modulate:a", 0, 0)

	bf.clear_children(container_ui_minimap)
	bf.clear_children(container_ui_progression)

	var ws: Vector2i = glib.ToV2i(glib.v.get_world_size())

	for y_ in range(ws.y):
		var y: int = ws.y - y_ - 1
		var rooms_slice: Array[Sprite2D] = []

		for x in range(ws.x):
			var room_data = RoomData.new()
			room_data.gindex = hash(room_index(Vector2i(x, y))) % len(glib.v.get_rooms())
			rooms.append(room_data)

			var minimap_room: Sprite2D = packed_ui_minimap_room.instantiate()
			rooms_slice.append(minimap_room)

			var scale: float = 1.0 / 3.0
			minimap_room.transform = minimap_room.transform.scaled(Vector2(1, 1) * scale)
			minimap_room.transform = minimap_room.transform.translated(Vector2(x + 1, y + 1) * 100 * scale)

			bf.duplicate_shader_material(minimap_room)
			container_ui_minimap.add_child(minimap_room)

		ui_minimap_rooms = rooms_slice + ui_minimap_rooms

	var progression_size: Vector2i = glib.ToV2i(glib.v.get_progression_size())
	for entry in glib.v.get_progression():
		if !entry.get_type():
			continue
		var node: Node2D = packed_ui_progression_entry.instantiate()
		container_ui_progression.add_child(node)
		var pos: Vector2i = glib.ToV2i(entry.get_pos())
		node.transform.origin = (Vector2(pos.x, pos.y) - Vector2(progression_size) / 2.0) * 40.0

	remake_room(Vector2i(Vector2(ws) / 2.0), -1)


func get_mouse_world_point() -> Vector3:
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	var ray_origin: Vector3 = camera.project_ray_origin(mouse_pos)
	var ray_dir: Vector3 = camera.project_ray_normal(mouse_pos)
	var hit_position = Plane(Vector3.UP, 0).intersects_ray(ray_origin, ray_dir)
	if hit_position:
		return hit_position
	return Vector3.INF


func _physics_process(_dt: float) -> void:
	if Meta.async_data_loaded and not async_scene_loaded:
		async_scene_loaded = true
		var r: PackedScene = load("res://assets/async_data.tscn")
		var n: Node = r.instantiate()
		add_child(n)

	if !player_is_entering_door:
		bf.move_body_with_speed(
			player.node_body,
			Input.get_vector("move_l", "move_r", "move_u", "move_d"),
			glib.v.get_player_speed(),
		)

	var end_point: Vector3 = get_mouse_world_point()
	if end_point != Vector3.INF:
		player_bow.transform.basis = player.transform.looking_at(end_point).basis


func _process(_dt: float) -> void:
	var camera_dir = Vector3(0, sin(camera_angle), cos(camera_angle))
	camera.transform.origin = player.transform.origin + camera_dir * camera_distance
	camera.transform = camera.transform.looking_at(player.node_body.transform.origin)

	for e in room.target_camera_elements:
		e.transform.basis = camera.transform.basis
