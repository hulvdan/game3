@tool
extends ActionLeaf

class_name ActionAttack

var projectiles_spawned: int


func tick(actor_: Node, _blackboard: Blackboard) -> int:
	var actor: Creature = actor_
	var data = glib.v.get_creatures()[actor.type]

	if !actor.attack_elapsed: ## Attack started
		Game.v.enemy_started_attack.emit(actor.transform.origin)
		actor.melee_attacking = true
		actor.melee_attack_id = Room.v.get_next_attack_id()
		actor.melee_damaged_creatures.clear()
	##

	if actor.melee_attacking and actor.attack_elapsed <= data.get_melee__attack_stops_tracking_at():
		actor.melee_target_pos = Room.v.player.transform.origin

	actor.attack_elapsed += get_physics_process_delta_time()

	if data.get_attack_projectile_type(): ## Spawning projectiles
		var i: int = 0
		for projectile_spawns_at in data.get_attack_projectiles_spawn_at():
			i += 1
			if projectiles_spawned < i and projectile_spawns_at < actor.attack_elapsed:
				projectiles_spawned += 1
				var d: Projectile.Data = Projectile.Data.new()
				d.type = data.get_attack_projectile_type() as glib.GProjectileType
				d.owner = actor.type
				d.pos = bf.from_xz(actor.transform.origin)
				d.target = bf.from_xz(Room.v.player.transform.origin)
				Game.v.make_projectile(data.get_attack_projectile_type(), d)
	##

	if actor.attack_elapsed >= data.get_attack_duration(): ## Finished attacking
		actor.attack_elapsed = 0.0
		projectiles_spawned = 0
		actor.melee_attacking = false
		return SUCCESS
	##

	return RUNNING
