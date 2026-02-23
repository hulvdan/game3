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
var player_attack_queued: bool
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
	player_stamina += value
	if player_stamina > glib.v.get_player_stamina():
		player_stamina = glib.v.get_player_stamina()
##
