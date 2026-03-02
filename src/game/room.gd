class_name Room
extends Node

static var v: Room

var player := PlayerController.new()
var start_elapsed := 0.0
var _next_attack_id := 0

@onready var container_creatures: Node = %_container_creatures
@onready var container_floor: Node = %_container_floor
@onready var container_doors: Node = %_container_doors
@onready var container_projectiles: Node = %_container_projectiles
@onready var container_mob_hp_bars: Node = %_container_mob_hp_bars
@onready var container_spikes: Node = %_container_spikes
@onready var container_interactables: Node = %_container_interactables
@onready var container_zones: Node = %_container_zones
@onready var action_labels: UIActionLabels = %_action_labels


func get_next_attack_id() -> int: ##
	_next_attack_id += 1
	return _next_attack_id
	##
