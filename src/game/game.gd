extends Node

class_name Game

## Variables
static var async_scene_loaded = false

@export_category("Values")
@export var camera_distance: float
@export var camera_angle: float

@export_category("Resources")
@export var color_ui_hp: Color
@export var color_ui_stamina: Color
@export var world_3d: Node3D
@export var packed_creature: PackedScene
@export var packed_floor_tile: PackedScene
@export var packed_collider_tile: PackedScene
@export var packed_door: PackedScene
@export var packed_room: PackedScene
@export var packed_ui_minimap_room: PackedScene
@export var packed_ui_progression_entry: PackedScene
@export var packed_bow: PackedScene
@export var packed_arrow: PackedScene
@export var packed_bar_player: PackedScene
@export var packed_bar_mob: PackedScene

var current_room_pos: Vector2i = Vector2i.MAX
var rooms: Array[RoomData] = []
var ui_minimap_rooms: Array[Sprite2D] = []
var stamina_bars: Array[Bar]

var room: Room
var player_is_entering_door := false

@onready var camera: Camera3D = %_camera
@onready var hp_bar: Bar = %_hp_bar
@onready var container_ui_minimap: Control = %_container_ui_minimap
@onready var container_ui_progression: Node2D = %_container_ui_progression
@onready var container_stamina_bars: Control = %_container_stamina_bars
@onready var container: Node = %_container
##

enum CollisionMask {
	WALLS = 1 << 0,
	CREATURES = 1 << 1,
}


class RoomData:
	var gindex: int = -1


func make_creature(type: glib.GCreatureType, pos: Vector2) -> Creature: ##
	var data: glib.GCreature = glib.v.get_creatures()[type]
	var creature: Creature = packed_creature.instantiate()
	creature.type = type
	creature.res = load(data.get_res())
	assert(creature.res)
	bf.set_pos_2d(creature, pos)

	creature.hp = data.get_hp()
	creature.node_sprite.texture = creature.res.texture

	if type != glib.GCreatureType.PLAYER:
		var bar: Bar = packed_bar_mob.instantiate()
		creature.hp_bar = bar
		bar.anchor_right *= creature.hp / 3.0
		room.container_mob_hp_bars.add_child(bar)

	room.target_camera_elements.append(creature.node_target_camera)
	room.container_creatures.add_child(creature)
	return creature
	##


func room_index(pos: Vector2i) -> int:
	return pos.y * glib.v.get_world_size().get_x() + pos.x


