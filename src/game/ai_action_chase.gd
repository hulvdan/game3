@tool
extends ActionLeaf

class_name ActionChase

@export var attack_range: float = 2.0


func tick(actor_: Node, _blackboard: Blackboard) -> int:
	var actor: Creature = actor_
	var target_pos: Vector2 = bf.from_xz(Room.v.player.creature.transform.origin)
	var pos = bf.from_xz((actor as Node3D).transform.origin)
	var dpos: Vector2 = target_pos - pos

	if dpos.length_squared() <= attack_range * attack_range:
		# Target is in attack range.
		actor.controller.move = Vector2(0, 0)
		return SUCCESS

	var dir: Vector2 = dpos.normalized()
	actor.controller.move = dir
	return RUNNING
