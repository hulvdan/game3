class_name PlayerController

## Variables
enum StateType {
	NONE,
	DEFAULT,
	ATTACK,
	ROLL,
	BLOCK,
}

var creature: Creature
var bow: Node3D
var inside_enemy_t := 0.0
var rolling_retrievable_cost := 0.0
var stamina := 0.0
var stamina_rally := 0.0
var stamina_ki := 0.0
var attack_queued: bool
var elapsed_since_stamina_consumed := 0.0
var elapsed_since_ki_maxed := 0.0
var dodging := false
var blocking := false
var blocking_perfectly := false
var ki := false
var aim_pos: Vector2
var finished_attack_recently := 0
var _next_combos: Array[glib.GComboNode]
var _actions_state: Array[bool]
var _stamina_depleted_at := 0.0
var _next_block_at: float = 0.0
var _next_roll_at: float = 0.0
var _stamina_regen_modifiers: Dictionary[String, float] = { }
var _current_state := StateType.DEFAULT
var _change_state_to := StateType.NONE
var _change_state_action: Action = null
var _buffer: Array[Action]
var _states: Array[PlayerBase] = [
	null,
	PlayerDefault.new(),
	PlayerAttack.new(),
	PlayerRoll.new(),
	PlayerBlock.new(),
] ##


func init(creature_: Creature, bow_: Node3D) -> void: ##
	assert(!_actions_state)
	for _i in range(glib.GActivationType.COUNT):
		_actions_state.append(false)

	_states[StateType.ROLL].inside_enemies_t_affects_speed = false

	for s: PlayerBase in _states:
		if s:
			s.player = self
	_states[_current_state].on_enter(null)

	creature = creature_
	bow = bow_
	creature.add_child(bow)

	stamina = glib.v.get_player().get_stamina()
	stamina_rally = stamina
	stamina_ki = stamina
	##


func push_action(type: glib.GActivationType, down: bool, dir: Vector2) -> void: ##
	match type:
		glib.GActivationType.SH:
			if down:
				bf.remove_all_by_key(_buffer, Action.is_unblock)
		glib.GActivationType.MOVE:
			bf.remove_all_by_key(_buffer, Action.is_set_move_dir)

	_buffer.append(Action.new(type, down, dir))
	##


func explicit_process(dt: float) -> void: ##
	assert(glib.v.get_controls().get_action_consumption_duration() >= 0)

	var pl := glib.v.get_player()

	creature.speed_modifiers.inside_enemies_t = 1.0
	if _states[_current_state].inside_enemies_t_affects_speed:
		creature.speed_modifiers.inside_enemies_t = lerp(
			1.0,
			pl.get_speed_scale__inside_enemies(),
			inside_enemy_t,
		)

	if _change_state_to:
		if _change_state_to != _current_state:
			_states[_current_state].on_exit()
			_current_state = _change_state_to
			_states[_current_state].on_enter(_change_state_action)
		_change_state_to = StateType.NONE
		_change_state_action = null

	if (
		(_current_state != StateType.ATTACK)
		&& (_states[_current_state].elapsed_frames >= 1)
	):
		_next_combos = glib.v.get_creatures()[glib.GCreatureType.PLAYER].get_combos()

	assert(creature.controller.move != Vector2.INF)
	_states[_current_state].explicit_process(dt)
	assert(creature.controller.move != Vector2.INF)

	var regen_dt := dt
	for v: float in _stamina_regen_modifiers.values():
		regen_dt *= v
	if (
		_stamina_depleted_at
		&& (Room.v.start_elapsed - _stamina_depleted_at < pl.get_stamina_depletion_regen_delay())
	):
		regen_dt = 0
	stamina += regen_dt * pl.get_stamina_regen_per_second()

	if stamina > pl.get_stamina():
		stamina = pl.get_stamina()
	if stamina_rally < stamina:
		stamina_rally = stamina

	elapsed_since_stamina_consumed += dt
	stamina_ki = max(stamina_ki, stamina)
	if elapsed_since_stamina_consumed >= pl.get_block__activation_start():
		stamina_ki += pl.get_ki__rally_increase_per_second() * dt
	if stamina_ki > stamina_rally:
		stamina_ki = stamina_rally
	assert(stamina >= 0)
	assert(stamina_rally <= pl.get_stamina())

	if stamina_ki >= stamina_rally:
		elapsed_since_ki_maxed += dt
	else:
		elapsed_since_ki_maxed = 0

	var decay_after := pl.get_stamina_ki_decay_after()
	if (elapsed_since_stamina_consumed > decay_after) && (elapsed_since_ki_maxed > decay_after):
		var delta := pl.get_stamina_ki_decay_speed() * dt
		stamina_rally = max(stamina, stamina_rally - delta)
		stamina_ki = max(stamina, stamina_ki - delta)

	finished_attack_recently = max(0, finished_attack_recently - 1)
	##


