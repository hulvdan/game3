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
		if _is_condition_satisfied(c, attack.get_condition()):
			c.controller.move = Vector2(0, 0)
			return SUCCESS

	var dir: Vector2 = dpos.normalized()
	c.controller.move = dir
	return RUNNING
	##


func _is_condition_satisfied(
		creature: Creature,
		condition: glib.GAttackConditionValue,
) -> bool: ##
	if !condition:
		return true

	var dir = creature.looking_dir.rotated(condition.get_rotation())
	var capsule_center_pos: Vector2 = (
		bf.xz(creature.transform.origin)
		+ dir * ((condition.get_distance_min() + condition.get_distance_max()) / 2.0)
	)

	var cond := condition.get_attackcondition_type()
	match cond:
		glib.GAttackConditionType.CAPSULE_CONTAINED, glib.GAttackConditionType.CAPSULE_RADIUS_EXTENDED:
			var dist := condition.get_distance_max() - condition.get_distance_min()
			if cond == glib.GAttackConditionType.CAPSULE_RADIUS_EXTENDED:
				dist += condition.get_capsule__radius() * 2.0
			for d: Dictionary in Collisions.query_capsule(
				capsule_center_pos,
				creature.looking_angle + condition.get_rotation(),
				dist,
				condition.get_capsule__radius(),
				2 ** glib.GMaskType.CREATURES,
				true,
				false,
				12,
			):
				var v: Creature = d.collider
				if v.type == glib.GCreatureType.PLAYER:
					return true
		_:
			bf.invalid_path()
	return false
	##
