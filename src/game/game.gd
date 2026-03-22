class_name Game
extends Node

## Variables
signal player_perfectly_evaded(world_pos: Vector3)
signal enemy_started_attack(world_pos: Vector3)
signal player_blocked(world_pos: Vector3)
signal player_perfectly_blocked(world_pos: Vector3)
signal player_ki(world_pos: Vector3)
signal player_perfectly_ki(world_pos: Vector3)
signal damaged(world_pos: Vector3, value: float, type: WhoGotDamagedType)

enum WhoGotDamagedType { PLAYER, MOB }

const GROUP_TARGET_CAMERA := "target_camera"

static var v: Game = null
static var async_scene_loaded := false
static var _impulses_to_remove_indices: Array[int]

@export_category("Values")
@export var camera_distance: float
@export var camera_angle: float
@export var camera_z_offset: float = 0.3
@export var color_ui_hp: Color
@export var color_ui_hp_rally: Color
@export var color_ui_stamina: Color
@export var color_ui_stamina_rally: Color
@export var color_ui_stamina_ki: Color
@export_category("Resources")
@export var world_3d: Node3D
@export var packed_room: PackedScene
@export var packed_creature: PackedScene
@export var packed_floor_tile: PackedScene
@export var packed_floor_void_tile: PackedScene
@export var packed_collider_tile: PackedScene
@export var packed_door: PackedScene
@export var packed_bow: PackedScene
@export var packed_projectile: PackedScene
@export var packed_spike: PackedScene
@export var packed_interactable: PackedScene
@export var packed_zone_circle: PackedScene
@export var packed_ai: PackedScene
@export var packed_ui_bar_player: PackedScene
@export var packed_ui_bar_mob: PackedScene
@export var packed_ui_minimap_room: PackedScene
@export var packed_ui_progression_entry: PackedScene

var current_room_pos := Vector2i.MAX
var rooms: Array[RoomData] = []
var ui_minimap_rooms: Array[Sprite2D] = []
var room: Room
var player_is_entering_door := false
var projectiles_to_make: Array[Projectile.Data]
var current_room_index:
	get:
		return _room_index(current_room_pos)

@onready var camera: Camera3D = %_camera
@onready var hp_bar: Bar = %_hp_bar
@onready var stamina_bar: Bar = %_stamina_bar
@onready var container_ui_minimap: Control = %_container_ui_minimap
@onready var container_ui_progression: Node2D = %_container_ui_progression
# @onready var container_stamina_bars: Control = %_container_stamina_bars
@onready var container_general: Node = %_container_general ##


static func add_impulse(
		arr: Array[Impulse],
		dir: Vector2,
		dist: float,
		dur: float,
		pow_: float,
) -> void: ##
	if dist == 0:
		return
	var x := Game.Impulse.new()
	x.dir = dir
	x.dist = dist
	x.pow_ = pow_
	x.dur = dur
	x.created_at = Room.v.start_elapsed
	arr.append(x)
	##


static func set_gizmos_color_according_to_evade_flags(flags: int) -> void: ##
	Collisions.set_gizmos_color(
		Color.YELLOW if (flags & glib.GEvadeType.JUST_BLOCKABLE) else Color.RED,
	)
	##


func _ready() -> void:
	Collisions.init(world_3d)
	assert(len(Projectile.updaters) == glib.GProjectileFlyType.COUNT)

	# TODO: REMOVEME
	TranslationServer.set_locale('ru')

	v = self

	## Setup
	assert(camera_distance > 0)
	assert(camera_angle > 0)

	hp_bar.init(color_ui_hp)
	hp_bar.init_rally_front(color_ui_hp_rally)
	stamina_bar.init(color_ui_stamina)
	stamina_bar.init_rally_front(color_ui_stamina_ki)
	stamina_bar.init_rally_back(color_ui_stamina_rally)

	var transition: Control = %_transition
	transition.visible = true
	create_tween().tween_property(transition, "modulate:a", 0, 0)

	bf.clear_children(container_ui_minimap)
	bf.clear_children(container_ui_progression)
	##

	var ws := glib.ToV2i(glib.v.get_world_size())
	var g_rooms = glib.v.get_rooms()

	## Filling ui minimap
	for y_ in range(ws.y):
		var y := ws.y - y_ - 1
		var rooms_slice: Array[Sprite2D] = []

		for x in range(ws.x):
			var room_data := RoomData.new()
			room_data.gindex = (x + y * ws.x) % len(g_rooms)

			rooms.append(room_data)

			var minimap_room: Sprite2D = packed_ui_minimap_room.instantiate()
			rooms_slice.append(minimap_room)

			var scale := 1.0 / 3.0
			minimap_room.transform = minimap_room.transform.scaled(Vector2(1, 1) * scale)
			minimap_room.transform = minimap_room.transform.translated(Vector2(x + 1, y + 1) * 100 * scale)

			container_ui_minimap.add_child(minimap_room)

		ui_minimap_rooms = rooms_slice + ui_minimap_rooms
	##

	## Filling ui progression
	var progression_size := glib.ToV2i(glib.v.get_progression_size())
	for entry in glib.v.get_progression():
		if !entry.get_type():
			continue
		var node: Node2D = packed_ui_progression_entry.instantiate()
		container_ui_progression.add_child(node)
		var pos := glib.ToV2i(entry.get_pos())
		node.transform.origin = (Vector2(pos.x, pos.y) - Vector2(progression_size) / 2.0) * 40.0
	##

	_remake_room(Vector2i(Vector2(ws) / 2.0), -1)


