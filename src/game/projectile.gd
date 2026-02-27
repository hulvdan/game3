extends Node3D

class_name Projectile

const MAX_COLLISIONS_DEFAULT := 4
const MAX_COLLISIONS_AOE := 12


## Variables
class Data:
	var type: glib.GProjectileType
	var owner: Creature
	var pos: Vector2
	var target: Vector2
	var homing__target: Node3D


var elapsed: float
var d: Data
var res: ResProjectile
var zones: Array[Node3D]
var damaged_creatures: Array[Creature]
var default__pierced: int
var attack_id: int
var calculated__dir: Vector2
var homing__velocity: Vector2
var travelled: float
var blinked: bool

@onready var sprite: Sprite3D = %_sprite

static var updaters: Array[UpdaterBase] = [
	UpdaterDefault.new(),
	UpdaterArc.new(),
]
##


func explicit_process(dt: float, data: glib.GProjectile) -> void: ##
	elapsed += dt

	for tag in data.get_tags():
		match tag.get_projectiletag_type():
			glib.GProjectileTagType.BLINK:
				assert(d.owner)
				if d.owner && !blinked && (elapsed >= tag.get_f1()):
					blinked = true
					if is_instance_valid(d.owner):
						d.owner.transform.origin = transform.origin
						d.owner.reset_physics_interpolation()
##


func on_free(data: glib.GProjectile) -> void: ##
	for tag in data.get_tags():
		match tag.get_projectiletag_type():
			glib.GProjectileTagType.HIVE:
				var angle := calculated__dir.angle()
				var children_count := tag.get_i1()
				assert(children_count > 0)

				var angle_step := 2 * PI / children_count
				for i in range(children_count):
					angle += angle_step

					var c := Projectile.Data.new()
					c.type = tag.get_projectile_type() as glib.GProjectileType
					c.owner = d.owner
					c.pos = bf.xz(transform.origin)
					c.target = c.pos + Vector2(1, 0).rotated(angle)
					c.homing__target = d.homing__target
					Game.v.make_projectile(c)
##


@abstract
class UpdaterBase:
	static var damage_data := Game.ApplyDamageData.new()


	func explicit_process(_dt: float, x: Projectile, _is_player: bool, data: glib.GProjectile) -> void: ##
		damage_data.attack_id = x.attack_id
		if x.travelled > data.get_distance():
			x.queue_free()
	##


class UpdaterDefault extends UpdaterBase:
	func explicit_process(dt: float, x: Projectile, is_player: bool, data: glib.GProjectile) -> void: ##
		super.explicit_process(dt, x, is_player, data)

		damage_data.type = glib.GDamageType.DEFAULT
		var projectile_travelled := data.get_default__speed() * dt
		x.travelled += projectile_travelled

		var moved := x.calculated__dir * projectile_travelled
		x.transform.origin += bf.to_xz(moved)
		for tag in data.get_tags():
			match tag.get_projectiletag_type():
				glib.GProjectileTagType.HOMING:
					if x.d.homing__target:
						var target_dir := bf.vector2_direction_or_random(
							bf.xz(x.transform.origin),
							bf.xz(x.d.homing__target.transform.origin),
						)
						x.calculated__dir = Vector2(1, 0).rotated(
							lerp_angle(
								x.calculated__dir.angle(),
								target_dir.angle(),
								tag.get_f1() * dt,
							),
						)

		var q: Array[Dictionary]

		for mask: int in [
			2 ** glib.GMaskType.WALLS,
			2 ** (glib.GMaskType.MOBS if is_player else glib.GMaskType.PLAYER),
		]:
			assert(data.get_collider_radius() >= 0)
			if data.get_collider_radius() > 0:
				q = Collisions.query_circle(
					bf.xz(x.transform.origin),
					data.get_collider_radius(),
					mask,
					true,
					false,
					MAX_COLLISIONS_DEFAULT,
				)
			else:
				q = Collisions.query_ray(
					bf.xz(x.transform.origin),
					x.calculated__dir.angle(),
					projectile_travelled,
					mask,
					true,
					false,
					MAX_COLLISIONS_DEFAULT,
				)

			if mask == 2 ** glib.GMaskType.WALLS:
				if q:
					x.queue_free()

			elif data.get_damage() > 0:
				for d: Dictionary in q:
					var damaged_creature: Creature = d.collider
					if damaged_creature in x.damaged_creatures:
						continue

					if Game.v.apply_damage(damaged_creature, data.get_damage(), damage_data):
						x.damaged_creatures.append(damaged_creature)
						x.default__pierced += 1
						if x.default__pierced > data.get_pierce():
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
			var color := Color(1, 0, 0, 1) if data.get_damage() > 0 else Color(1, 1, 1, 1)
			ImmediateGizmos3D.line_circle(
				Vector3(0, 0, 0),
				Vector3(0, 1, 0),
				data.get_collider_radius(),
				color,
			)
			ImmediateGizmos3D.line_circle(
				Vector3(0, 0, 0),
				Vector3(0, 1, 0),
				t * data.get_collider_radius(),
				color,
			)

		if x.elapsed >= data.get_arc__duration():
			var mask: int = 2 ** (glib.GMaskType.MOBS if is_player else glib.GMaskType.PLAYER)

			if data.get_damage() > 0:
				for d: Dictionary in Collisions.query_circle(
					bf.xz(x.transform.origin),
					data.get_collider_radius(),
					mask,
					true,
					false,
					MAX_COLLISIONS_AOE,
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