func add_stamina(value: float, rallies_scale: float) -> void: ##
	assert(value > 0)
	stamina = min(stamina + value, glib.v.get_player().get_stamina())
	_stamina_depleted_at = 0.0
	stamina_rally = min(stamina_rally + value * rallies_scale, glib.v.get_player().get_stamina())
	stamina_ki = min(stamina_ki + value * rallies_scale, glib.v.get_player().get_stamina())
	##


func consume_stamina(cost: glib.GStaminaCost) -> void: ##
	assert(stamina > 0)
	assert(stamina_rally >= stamina)
	elapsed_since_stamina_consumed = 0.0

	stamina_rally -= (stamina_rally - stamina) * cost.get_rally_discard_mult_pre()
	stamina -= cost.get_flat()
	stamina = max(0, stamina)
	stamina_rally -= cost.get_rally()
	stamina_rally = max(stamina_rally, stamina)
	stamina_rally -= (stamina_rally - stamina) * cost.get_rally_discard_mult_post()
	if stamina <= 0:
		_stamina_depleted_at = Room.v.start_elapsed
	if stamina_ki > stamina:
		elapsed_since_ki_maxed = 0
	stamina_ki = stamina
	assert(stamina_rally >= 0)
	assert(stamina >= 0)
	assert(stamina_ki >= 0)
	##


func _change_state(to: StateType, action: Action) -> void: ##
	_change_state_to = to
	_change_state_action = action
	##


func _can_start_attack() -> bool: ##
	return stamina > 0
	##


func _get_next_combo_node() -> glib.GComboNode: ##
	if not _next_combos:
		_next_combos = glib.v.get_creatures()[glib.GCreatureType.PLAYER].get_combos()
	if not _next_combos:
		return null

	for combo in _next_combos:
		var found := true

		for x in combo.get_activation_types():
			if not _actions_state[x]:
				found = false
				break

		if found:
			return combo

	return null
	##


func _can_start_roll() -> bool: ##
	if stamina <= 0:
		return false
	return Room.v.start_elapsed >= _next_roll_at
	##


func _can_start_block() -> bool: ##
	return Room.v.start_elapsed >= _next_block_at
	##


class Action: ##
	var type: glib.GActivationType
	var down: bool
	var shoot_or_move_or_roll__dir: Vector2
	var created_at: float


	func _init(type_: glib.GActivationType, down_: bool, dir_: Vector2) -> void:
		self.type = type_
		self.down = down_
		self.shoot_or_move_or_roll__dir = dir_
		self.created_at = Room.v.start_elapsed


	static func is_set_move_dir(x: Action) -> bool:
		return x.type == glib.GActivationType.MOVE


	static func is_unblock(x: Action) -> bool:
		return (x.type == glib.GActivationType.SH) and !x.down

	##


@abstract
class PlayerBase: ##
	var elapsed: float
	var elapsed_frames: int
	var player: PlayerController
	var inside_enemies_t_affects_speed := true

	var _consumed_action_indices: Array[int]


	func on_enter(_a: Action) -> void:
		elapsed = 0
		elapsed_frames = 0


	func on_exit() -> void:
		pass


	@abstract func consume_action(a: Action) -> bool


	func explicit_process(dt: float) -> void:
		elapsed += dt
		elapsed_frames += 1

		# Consuming actions
		var action_consumption_duration := glib.v.get_controls().get_action_consumption_duration()

		var i := -1
		for a: Action in player._buffer:
			i += 1

			if a.down && (a.type in glib.v.get_consumable_activation_types()):
				self.player._actions_state[a.type] = true

			var e := Room.v.start_elapsed - a.created_at
			if e > action_consumption_duration:
				_consumed_action_indices.append(i)
			elif consume_action(a):
				_consumed_action_indices.append(i)

		bf.unstable_remove_indices(player._buffer, _consumed_action_indices)
	##


class PlayerDefault extends PlayerBase: ##
	func consume_action(a: Action) -> bool:
		if a.type == glib.GActivationType.MOVE:
			player.creature.controller.move = a.shoot_or_move_or_roll__dir
			return true

		if a.down:
			if player._can_start_attack() && player._get_next_combo_node():
				player._change_state(StateType.ATTACK, a)
				return true

			if (a.type == glib.GActivationType.SP) && player._can_start_roll():
				player._change_state(StateType.ROLL, a)
				return true

			if (a.type == glib.GActivationType.SH) && player._can_start_block():
				player._change_state(StateType.BLOCK, a)
				return true

		return false
	##