func _process(dt: float) -> void:
	## Updating camera and stuff looking at camera
	var g_room := glib.v.get_rooms()[rooms[current_room_index].gindex]
	var room_size := Vector2(glib.ToV2i(g_room.get_size()))

	var camera_dir := Vector3(0, sin(camera_angle), cos(camera_angle))
	var target: Vector3 = lerp(
		room.player.creature.transform.origin,
		Vector3(room_size.x / 2, 0, room_size.y * 2 / 3),
		# bf.to_xz(ws.x / 2,),
		0.15,
	) + Vector3(0, 0, camera_z_offset)
	camera.transform.origin = target + camera_dir * camera_distance
	camera.transform = camera.transform.looking_at(target)
	# camera.transform.origin += Vector3(0, 0, .3)

	# camera.transform.origin = lerp(camera.transform.origin, bf.to_xz(ws), 0.2)

	for e: Node3D in get_tree().get_nodes_in_group(GROUP_TARGET_CAMERA):
		if e.visible:
			e.rotation = camera.rotation
	##

	var target_camera_dir := (camera.position - target).normalized()
	var target_camera_dot := (camera.position - target).dot(target_camera_dir)

	## Updating creature hp bar positions
	for creature: Creature in room.container_creatures.get_children():
		if creature.type <= glib.GCreatureType.PLAYER:
			continue
		var creature_camera_dot := (camera.position - creature.transform.origin).dot(target_camera_dir)
		creature.hp_bar.scale = Vector2(1, 1) * (target_camera_dot / creature_camera_dot)
		creature.hp_bar.position = camera.unproject_position(creature.transform.origin) - creature.hp_bar.size / 2.0 * creature.hp_bar.scale
	##

	## Drawing creature gizmos
	if glib.v.get_debug_collisions():
		for creature: Creature in room.container_creatures.get_children():
			ImmediateGizmos3D.set_transform(creature.transform)
			ImmediateGizmos3D.line_circle(Vector3(0, 0, 0), Vector3(0, 1, 0), creature.node_shape.scale.x / 2)
	##

	room.action_labels.explicit_process(dt, target_camera_dir, target_camera_dot)


