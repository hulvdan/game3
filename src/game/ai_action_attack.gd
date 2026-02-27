@tool
extends ActionLeaf

class_name ActionAttack

var cooldown: ActionRandCooldown


static func explicit_update_attack(dt: float, c: Creature, action_cooldown: ActionRandCooldown) -> bool: ##
	c.attack_elapsed += dt
	var data = glib.v.get_creatures()[c.type]

	var attack := data.get_attacks()[0]
	var attack_duration := attack.get_duration()

	## Attack start
	if !c.attack_elapsed:
		c.melee_attack = attack
		c.melee_attack_id = Room.v.get_next_attack_id()
		c.melee_damaged_creatures.clear()
		c.controller.move = Vector2(0, 0)
		if c.type != glib.GCreatureType.PLAYER:
			Game.v.enemy_started_attack.emit(c.transform.origin)
			if action_cooldown:
				action_cooldown.cooldown_min = attack.get_cooldown_min() + attack_duration
				action_cooldown.cooldown_min = attack.get_cooldown_max() + attack_duration
	##

	## Tracking target (player)
	if c.melee_attack and c.attack_elapsed <= attack.get_melee__stops_tracking_at():
		c.attack_target_pos = bf.xz(Room.v.player.creature.transform.origin)
		c.attack_target_dir = bf.vector2_direction_or_random(
			bf.xz(c.transform.origin),
			c.attack_target_pos,
		)
	##

	# Processing tags
	for tag in attack.get_melee__tags():
		match tag.get_meleetag_type():
			glib.GMeleeTagType.DASH: ##
				c.controller.move = c.attack_target_dir

				var e: float = min(c.attack_elapsed, attack.get_duration())
				c.speed_modifiers.melee_dash = 0

				var start := tag.get_f1()
				var end := tag.get_f2()
				var dur := end - start

				if (start <= c.attack_elapsed) && (c.attack_elapsed <= end):
					c.speed_modifiers.melee_dash = bf.get_roll_speed(
						tag.get_f3(),
						dur,
						e - start,
						tag.get_f4(),
					)
			##
			glib.GMeleeTagType.BLINK: ##
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
		for projectile_spawns_at in attack.get_projectiles_spawn_at():
			i += 1
			if c.attack_projectiles_spawned < i and projectile_spawns_at < c.attack_elapsed:
				c.attack_projectiles_spawned += 1
				var d := Projectile.Data.new()
				d.type = attack.get_projectile_type() as glib.GProjectileType
				d.owner = c
				d.pos = bf.xz(c.transform.origin)
				d.target = c.attack_target_pos
				if c.type != glib.GCreatureType.PLAYER:
					d.homing__target = Room.v.player.creature
				Game.v.make_projectile(d)
	##

	## Attack finish
	if c.attack_elapsed >= attack_duration:
		c.attack_blinked = false
		c.attack_elapsed = 0.0
		c.attack_projectiles_spawned = 0
		c.melee_attack = null
		c.controller.move = Vector2(0, 0)
		c.speed_modifiers.melee_dash = 1
		return true
	##

	return false
##


func tick(actor: Node, _blackboard: Blackboard) -> int: ##
	var creature: Creature = actor
	if explicit_update_attack(get_physics_process_delta_time(), creature, cooldown):
		return SUCCESS
	return RUNNING
##
