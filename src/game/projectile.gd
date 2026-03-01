extends Node3D

class_name Projectile

## Variables
const MAX_COLLISIONS_DEFAULT := 4
const MAX_COLLISIONS_AOE := 12

static var updaters: Array[UpdaterBase] = [
	UpdaterDefault.new(),
	UpdaterArc.new(),
	UpdaterArea.new(),
]


class Data:
	var type: glib.GProjectileType
	var owner_type: glib.GCreatureType
	var owner__mb_freed_or_null: Creature
	var pos: Vector2
	var target: Vector2
	var homing__target: Node3D


var elapsed: float
var d: Data
var res: ResProjectile
var zones: Array[Node3D]
var touched_creatures: Array[Creature]
var default__pierced: int
var attack_id: int
var calculated__dir: Vector2
var homing__velocity: Vector2
var travelled: float
var blinked: bool

@onready var sprite: Sprite3D = %_sprite
@onready var area_sphere: Area3D = %_area_sphere
@onready var shape_sphere: CollisionShape3D = %_shape_sphere
##


func explicit_process(dt: float, data: glib.GProjectile) -> void: ##
	elapsed += dt

	for tag in data.get_tags():
		match tag.get_tag_type():
			glib.GTagType.BLINK:
				if d.owner__mb_freed_or_null && !blinked && (elapsed >= tag.get_f1()):
					blinked = true
					if is_instance_valid(d.owner__mb_freed_or_null):
						d.owner__mb_freed_or_null.transform.origin = transform.origin
						d.owner__mb_freed_or_null.reset_physics_interpolation()
##


func on_body_entered(creature: Creature) -> void: ##
	var is_me := is_instance_valid(owner) && (creature == owner)
	var is_on_my_team := !is_me && (
		(creature.type == glib.GCreatureType.PLAYER)
		== (d.owner_type == glib.GCreatureType.PLAYER)
	)
	var is_enemy := !is_me && !is_on_my_team

	for tag in glib.v.get_projectiles()[d.type].get_tags():
		var activate := false
		var flags := tag.get_team_flags()
		if (flags & glib.GTeamType.ME) && is_me:
			activate = true
		elif (flags & glib.GTeamType.COMRADES) && is_on_my_team:
			activate = true
		elif (flags & glib.GTeamType.ENEMIES) && is_enemy:
			activate = true
		if !activate:
			break

		match tag.get_tag_type():
			glib.GTagType.SCALE_MOVEMENT_SPEED:
				creature.speed_modifiers['pr_sms_%d' % get_instance_id()] = tag.get_f1()
	##


func on_body_exited(creature: Creature) -> void: ##
	for tag in glib.v.get_projectiles()[d.type].get_tags():
		match tag.get_tag_type():
			glib.GTagType.SCALE_MOVEMENT_SPEED:
				creature.speed_modifiers.erase('pr_sms_%d' % get_instance_id())
	##


func on_free(data: glib.GProjectile) -> void: ##
	for tag in data.get_tags():
		match tag.get_tag_type():
			glib.GTagType.HIVE:
				var angle := calculated__dir.angle()
				var children_count := tag.get_i1()
				assert(children_count > 0)

				var angle_step := 2 * PI / children_count
				for i in range(children_count):
					angle += angle_step

					var c := Projectile.Data.new()
					c.type = tag.get_projectile_type() as glib.GProjectileType
					c.owner_type = d.owner_type
					if is_instance_valid(d.owner__mb_freed_or_null):
						c.owner__mb_freed_or_null = d.owner__mb_freed_or_null
					c.pos = bf.xz(transform.origin)
					c.target = c.pos + Vector2(1, 0).rotated(angle)
					c.homing__target = d.homing__target
					Game.v.make_projectile(c)
			glib.GTagType.SUMMON:
				Game.v.make_creature(tag.get_creature_type(), d.target)

##


