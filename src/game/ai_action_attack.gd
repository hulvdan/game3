@tool
extends ActionLeaf

class_name ActionAttack

var cooldown: ActionRandCooldown


static func explicit_update_attack(dt: float, creature: Creature, action_cooldown: ActionRandCooldown) -> bool: ##
	creature.attack_elapsed += dt
	var data = glib.v.get_creatures()[creature.type]

	var attack := data.get_attacks()[0]
	var attack_duration := attack.get_duration()

	## Attack start
	if !creature.attack_elapsed:
		creature.melee_attack = attack
		creature.melee_attack_id = Room.v.get_next_attack_id()
		creature.melee_damaged_creatures.clear()
		creature.controller.move = Vector2(0, 0)
		if creature.type != glib.GCreatureType.PLAYER:
			Game.v.enemy_started_attack.emit(creature.transform.origin)
			if action_cooldown:
				action_cooldown.cooldown_min = attack.get_cooldown_min() + attack_duration
				action_cooldown.cooldown_min = attack.get_cooldown_max() + attack_duration
	##

	## Tracking target (player)
	if creature.melee_attack and creature.attack_elapsed <= attack.get_melee__stops_tracking_at():
		creature.melee_target_pos = bf.xz(Room.v.player.creature.transform.origin)
		creature.melee_target_dir = bf.vector2_direction_or_random(
			bf.xz(creature.transform.origin),
			creature.melee_target_pos,
		)
	##

	# Processing tags
	for tag in attack.get_melee__tags():
		match tag.get_meleetag_type():
			glib.GMeleeTagType.DASH: ##
				creature.controller.move = creature.melee_target_dir

				var e: float = min(creature.attack_elapsed, attack.get_duration())
				creature.speed_modifiers.melee_dash = 0

				var start := tag.get_f1()
				var end := tag.get_f2()
				var dur := end - start

				if (start <= creature.attack_elapsed) && (creature.attack_elapsed <= end):
					creature.speed_modifiers.melee_dash = bf.get_roll_speed(
						tag.get_f3(),
						dur,
						e - start,
						tag.get_f4(),
					)
			##
			glib.GMeleeTagType.BLINK: ##
				if !creature.attack_blinked:
					var dur := tag.get_f2() - tag.get_f1()
					if creature.attack_elapsed >= dur / 2:
						creature.attack_blinked = true
						var d := creature.melee_target_pos - bf.xz(creature.transform.origin)
						var l: float = max(0, min(d.length(), tag.get_f3()) - tag.get_f4())
						creature.transform.origin += bf.to_xz(creature.melee_target_dir * l)
						creature.reset_physics_interpolation()
			##

	## Spawning projectiles
	if attack.get_projectile_type():
		var i: int = 0
		for projectile_spawns_at in attack.get_projectiles_spawn_at():
			i += 1
			if creature.attack_projectiles_spawned < i and projectile_spawns_at < creature.attack_elapsed:
				creature.attack_projectiles_spawned += 1
				var d := Projectile.Data.new()
				d.type = attack.get_projectile_type() as glib.GProjectileType
				d.owner = creature
				d.pos = bf.xz(creature.transform.origin)
				d.target = bf.xz(Room.v.player.creature.transform.origin)
				d.homing__target = Room.v.player.creature
				Game.v.make_projectile(d)
	##

	## Attack finish
	if creature.attack_elapsed >= attack_duration:
		creature.attack_blinked = false
		creature.attack_elapsed = 0.0
		creature.attack_projectiles_spawned = 0
		creature.melee_attack = null
		creature.controller.move = Vector2(0, 0)
		creature.speed_modifiers.melee_dash = 1
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
