@tool
extends ActionLeaf

class_name ActionAttack

var cooldown: ActionRandCooldown


static func explicit_update_attack(
		dt: float,
		c: Creature,
		action_cooldown: ActionRandCooldown,
		attack: glib.GAttack,
		tracking_pos: Vector2,
) -> bool:
	var is_player := c.type == glib.GCreatureType.PLAYER
	var attack_duration := attack.get_duration()
	var melee := attack.get_melee()

	## Attack start
	if !c.attack_elapsed:
		c.melee_attack = attack
		c.melee_attack_id = Room.v.get_next_attack_id()
		c.melee_damaged_creatures.clear()
		if c.type != glib.GCreatureType.PLAYER:
			Game.v.enemy_started_attack.emit(c.transform.origin)
			if action_cooldown:
				action_cooldown.cooldown_min = attack.get_cooldown_min() + attack_duration
				action_cooldown.cooldown_min = attack.get_cooldown_max() + attack_duration
	##

	## Tracking target
	if c.melee_attack && (c.attack_elapsed <= attack.get_stops_tracking_at()):
		c.attack_target_pos = tracking_pos
		c.attack_target_dir = bf.vector2_direction_or_random(
			bf.xz(c.transform.origin),
			c.attack_target_pos,
		)
	##

	c.attack_elapsed += dt

	## Player consuming stamina
	if is_player:
		var consume_stamina_at := INF
		if attack.get_projectile_spawns():
			consume_stamina_at = min(consume_stamina_at, attack.get_projectile_spawns()[0].get_at())
		if melee:
			consume_stamina_at = min(consume_stamina_at, melee.get_starts_at())
		if consume_stamina_at == INF:
			consume_stamina_at = 0.0

		if (
			!Room.v.player.attack_consumed_stamina
			&& (c.attack_elapsed >= consume_stamina_at)
		):
			Room.v.player.attack_consumed_stamina = true
			Room.v.player.consume_stamina(attack.get_stamina_cost())
	##

	# Processing tags
	for tag in attack.get_tags():
		match tag.get_tag_type():
			glib.GTagType.DASH: ##
				if !c.attack_dashed:
					var start := tag.get_f1()
					if start <= c.attack_elapsed:
						c.attack_dashed = true
						var d := c.attack_target_pos - bf.xz(c.transform.origin)
						var dist: float = max(0, min(d.length(), tag.get_f3()) - tag.get_f4())
						var pow_ := tag.get_f5()
						c.add_impulse(c.attack_target_dir, dist, tag.get_f2() - start, pow_)
			##
			glib.GTagType.BLINK: ##
				if !c.attack_blinked:
					var dur := tag.get_f2() - tag.get_f1()
					if c.attack_elapsed >= dur / 2:
						c.attack_blinked = true
						var d := c.attack_target_pos - bf.xz(c.transform.origin)
						var l: float = max(0, min(d.length(), tag.get_f3()) - tag.get_f4())
						c.transform.origin += bf.to_xz(c.attack_target_dir * l)
						c.reset_physics_interpolation()
			##

	## Spawning projectiles
	if attack.get_projectile_type():
		var i: int = 0
		for spawn in attack.get_projectile_spawns():
			i += 1
			if (c.attack_projectiles_spawned < i) && (spawn.get_at() < c.attack_elapsed):
				c.attack_projectiles_spawned += 1
				var d := Projectile.Data.new()
				d.type = attack.get_projectile_type() as glib.GProjectileType
				d.owner_type = c.type
				d.owner__mb_freed_or_null = c
				d.pos = bf.xz(c.transform.origin)
				d.target = d.pos + (c.attack_target_pos - d.pos).rotated(spawn.get_angle())
				if c.type != glib.GCreatureType.PLAYER:
					d.homing__target = Room.v.player.creature
				Game.v.make_projectile(d)
	##

	## Attack finish
	if c.attack_elapsed >= attack_duration:
		if is_player:
			Room.v.player.attack_consumed_stamina = false
		c.attack_blinked = false
		c.attack_dashed = false
		c.attack_elapsed = 0.0
		c.attack_projectiles_spawned = 0
		c.melee_attack = null
		c.controller.move = Vector2(0, 0)
		return true
	##

	return false


func tick(actor: Node, _blackboard: Blackboard) -> int: ##
	var creature: Creature = actor
	var attack: = glib.v.get_creatures()[creature.type].get_attacks()[0]
	if explicit_update_attack(
		get_physics_process_delta_time(),
		creature,
		cooldown,
		attack,
		bf.xz(Room.v.player.creature.transform.origin),
	):
		return SUCCESS
	return RUNNING
##