func _physics_process(dt: float) -> void:
	Collisions.init_frame()

	var g_projectiles := glib.v.get_projectiles()
	var g_creatures := glib.v.get_creatures()

	room.start_elapsed += dt

	## Async scene loading handler
	if Meta.async_data_loaded and not async_scene_loaded:
		async_scene_loaded = true
		var r: PackedScene = load("res://assets/async_data.tscn")
		add_child(r.instantiate())
	##

	## Player actions
	room.player.creature.controller.move = Vector2(0, 0)
	if !player_is_entering_door:
		if Input.is_action_just_pressed("block"):
			room.player.push_action(PlayerController.ActionType.BLOCK, Vector2.INF)
		if Input.is_action_just_released("block"):
			room.player.push_action(PlayerController.ActionType.UNBLOCK, Vector2.INF)
		if Input.is_action_just_pressed("shoot"):
			room.player.push_action(PlayerController.ActionType.ATTACK, Vector2.INF)
		if Input.is_action_just_pressed("ability_1"):
			room.player.push_action(PlayerController.ActionType.ABILITY_1, Vector2.INF)
		if Input.is_action_just_pressed("ability_2"):
			room.player.push_action(PlayerController.ActionType.ABILITY_2, Vector2.INF)
		if Input.is_action_just_pressed("roll"):
			room.player.push_action(PlayerController.ActionType.ROLL, Vector2.INF)
		room.player.push_action(
			PlayerController.ActionType.SET_MOVE_DIR,
			Input.get_vector("move_l", "move_r", "move_u", "move_d"),
		)
	##

	room.player.explicit_process(dt)

	## Updating player's bow direction
	var end_point := _get_mouse_world_point()
	room.player.aim_pos = bf.xz(end_point)
	room.player.creature.target_pos = room.player.aim_pos
	if end_point != Vector3.INF:
		room.player.bow.transform.basis = room.player.creature.transform.looking_at(end_point).basis
	##

	## Creatures updating + moving
	var player_xz_pos := bf.xz(room.player.creature.transform.origin)
	for x: Creature in room.container_creatures.get_children():
		var data := g_creatures[x.type]
		if x.type != glib.GCreatureType.PLAYER:
			x.target_pos = player_xz_pos

		var target_angle := INF
		var from := bf.xz(x.transform.origin)
		if x.attack_id:
			target_angle = x.attack_target_dir.angle()
		elif x.target_pos != from:
			target_angle = (x.target_pos - from).angle()

		if target_angle != INF:
			if data.get_rotation_speed():
				x.looking_angle = bf.angle_rotate_with_speed(
					x.looking_angle,
					target_angle,
					data.get_rotation_speed() * dt,
				)
			else:
				x.looking_angle = target_angle
			x.looking_dir = Vector2(1, 0).rotated(x.looking_angle)

		if glib.v.get_debug_collisions():
			ImmediateGizmos3D.set_transform(x.transform)
			ImmediateGizmos3D.line(Vector3(0, 0, 0), bf.to_xz(x.looking_dir))

		x.explicit_process(dt)

		var dir := x.controller.move
		if dir != Vector2(0, 0):
			x.controller.last_move = dir
		bf.move_body_with_speed(x.node_body, dir, x.get_speed())
		_process_impulses(x.impulses, x.node_body)
	##

	## Interactables moving
	for x: Interactable in room.container_interactables.get_children():
		_process_impulses(x.impulses, x.node_body)
	##

	## Spawning projectiles (flushing `projectiles_to_make`)
	for d: Projectile.Data in projectiles_to_make:
		var data := glib.v.get_projectiles()[d.type]

		var x: Projectile = packed_projectile.instantiate()
		room.container_projectiles.add_child(x)

		if data.get_collider_radius() > 0:
			x.area_sphere.body_entered.connect(x.on_body_entered)
			x.area_sphere.body_exited.connect(x.on_body_exited)
			x.shape_sphere.disabled = false
			x.area_sphere.scale = Vector3(1, 1, 1) * data.get_collider_radius()
			x.area_sphere.collision_mask = 2 ** glib.GMaskType.CREATURES

		x.attack_id = room.get_next_attack_id()
		if data.get_collider_radius():
			x.sprite.scale = Vector3(1, 1, 1) * (data.get_collider_radius() * 1.53 * 2)
			x.sprite.add_to_group(GROUP_TARGET_CAMERA)

		if data.get_projectilefly_type() == glib.GProjectileFlyType.ARC:
			x.sprite.add_to_group(GROUP_TARGET_CAMERA)

		x.d = d
		x.calculated__dir = bf.vector2_direction_or_random(d.pos, d.target)
		x.res = load(data.get_res())
		x.sprite.texture = x.res.texture

		x.transform.origin = bf.to_xz(d.pos)

		if data.get_projectilefly_type() == glib.GProjectileFlyType.DEFAULT:
			if !data.get_collider_radius():
				x.transform.basis = Basis(
					Vector3(0, 1, 0).cross(bf.to_xz(x.calculated__dir)),
					Vector3(0, 1, 0),
					bf.to_xz(x.calculated__dir),
				)

		elif data.get_projectilefly_type() in [glib.GProjectileFlyType.ARC, glib.GProjectileFlyType.AREA]:
			var target_scale := Vector3(1, 1, 1) * data.get_collider_radius() * 2.0
			for i in range(2):
				var zone: Node3D = packed_zone_circle.instantiate()
				room.container_zones.add_child(zone)
				zone.transform.origin = bf.to_xz(x.d.target) + Vector3(0, 0.01 * i, 0)

				var tween = create_tween()
				if i:
					tween.tween_property(zone, "scale", Vector3(0, 1, 0), 0)
					tween.tween_property(zone, "scale", target_scale, data.get_arc_or_area__duration())
				else:
					tween.tween_property(zone, "scale", target_scale, 0)
				x.zones.append(zone)

		else:
			bf.invalid_path()

	projectiles_to_make.clear()
	##

	## - Melee attacks collisions
	var apply_damage_melee_data := ApplyDamageData.new()
	for creature: Creature in room.container_creatures.get_children():
		if !creature.attack_id:
			continue

		var attack := creature.current_attack
		var melee := attack.get_melee()
		if !melee:
			continue

		apply_damage_melee_data.attack_id = creature.attack_id
		apply_damage_melee_data.impulse = 1
		apply_damage_melee_data.evade_flags = melee.get_evade_flags()

		var attacker_pos := bf.xz(creature.transform.origin)
		var e: int = creature.attack_elapsed_frames

		for collider in attack.get_melee().get_colliders():
			var is_active := false
			for k in collider.get_is_active():
				if k.get_index_timeline() > e:
					break
				is_active = k.get_value()
			if !is_active:
				continue

			var off: Vector2 = _make_keyframe_value_at(collider.get_tr(), e)
			var collider_pos := attacker_pos + off

			Game.set_gizmos_color_according_to_evade_flags(apply_damage_melee_data.evade_flags)
			for mask: int in [
				2 ** glib.GMaskType.CREATURES,
				2 ** glib.GMaskType.INTERACTABLES,
			]:
				var q: Array[Dictionary]

				match collider.get_type():
					1: # Circle
						var radius: float = _make_keyframe_value_at(collider.get_circle__radius(), e)
						q = Collisions.query_circle(collider_pos, radius, mask, true, false, 12)
					2: # Capsule
						var radius: float = _make_keyframe_value_at(collider.get_capsule__radius(), e)
						var rotation: float = _make_keyframe_value_at(collider.get_capsule__rotation(), e)
						var spread: float = _make_keyframe_value_at(collider.get_capsule__spread(), e)
						q = Collisions.query_capsule(
							collider_pos,
							-creature.attack_target_dir.angle() + deg_to_rad(rotation),
							radius * 2 + spread,
							radius,
							mask,
							true,
							false,
							12,
						)
					3: # Polygon
						var dist_max: float = _make_keyframe_value_at(collider.get_polygon__dist_max(), e)
						var dist_min: float = _make_keyframe_value_at(collider.get_polygon__dist_min(), e)
						var rotation: float = _make_keyframe_value_at(collider.get_polygon__rotation(), e)
						var spread_angle: float = _make_keyframe_value_at(collider.get_polygon__spread_angle(), e)
						q = Collisions.query_circle_segment(
							collider_pos,
							dist_min,
							dist_max,
							-creature.attack_target_dir.angle() + deg_to_rad(rotation),
							deg_to_rad(spread_angle),
							mask,
							true,
							false,
							12,
						)
					_:
						bf.invalid_path()

				if mask == 2 ** glib.GMaskType.INTERACTABLES:
					for d: Dictionary in q:
						var x: Interactable = d.collider
						if x in creature.attack_damaged_interactables:
							continue
						apply_damage_melee_data.impulse_dir = bf.vector2_direction_or_random(
							attacker_pos,
							bf.xz(x.transform.origin),
						)
						if apply_damage_interactable(x, melee.get_damage(), apply_damage_melee_data):
							creature.attack_damaged_interactables.append(x)
				else:
					for d: Dictionary in q:
						var x: Creature = d.collider
						if (
							(x.type == glib.GCreatureType.PLAYER)
							== (creature.type == glib.GCreatureType.PLAYER)
						):
							continue
						if x in creature.attack_damaged_creatures:
							continue
						apply_damage_melee_data.impulse_dir = bf.vector2_direction_or_random(
							attacker_pos,
							bf.xz(x.transform.origin),
						)
						apply_damage_melee_data.damage_stamina = melee.get_damage_stamina()
						if apply_damage(x, melee.get_damage(), apply_damage_melee_data):
							creature.attack_damaged_creatures.append(x)

	Collisions.set_gizmos_color(Color.YELLOW)
	##

	## - Updating projectiles + collisions + despawning
	for x: Projectile in room.container_projectiles.get_children():
		var data := g_projectiles[x.d.type]
		x.explicit_process(dt, data)
		Projectile.updaters[data.get_projectilefly_type()].explicit_process(
			dt,
			x,
			(x.d.owner_type == glib.GCreatureType.PLAYER),
			data,
		)
		if x.is_queued_for_deletion():
			x.on_free(data)

	Collisions.set_gizmos_color(Color.YELLOW)
	##

	## Spike collisions
	if 1:
		var dd := ApplyDamageData.new()
		dd.type = glib.GDamageType.SPIKE
		var spikes_data := glib.v.get_spikes()
		var evade_flags := [spikes_data.get_initial_evade_flags(), spikes_data.get_continuous_evade_flags()]
		for spike: Spike in room.container_spikes.get_children():
			if spike.is_active && (spike.activation_elapsed >= glib.v.get_spikes().get_damage_starts_at()):
				dd.evade_flags = evade_flags[int(spike.striked)]
				dd.attack_id = spike.attack_id
				spike.striked = true
				for creature: Creature in spike.creatures_to_damage:
					apply_damage(creature, glib.v.get_spikes().get_damage(), dd)
	##

	## Pushing creatures apart from each other
	if 1:
		var creatures_push_radius := glib.v.get_creatures_push_radius()
		var creatures_push_radius_sqr := creatures_push_radius * creatures_push_radius
		room.player.inside_enemy_t = 0
		for c1: Creature in room.container_creatures.get_children():
			for c2: Creature in room.container_creatures.get_children():
				if c1 == c2:
					continue
				var dir := bf.xz(c1.transform.origin - c2.transform.origin)
				var d := dir.length_squared()
				if d < creatures_push_radius_sqr:
					var t := 1.0 - sqrt(d) / creatures_push_radius
					bf.move_body_with_speed(c1.node_body, dir, t)
					if c1.type == glib.GCreatureType.PLAYER:
						room.player.inside_enemy_t = max(room.player.inside_enemy_t, t)
		room.player.inside_enemy_t = min(1, room.player.inside_enemy_t)
	##

	## Updating creatures time_since_last_damage_taken + flashing
	for creature: Creature in room.container_creatures.get_children():
		creature.time_since_last_damage_taken += dt
		creature.time_since_hp_rally += dt
		creature.time_since_last_damage_taken_visual += dt

		if (
			(creature.type == glib.GCreatureType.PLAYER)
			&& (creature.time_since_hp_rally >= glib.v.get_hp_rally_decays_after())
		):
			assert(creature.hp_recoverable_up_to >= creature.hp)
			creature.hp_recoverable_up_to -= glib.v.get_hp_rally_decay_speed() * dt
			creature.hp_recoverable_up_to = max(creature.hp_recoverable_up_to, creature.hp)
			assert(creature.hp_recoverable_up_to >= creature.hp)
			var max_hp: float = glib.v.get_creatures()[creature.type].get_hp()
			creature.hp_bar.set_rally_front_progress((creature.hp_recoverable_up_to as float) / max_hp)

		var sh: ShaderMaterial = creature.node_sprite.material_override
		var t: float = max(0.0, lerp(1.0, 0.0, creature.time_since_last_damage_taken_visual))
		sh.set_shader_parameter("flash", Color(1, 1, 1, t))
	##

	## Flashing player
	if 1:
		var sh: ShaderMaterial = room.player.creature.node_sprite.material_override
		if room.player.dodging:
			sh.set_shader_parameter("flash", Color(0, 1, 0, 0.5))
		if room.player.blocking:
			sh.set_shader_parameter("flash", Color(0, 0, 1, 0.6))
		if room.player.ki:
			sh.set_shader_parameter("flash", Color(0, 0, 1, 0.5))
		if room.player.blocking_perfectly:
			sh.set_shader_parameter("flash", Color(1, 1, 0, 0.4))
	##

	## Updating player hp and stamina bars
	hp_bar.set_progress((room.player.creature.hp as float) / (g_creatures[room.player.creature.type].get_hp() as float))
	var st := glib.v.get_player().get_stamina()
	stamina_bar.set_progress(room.player.stamina / st)
	stamina_bar.set_rally_back_progress(room.player.stamina_rally / st)
	stamina_bar.set_rally_front_progress(room.player.stamina_ki / st)
	##


