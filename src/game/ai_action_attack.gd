@tool
class_name ActionAttack
extends ActionLeaf

var cooldown: ActionRandCooldown


static func explicit_update_attack(
		dt: float,
		c: Creature,
		action_cooldown: ActionRandCooldown,
		tracking_pos: Vector2,
) -> bool:
	var is_player := c.type == glib.GCreatureType.PLAYER

	## Attack start
	if !c.attack_elapsed_frames:
		if c.change_attack_to:
			c.current_attack = c.change_attack_to
		elif c.change_ability_to:
			c.current_attack = c.change_ability_to.get_attacks()[0]
		else:
			bf.invalid_path()

		c.attack_id = Room.v.get_next_attack_id()
		c.attack_damaged_creatures.clear()
		c.attack_damaged_interactables.clear()

		if c.type != glib.GCreatureType.PLAYER:
			Game.v.enemy_started_attack.emit(c.transform.origin)
			if action_cooldown:
				action_cooldown.cooldown_min = c.current_attack.get_cooldown_min()
				action_cooldown.cooldown_min = c.current_attack.get_cooldown_max()
	##

	var attack := c.current_attack

	## Tracking target
	var tracking := false
	for k in attack.get_tracking():
		if k.get_index_timeline() > c.attack_elapsed_frames:
			break
		tracking = k.get_value()
	if tracking:
		c.attack_target_pos = tracking_pos
		c.attack_target_dir = bf.vector2_direction_or_random(
			bf.xz(c.transform.origin),
			c.attack_target_pos,
		)
	##

	## Player consuming stamina
	if is_player:
		if c.attack_elapsed_frames == attack.get_stamina_consumption_frame():
			Room.v.player.consume_stamina(attack.get_stamina_cost())
	##

	## Applying impulses
	for impulse in attack.get_impulses():
		if impulse.get_at() == c.attack_elapsed_frames:
			var impulse_dir := c.looking_dir
			if impulse.get_rotation():
				impulse_dir = impulse_dir.rotated(deg_to_rad(impulse.get_rotation()))
			Game.add_impulse(
				c.impulses,
				impulse_dir,
				impulse.get_distance(),
				float(impulse.get_dur()) / glib.ATTACKS_FPS,
				impulse.get_pow(),
			)
	##

	c.attack_elapsed += dt
	c.attack_elapsed_frames += 1

	# Processing tags
	for tag in attack.get_tags():
		match tag.get_tag_type():
			glib.GTagType.DASH_LIMITED: ##
				if c.attack_dashed:
					continue
				var start := tag.get_f1()
				if start > c.attack_elapsed:
					continue
				c.attack_dashed = true
				var d := c.looking_dir - bf.xz(c.transform.origin)
				var dist: float = max(0, min(d.length(), tag.get_f3()) - tag.get_f4())
				var pow_ := tag.get_f5()
				var end := tag.get_f2()
				var dir := c.looking_dir
				var dir_rotation := tag.get_f5()
				if dir_rotation:
					dir = dir.rotated(dir_rotation)
				Game.add_impulse(c.impulses, dir, dist, end - start, pow_)
			##
			glib.GTagType.DASH: ##
				if c.attack_dashed:
					continue
				var start := tag.get_f1()
				if start > c.attack_elapsed:
					continue
				c.attack_dashed = true
				var dist := tag.get_f3()
				var pow_ := tag.get_f4()
				var end := tag.get_f2()
				var dir := c.looking_dir
				var dir_rotation := tag.get_f5()
				if dir_rotation:
					dir = dir.rotated(dir_rotation)
				Game.add_impulse(c.impulses, dir, dist, end - start, pow_)
			##
			glib.GTagType.BLINK: ##
				if c.attack_blinked:
					continue
				var dur := tag.get_f2() - tag.get_f1()
				if c.attack_elapsed < dur / 2:
					continue
				c.attack_blinked = true
				var d := c.attack_target_pos - bf.xz(c.transform.origin)
				var l: float = max(0, min(d.length(), tag.get_f3()) - tag.get_f4())
				c.transform.origin += bf.to_xz(c.attack_target_dir * l)
				c.reset_physics_interpolation()
			##

	## Spawning projectiles
	if attack.get_projectile_type():
		for spawn in attack.get_projectile_spawns():
			if spawn.get_at() == c.attack_elapsed_frames:
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
	if c.attack_elapsed_frames >= c.current_attack.get_duration_frames():
		c.attack_blinked = false
		c.attack_dashed = false
		c.attack_elapsed = 0.0
		c.attack_elapsed_frames = 0
		c.attack_id = 0
		c.attack_damaged_creatures.clear()
		c.attack_damaged_interactables.clear()
		c.attack_target_pos = Vector2(0, 0)
		c.attack_target_dir = Vector2(0, 0)
		return true
	##

	return false


func tick(actor: Node, _blackboard: Blackboard) -> int: ##
	var c: Creature = actor

	var player_pos := bf.xz(Room.v.player.creature.transform.origin)
	var pos := bf.xz(c.transform.origin)
	var l: float = max(0.0, (player_pos - pos).length() - glib.v.get_mob_arc_throw_distance_delta())
	if explicit_update_attack(
		get_physics_process_delta_time(),
		c,
		cooldown,
		pos + bf.vector2_direction_or_random(pos, player_pos) * l,
	):
		return SUCCESS
	return RUNNING
	##
