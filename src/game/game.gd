extends Node

class_name Game

## Variables
static var v: Game = null
static var async_scene_loaded = false

@export_category("Values")
@export var camera_distance: float
@export var camera_angle: float
@export var color_ui_hp: Color
@export var color_ui_stamina: Color

@export_category("Resources")
@export var world_3d: Node3D
@export var packed_room: PackedScene
@export var packed_creature: PackedScene
@export var packed_floor_tile: PackedScene
@export var packed_collider_tile: PackedScene
@export var packed_door: PackedScene
@export var packed_bow: PackedScene
@export var packed_projectile: PackedScene
@export var packed_spike: PackedScene
@export var packed_zone_circle: PackedScene
@export var packed_ai: PackedScene
@export var packed_ui_bar_player: PackedScene
@export var packed_ui_bar_mob: PackedScene
@export var packed_ui_minimap_room: PackedScene
@export var packed_ui_progression_entry: PackedScene

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
@onready var container_general: Node = %_container_general
##


class RoomData:
	var gindex: int = -1


func make_creature(type: glib.GCreatureType, pos: Vector2) -> Creature: ##
	var data: glib.GCreature = glib.v.get_creatures()[type]
	var creature: Creature = packed_creature.instantiate()
	room.container_creatures.add_child(creature)

	var ctype: int = data.get_collision_type()
	creature.node_body.collision_layer = 2 ** ctype
	creature.type = type
	creature.res = load(data.get_res())
	assert(creature.res)
	bf.set_pos_2d(creature, pos)

	creature.hp = data.get_hp()
	creature.node_sprite.texture = creature.res.texture

	if type == glib.GCreatureType.PLAYER:
		creature.hp_bar = hp_bar
	else:
		var bar: Bar = packed_ui_bar_mob.instantiate()
		creature.hp_bar = bar
		bar.anchor_right *= creature.hp / 3.0
		room.container_mob_hp_bars.add_child(bar)
		var tree: BeehaveTree = packed_ai.instantiate()
		creature.setup_ai(tree)

	room.target_camera_elements.append(creature.node_target_camera)

	var sh: ShaderMaterial = creature.node_sprite.material_override
	sh.set_shader_parameter("flash", Color(1, 1, 1, 0))
	sh.set_shader_parameter("albedo", creature.res.texture)

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
	container_general.add_child(room)
	Room.v = room

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

		var node: Area3D = packed_door.instantiate()
		bf.scale_2d(node, glib.ToV2(door.get_size()))
		bf.set_pos_2d(node, glib.ToV2(door.get_center_pos()))
		room.container_doors.add_child(node)

		node.body_entered.connect(on_player_entered_door.bind(door.get_direction()))

		if (door.get_direction() + 2) % 4 == player_direction_index:
			player_pos = glib.ToV2(door.get_center_pos()) + Vector2(bf.DIRECTION_OFFSETS[player_direction_index]) * 2
	##

	## Placing spikes
	for spike in g_room.get_spikes():
		var node: Spike = packed_spike.instantiate()
		node.transform.origin = bf.to_xz(glib.ToV2(spike.get_pos()))
		room.container_spikes.add_child(node)
		node.init(room)
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
	v = self

	## Setup
	assert(camera_distance > 0)
	assert(camera_angle > 0)

	hp_bar.init(color_ui_hp, false)
	bf.clear_children(container_stamina_bars)
	for i in range(glib.v.get_player_stamina_charges()):
		var bar: Bar = packed_ui_bar_player.instantiate()
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

	## Creatures moving
	room.player.controller.move = Vector2(0, 0)
	if !player_is_entering_door:
		room.player.controller.move = Input.get_vector("move_l", "move_r", "move_u", "move_d")

	var creatures = glib.v.get_creatures()
	for creature: Creature in room.container_creatures.get_children():
		var data: glib.GCreature = creatures[creature.type]

		var dir: Vector2 = creature.controller.move
		if dir != Vector2(0, 0):
			creature.controller.last_move = dir
		var speed: float = data.get_speed()

		if creature.type == glib.GCreatureType.PLAYER:
			if room.player_rolling:
				dir = room.player_roll_direction
				speed = bf.get_roll_speed(
					glib.v.get_player_roll_distance(),
					glib.v.get_player_roll_duration_seconds(),
					room.player_rolling,
					glib.v.get_player_roll_pow(),
				)
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
	var shooting: bool = Input.get_action_strength("shoot") >= 0.5

	if room.player_rolling and (room.player_rolling < glib.v.get_player_roll_can_shoot_after()):
		if shooting:
			room.player_shooting_after_roll_scheduled = true

	else:
		var dur: float = glib.v.get_shooting_seconds()
		if room.player_shooting_after_roll_scheduled:
			dur = glib.v.get_shooting_after_roll_seconds()

		if room.player_holding >= dur:
			var from: Vector2 = bf.from_xz(room.player.transform.origin)
			var to: Vector2 = from + bf.from_xz(room.player_bow.transform.basis.z)
			var d: Projectile.Data = Projectile.Data.new()
			d.type = glib.GProjectileType.ARROW
			d.owner = glib.GCreatureType.PLAYER
			make_projectile(glib.GProjectileType.ARROW, from, to, d)
			room.player_holding = 0
			room.player_shooting_after_roll_scheduled = false
		elif shooting or room.player_holding or room.player_shooting_after_roll_scheduled:
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
		&& (room.player.controller.last_move != Vector2(0, 0))
	):
		room.player_rolling = dt
		room.player_holding = 0
		room.player_roll_direction = room.player.controller.last_move
		room.player_stamina -= 1
		room.player_stamina_elapsed = 0
	##

	## Updating projectiles + collisions + despawning
	var space = world_3d.get_world_3d().direct_space_state
	var param_ray: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.new()
	param_ray.collide_with_areas = false
	param_ray.collide_with_bodies = true
	param_ray.hit_back_faces = true
	param_ray.hit_from_inside = true

	var param_shape: PhysicsShapeQueryParameters3D = PhysicsShapeQueryParameters3D.new()
	param_shape.collide_with_areas = false
	param_shape.collide_with_bodies = true
	var shape_rid: RID = PhysicsServer3D.sphere_shape_create()
	param_shape.shape_rid = shape_rid

	var projectiles = glib.v.get_projectiles()
	var apply_damage_projectile_data: ApplyDamageData = ApplyDamageData.new()
	for projectile: Projectile in room.container_projectiles.get_children():
		var is_player: bool = projectile.d.owner == glib.GCreatureType.PLAYER

		projectile.elapsed += dt

		var should_remove: bool = false

		var data = projectiles[projectile.d.type]

		if data.get_projectilefly_type() == glib.GProjectileFlyType.STRAIGHT:
			var projectile_step: Vector3 = Vector3(0, 0, -1) * (data.get_straight__speed() * dt)
			projectile.translate_object_local(projectile_step)

			param_ray.from = projectile.transform.origin
			param_ray.to = projectile.transform.origin + projectile.transform.basis * projectile_step

			for mask in [
				glib.GCollisionType.WALLS,
				glib.GCollisionType.MOBS if is_player else glib.GCollisionType.PLAYER,
			]:
				param_ray.collision_mask = mask
				var d: Dictionary = space.intersect_ray(param_ray)
				if d:
					should_remove = true
					if mask != glib.GCollisionType.WALLS:
						var damaged_creature: Creature = d.collider
						apply_damage(damaged_creature, data.get_damage(), apply_damage_projectile_data)
					break

		elif data.get_projectilefly_type() == glib.GProjectileFlyType.ARC:
			PhysicsServer3D.shape_set_data(shape_rid, data.get_arc__aoe_radius())

			var t: float = projectile.elapsed / data.get_arc__duration()
			var p: Vector2 = lerp(projectile.d.origin, projectile.d.target, t)
			var pos: Vector3 = bf.to_xz(p)
			pos.y = data.get_arc__height() * sin(t * PI)
			projectile.transform.origin = pos

			if projectile.elapsed >= data.get_arc__duration():
				param_shape.collision_mask = glib.GCollisionType.MOBS if is_player else glib.GCollisionType.PLAYER
				param_shape.transform.origin = bf.to_xz(projectile.d.target)

				for d: Dictionary in space.intersect_shape(param_shape, 12):
					var damaged_creature: Creature = d.collider
					apply_damage(damaged_creature, data.get_damage(), apply_damage_projectile_data)

				should_remove = true
				var i: int = -1
				for v2: Node3D in room.target_camera_elements:
					i += 1
					if v2 == projectile.sprite:
						room.target_camera_elements.remove_at(i)
						break
				for z: Node3D in projectile.zones:
					room.container_zones.remove_child(z)

		else:
			bf.invalid_path()

		if should_remove:
			room.container_projectiles.remove_child(projectile)
			projectile.queue_free()

	PhysicsServer3D.free_rid(shape_rid)
	##

	## Spike collisions
	var apply_damage_spike_data: ApplyDamageData = ApplyDamageData.new()
	apply_damage_spike_data.type = glib.GDamageType.SPIKE
	for spike: Spike in room.container_spikes.get_children():
		if spike.is_active && (spike.activation_elapsed >= glib.v.get_spikes_damage_starts_at()):
			apply_damage_spike_data.immediate = !spike.striked
			spike.striked = true
			for creature: Creature in spike.creatures_to_damage:
				apply_damage(creature, glib.v.get_spikes_damage(), apply_damage_spike_data)
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

	## Updating creatures time_since_last_damage_taken
	for creature: Creature in room.container_creatures.get_children():
		creature.time_since_last_damage_taken += dt
		creature.time_since_last_damage_taken_visual += dt

		var sh: ShaderMaterial = creature.node_sprite.material_override
		var t: float = max(0, lerp(1, 0, creature.time_since_last_damage_taken_visual))
		sh.set_shader_parameter("flash", Color(1, 1, 1, t))
	##

	## Flashing player green during rolls
	if room.player_rolling:
		var sh: ShaderMaterial = room.player.node_sprite.material_override
		sh.set_shader_parameter('flash', Color(0, 1, 0, 0.5))
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
	camera.transform = camera.transform.looking_at(room.player.transform.origin)

	for e: Node3D in room.target_camera_elements:
		if e.visible:
			e.rotation = camera.rotation
	##

	## Updating creature hp bar positions
	var player_camera_dir: Vector3 = (camera.position - room.player.transform.origin).normalized()
	var player_camera_dot: float = (camera.position - room.player.transform.origin).dot(player_camera_dir)
	for creature: Creature in room.container_creatures.get_children():
		if creature.type <= glib.GCreatureType.PLAYER:
			continue
		var creature_camera_dot: float = (camera.position - creature.transform.origin).dot(player_camera_dir)
		creature.hp_bar.scale = Vector2(1, 1) * (player_camera_dot / creature_camera_dot)
		creature.hp_bar.position = camera.unproject_position(creature.transform.origin) - creature.hp_bar.size / 2.0 * creature.hp_bar.scale
	##


