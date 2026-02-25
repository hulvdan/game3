@tool
extends ActionLeaf

class_name ActionChase

var _attack_distance: float


func set_attack_distance(value: float) -> void: ##
	_attack_distance = value
##


func tick(actor_: Node, _blackboard: Blackboard) -> int:
	var actor: Creature = actor_
	var target_pos: Vector2 = bf.xz(Room.v.player.creature.transform.origin)
	var pos = bf.xz((actor as Node3D).transform.origin)
	var dpos: Vector2 = target_pos - pos

	if glib.v.get_debug_collisions():
		ImmediateGizmos3D.set_transform(actor.transform)
		ImmediateGizmos3D.line_circle(Vector3(0, 0, 0), Vector3(0, 1, 0), _attack_distance)

	if dpos.length_squared() <= _attack_distance * _attack_distance:
		# Target is in attack range.
		actor.controller.move = Vector2(0, 0)
		return SUCCESS

	var dir: Vector2 = dpos.normalized()
	actor.controller.move = dir
	return RUNNING
