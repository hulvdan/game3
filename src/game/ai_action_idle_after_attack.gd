@tool
class_name ActionIdleAfterAttack
extends ActionLeaf

@export var idle_for_min: float = 1.0
@export var idle_for_max: float = 3.0

var will_idle_for: float
var elapsed_since_start: float


func tick(_actor: Node, _blackboard: Blackboard) -> int:
	if !elapsed_since_start:
		will_idle_for = randf_range(idle_for_min, idle_for_max)

	elapsed_since_start += get_physics_process_delta_time()

	if elapsed_since_start < will_idle_for:
		return RUNNING

	return SUCCESS