class ApplyDamageData:
	var type: glib.GDamageType = glib.GDamageType.STRIKE
	var immediate: bool = true


func apply_damage(
		creature: Creature,
		damage: int,
		data: ApplyDamageData,
) -> void: ##
	if creature.type == glib.GCreatureType.PLAYER:
		if (
			(glib.v.get_player_roll_invincibility_start() <= room.player_rolling)
			&& (room.player_rolling <= glib.v.get_player_roll_invincibility_end())
		):
			if data.immediate:
				room.player_stamina = min(room.player_stamina + 1, glib.v.get_player_stamina_charges())
			return
		if creature.time_since_last_damage_taken <= glib.v.get_player_invincibility_after_hit_seconds():
			return
		creature.time_since_last_damage_taken = 0

	else:
		if data.type == glib.GDamageType.SPIKE:
			if creature.time_since_last_damage_taken <= glib.v.get_mob_invincibility_spikes_seconds():
				return
			creature.time_since_last_damage_taken = 0

	creature.hp -= damage
	creature.hp = max(0, creature.hp)
	creature.hp_bar.set_progress((creature.hp as float) / (glib.v.get_creatures()[creature.type].get_hp() as float))
	creature.time_since_last_damage_taken_visual = 0

	if (creature != room.player) && (creature.hp <= 0):
		creature.queue_free()
		var found: bool = false
		for i in range(len(room.target_camera_elements)):
			if room.target_camera_elements[i] == creature.node_target_camera:
				room.target_camera_elements.remove_at(i)
				found = true
				break
		assert(found)
		if creature.type != glib.GCreatureType.PLAYER:
			room.container_mob_hp_bars.remove_child(creature.hp_bar)
	##


