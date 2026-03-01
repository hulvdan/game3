class_name PlayerController

## Variables
var creature: Creature
var bow: Node3D
var inside_enemy_t := 0.0
var rolling_retrievable_cost := 0.0

var attack_consumed_stamina: bool

var stamina := 0.0
var stamina_rally := 0.0
var stamina_ki := 0.0
var attack_queued: bool
var elapsed_since_stamina_consumed := 0.0
var dodging := false
var blocking := false
var blocking_perfectly := false
var ki := false
var aim_pos: Vector2

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
]

enum StateType {
	NONE,
	DEFAULT,
	ATTACK,
	ROLL,
	BLOCK,
}

enum ActionType {
	NONE,
	ATTACK,
	ROLL,
	BLOCK,
	UNBLOCK,
	SET_MOVE_DIR,
	ABILITY_1,
	ABILITY_2,
}
##


func init(creature_: Creature, bow_: Node3D) -> void: ##
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


func push_action(type: ActionType, dir: Vector2) -> void: ##
	match type:
		ActionType.BLOCK:
			bf.remove_all_by_key(_buffer, Action.is_unblock)
		ActionType.SET_MOVE_DIR:
			bf.remove_all_by_key(_buffer, Action.is_set_move_dir)

	var x := Action.new()
	x.created_at = Room.v.start_elapsed
	x.type = type
	x.shoot_or_move_or_roll__dir = dir
	_buffer.append(x)
##


func explicit_process(dt: float) -> void: ##
	assert(glib.v.get_controls().get_action_consumption_duration() >= 0)

	creature.speed_modifiers.inside_enemies_t = 1.0
	if _states[_current_state].inside_enemies_t_affects_speed:
		creature.speed_modifiers.inside_enemies_t = lerp(
			1.0,
			glib.v.get_player().get_speed_scale__inside_enemies(),
			inside_enemy_t,
		)

	if _change_state_to:
		if _change_state_to != _current_state:
			_states[_current_state].on_exit()
			_current_state = _change_state_to
			_states[_current_state].on_enter(_change_state_action)
		_change_state_to = StateType.NONE
		_change_state_action = null

	assert(creature.controller.move != Vector2.INF)
	_states[_current_state].explicit_process(dt)
	assert(creature.controller.move != Vector2.INF)

	var regen_dt := dt
	for v: float in _stamina_regen_modifiers.values():
		regen_dt *= v
	if (
		_stamina_depleted_at
		&& (Room.v.start_elapsed - _stamina_depleted_at < glib.v.get_player().get_stamina_depletion_regen_delay())
	):
		regen_dt = 0
	stamina += regen_dt * glib.v.get_player().get_stamina_regen_per_second()

	if stamina > glib.v.get_player().get_stamina():
		stamina = glib.v.get_player().get_stamina()
	if stamina_rally < stamina:
		stamina_rally = stamina

	elapsed_since_stamina_consumed += dt
	stamina_ki = max(stamina_ki, stamina)
	if elapsed_since_stamina_consumed >= glib.v.get_player().get_block__activation_start():
		stamina_ki += glib.v.get_player().get_ki__rally_increase_per_second() * dt
	if stamina_ki > stamina_rally:
		stamina_ki = stamina_rally
	assert(stamina >= 0)
	assert(stamina_rally <= glib.v.get_player().get_stamina())
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
	stamina_ki = stamina
	assert(stamina_rally >= 0)
	assert(stamina >= 0)
	assert(stamina_ki >= 0)
##


func _change_state(to: StateType, action: Action) -> void: ##
	_change_state_to = to
	_change_state_action = action
##


class Action: ##
	var type: ActionType
	var created_at: float
	var shoot_or_move_or_roll__dir: Vector2


	static func is_set_move_dir(x: Action) -> bool:
		return x.type == ActionType.SET_MOVE_DIR


	static func is_unblock(x: Action) -> bool:
		return x.type == ActionType.UNBLOCK
##


@abstract
class PlayerBase: ##
	var elapsed: float
	var player: PlayerController
	var inside_enemies_t_affects_speed := true

	var _consumed_action_indices: Array[int]


	func on_enter(_a: Action) -> void:
		elapsed = 0


	func on_exit() -> void:
		pass


	@abstract func consume_action(a: Action) -> bool


	func explicit_process(dt: float) -> void:
		elapsed += dt

		# Consuming actions
		var action_consumption_duration := glib.v.get_controls().get_action_consumption_duration()
		var i1 := -1
		for a: Action in player._buffer:
			i1 += 1
			var e := Room.v.start_elapsed - a.created_at
			if e > action_consumption_duration:
				_consumed_action_indices.append(i1)
			elif consume_action(a):
				_consumed_action_indices.append(i1)

		bf.unstable_remove_indices(player._buffer, _consumed_action_indices)
##


class PlayerDefault extends PlayerBase: ##
	func consume_action(a: Action) -> bool:
		match a.type:
			ActionType.ATTACK, ActionType.ABILITY_1, ActionType.ABILITY_2:
				if player._can_start_attack():
					match a.type:
						ActionType.ATTACK:
							player.creature.enqueue_attack(glib.v.get_creatures()[player.creature.type].get_attacks()[0])
						ActionType.ABILITY_1:
							player.creature.enqueue_ability(glib.v.get_abilities()[0])
						ActionType.ABILITY_2:
							player.creature.enqueue_ability(glib.v.get_abilities()[1])
						_:
							bf.invalid_path()
					player._change_state(StateType.ATTACK, a)
					return true
			ActionType.ROLL:
				if player._can_start_roll():
					player._change_state(StateType.ROLL, a)
					return true
			ActionType.BLOCK:
				if player._can_start_block():
					player._change_state(StateType.BLOCK, a)
					return true
			ActionType.SET_MOVE_DIR:
				player.creature.controller.move = a.shoot_or_move_or_roll__dir
				return true
		return false

##


class PlayerAttack extends PlayerBase: ##
	func on_enter(a: Action) -> void:
		super.on_enter(a)
		player.creature.speed_modifiers.attacking = glib.v.get_player().get_speed_scale__shooting()
		player._stamina_regen_modifiers.attacking = glib.v.get_player().get_stamina_regen_scale__shooting()


	func on_exit() -> void:
		super.on_exit()
		player.creature.speed_modifiers.attacking = 1
		player._stamina_regen_modifiers.attacking = 1


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
			ActionType.ROLL:
				if player._can_start_roll():
					player._change_state(StateType.ROLL, a)
					return true
			ActionType.SET_MOVE_DIR:
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
			ActionType.SET_MOVE_DIR:
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
			ActionType.BLOCK:
				scheduled_exit = false
				return true
			ActionType.UNBLOCK:
				scheduled_exit = true
				return true
			ActionType.SET_MOVE_DIR:
				player.creature.controller.move = a.shoot_or_move_or_roll__dir
				return true
		return false
##


func _can_start_attack() -> bool: ##
	return stamina > 0
##


func _can_start_roll() -> bool: ##
	if stamina <= 0:
		return false
	return Room.v.start_elapsed >= _next_roll_at
##


func _can_start_block() -> bool: ##
	return Room.v.start_elapsed >= _next_block_at
##