func make_creature(type: glib.GCreatureType, pos: Vector2) -> Creature: ##
	var data := glib.v.get_creatures()[type]
	var creature: Creature = packed_creature.instantiate()
	room.container_creatures.add_child(creature)

	creature.type = type
	creature.res = load(data.get_res())
	creature.speed_modifiers.base = data.get_speed()
	creature.node_body.mass = data.get_mass()
	assert(creature.res)
	bf.set_pos_2d(creature, pos)

	creature.scale = Vector3(1, 1, 1) * data.get_collider_size()
	assert(creature.scale.x > 0)
	assert(creature.scale.y > 0)
	assert(creature.scale.z > 0)
	creature.hp = data.get_hp()
	creature.hp_recoverable_up_to = creature.hp
	creature.node_sprite.texture = creature.res.texture

	if type == glib.GCreatureType.PLAYER:
		creature.hp_bar = hp_bar
	else:
		var bar: Bar = packed_ui_bar_mob.instantiate()
		creature.hp_bar = bar
		bar.anchor_right *= creature.hp / 30.0
		room.container_mob_hp_bars.add_child(bar)
		var tree: BeehaveTree = packed_ai.instantiate()
		creature.setup_ai(tree)
	creature.node_target_camera.add_to_group(GROUP_TARGET_CAMERA)

	var sh: ShaderMaterial = creature.node_sprite.material_override
	sh.set_shader_parameter("flash", Color(1, 1, 1, 0))
	sh.set_shader_parameter("albedo", creature.res.texture)

	return creature
	##


