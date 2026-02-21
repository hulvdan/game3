extends Node

class_name Room

static var v: Room

var player: Creature
var player_bow: Node3D
var target_camera_elements: Array[Node3D]

var start_elapsed: float = 0
var player_inside_enemy_t: float = 0
var player_holding: float = 0
var player_shooting_after_roll_scheduled: bool = false
var player_rolling: float = 0
var player_roll_direction: Vector2
var player_stamina: int = 0
var player_stamina_elapsed: float = 0
var player_attack_queued: bool

@onready var container_creatures: Node = %_container_creatures
@onready var container_floor: Node = %_container_floor
@onready var container_doors: Node = %_container_doors
@onready var container_projectiles: Node = %_container_projectiles
@onready var container_mob_hp_bars: Node = %_container_mob_hp_bars
@onready var container_spikes: Node = %_container_spikes
@onready var container_zones: Node = %_container_zones
@onready var container_action_labels: Node = %_container_action_labels
@onready var ui_action_labels: UIActionLabels = %_ui_action_labels
# @onready var container_action_labels: Node = %_container_action_labels
