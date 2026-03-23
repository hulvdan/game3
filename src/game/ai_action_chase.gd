@tool
class_name ActionChase
extends ActionLeaf


func tick(actor_: Node, _blackboard: Blackboard) -> int: ##
	var c: Creature = actor_
	var data := glib.v.get_creatures()[c.type]
	var target_pos: Vector2 = bf.xz(Room.v.player.creature.transform.origin)
	var pos = bf.xz((c as Node3D).transform.origin)
	var dpos: Vector2 = target_pos - pos

	for attack: glib.GAttack in data.get_attacks():
		for condition in attack.get_conditions():
			if _is_condition_satisfied(c, condition):
				c.change_attack_to = attack
				c.controller.move = Vector2(0, 0)
				return SUCCESS

	c.controller.move = dpos.normalized()
	return RUNNING
	##


func _is_condition_satisfied(creature: Creature, condition: glib.GCollider) -> bool:
	## Setup
	assert(condition)
	var creature_pos := bf.xz(creature.transform.origin)
	var cond := condition.get_type() as glib.GColType
	##

	match cond:
		glib.GColType.CIRCLE: ##
			for d: Dictionary in Collisions.query_circle(
				creature_pos + glib.ToV2(condition.get_tr()).rotated(creature.looking_angle),
				condition.get_circle__radius(),
				2 ** glib.GMaskType.CREATURES,
				true,
				false,
				12,
			):
				var v: Creature = d.collider
				if v.type == glib.GCreatureType.PLAYER:
					return true
			##
		glib.GColType.CAPSULE: ##
			for d: Dictionary in Collisions.query_capsule(
				creature_pos + glib.ToV2(condition.get_tr()).rotated(creature.looking_angle),
				deg_to_rad(condition.get_capsule__rotation()) + creature.looking_angle,
				condition.get_capsule__spread(),
				condition.get_capsule__radius(),
				2 ** glib.GMaskType.CREATURES,
				true,
				false,
				12,
			):
				var v: Creature = d.collider
				if v.type == glib.GCreatureType.PLAYER:
					return true
			##
		glib.GColType.POLYGON: ##
			for d: Dictionary in Collisions.query_circle_segment(
				creature_pos + glib.ToV2(condition.get_tr()).rotated(creature.looking_angle),
				condition.get_polygon__dist_min(),
				condition.get_polygon__dist_max(),
				deg_to_rad(condition.get_capsule__rotation()) + creature.looking_angle,
				deg_to_rad(condition.get_polygon__spread_angle()),
				2 ** glib.GMaskType.CREATURES,
				true,
				false,
				12,
			):
				var v: Creature = d.collider
				if v.type == glib.GCreatureType.PLAYER:
					return true
			##
		_:
			bf.invalid_path()

	return false
	##