func apply_damage(creature: Creature, damage: float, data: ApplyDamageData) -> bool: ##
	assert(data.impulse >= 0)

	assert(data.attack_id)
	if creature.is_attack_evaded(data.attack_id):
		return false

	var impulse_dur := glib.v.get_default_impulse_duration_seconds()
	var impulse_pow := glib.v.get_default_impulse_pow()

	var player_got_damaged := (creature.type == glib.GCreatureType.PLAYER)
	if player_got_damaged:
		if (data.evade_flags & glib.GEvadeType.PERFECT_BLOCKABLE) && room.player.blocking_perfectly:
			player_perfectly_blocked.emit(creature.transform.origin)
			creature.mark_attack_as_evaded(data.attack_id)
			add_impulse(
				creature.impulses,
				data.impulse_dir,
				data.impulse * glib.v.get_impulse_block_scale() / creature.node_body.mass,
				impulse_dur,
				impulse_pow,
			)
			return false

		elif (data.evade_flags & glib.GEvadeType.JUST_BLOCKABLE) && room.player.blocking:
			creature.mark_attack_as_evaded(data.attack_id)
			creature.blocked = true
			player_blocked.emit(creature.transform.origin)
			room.player.consume_stamina(data.damage_stamina)
			add_impulse(
				creature.impulses,
				data.impulse_dir,
				data.impulse * glib.v.get_impulse_block_scale() / creature.node_body.mass,
				impulse_dur,
				impulse_pow,
			)
			damage /= 2
			assert(damage >= 0)
			if damage <= 0:
				return false

		elif (data.evade_flags & glib.GEvadeType.ROLLABLE) && room.player.dodging:
			if data.evade_flags & glib.GEvadeType.STAMINA_RECOVERING_ROLLABLE:
				var retrieve := (
					room.player.rolling_retrievable_cost
					* glib.v.get_player().get_dodge_stamina_retrieve_percent() / 100.0
				)
				room.player.add_stamina(retrieve, 1)
				room.player.rolling_retrievable_cost -= retrieve
				player_perfectly_evaded.emit(creature.transform.origin)
			creature.mark_attack_as_evaded(data.attack_id)
			return false

		var invincibility_dur := glib.v.get_player().get_invincibility_after_hit_seconds()
		if creature.time_since_last_damage_taken <= invincibility_dur:
			return false

		creature.time_since_last_damage_taken = 0
		creature.time_since_hp_rally = 0

	else:
		if data.type == glib.GDamageType.SPIKE:
			if creature.time_since_last_damage_taken <= glib.v.get_mob_invincibility_spikes_seconds():
				return false
			creature.time_since_last_damage_taken = 0
			creature.time_since_hp_rally = 0

	if damage > 0:
		creature.hp_recoverable_up_to = creature.hp
	var dealt_damage: float = min(creature.hp, damage)
	creature.hp -= dealt_damage
	var creature_max_hp: float = glib.v.get_creatures()[creature.type].get_hp()
	creature.hp_bar.set_progress((creature.hp as float) / creature_max_hp)
	creature.time_since_last_damage_taken_visual = 0

	if creature.type == glib.GCreatureType.PLAYER:
		creature.hp_recoverable_up_to = lerp(
			creature.hp,
			creature.hp_recoverable_up_to,
			glib.v.get_hp_damage_rally_percent(),
		)
		assert(creature.hp >= 0)
		creature.hp_bar.set_rally_front_progress(
			(creature.hp_recoverable_up_to as float) / creature_max_hp,
		)
	if is_instance_valid(data.owner__mb_freed_or_null):
		data.owner__mb_freed_or_null.recover_hp_rally(data.hp_rally_recover)

	if (creature.type != glib.GCreatureType.PLAYER) && (creature.hp <= 0):
		room.player.add_stamina(glib.v.get_player().get_stamina_regen_on_kill(), 1)
		creature.queue_free()
		creature.node_target_camera.add_to_group(GROUP_TARGET_CAMERA)
		if creature.type != glib.GCreatureType.PLAYER:
			room.container_mob_hp_bars.remove_child(creature.hp_bar)

	if dealt_damage > 0:
		damaged.emit(
			creature.transform.origin,
			dealt_damage,
			WhoGotDamagedType.PLAYER if player_got_damaged else WhoGotDamagedType.MOB,
		)
	add_impulse(creature.impulses, data.impulse_dir, data.impulse / creature.node_body.mass, impulse_dur, impulse_pow)

	return true
	##


