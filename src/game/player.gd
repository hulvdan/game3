class_name Player

## Variables
var creature: Creature
var bow: Node3D
var inside_enemy_t := 0.0
var shoot_after_roll := false
var rolling_retrievable_cost := 0.0
var roll_direction: Vector2
var stamina := 0.0
var stamina_rally := 0.0
var stamina_ki := 0.0
var attack_queued: bool
var elapsed_since_stamina_consumed := 0.0
var shooting := false

var current_state := PlayerStateType.DEFAULT
var buffer: Array[PlayerAction]

var _states: Array[PlayerBase] = [
	PlayerDefault.new(),
	PlayerShoot.new(),
	PlayerRoll.new(),
	PlayerBlock.new(),
]
##


func init(creature_: Creature, bow_: Node3D) -> void: ##
	for s: PlayerBase in _states:
		s.player = self
	_states[current_state].on_enter(null)

	creature = creature_
	bow = bow_
	creature.add_child(bow)

	stamina = glib.v.get_player_stamina()
	stamina_rally = stamina
	stamina_ki = stamina
##


func push_action(type: PlayerActionType, dir: Vector2) -> void: ##
	var a := PlayerAction.new()
	a.created_at = Room.v.start_elapsed
	a.type = type
	a.shoot_or_move_or_roll__dir = dir
	buffer.append(a)
##


func explicit_process(dt: float) -> void: ##
	shooting = Input.get_action_strength("shoot") >= 0.5
	if Input.get_action_strength("roll") >= 0.5:
		push_action(PlayerActionType.ROLL, Vector2.INF)
	creature.speed_modifiers.inside_enemies_t = lerp(
		1.0,
		glib.v.get_player_speed_inside_enemies_scale(),
		inside_enemy_t,
	)
	_states[current_state].explicit_process(dt)
##


func change_state(to: PlayerStateType, action: PlayerAction) -> void: ##
	assert(to != current_state)
	_states[current_state].on_exit()
	current_state = to
	_states[current_state].on_enter(action)
##


func add_stamina(value: float) -> void: ##
	assert(value > 0)
	stamina += value
	if stamina > glib.v.get_player_stamina():
		stamina = glib.v.get_player_stamina()
##


func consume_stamina(value: float, drop_rally: bool) -> void: ##
	assert(value > 0)
	elapsed_since_stamina_consumed = 0.0
	stamina -= value
	if stamina < 0:
		stamina = 0
	stamina_ki = stamina
	if stamina < 0:
		stamina = 0
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

enum PlayerStateType { DEFAULT, SHOOT, ROLL, BLOCK }
enum PlayerActionType { NONE, SHOOT, ROLL, BLOCK, SET_MOVE_DIR }


class PlayerAction: ##
	var type: PlayerActionType
	var created_at: float
	var shoot_or_move_or_roll__dir: Vector2
##


@abstract
class PlayerBase: ##
	var elapsed: float
	var action: PlayerAction
	var buffer: Array[PlayerAction]
	var player: Player

	var _consumed_action_indices: Array[int]


	@abstract func on_enter(a: PlayerAction) -> void


	@abstract func on_exit() -> void


	@abstract func explicit_process(dt: float) -> void


	@abstract func consume_action(a: PlayerAction) -> bool


	func base_on_enter(_action: PlayerAction) -> void:
		elapsed = 0


	func base_on_exit() -> void:
		pass


	func base_process(dt: float) -> void:
		elapsed += dt

		# Consuming actions
		var action_consumption_duration: float = glib.v.get_action_consumption_duration()
		var i1 := -1
		for a: PlayerAction in buffer:
			i1 += 1
			var e := Room.v.start_elapsed - a.created_at
			if e > action_consumption_duration:
				_consumed_action_indices.append(i1)
			elif consume_action(a):
				_consumed_action_indices.append(i1)
		for i2 in range(len(_consumed_action_indices)):
			var v := _consumed_action_indices[len(_consumed_action_indices) - i2 - 1]
			buffer.remove_at(v)
		_consumed_action_indices.clear()
