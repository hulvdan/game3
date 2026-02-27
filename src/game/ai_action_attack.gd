@tool
extends ActionLeaf

class_name ActionAttack

var cooldown: ActionRandCooldown

var projectiles_spawned: int
var blinked := false


func tick(actor_: Node, _blackboard: Blackboard) -> int:
	var actor: Creature = actor_
	var data = glib.v.get_creatures()[actor.type]

	var attack := data.get_attacks()[0]
	var attack_duration := attack.get_duration()

	## Attack start
	if !actor.attack_elapsed:
		Game.v.enemy_started_attack.emit(actor.transform.origin)
		actor.melee_attack = attack
		actor.melee_attack_id = Room.v.get_next_attack_id()
		actor.melee_damaged_creatures.clear()
		actor.controller.move = Vector2(0, 0)
		cooldown.cooldown_min = attack.get_cooldown_min() + attack_duration
		cooldown.cooldown_min = attack.get_cooldown_max() + attack_duration
	##

	## Tracking target (player)
	if actor.melee_attack and actor.attack_elapsed <= attack.get_melee__stops_tracking_at():
		actor.melee_target_pos = bf.xz(Room.v.player.creature.transform.origin)
		actor.melee_target_dir = bf.vector2_direction_or_random(
			bf.xz(actor.transform.origin),
			actor.melee_target_pos,
		)
	##

	actor.attack_elapsed += get_physics_process_delta_time()

	# Processing tags
	for tag in attack.get_melee__tags():
		match tag.get_meleetag_type():
			glib.GMeleeTagType.DASH: ##
				actor.controller.move = actor.melee_target_dir

				var e: float = min(actor.attack_elapsed, attack.get_duration())
				actor.speed_modifiers.melee_dash = 0

				var start := tag.get_f1()
				var end := tag.get_f2()
				var dur := end - start

				if ((start <= actor.attack_elapsed) && (actor.attack_elapsed <= end)):
					actor.speed_modifiers.melee_dash = bf.get_roll_speed(
						tag.get_f3(),
						dur,
						e - start,
						tag.get_f4(),
					)
			##
			glib.GMeleeTagType.BLINK: ##
				if !blinked:
					var start := tag.get_f1()
					var end := tag.get_f2()
					var dur := end - start
					var e: float = min(actor.attack_elapsed, attack.get_duration())
					if e >= dur / 2:
						blinked = true
						var d := actor.melee_target_pos - bf.xz(actor.transform.origin)
						var l: float = max(0, min(d.length(), tag.get_f3()) - tag.get_f4())
						actor.transform.origin += bf.to_xz(actor.melee_target_dir * l)
						actor.reset_physics_interpolation()
			##

	## Spawning projectiles
	if attack.get_projectile_type():
		var i: int = 0
		for projectile_spawns_at in attack.get_projectiles_spawn_at():
			i += 1
			if projectiles_spawned < i and projectile_spawns_at < actor.attack_elapsed:
				projectiles_spawned += 1
				var d := Projectile.Data.new()
				d.type = attack.get_projectile_type() as glib.GProjectileType
				d.owner = actor
				d.pos = bf.xz(actor.transform.origin)
				d.target = bf.xz(Room.v.player.creature.transform.origin)
				d.homing__target = Room.v.player.creature
				Game.v.make_projectile(d)
	##

	## Attack finish
	if actor.attack_elapsed >= attack_duration:
		blinked = false
		actor.attack_elapsed = 0.0
		projectiles_spawned = 0
		actor.melee_attack = null
		actor.controller.move = Vector2(0, 0)
		actor.speed_modifiers.melee_dash = 1
		return SUCCESS
	##

	return RUNNING