func apply_damage_interactable(interactable: Interactable, damage: float, data: ApplyDamageData) -> bool: ##
	var dealt_damage: float = min(damage, interactable.hp)
	interactable.hp -= dealt_damage

	if is_instance_valid(data.owner__mb_freed_or_null):
		data.owner__mb_freed_or_null.recover_hp_rally(data.hp_rally_recover)

	var impulse_dur := glib.v.get_default_impulse_duration_seconds()
	var impulse_pow := glib.v.get_default_impulse_pow()
	add_impulse(interactable.impulses, data.impulse_dir, data.impulse, impulse_dur, impulse_pow)

	assert(interactable.hp >= 0)
	if dealt_damage > 0:
		damaged.emit(
			interactable.transform.origin,
			dealt_damage,
			WhoGotDamagedType.MOB,
		)
	if !interactable.spawned_projectile && (interactable.hp <= 0):
		interactable.spawned_projectile = true
		var id := glib.v.get_interactables()[interactable.type]
		var d := Projectile.Data.new()
		d.type = id.get_projectile_type() as glib.GProjectileType
		d.pos = bf.xz(interactable.transform.origin)
		d.target = d.pos
		d.homing__target = null
		make_projectile(d)
		interactable.queue_free()
	return true
	##


func make_projectile(d: Projectile.Data) -> void: ##
	assert(d.type)

	var data := glib.v.get_projectiles()[d.type]
	var target_dir := bf.vector2_direction_or_random(d.pos, d.target)
	d.target = d.pos + target_dir * min(data.get_distance(), (d.target - d.pos).length())

	projectiles_to_make.append(d)
	##


