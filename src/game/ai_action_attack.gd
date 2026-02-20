@tool
extends ActionLeaf

class_name ActionAttack

@export var attack_duration: float = 1.0

var elapsed_since_start: float = 0.0


func tick(_actor: Node, _blackboard: Blackboard) -> int:
	# var target_pos: Vector2 = bf.from_xz(Room.v.player.transform.origin)
	# var pos = bf.from_xz((actor as Node3D).transform.origin)
	# var dpos: Vector2 = target_pos - pos
	# var _dir: Vector2 = dpos.normalized()
	elapsed_since_start += get_physics_process_delta_time()

	if elapsed_since_start >= attack_duration:
		# Finished attacking.
		elapsed_since_start = 0.0
		return SUCCESS

	return RUNNING
