extends Node

class_name Room

static var v: Room

var player: Creature
var player_bow: Node3D

var start_elapsed := 0.0
var player_inside_enemy_t := 0.0
var player_holding := 0.0
var player_shooting_after_roll_scheduled := false
var player_rolling := 0.0
var player_rolling_retrievable_cost := 0.0
var player_roll_direction: Vector2
var player_stamina := 0.0
var player_stamina_rally := 0.0
var player_stamina_ki := 0.0
var player_attack_queued: bool
var player_elapsed_since_stamina_consumed := 0.0
var _next_attack_id := 0

@onready var container_creatures: Node = %_container_creatures
@onready var container_floor: Node = %_container_floor
@onready var container_doors: Node = %_container_doors
@onready var container_projectiles: Node = %_container_projectiles
@onready var container_mob_hp_bars: Node = %_container_mob_hp_bars
@onready var container_spikes: Node = %_container_spikes
@onready var container_zones: Node = %_container_zones
@onready var action_labels: UIActionLabels = %_action_labels
# @onready var container_action_labels: Node = %_container_action_labels


func get_next_attack_id() -> int: ##
	_next_attack_id += 1
	return _next_attack_id
##


func add_stamina(value: float) -> void: ##
	assert(value > 0)
	player_stamina += value
	if player_stamina > glib.v.get_player_stamina():
		player_stamina = glib.v.get_player_stamina()
##


func consume_stamina(value: float, drop_rally: bool) -> void: ##
	assert(value > 0)
	player_elapsed_since_stamina_consumed = 0.0
	player_stamina -= value
	if player_stamina < 0:
		player_stamina = 0
	player_stamina_ki = player_stamina
	if player_stamina < 0:
		player_stamina = 0
	player_stamina_ki = player_stamina
	if drop_rally:
		player_stamina_rally = player_stamina
	if player_stamina_rally > player_stamina:
		player_stamina_rally = lerp(
			player_stamina,
			player_stamina_rally,
			glib.v.get_player_stamina_attack_rally_scale(),
		)
##

enum PlayerStateType { DEFAULT, SHOOT, ROLL, BLOCK }
enum PlayerActionType { NONE, SHOOT, ROLL, BLOCK }


class PlayerAction:
	var type: PlayerActionType
	var shoot_or_roll__dir: Vector2


var player_current_state := PlayerStateType.DEFAULT
static var player_action_buffer: Array[PlayerAction]


func _ready() -> void:
	_player_states[player_current_state].on_enter()


func player_change_state(
		to: PlayerStateType,
		action_type: PlayerActionType,
		action: PlayerAction,
) -> void:
	assert(to != player_current_state)
	_player_states[player_current_state].on_exit()
	player_current_state = to
	_player_states[player_current_state].on_enter()


var _player_states: Array[PlayerBase] = [
	PlayerDefault.new(),
	PlayerShoot.new(),
	PlayerRoll.new(),
	PlayerBlock.new(),
]


@abstract
class PlayerBase:
	var elapsed: float


	@abstract func on_enter() -> void


	@abstract func on_exit() -> void


	@abstract func process(dt: float) -> void


	func base_on_enter() -> void:
		elapsed = 0


	func base_on_exit() -> void:
		pass


	func base_process(dt: float) -> void:
		elapsed += dt


class PlayerDefault extends PlayerBase:
	func on_enter() -> void:
		base_on_enter()


	func on_exit() -> void:
		base_on_exit()


	func process(dt: float) -> void:
		base_process(dt)
		if !Room.player_action_buffer:
			return
		var action := Room.player_action_buffer[0]
		match action.type:
			PlayerActionType.SHOOT:
				Room.v.player_change_state(PlayerStateType.SHOOT, action)
			PlayerActionType.ROLL:
				Room.v.player_change_state(PlayerStateType.ROLL, action)
			PlayerActionType.BLOCK:
				Room.v.player_change_state(PlayerStateType.BLOCK, action)


class PlayerShoot extends PlayerBase:
	func on_enter() -> void:
		base_on_enter()


	func on_exit() -> void:
		base_on_exit()


	func process(dt: float) -> void:
		base_process(dt)
		if elapsed >= glib.v.get_shooting_seconds():
			Room.v.player_change_state(PlayerStateType.DEFAULT)


class PlayerRoll extends PlayerBase:
	func on_enter() -> void:
		base_on_enter()


	func on_exit() -> void:
		base_on_exit()


	func process(dt: float) -> void:
		base_process(dt)
		if elapsed >= glib.v.get_player_roll_duration_seconds():
			Room.v.player_change_state(PlayerStateType.DEFAULT)


class PlayerBlock extends PlayerBase:
	func on_enter() -> void:
		base_on_enter()


	func on_exit() -> void:
		base_on_exit()


	func process(dt: float) -> void:
		base_process(dt)
		if elapsed >= glib.v.get_player_ki_state_min_duration():
			Room.v.player_change_state(PlayerStateType.DEFAULT)