func make_projectile(
		type: glib.GProjectileType,
		pos: Vector2,
		target: Vector2,
		d: Projectile.Data,
) -> void: ##
	var data: glib.GProjectile = glib.v.get_projectiles()[type]

	var x: Projectile = packed_projectile.instantiate()
	room.container_projectiles.add_child(x)

	if data.get_projectilefly_type() == glib.GProjectileFlyType.ARC:
		room.target_camera_elements.append(x.sprite)

	x.d = d
	x.d.origin = pos
	x.d.target = target
	x.res = load(data.get_res())
	x.sprite.texture = x.res.texture

	x.transform.origin = bf.to_xz(pos)

	if data.get_projectilefly_type() == glib.GProjectileFlyType.STRAIGHT:
		if target == pos:
			target = pos + Vector2(1, 0).rotated(randf() * 2.0 * PI)
		var forward: Vector3 = bf.to_xz((target - pos).normalized())
		x.transform.basis = Basis(Vector3(0, 1, 0).cross(forward), Vector3(0, 1, 0), forward)

	elif data.get_projectilefly_type() == glib.GProjectileFlyType.ARC:
		var target_scale: Vector3 = Vector3(1, 1, 1) * data.get_arc__aoe_radius() * 2.0
		for i in range(2):
			var zone: Node3D = packed_zone_circle.instantiate()
			room.container_zones.add_child(zone)
			zone.transform.origin = bf.to_xz(x.d.target) + Vector3(0, 0.01 * i, 0)

			var tween = create_tween()
			if i:
				tween.tween_property(zone, "scale", Vector3(0, 1, 0), 0)
				tween.tween_property(zone, "scale", target_scale, data.get_arc__duration())
			else:
				tween.tween_property(zone, "scale", target_scale, 0)
			x.zones.append(zone)

	else:
		bf.invalid_path()

##
