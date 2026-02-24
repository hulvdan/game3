extends Node3D

class_name Projectile

class Data:
	var type: glib.GProjectileType
	var owner: glib.GCreatureType
	var pos: Vector2
	var target: Vector2
	var homing__target: Node3D


var elapsed: float
var d: Data
var res: ResProjectile
var zones: Array[Node3D]
var damaged_creatures: Array[Creature]
var straight__pierced: int
var attack_id: int
var calculated__dir: Vector2
var homing__velocity: Vector2

@onready var sprite: Sprite3D = %_sprite

static var updaters: Array[UpdaterBase] = [
	UpdaterStraight.new(),
	UpdaterArc.new(),
	UpdaterHoming.new(),
]


@abstract
class UpdaterBase:
	static var damage_data := Game.ApplyDamageData.new()


	func explicit_process(
			dt: float,
			x: Projectile,
			_is_player: bool,
			_data: glib.GProjectile,
	) -> void:
		x.elapsed += dt
		damage_data.attack_id = x.attack_id


class UpdaterStraight extends UpdaterBase:
	func explicit_process(
			dt: float,
			x: Projectile,
			is_player: bool,
			data: glib.GProjectile,
	) -> void:
		super().explicit_process(dt, x, is_player, data)

		damage_data.type = glib.GDamageType.DEFAULT
		var projectile_travelled := data.get_straight__speed() * dt
		cylinder_shape_dict.height = projectile_travelled
		var moved := projectile.calculated__dir * projectile_travelled
		projectile.transform.origin += bf.to_xz(moved)

		if data.get_collider_radius():
			PhysicsServer3D.shape_set_data(shape_rid_sphere, data.get_collider_radius())
			param_shape.shape_rid = shape_rid_sphere
		else:
			PhysicsServer3D.shape_set_data(shape_rid_cylinder, cylinder_shape_dict)
			param_shape.shape_rid = shape_rid_cylinder
		param_shape.transform.origin = projectile.transform.origin
		param_shape.transform.basis = projectile.transform.basis * Basis.from_euler(Vector3(0.0, PI / 2, PI / 2))

		if _debug_collisions:
			ImmediateGizmos3D.set_transform(_param_shape.transform)
			if data.get_collider_radius():
				ImmediateGizmos3D.line_circle(
					Vector3(0, 0, 0),
					Vector3(1, 0, 0),
					data.get_collider_radius(),
					Color.BLUE,
				)
			else:
				ImmediateGizmos3D.line_capsule(
					Vector3(0, 0, 0),
					_cylinder_shape_dict.radius as float,
					_cylinder_shape_dict.height as float,
					Color.BLUE,
				)

		for mask in [
			glib.GCollisionType.WALLS,
			glib.GCollisionType.MOBS if is_player else glib.GCollisionType.PLAYER,
		]:
			# param_shape.collision_mask = mask
			# for d: Dictionary in space.intersect_shape(param_shape, 12):
			for d: Dictionary in Collisions.query_ray():
				if mask == glib.GCollisionType.WALLS:
					x.queue_free()
					break

				var damaged_creature: Creature = d.collider
				if damaged_creature in projectile.damaged_creatures:
					continue

				if apply_damage(damaged_creature, data.get_damage(), damage_data):
					projectile.damaged_creatures.append(damaged_creature)
					projectile.straight__pierced += 1
					if projectile.straight__pierced > data.get_pierce():
						x.queue_free()
						break


class UpdaterArc extends UpdaterBase:
	func explicit_process(
			dt: float,
			x: Projectile,
			is_player: bool,
			data: glib.GProjectile,
	) -> void:
		damage_data.type = glib.GDamageType.AOE
		PhysicsServer3D.shape_set_data(shape_rid_sphere, data.get_arc__aoe_radius())
		param_shape.shape_rid = shape_rid_sphere

		var t := projectile.elapsed / data.get_arc__duration()
		var p: Vector2 = lerp(projectile.d.pos, projectile.d.target, t)
		var pos: Vector3 = bf.to_xz(p)
		pos.y = data.get_arc__height() * sin(t * PI)
		projectile.transform.origin = pos

		if projectile.elapsed >= data.get_arc__duration():
			param_shape.collision_mask = glib.GCollisionType.MOBS if is_player else glib.GCollisionType.PLAYER
			param_shape.transform.origin = bf.to_xz(projectile.d.target)

			for d: Dictionary in space.intersect_shape(param_shape, 12):
				var damaged_creature: Creature = d.collider
				if damaged_creature in projectile.damaged_creatures:
					continue

				if Game.v.apply_damage(damaged_creature, data.get_damage(), damage_data):
					projectile.damaged_creatures.append(damaged_creature)

			x.queue_free()
			for z: Node3D in projectile.zones:
				room.container_zones.remove_child(z)


class UpdaterHoming extends UpdaterBase:
	func explicit_process(
			dt: float,
			x: Projectile,
			is_player: bool,
			data: glib.GProjectile,
	) -> void:
		pass