##


class PlayerDefault extends PlayerBase: ##
	func on_enter(a: PlayerAction) -> void:
		base_on_enter(a)


	func on_exit() -> void:
		base_on_exit()


	func explicit_process(dt: float) -> void:
		base_process(dt)
		if !buffer:
			return


	func consume_action(a: PlayerAction) -> bool:
		var consumed := true
		match a.type:
			PlayerActionType.SHOOT:
				player.change_state(PlayerStateType.SHOOT, a)
			PlayerActionType.ROLL:
				player.change_state(PlayerStateType.ROLL, a)
			PlayerActionType.BLOCK:
				player.change_state(PlayerStateType.BLOCK, a)
			PlayerActionType.SET_MOVE_DIR:
				player.creature.controller.move = a.shoot_or_move_or_roll__dir
			_:
				consumed = false
		return consumed
##


class PlayerShoot extends PlayerBase: ##
	func on_enter(a: PlayerAction) -> void:
		base_on_enter(a)


	func on_exit() -> void:
		base_on_exit()


	func explicit_process(dt: float) -> void:
		base_process(dt)

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
			player.change_state(PlayerStateType.DEFAULT, null)


	func consume_action(a: PlayerAction) -> bool:
		var consumed := true
		match a.type:
			PlayerActionType.ROLL:
				player.change_state(PlayerStateType.ROLL, a)
			PlayerActionType.BLOCK:
				player.change_state(PlayerStateType.BLOCK, a)
			PlayerActionType.SET_MOVE_DIR:
				player.creature.controller.move = a.shoot_or_move_or_roll__dir
			_:
				consumed = false
		return consumed
##


class PlayerRoll extends PlayerBase: ##
	func on_enter(a: PlayerAction) -> void:
		base_on_enter(a)
		player.creature.controller.move = a.shoot_or_move_or_roll__dir


	func on_exit() -> void:
		base_on_exit()
		player.creature.speed_modifiers.roll = 1


	func explicit_process(dt: float) -> void:
		buffer.clear()
		base_process(dt)
		player.creature.speed_modifiers.roll = bf.get_roll_speed(
			glib.v.get_player_roll_distance(),
			glib.v.get_player_roll_duration_seconds(),
			elapsed,
			glib.v.get_player_roll_pow(),
		)
		if elapsed >= glib.v.get_player_roll_duration_seconds():
			player.change_state(PlayerStateType.DEFAULT, null)

		if elapsed >= glib.v.get_player_roll_duration_seconds():
			player.rolling_retrievable_cost = 0
			player.creature.evaded_attack_ids.clear()
		elif (
			(player.stamina >= glib.v.get_player_stamina_roll_cost())
			&& (Input.get_action_strength("roll") >= 0.5)
			&& (player.creature.controller.last_move != Vector2(0, 0))
		):
			player.roll_direction = player.creature.controller.last_move
			player.consume_stamina(glib.v.get_player_stamina_roll_cost(), true)
			player.rolling_retrievable_cost = glib.v.get_player_stamina_roll_cost()


	func consume_action(a: PlayerAction) -> bool:
		var consumed := true
		match a.type:
			PlayerActionType.SHOOT:
				player.shoot_after_roll = true
			_:
				consumed = false
		return consumed
##


class PlayerBlock extends PlayerBase: ##
	func on_enter(a: PlayerAction) -> void:
		base_on_enter(a)
		player.creature.speed_modifiers.block = 0


	func on_exit() -> void:
		base_on_exit()
		player.creature.speed_modifiers.block = 1


	func explicit_process(dt: float) -> void:
		buffer.clear()
		base_process(dt)
		player.stamina = max(player.stamina, player.stamina_ki)
		player.stamina_rally = max(player.stamina_rally, player.stamina)
		if elapsed >= glib.v.get_player_ki_state_min_duration():
			player.change_state(PlayerStateType.DEFAULT, null)


	func consume_action(a: PlayerAction) -> bool:
		var consumed := true
		match a.type:
			_:
				consumed = false
		return consumed
##
