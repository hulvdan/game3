extends Node3D

class_name Projectile

## Variables
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
##


@abstract
class UpdaterBase:
	static var damage_data := Game.ApplyDamageData.new()


	func explicit_process(dt: float, x: Projectile, _is_player: bool, _data: glib.GProjectile) -> void: ##
		x.elapsed += dt
		damage_data.attack_id = x.attack_id
	##


class UpdaterStraight extends UpdaterBase:
	func explicit_process(dt: float, x: Projectile, is_player: bool, data: glib.GProjectile) -> void: ##
		super.explicit_process(dt, x, is_player, data)

		damage_data.type = glib.GDamageType.DEFAULT
		var projectile_travelled := data.get_straight__speed() * dt
		var moved := x.calculated__dir * projectile_travelled
		x.transform.origin += bf.to_xz(moved)

		var q: Array[Dictionary]

		for mask: int in [
			glib.GCollisionType.WALLS,
			glib.GCollisionType.MOBS if is_player else glib.GCollisionType.PLAYER,
		]:
			if data.get_collider_radius():
				q = Collisions.query_circle(
					bf.from_xz(x.transform.origin),
					data.get_collider_radius(),
					mask,
					true,
					false,
					12,
				)
			else:
				q = Collisions.query_ray(
					bf.from_xz(x.transform.origin),
					x.calculated__dir.angle(),
					projectile_travelled,
					mask,
					true,
					false,
					12,
				)

			for d: Dictionary in q:
				if mask == glib.GCollisionType.WALLS:
					x.queue_free()
					break

				var damaged_creature: Creature = d.collider
				if damaged_creature in x.damaged_creatures:
					continue

				if Game.v.apply_damage(damaged_creature, data.get_damage(), damage_data):
					x.damaged_creatures.append(damaged_creature)
					x.straight__pierced += 1
					if x.straight__pierced > data.get_pierce():
						x.queue_free()
						break
	##


class UpdaterArc extends UpdaterBase:
	func explicit_process(dt: float, x: Projectile, is_player: bool, data: glib.GProjectile) -> void: ##
		super.explicit_process(dt, x, is_player, data)
		damage_data.type = glib.GDamageType.AOE

		var t := x.elapsed / data.get_arc__duration()
		var p: Vector2 = lerp(x.d.pos, x.d.target, t)
		var pos: Vector3 = bf.to_xz(p)
		pos.y = data.get_arc__height() * sin(t * PI)
		x.transform.origin = pos

		if glib.v.get_debug_collisions():
			var trr := Transform3D()
			trr.origin = bf.to_xz(x.d.target)
			trr.basis = x.transform.basis
			ImmediateGizmos3D.set_transform(trr)
			ImmediateGizmos3D.line_circle(
				Vector3(0, 0, 0),
				Vector3(0, 1, 0),
				data.get_arc__aoe_radius(),
				Color(1, 0, 0, 1),
			)
			ImmediateGizmos3D.line_circle(
				Vector3(0, 0, 0),
				Vector3(0, 1, 0),
				t * data.get_arc__aoe_radius(),
				Color(1, 0, 0, 1),
			)

		if x.elapsed >= data.get_arc__duration():
			var mask: int = glib.GCollisionType.MOBS if is_player else glib.GCollisionType.PLAYER

			for d: Dictionary in Collisions.query_circle(
				bf.from_xz(x.transform.origin),
				data.get_arc__aoe_radius(),
				mask,
				true,
				false,
				12,
			):
				var damaged_creature: Creature = d.collider
				if damaged_creature in x.damaged_creatures:
					continue

				if Game.v.apply_damage(damaged_creature, data.get_damage(), damage_data):
					x.damaged_creatures.append(damaged_creature)

			x.queue_free()
			for z: Node3D in x.zones:
				Room.v.container_zones.remove_child(z)
	##


class UpdaterHoming extends UpdaterBase:
	func explicit_process(dt: float, x: Projectile, is_player: bool, data: glib.GProjectile) -> void: ##
		super.explicit_process(dt, x, is_player, data)
	##
