class_name Player

## Variables
var creature: Creature
var bow: Node3D
var inside_enemy_t := 0.0
var holding := 0.0
var shooting_after_roll_scheduled := false
var rolling_retrievable_cost := 0.0
var roll_direction: Vector2
var stamina := 0.0
var stamina_rally := 0.0
var stamina_ki := 0.0
var attack_queued: bool
var elapsed_since_stamina_consumed := 0.0

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


func explicit_process(dt: float) -> void: ##
	creature.speed_modifiers.inside_enemies_t = lerp(1.0, glib.v.get_player_speed_inside_enemies_scale(), inside_enemy_t)
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
	var shoot_or_move_or_roll__dir: Vector2
##


@abstract
class PlayerBase: ##
	var elapsed: float
	var action: PlayerAction
	var buffer: Array[PlayerAction]
	var player: Player


	@abstract func on_enter(a: PlayerAction) -> void


	@abstract func on_exit() -> void


	@abstract func explicit_process(dt: float) -> void


	func base_on_enter(_action: PlayerAction) -> void:
		elapsed = 0


	func base_on_exit() -> void:
		pass


	func base_process(dt: float) -> void:
		elapsed += dt
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
		var a := buffer[0]
		match a.type:
			PlayerActionType.SHOOT:
				player.change_state(PlayerStateType.SHOOT, a)
			PlayerActionType.ROLL:
				player.change_state(PlayerStateType.ROLL, a)
			PlayerActionType.BLOCK:
				player.change_state(PlayerStateType.BLOCK, a)
			PlayerActionType.SET_MOVE_DIR:
				player.creature.controller.move = a.shoot_or_move_or_roll__dir
##


class PlayerShoot extends PlayerBase: ##
	func on_enter(a: PlayerAction) -> void:
		base_on_enter(a)


	func on_exit() -> void:
		base_on_exit()


	func explicit_process(dt: float) -> void:
		base_process(dt)
		if elapsed >= glib.v.get_shooting_seconds():
			player.change_state(PlayerStateType.DEFAULT, null)
		if buffer:
			var a := buffer[0]
			match a.type:
				PlayerActionType.ROLL:
					player.change_state(PlayerStateType.ROLL, a)
				PlayerActionType.BLOCK:
					player.change_state(PlayerStateType.BLOCK, a)
				PlayerActionType.SET_MOVE_DIR:
					player.creature.controller.move = a.shoot_or_move_or_roll__dir
##


class PlayerRoll extends PlayerBase: ##
	func on_enter(a: PlayerAction) -> void:
		base_on_enter(a)
		player.creature.controller.move = a.shoot_or_move_or_roll__dir


	func on_exit() -> void:
		base_on_exit()


	func explicit_process(dt: float) -> void:
		buffer.clear()
		base_process(dt)
		player.creature.speed = bf.get_roll_speed(
			glib.v.get_player_roll_distance(),
			glib.v.get_player_roll_duration_seconds(),
			elapsed,
			glib.v.get_player_roll_pow(),
		)
		if elapsed >= glib.v.get_player_roll_duration_seconds():
			player.change_state(PlayerStateType.DEFAULT, null)
##


class PlayerBlock extends PlayerBase: ##
	func on_enter(a: PlayerAction) -> void:
		base_on_enter(a)


	func on_exit() -> void:
		base_on_exit()


	func explicit_process(dt: float) -> void:
		buffer.clear()
		base_process(dt)
		player.stamina = max(player.stamina, player.stamina_ki)
		player.stamina_rally = max(player.stamina_rally, player.stamina)
		if elapsed >= glib.v.get_player_ki_state_min_duration():
			player.change_state(PlayerStateType.DEFAULT, null)
##
