class_name PlayerController

## Variables
var creature: Creature
var bow: Node3D
var inside_enemy_t := 0.0
var shoot_after_roll := false
var rolling_retrievable_cost := 0.0
var stamina := 0.0
var stamina_rally := 0.0
var stamina_ki := 0.0
var attack_queued: bool
var elapsed_since_stamina_consumed := 0.0
var dodging := false
var blocking := false
var blocking_perfectly := false
var ki := false
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
	PlayerShoot.new(),
	PlayerRoll.new(),
	PlayerBlock.new(),
]

enum StateType { NONE, DEFAULT, SHOOT, ROLL, BLOCK }
enum ActionType { NONE, SHOOT, ROLL, BLOCK, UNBLOCK, SET_MOVE_DIR }
##


func init(creature_: Creature, bow_: Node3D) -> void: ##
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
	var a := Action.new()
	a.created_at = Room.v.start_elapsed
	a.type = type
	a.shoot_or_move_or_roll__dir = dir
	_buffer.append(a)
##


func explicit_process(dt: float) -> void: ##
	assert(glib.v.get_controls().get_action_consumption_duration() >= 0)
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


func consume_stamina(value: float, rally_lerp_t: float) -> void: ##
	assert(value > 0)
	assert(stamina > 0)
	elapsed_since_stamina_consumed = 0.0
	stamina = max(0, stamina - value)
	if stamina <= 0:
		_stamina_depleted_at = Room.v.start_elapsed
	stamina_ki = stamina
	if stamina_rally > stamina:
		stamina_rally = lerp(stamina, stamina_rally, rally_lerp_t)
##


func _change_state(to: StateType, action: Action) -> void: ##
	_change_state_to = to
	_change_state_action = action
##


class Action: ##
	var type: ActionType
	var created_at: float
	var shoot_or_move_or_roll__dir: Vector2
##


@abstract
class PlayerBase: ##
	var elapsed: float
	var player: PlayerController

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
		for i2 in range(len(_consumed_action_indices)):
			var v := _consumed_action_indices[len(_consumed_action_indices) - i2 - 1]
			player._buffer.remove_at(v)
		_consumed_action_indices.clear()
##


class PlayerDefault extends PlayerBase: ##
	func consume_action(a: Action) -> bool:
		match a.type:
			ActionType.SHOOT:
				if player._can_start_shoot():
					player._change_state(StateType.SHOOT, a)
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


	func explicit_process(dt: float) -> void:
		super.explicit_process(dt)
		if player.shoot_after_roll:
			if player._can_start_shoot():
				player._change_state(StateType.SHOOT, null)
			else:
				player.shoot_after_roll = false
##


class PlayerShoot extends PlayerBase: ##
	func on_enter(a: Action) -> void:
		super.on_enter(a)
		player.creature.speed_modifiers.shooting = glib.v.get_player().get_speed_scale__shooting()
		player._stamina_regen_modifiers.shooting = glib.v.get_player().get_stamina_regen_scale__shooting()


	func on_exit() -> void:
		super.on_exit()
		player.creature.speed_modifiers.shooting = 1
		player._stamina_regen_modifiers.shooting = 1


	func explicit_process(dt: float) -> void:
		super.explicit_process(dt)

		var dur := glib.v.get_player().get_shooting_seconds()
		if player.shoot_after_roll:
			dur = glib.v.get_player().get_shooting_after_roll_seconds()

		if elapsed >= dur:
			player.consume_stamina(
				glib.v.get_player().get_stamina_attack_cost(),
				glib.v.get_player().get_stamina_attack_rally_scale(),
			)
			var d := Projectile.Data.new()
			d.type = glib.GProjectileType.ARROW
			d.owner = glib.GCreatureType.PLAYER
			d.pos = bf.xz(player.creature.transform.origin)
			d.target = d.pos - bf.xz(player.bow.transform.basis.z)
			Game.v.make_projectile(d)
			player.shoot_after_roll = false
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
		player.consume_stamina(
			glib.v.get_player().get_stamina_roll_cost(),
			glib.v.get_player().get_stamina_roll_rally_scale(),
		)
		player.rolling_retrievable_cost = glib.v.get_player().get_stamina_roll_cost()
		player.dodging = false


	func on_exit() -> void:
		super.on_exit()
		player.rolling_retrievable_cost = 0
		player.creature.speed_modifiers.base = glib.v.get_creatures()[glib.GCreatureType.PLAYER].get_speed()
		player.dodging = false
		player._next_roll_at = Room.v.start_elapsed + glib.v.get_player().get_cooldown__roll()


	func explicit_process(dt: float) -> void:
		super.explicit_process(dt)

		player.dodging = (
			(glib.v.get_player().get_roll_invincibility_start() <= elapsed)
			&& (elapsed <= glib.v.get_player().get_roll_invincibility_end())
		)

		player.creature.controller.move = player.creature.controller.last_move
		player.creature.speed_modifiers.base = bf.get_roll_speed(
			glib.v.get_player().get_roll_distance(),
			glib.v.get_player().get_roll_duration_seconds(),
			elapsed,
			glib.v.get_player().get_roll_pow(),
		)

		if elapsed >= glib.v.get_player().get_roll_duration_seconds():
			player._change_state(StateType.DEFAULT, null)


	func consume_action(a: Action) -> bool:
		match a.type:
			ActionType.SHOOT:
				if player._can_start_shoot():
					player.shoot_after_roll = true
					return true
		return false
##


class PlayerBlock extends PlayerBase: ##
	var scheduled_exit := false


	func on_enter(a: Action) -> void:
		super.on_enter(a)
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


func _can_start_shoot() -> bool: ##
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
