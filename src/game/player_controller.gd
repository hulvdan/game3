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
var stamina_depleted_at := 0.0

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
##


func init(creature_: Creature, bow_: Node3D) -> void: ##
	for s: PlayerBase in _states:
		if s:
			s.player = self
	_states[_current_state].on_enter(null)

	creature = creature_
	bow = bow_
	creature.add_child(bow)

	stamina = glib.v.get_player_stamina()
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
	assert(glib.v.get_action_consumption_duration() >= 0)
	creature.speed_modifiers.inside_enemies_t = lerp(
		1.0,
		glib.v.get_player_speed_inside_enemies_scale(),
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
		stamina_depleted_at
		&& (Room.v.start_elapsed - stamina_depleted_at < glib.v.get_player_stamina_depletion_regen_delay())
	):
		regen_dt = 0
	stamina += regen_dt * glib.v.get_player_stamina_regen_per_second()

	if stamina > glib.v.get_player_stamina():
		stamina = glib.v.get_player_stamina()
	if stamina_rally < stamina:
		stamina_rally = stamina

	elapsed_since_stamina_consumed += dt
	stamina_ki = max(stamina_ki, stamina)
	if elapsed_since_stamina_consumed >= glib.v.get_player_ki_min_delay():
		stamina_ki += glib.v.get_player_ki_increase_per_second() * dt
	if stamina_ki > stamina_rally:
		stamina_ki = stamina_rally
	assert(stamina >= 0)
	assert(stamina_rally <= glib.v.get_player_stamina())
##


func add_stamina(value: float) -> void: ##
	assert(value > 0)
	stamina = min(stamina + value, glib.v.get_player_stamina())
##


func consume_stamina(value: float, drop_rally: bool) -> void: ##
	assert(value > 0)
	assert(stamina > 0)
	elapsed_since_stamina_consumed = 0.0
	stamina = max(0, stamina - value)
	if stamina <= 0:
		stamina_depleted_at = Room.v.start_elapsed
	stamina_ki = stamina
	if drop_rally:
		stamina_rally = stamina
	if stamina_rally > stamina:
		stamina_rally = lerp(
			stamina,
			stamina_rally,
			glib.v.get_player_stamina_attack_rally_scale(),
		)
##


func _change_state(to: StateType, action: Action) -> void: ##
	_change_state_to = to
	_change_state_action = action
##

enum StateType { NONE, DEFAULT, SHOOT, ROLL, BLOCK }
enum ActionType { NONE, SHOOT, ROLL, BLOCK, UNBLOCK, SET_MOVE_DIR }


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
		var action_consumption_duration: float = glib.v.get_action_consumption_duration()
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
		var consumed := true
		match a.type:
			ActionType.SHOOT:
				if player._can_start_shoot():
					player._change_state(StateType.SHOOT, a)
				else:
					consumed = false
			ActionType.ROLL:
				if player._can_start_roll():
					player._change_state(StateType.ROLL, a)
				else:
					consumed = false
			ActionType.BLOCK:
				player._change_state(StateType.BLOCK, a)
			ActionType.SET_MOVE_DIR:
				player.creature.controller.move = a.shoot_or_move_or_roll__dir
			_:
				consumed = false
		return consumed
##


