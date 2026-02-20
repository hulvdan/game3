@tool
extends ActionLeaf

class_name ActionAttack

@export var attack_duration: float = 1.0

var elapsed_since_start: float = 0.0
var projectile_spawned: bool


func tick(actor_: Node, _blackboard: Blackboard) -> int:
	var actor: Creature = actor_
	var data = glib.v.get_creatures()[actor.type]

	# var target_pos: Vector2 = bf.from_xz(Room.v.player.transform.origin)
	# var pos = bf.from_xz((actor as Node3D).transform.origin)
	# var dpos: Vector2 = target_pos - pos
	elapsed_since_start += get_physics_process_delta_time()

	if (
		!projectile_spawned
		&& data.get_attack_projectile_type()
		&& (data.get_attack_projectile_spawn_at() < elapsed_since_start)
	):
		projectile_spawned = true
		Game.v.make_projectile(
			data.get_attack_projectile_type(),
			actor.type,
			bf.from_xz(actor.transform.origin),
			bf.from_xz(Room.v.player.transform.origin),
		)

	if elapsed_since_start >= attack_duration:
		# Finished attacking.
		elapsed_since_start = 0.0
		projectile_spawned = false
		return SUCCESS

	return RUNNING