class PlayerAttack extends PlayerBase: ##
	func on_enter(a: Action) -> void:
		super.on_enter(a)

		if a.type == glib.GActivationType.A1:
			player.creature.enqueue_ability(glib.v.get_abilities()[0])
		elif a.type == glib.GActivationType.A2:
			player.creature.enqueue_ability(glib.v.get_abilities()[1])
		else:
			var combo := player._get_next_combo_node()
			assert(combo)
			for x in combo.get_activation_types():
				player._actions_state[x] = false
			player._next_combos = combo.get_children()
			var data := glib.v.get_creatures()[player.creature.type]
			var attack := data.get_attacks()[combo.get_action_index()]
			player.creature.enqueue_attack(attack)

		player.creature.speed_modifiers.attacking = glib.v.get_player().get_speed_scale__shooting()
		player._stamina_regen_modifiers.attacking = glib.v.get_player().get_stamina_regen_scale__shooting()


	func on_exit() -> void:
		super.on_exit()
		player.creature.speed_modifiers.attacking = 1
		player._stamina_regen_modifiers.attacking = 1
		player.finished_attack_recently = 2


	func explicit_process(dt: float) -> void:
		super.explicit_process(dt)

		if ActionAttack.explicit_update_attack(
			dt,
			player.creature,
			null,
			player.aim_pos,
		):
			player._change_state(StateType.DEFAULT, null)


	func consume_action(a: Action) -> bool:
		match a.type:
			glib.GActivationType.SP:
				if a.down && player._can_start_roll():
					player._change_state(StateType.ROLL, a)
					return true
			glib.GActivationType.MOVE:
				player.creature.controller.move = a.shoot_or_move_or_roll__dir
				return true
		return false
	##


class PlayerRoll extends PlayerBase: ##
	func on_enter(a: Action) -> void:
		super.on_enter(a)

		var pl := glib.v.get_player()

		var cost := pl.get_roll_stamina_cost()
		player.consume_stamina(cost)
		player.rolling_retrievable_cost = cost.get_flat()
		player.dodging = false

		player.creature.speed_modifiers.roll = 0

		Game.add_impulse(
			player.creature.impulses,
			player.creature.controller.last_move,
			pl.get_roll_distance(),
			pl.get_roll_duration_seconds(),
			pl.get_roll_pow(),
		)


	func on_exit() -> void:
		super.on_exit()
		player.rolling_retrievable_cost = 0
		player.creature.speed_modifiers.roll = 1
		player.dodging = false
		player._next_roll_at = Room.v.start_elapsed + glib.v.get_player().get_cooldown__roll()


	func explicit_process(dt: float) -> void:
		super.explicit_process(dt)

		var pl := glib.v.get_player()

		player.dodging = (
			(pl.get_roll_invincibility_start() <= elapsed)
			&& (elapsed <= pl.get_roll_invincibility_end())
		)

		var t := (elapsed - pl.get_roll_control_return_starts_at()) / (pl.get_roll_duration_seconds() - pl.get_roll_control_return_starts_at())
		player.creature.speed_modifiers.roll = clamp(t, 0, 1)

		if elapsed >= glib.v.get_player().get_roll_duration_seconds():
			player._change_state(StateType.DEFAULT, null)


	func consume_action(a: Action) -> bool:
		match a.type:
			glib.GActivationType.MOVE:
				player.creature.controller.move = a.shoot_or_move_or_roll__dir
				return true
		return false
	##


class PlayerBlock extends PlayerBase: ##
	var scheduled_exit := false


	func on_enter(a: Action) -> void:
		super.on_enter(a)

		if player.stamina < player.stamina_ki:
			if player.stamina_ki >= player.stamina_rally:
				Game.v.player_perfectly_ki.emit(player.creature.transform.origin)
			else:
				Game.v.player_ki.emit(player.creature.transform.origin)

		player.creature.speed_modifiers.block = glib.v.get_player().get_speed_scale__blocking()
		player.stamina = max(player.stamina, player.stamina_ki)
		player.stamina_rally = player.stamina
		player._stamina_depleted_at = 0.0
		player.blocking = true
		player.blocking_perfectly = true
		player.ki = true


	func on_exit() -> void:
		super.on_exit()
		player.creature.speed_modifiers.block = 1
		player._stamina_regen_modifiers.block = 1
		player.blocking = false
		player.blocking_perfectly = false
		scheduled_exit = false
		player._next_block_at = Room.v.start_elapsed + glib.v.get_player().get_cooldown__block()


	func explicit_process(dt: float) -> void:
		super.explicit_process(dt)

		var player_data := glib.v.get_player()
		if player.creature.blocked:
			player.creature.blocked = false
			elapsed = min(
				elapsed,
				player_data.get_block__min_duration() - player_data.get_block__idle_after_block(),
			)

		if elapsed > glib.v.get_player().get_block__perfect_end():
			player.blocking_perfectly = false

		if elapsed >= glib.v.get_player().get_block__min_duration():
			player.ki = false
			player._stamina_regen_modifiers.block = glib.v.get_player().get_stamina_regen_scale__blocking()
			if scheduled_exit:
				player._change_state(StateType.DEFAULT, null)
		else:
			player.ki = true


	func consume_action(a: Action) -> bool:
		match a.type:
			glib.GActivationType.SH:
				scheduled_exit = !a.down
				return true
			glib.GActivationType.MOVE:
				player.creature.controller.move = a.shoot_or_move_or_roll__dir
				return true
		return false
	##