func on_player_entered_door(body: Node3D, direction_index: int) -> void: ##
	if player_is_entering_door:
		return
	if body != room.player:
		return

	var tween = create_tween()
	var r: Node = %_transition
	player_is_entering_door = true
	tween.tween_property(r, "modulate:a", 1, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(remake_room.bind(current_room_pos + bf.DIRECTION_OFFSETS[direction_index], direction_index))
	tween.tween_property(r, "modulate:a", 0, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	##


func remake_room(new_room_pos: Vector2i, player_direction_index: int) -> void:
	## Updating flash of ui minimap
	if current_room_pos != Vector2i.MAX:
		var s1: ShaderMaterial = ui_minimap_rooms[room_index(current_room_pos)].material
		s1.set_shader_parameter('flash', Vector4(1, 1, 1, 0))
	current_room_pos = new_room_pos
	var s2: ShaderMaterial = ui_minimap_rooms[room_index(current_room_pos)].material
	s2.set_shader_parameter('flash', Vector4(1, 1, 1, 0.6))
	##

	## Reinstantiating room node
	player_is_entering_door = false
	if room:
		room.queue_free()
	room = packed_room.instantiate()
	container.add_child(room)

	bf.clear_children(room.container_creatures)
	for element in room.target_camera_elements:
		assert(element)
	##

	var g_rooms = glib.v.get_rooms()
	var g_room = g_rooms[(current_room_pos.x + current_room_pos.y) % len(g_rooms)]
	var size: Vector2i = glib.ToV2i(g_room.get_size())

	## Placing floor tiles
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
	##

	var ws: Vector2i = glib.ToV2i(glib.v.get_world_size())
	var bounds = Rect2i(Vector2i(0, 0), ws)

	var player_pos: Vector2 = Vector2(size) / 2

	## Placing doors
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
	##

	## Placing player and other creatures
	room.player = make_creature(glib.GCreatureType.PLAYER, player_pos)
	room.player_bow = packed_bow.instantiate()
	room.player.add_child(room.player_bow)
	for mob in glib.v.get_mobs_to_spawn():
		make_creature(mob.get_creature_type(), glib.ToV2(mob.get_pos()) + Vector2(size) / 2)
	##

	room.player_stamina = glib.v.get_player_stamina_charges()


func _ready() -> void:
	## Setup
	assert(camera_distance > 0)
	assert(camera_angle > 0)

	hp_bar.init(color_ui_hp, false)
	bf.clear_children(container_stamina_bars)
	for i in range(glib.v.get_player_stamina_charges()):
		var bar: Bar = packed_bar_player.instantiate()
		stamina_bars.append(bar)
		container_stamina_bars.add_child(bar)
		bar.init(color_ui_stamina, true)

	var transition: Control = %_transition
	transition.visible = true
	create_tween().tween_property(transition, "modulate:a", 0, 0)

	bf.clear_children(container_ui_minimap)
	bf.clear_children(container_ui_progression)
	##

	var ws: Vector2i = glib.ToV2i(glib.v.get_world_size())

	## Filling ui minimap
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
	##

	## Filling ui progression
	var progression_size: Vector2i = glib.ToV2i(glib.v.get_progression_size())
	for entry in glib.v.get_progression():
		if !entry.get_type():
			continue
		var node: Node2D = packed_ui_progression_entry.instantiate()
		container_ui_progression.add_child(node)
		var pos: Vector2i = glib.ToV2i(entry.get_pos())
		node.transform.origin = (Vector2(pos.x, pos.y) - Vector2(progression_size) / 2.0) * 40.0
	##

	remake_room(Vector2i(Vector2(ws) / 2.0), -1)


func get_mouse_world_point() -> Vector3: ##
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	var ray_origin: Vector3 = camera.project_ray_origin(mouse_pos)
	var ray_dir: Vector3 = camera.project_ray_normal(mouse_pos)
	var hit_position = Plane(Vector3.UP, 0).intersects_ray(ray_origin, ray_dir)
	if hit_position:
		return hit_position
	return Vector3.INF
	##


func _physics_process(dt: float) -> void:
	room.start_elapsed += dt

	## Async scene loading handler
	if Meta.async_data_loaded and not async_scene_loaded:
		async_scene_loaded = true
		var r: PackedScene = load("res://assets/async_data.tscn")
		add_child(r.instantiate())
	##

	## Setting enemy controller.move towards player
	for creature: Creature in room.container_creatures.get_children():
		creature.controller.move = Vector2(0, 0)

	if room.start_elapsed >= 1:
		for creature: Creature in room.container_creatures.get_children():
			if creature.type <= glib.GCreatureType.PLAYER:
				continue
			var dir: Vector2 = bf.from_xz(room.player.transform.origin) - bf.from_xz(creature.transform.origin)
			if dir != Vector2(0, 0):
				dir = dir.normalized()
			creature.controller.move = dir
	##

	## Creatures moving
	if !player_is_entering_door:
		room.player.controller.move = Input.get_vector("move_l", "move_r", "move_u", "move_d")

	var creatures = glib.v.get_creatures()
	for creature: Creature in room.container_creatures.get_children():
		var data: glib.GCreature = creatures[creature.type]

		var dir: Vector2 = creature.controller.move
		var speed: float = data.get_speed()

		if creature.type == glib.GCreatureType.PLAYER:
			if room.player_rolling:
				# v(t) of player during roll = A - B * t^x
				var dist: float = glib.v.get_player_roll_distance()
				var dur: float = glib.v.get_player_roll_duration_seconds()
				var x: float = glib.v.get_player_roll_pow()
				speed = dist * (x + 1) / (x * pow(dur, x) * dur) * (pow(dur, x) - pow(room.player_rolling, x))
				dir = room.player_roll_direction
			else:
				if room.player_holding:
					speed *= glib.v.get_player_speed_holding_scale()
				speed *= lerp(1.0, glib.v.get_player_speed_inside_enemies_scale(), room.player_inside_enemy_t)

		bf.move_body_with_speed(creature.node_body, dir, speed)
	##

	## Updating player's bow direction
	var end_point: Vector3 = get_mouse_world_point()
	if end_point != Vector3.INF:
		room.player_bow.transform.basis = room.player.transform.looking_at(end_point).basis
	##

	## Player shooting
	if not room.player_rolling:
		if Input.get_action_strength("shoot") >= 0.5:
			room.player_holding += dt
		elif room.player_holding >= glib.v.get_shooting_min_seconds():
			var arrow: Projectile = packed_arrow.instantiate()
			var t = (room.player_holding - glib.v.get_shooting_min_seconds()) / glib.v.get_shooting_max_seconds()
			t = lerp(t, t * t, 0.25)
			arrow.speed = lerp(glib.v.get_arrow_speed_min(), glib.v.get_arrow_speed_max(), t)
			arrow.damage = round(lerp(glib.v.get_arrow_damage_min(), glib.v.get_arrow_damage_max(), t))
			arrow.transform.origin = room.player.transform.origin
			arrow.transform.basis = room.player_bow.transform.basis
			room.container_projectiles.add_child(arrow)
			room.player_holding = 0
		elif room.player_holding > 0:
			room.player_holding += dt
	##

	## Player rolling
	if room.player_rolling:
		room.player_rolling += dt
		if room.player_rolling >= glib.v.get_player_roll_duration_seconds():
			room.player_rolling = 0
	elif (
		(room.player_stamina > 0)
		&& (Input.get_action_strength("roll") >= 0.5)
		&& (room.player.controller.move != Vector2(0, 0))
	):
		room.player_rolling = dt
		room.player_holding = 0
		room.player_roll_direction = room.player.controller.move
		room.player_stamina -= 1
		room.player_stamina_elapsed = 0
	##

	## Projectile collisions
	var space = world_3d.get_world_3d().direct_space_state
	var param: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.new()
	param.collide_with_areas = false
	param.collide_with_bodies = true
	param.hit_back_faces = true
	param.hit_from_inside = true
	param.exclude = [room.player]

	for projectile: Projectile in room.container_projectiles.get_children():
		var projectile_step: Vector3 = Vector3(0, 0, -1) * (projectile.speed * dt)
		projectile.translate_object_local(projectile_step)

		param.from = projectile.transform.origin
		param.to = projectile.transform.origin + projectile.transform.basis * projectile_step

		for mask in [CollisionMask.CREATURES, CollisionMask.WALLS]:
			param.collision_mask = mask

			var d: Dictionary = space.intersect_ray(param)
			if d:
				room.container_projectiles.remove_child(projectile)
				if mask == CollisionMask.CREATURES:
					var damaged_creature: Creature = d.collider
					damaged_creature.this_frame_taken_damage += projectile.damage
				break
	##

	## Pushing creatures apart from each other
	var creatures_push_radius: float = glib.v.get_creatures_push_radius()
	var creatures_push_radius_sqr: float = creatures_push_radius * creatures_push_radius
	room.player_inside_enemy_t = 0
	for c1: Creature in room.container_creatures.get_children():
		for c2: Creature in room.container_creatures.get_children():
			if c1 == c2:
				continue
			var dir: Vector2 = bf.from_xz(c1.transform.origin - c2.transform.origin)
			var d: float = dir.length_squared()
			if d < creatures_push_radius_sqr:
				var t: float = 1 - sqrt(d) / creatures_push_radius
				bf.move_body_with_speed(c1.node_body, dir, t)
				if c1.type == glib.GCreatureType.PLAYER:
					room.player_inside_enemy_t = max(room.player_inside_enemy_t, t)
	room.player_inside_enemy_t = min(1, room.player_inside_enemy_t)
	##

	## Updating damaged creatures
	for creature: Creature in room.container_creatures.get_children():
		if creature.this_frame_taken_damage:
			creature.hp -= creature.this_frame_taken_damage
			creature.hp = max(0, creature.hp)
			creature.hp_bar.set_progress((creature.hp as float) / (glib.v.get_creatures()[creature.type].get_hp() as float))
			creature.this_frame_taken_damage = 0
			if creature.type != glib.GCreatureType.PLAYER:
				creature.hp_bar.visible = true

		if creature.hp <= 0:
			room.container_creatures.remove_child(creature)
			if creature.type != glib.GCreatureType.PLAYER:
				room.container_mob_hp_bars.remove_child(creature.hp_bar)
	##

	## Updating player hp bar
	hp_bar.set_progress((room.player.hp as float) / (glib.v.get_creatures()[room.player.type].get_hp() as float))
	##

	## Updating player stamina bars
	for i in range(len(stamina_bars) - room.player_stamina + 1):
		stamina_bars[len(stamina_bars) - 1 - i].set_progress(0)
	if len(stamina_bars) > room.player_stamina:
		var regen_dt: float = dt
		if room.player_holding:
			regen_dt *= glib.v.get_player_holding_stamina_regen_scale()
		room.player_stamina_elapsed += regen_dt
		var t: float = min(1, room.player_stamina_elapsed / glib.v.get_player_stamina_regen_seconds())
		stamina_bars[room.player_stamina].set_progress(t)
		if t >= 1:
			room.player_stamina += 1
			room.player_stamina_elapsed = 0
	for i in range(room.player_stamina):
		stamina_bars[i].set_progress(1)
	##


func _process(_dt: float) -> void:
	## Updating camera and stuff looking at camera
	var camera_dir = Vector3(0, sin(camera_angle), cos(camera_angle))
	camera.transform.origin = room.player.transform.origin + camera_dir * camera_distance
	camera.transform = camera.transform.looking_at(room.player.node_body.transform.origin)

	for e in room.target_camera_elements:
		e.transform.basis = camera.transform.basis
	##

	## Updating creatures hp bar positions
	var player_camera_dir: Vector3 = (camera.position - room.player.transform.origin).normalized()
	var player_camera_dot: float = (camera.position - room.player.transform.origin).dot(player_camera_dir)
	for creature: Creature in room.container_creatures.get_children():
		if creature.type <= glib.GCreatureType.PLAYER:
			continue
		creature.hp_bar.scale = Vector2(1, 1) * player_camera_dot / (camera.position - creature.transform.origin).dot(player_camera_dir)
		creature.hp_bar.position = camera.unproject_position(creature.transform.origin) - creature.hp_bar.size / 2.0 * creature.hp_bar.scale
	##