func _from_proto(val: Variant) -> Variant: ##
	if val is glib.GV2:
		var v_: glib.GV2 = val
		return Vector2(v_.get_x(), v_.get_y())

	if val is glib.GV3:
		var v_: glib.GV3 = val
		return Vector3(v_.get_x(), v_.get_y(), v_.get_z())

	if val is glib.GV4:
		var v_: glib.GV4 = val
		return Vector4(v_.get_x(), v_.get_y(), v_.get_z(), v_.get_w())

	return val
	##


func _keyframe_make_lerp(v1: Variant, v2: Variant, t: float) -> Variant: ##
	assert(typeof(v1) == typeof(v2))

	assert(t >= 0)
	assert(t <= 1)
	if v1 is int:
		return lerp(float(v1 as int), float(v2 as int), t)

	if v1 is float:
		return lerp(v1, v2, t)

	if v1 is glib.GV2:
		var v1_: glib.GV2 = v1
		var v2_: glib.GV2 = v2
		var x: float = lerp(v1_.get_x(), v2_.get_x(), t)
		var y: float = lerp(v1_.get_y(), v2_.get_y(), t)
		return Vector2(x, y)

	if v1 is glib.GV3:
		var v1_: glib.GV3 = v1
		var v2_: glib.GV3 = v2
		var x: float = lerp(v1_.get_x(), v2_.get_x(), t)
		var y: float = lerp(v1_.get_y(), v2_.get_y(), t)
		var z: float = lerp(v1_.get_z(), v2_.get_z(), t)
		return Vector3(x, y, z)

	if v1 is glib.GV4:
		var v1_: glib.GV4 = v1
		var v2_: glib.GV4 = v2
		var x: float = lerp(v1_.get_x(), v2_.get_x(), t)
		var y: float = lerp(v1_.get_y(), v2_.get_y(), t)
		var z: float = lerp(v1_.get_z(), v2_.get_z(), t)
		var w: float = lerp(v1_.get_w(), v2_.get_w(), t)
		return Vector4(x, y, z, w)

	bf.invalid_path()
	return null
	##


func _make_keyframe_value_at(keyframes: Array, index_timeline: int) -> Variant: ##
	assert(len(keyframes))
	for item in bf.iter_neighbors.new(keyframes):
		var left = item[1]
		var right = item[3]

		@warning_ignore_start("unsafe_method_access")

		if left and right:
			if (
				(left.get_index_timeline() < index_timeline)
				&& (index_timeline < right.get_index_timeline())
			):
				var l: int = left.get_index_timeline()
				var r: int = right.get_index_timeline()
				var t := float(index_timeline - l) / float(r - l)
				return _keyframe_make_lerp(left.get_value(), right.get_value(), t)

		elif left:
			if left.get_index_timeline() <= index_timeline:
				return _from_proto(left.get_value())

		elif right:
			if index_timeline < right.get_index_timeline():
				return _from_proto(right.get_value())

		@warning_ignore_restore("unsafe_method_access")

	bf.invalid_path()
	return null
	##


func _room_index(pos: Vector2i) -> int: ##
	return pos.y * glib.v.get_world_size().get_x() + pos.x
	##


