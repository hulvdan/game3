@tool
extends ActionLeaf

class_name ActionAttack

var projectiles_spawned: int


func tick(actor_: Node, _blackboard: Blackboard) -> int:
	var actor: Creature = actor_
	var data = glib.v.get_creatures()[actor.type]

	## Attack start
	if !actor.attack_elapsed:
		Game.v.enemy_started_attack.emit(actor.transform.origin)
		actor.melee_attacking = true
		actor.melee_attack_id = Room.v.get_next_attack_id()
		actor.melee_damaged_creatures.clear()
		actor.controller.move = Vector2(0, 0)
	##

	if actor.melee_attacking and actor.attack_elapsed <= data.get_melee__attack_stops_tracking_at():
		actor.melee_target_pos = bf.xz(Room.v.player.creature.transform.origin)
		actor.melee_target_dir = bf.vector2_direction_or_random(
			bf.xz(actor.transform.origin),
			actor.melee_target_pos,
		)

	actor.attack_elapsed += get_physics_process_delta_time()

	# Processing dash tag
	if data.get_melee__attack_dash_distance() > 0:
		actor.controller.move = actor.melee_target_dir

		var e: float = min(actor.attack_elapsed, data.get_attack_duration())
		actor.speed_modifiers.melee_dash = 0

		var start := data.get_melee__attack_dash_starts_at()
		var end := data.get_melee__attack_dash_ends_at()
		var dur := end - start

		if ((start <= actor.attack_elapsed) && (actor.attack_elapsed <= end)):
			actor.speed_modifiers.melee_dash = bf.get_roll_speed(
				data.get_melee__attack_dash_distance(),
				dur,
				e - start,
				data.get_melee__attack_dash_pow(),
			)

	## Spawning projectiles
	if data.get_attack_projectile_type():
		var i: int = 0
		for projectile_spawns_at in data.get_attack_projectiles_spawn_at():
			i += 1
			if projectiles_spawned < i and projectile_spawns_at < actor.attack_elapsed:
				projectiles_spawned += 1
				var d := Projectile.Data.new()
				d.type = data.get_attack_projectile_type() as glib.GProjectileType
				d.owner = actor.type
				d.pos = bf.xz(actor.transform.origin)
				d.target = bf.xz(Room.v.player.creature.transform.origin)
				d.homing__target = Room.v.player.creature
				Game.v.make_projectile(d)
	##

	## Attack finish
	if actor.attack_elapsed >= data.get_attack_duration():
		actor.attack_elapsed = 0.0
		projectiles_spawned = 0
		actor.melee_attacking = false
		actor.controller.move = Vector2(0, 0)
		actor.speed_modifiers.melee_dash = 1
		return SUCCESS
	##

	return RUNNING