class PlayerShoot extends PlayerBase: ##
	func on_enter(a: Action) -> void:
		super.on_enter(a)
		player.creature.speed_modifiers.shooting = glib.v.get_player_speed_shooting_scale()
		player._stamina_regen_modifiers.shooting = glib.v.get_player_shooting_stamina_regen_scale()


	func on_exit() -> void:
		super.on_exit()
		player.creature.speed_modifiers.shooting = 1
		player._stamina_regen_modifiers.shooting = 1


	func explicit_process(dt: float) -> void:
		super.explicit_process(dt)

		var dur := glib.v.get_shooting_seconds()
		if player.shoot_after_roll:
			dur = glib.v.get_shooting_after_roll_seconds()

		if elapsed >= dur:
			player.consume_stamina(glib.v.get_player_stamina_attack_cost(), false)
			var d := Projectile.Data.new()
			d.type = glib.GProjectileType.ARROW
			d.owner = glib.GCreatureType.PLAYER
			d.pos = bf.from_xz(player.creature.transform.origin)
			d.target = d.pos - bf.from_xz(player.bow.transform.basis.z)
			Game.v.make_projectile(d)
			player.shoot_after_roll = false
			player._change_state(StateType.DEFAULT, null)


	func consume_action(a: Action) -> bool:
		var consumed := true
		match a.type:
			ActionType.ROLL:
				if player._can_start_roll():
					player._change_state(StateType.ROLL, a)
				else:
					consumed = false
			ActionType.SET_MOVE_DIR:
				player.creature.controller.move = a.shoot_or_move_or_roll__dir
			_:
				consumed = false
		return consumed
##


class PlayerRoll extends PlayerBase: ##
	func on_enter(a: Action) -> void:
		super.on_enter(a)
		player.consume_stamina(glib.v.get_player_stamina_roll_cost(), true)
		player.rolling_retrievable_cost = glib.v.get_player_stamina_roll_cost()
		player.dodging = false


	func on_exit() -> void:
		super.on_exit()
		player.creature.evaded_attack_ids.clear()
		player.rolling_retrievable_cost = 0
		player.creature.speed_modifiers.base = glib.v.get_creatures()[glib.GCreatureType.PLAYER].get_speed()
		player.dodging = false


	func explicit_process(dt: float) -> void:
		super.explicit_process(dt)

		player.dodging = (
			(glib.v.get_player_roll_invincibility_start() <= elapsed)
			&& (elapsed <= glib.v.get_player_roll_invincibility_end())
		)

		player.creature.controller.move = player.creature.controller.last_move
		player.creature.speed_modifiers.base = bf.get_roll_speed(
			glib.v.get_player_roll_distance(),
			glib.v.get_player_roll_duration_seconds(),
			elapsed,
			glib.v.get_player_roll_pow(),
		)

		if elapsed >= glib.v.get_player_roll_duration_seconds():
			player._change_state(StateType.DEFAULT, null)


	func consume_action(a: Action) -> bool:
		var consumed := true
		match a.type:
			ActionType.SHOOT:
				player.shoot_after_roll = true
			_:
				consumed = false
		return consumed
##


class PlayerBlock extends PlayerBase: ##
	var scheduled_exit := false


	func on_enter(a: Action) -> void:
		super.on_enter(a)
		player.creature.speed_modifiers.block = glib.v.get_player_speed_blocking_scale()
		player.stamina = max(player.stamina, player.stamina_ki)
		player.stamina_rally = player.stamina
		player.stamina_depleted_at = 0.0
		player.blocking = true
		player.blocking_perfectly = true


	func on_exit() -> void:
		super.on_exit()
		player.creature.speed_modifiers.block = 1
		player.blocking = false
		player.blocking_perfectly = false
		scheduled_exit = false


	func explicit_process(dt: float) -> void:
		super.explicit_process(dt)
		player.blocking_perfectly = (elapsed <= glib.v.get_player_perfect_block_window())
		if scheduled_exit && (elapsed >= glib.v.get_player_ki_state_min_duration()):
			player._change_state(StateType.DEFAULT, null)


	func consume_action(a: Action) -> bool:
		var consumed := true
		match a.type:
			ActionType.UNBLOCK:
				scheduled_exit = true
			ActionType.SET_MOVE_DIR:
				player.creature.controller.move = a.shoot_or_move_or_roll__dir
			_:
				consumed = false
		return consumed
##


func _can_start_shoot() -> bool:
	return stamina > 0


func _can_start_roll() -> bool:
	return stamina > 0