@abstract
class UpdaterBase:
	static var _damage_data := Game.ApplyDamageData.new()


	func explicit_process(_dt: float, x: Projectile, _is_player: bool, data: glib.GProjectile) -> void: ##
		_damage_data.attack_id = x.attack_id
		if x.travelled > data.get_distance():
			x.queue_free()

		_damage_data.evade_flags = data.get_evade_flags()
		Game.set_gizmos_color_according_to_evade_flags(_damage_data.evade_flags)
	##


	func draw_circle_gizmos(pos: Vector2, radius: float, t: float) -> void: ##
		if !glib.v.get_debug_collisions():
			return
		var trr := Transform3D()
		trr.origin = bf.to_xz(pos)
		ImmediateGizmos3D.set_transform(trr)
		ImmediateGizmos3D.line_circle(
			Vector3(0, 0, 0),
			Vector3(0, 1, 0),
			radius,
		)
		ImmediateGizmos3D.line_circle(
			Vector3(0, 0, 0),
			Vector3(0, 1, 0),
			t * radius,
		)
	##


class UpdaterDefault extends UpdaterBase:
	func explicit_process(dt: float, x: Projectile, is_player: bool, data: glib.GProjectile) -> void: ##
		super.explicit_process(dt, x, is_player, data)

		var projectile_travelled := data.get_default__speed() * dt
		x.travelled += projectile_travelled

		var moved := x.calculated__dir * projectile_travelled
		x.transform.origin += bf.to_xz(moved)
		for tag in data.get_tags():
			match tag.get_tag_type():
				glib.GTagType.HOMING:
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

			else:
				var hook: glib.GTagValue

				for tag in data.get_tags():
					match tag.get_tag_type():
						glib.GTagType.HOOK:
							if is_instance_valid(x.d.owner__mb_freed_or_null):
								hook = tag

				for d: Dictionary in q:
					var creature: Creature = d.collider
					if creature in x.touched_creatures:
						continue

					if Game.v.apply_damage(creature, data.get_damage(), _damage_data):
						x.touched_creatures.append(creature)
						x.default__pierced += 1

						if hook:
							var owner := x.d.owner__mb_freed_or_null
							assert(owner.current_attack)
							if owner.current_attack:
								owner.attack_elapsed = max(
									owner.attack_elapsed,
									owner.current_attack.get_duration() - hook.get_f4(),
								)
							var dd := (
								bf.xz(creature.transform.origin)
								- bf.xz(x.d.owner__mb_freed_or_null.transform.origin)
							)
							var hook_dist: float = max(0.0, dd.length() - hook.get_f3())
							creature.add_impulse(
								bf.vector2_direction_or_random(dd, Vector2(0, 0)),
								hook_dist,
								hook.get_f1(),
								hook.get_f2(),
							)

						if x.default__pierced > data.get_pierce():
							x.queue_free()
							break

	##


class UpdaterArc extends UpdaterBase:
	func explicit_process(dt: float, x: Projectile, is_player: bool, data: glib.GProjectile) -> void: ##
		super.explicit_process(dt, x, is_player, data)

		var t := x.elapsed / data.get_arc_or_area__duration()
		var p: Vector2 = lerp(x.d.pos, x.d.target, t)
		var pos: Vector3 = bf.to_xz(p)
		pos.y = data.get_arc__height() * sin(t * PI)
		x.transform.origin = pos

		draw_circle_gizmos(x.d.target, data.get_collider_radius(), t)

		if x.elapsed >= data.get_arc_or_area__duration():
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
					if damaged_creature in x.touched_creatures:
						continue

					if Game.v.apply_damage(damaged_creature, data.get_damage(), _damage_data):
						x.touched_creatures.append(damaged_creature)

			x.queue_free()
			for z: Node3D in x.zones:
				Room.v.container_zones.remove_child(z)
	##


class UpdaterArea extends UpdaterBase:
	func explicit_process(dt: float, x: Projectile, is_player: bool, data: glib.GProjectile) -> void: ##
		super.explicit_process(dt, x, is_player, data)

		x.transform.origin = bf.to_xz(x.d.target)

		draw_circle_gizmos(x.d.target, data.get_collider_radius(), x.elapsed / data.get_arc_or_area__duration())

		if x.elapsed >= data.get_arc_or_area__duration():
			x.queue_free()
			for z: Node3D in x.zones:
				Room.v.container_zones.remove_child(z)
	##
