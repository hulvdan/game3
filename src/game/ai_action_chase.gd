@tool
class_name ActionChase
extends ActionLeaf


func tick(actor_: Node, _blackboard: Blackboard) -> int: ##
	var actor: Creature = actor_
	var data := glib.v.get_creatures()[actor.type]
	var target_pos: Vector2 = bf.xz(Room.v.player.creature.transform.origin)
	var pos = bf.xz((actor as Node3D).transform.origin)
	var dpos: Vector2 = target_pos - pos

	if _is_condition_satisfied(actor, data.get_attacks()[0].get_condition()):
		actor.controller.move = Vector2(0, 0)
		return SUCCESS

	var dir: Vector2 = dpos.normalized()
	actor.controller.move = dir
	return RUNNING
	##


func _is_condition_satisfied(
		creature: Creature,
		condition: glib.GAttackConditionValue,
) -> bool: ##
	if !condition:
		return true

	assert(!condition.get_distance_min())
	match condition.get_attackcondition_type():
		glib.GAttackConditionType.TUNNEL:
			for d: Dictionary in Collisions.query_capsule(
				bf.xz(creature.transform.origin) + creature.looking_dir * (condition.get_distance_max() / 2.0),
				creature.looking_angle,
				condition.get_distance_max(),
				condition.get_tunnel__capsule_radius(),
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