func _on_player_entered_door(body: Node3D, direction_index: int) -> void: ##
	if player_is_entering_door:
		return
	if body != room.player.creature:
		return

	var tween = create_tween()
	var r: Node = %_transition
	player_is_entering_door = true
	Room.v.player._buffer.clear()
	tween.tween_property(r, "modulate:a", 1, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(_remake_room.bind(current_room_pos + bf.DIRECTION_OFFSETS[direction_index], direction_index))
	tween.tween_property(r, "modulate:a", 0, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	##


func _remake_room(new_room_pos: Vector2i, player_direction_index: int) -> void:
	var player_hp: float = glib.v.get_creatures()[glib.GCreatureType.PLAYER].get_hp()
	var player_hp_recoverable_up_to := player_hp

	## Updating flash of ui minimap
	if current_room_pos != Vector2i.MAX:
		var s1: ShaderMaterial = ui_minimap_rooms[current_room_index].material
		s1.set_shader_parameter('flash', Vector4(1, 1, 1, 0))
	current_room_pos = new_room_pos
	var s2: ShaderMaterial = ui_minimap_rooms[current_room_index].material
	s2.set_shader_parameter('flash', Vector4(1, 1, 1, 0.6))
	##

	## Reinstantiating room node
	player_is_entering_door = false
	if room:
		player_hp = room.player.creature.hp
		player_hp_recoverable_up_to = room.player.creature.hp_recoverable_up_to
		room.queue_free()
	room = packed_room.instantiate()
	container_general.add_child(room)
	Room.v = room

	bf.clear_children(room.container_creatures)
	##

	var g_rooms = glib.v.get_rooms()
	var g_room = g_rooms[rooms[current_room_index].gindex]
	var size := glib.ToV2i(g_room.get_size())

	## Placing floor tiles
	bf.clear_children(room.container_floor)
	var tiles = g_room.get_tiles()
	for y in range(size.y):
		for x in range(size.x):
			var t = y * size.x + x
			var node: Node3D
			if tiles[t] == 1:
				node = packed_floor_tile.instantiate()
			elif tiles[t] == 2:
				node = packed_floor_void_tile.instantiate()
			else:
				node = packed_collider_tile.instantiate()
			bf.set_pos_2d(node, Vector2(x, y) + Vector2(0.5, 0.5))
			room.container_floor.add_child(node)
	##

	var ws := glib.ToV2i(glib.v.get_world_size())
	var bounds = Rect2i(Vector2i(0, 0), ws)

	var player_pos := Vector2(size) / 2

	## Placing doors
	for door in g_room.get_doors():
		var offset := bf.DIRECTION_OFFSETS[door.get_direction()]
		var to_pos := current_room_pos + offset
		if !bounds.has_point(to_pos):
			continue

		var node: Area3D = packed_door.instantiate()
		bf.scale_2d(node, glib.ToV2(door.get_size()))
		bf.set_pos_2d(node, glib.ToV2(door.get_center_pos()))
		room.container_doors.add_child(node)

		node.body_entered.connect(_on_player_entered_door.bind(door.get_direction()))

		if (door.get_direction() + 2) % 4 == player_direction_index:
			player_pos = glib.ToV2(door.get_center_pos()) + Vector2(bf.DIRECTION_OFFSETS[player_direction_index]) * 2
	##

	## Placing spikes
	for x in g_room.get_spikes():
		var node: Spike = packed_spike.instantiate()
		node.transform.origin = bf.to_xz(glib.ToV2(x.get_pos()))
		room.container_spikes.add_child(node)
		node.init(room)
	##

	## Placing interactables
	for xd in g_room.get_interactables():
		var type := xd.get_interactable_type() as glib.GInteractableType
		var d := glib.v.get_interactables()[type]

		var x: Interactable = packed_interactable.instantiate()
		x.type = type
		x.res = load(d.get_res())
		x.transform.origin = bf.to_xz(glib.ToV2(xd.get_pos()))
		room.container_interactables.add_child(x)

		x.hp = d.get_hp()
		x.node_body.mass = d.get_mass()
		x.node_target_camera.add_to_group(GROUP_TARGET_CAMERA)
		x.node_sprite.texture = x.res.texture
	##

	## Placing player and other creatures
	var bow: Node3D = packed_bow.instantiate()
	var player_creature := make_creature(glib.GCreatureType.PLAYER, player_pos)
	player_creature.hp = player_hp
	player_creature.hp_recoverable_up_to = player_hp_recoverable_up_to
	room.player.init(player_creature, bow)
	for mob in g_room.get_creatures():
		make_creature(mob.get_creature_type(), glib.ToV2(mob.get_pos()))
	##


func _get_mouse_world_point() -> Vector3: ##
	var mouse_pos := get_viewport().get_mouse_position()
	var ray_origin := camera.project_ray_origin(mouse_pos)
	var ray_dir := camera.project_ray_normal(mouse_pos)
	var hit_position = Plane(Vector3.UP, 0).intersects_ray(ray_origin, ray_dir)
	if hit_position:
		return hit_position
	return Vector3.INF
	##


func _process_impulses(arr: Array[Impulse], body: RigidBody3D) -> void: ##
	var impulse_index := -1
	for impulse in arr:
		impulse_index += 1
		var e := Room.v.start_elapsed - impulse.created_at
		if e < impulse.dur:
			var speed := bf.get_roll_speed(impulse.dist, impulse.dur, e, impulse.pow_)
			bf.move_body_with_speed(body, impulse.dir, speed)
		else:
			_impulses_to_remove_indices.append(impulse_index)
	bf.unstable_remove_indices(arr, _impulses_to_remove_indices)
	##


class Impulse: ##
	var dir: Vector2
	var dist: float
	var pow_: float
	var dur: float
	var created_at: float
	##


class RoomData: ##
	var directions := 0
	var gindex := -1
	##


class ApplyDamageData: ##
	var type := glib.GDamageType.DEFAULT
	var evade_flags: int
	var attack_id := 0
	var impulse := 0.0
	var impulse_dir := Vector2(0, 0)
	var damage_stamina: glib.GStaminaCost = null
	var hp_rally_recover: float
	var owner__mb_freed_or_null: Creature
	##
