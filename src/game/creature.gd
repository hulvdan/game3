extends Node3D

class_name Creature

@export var node_body: RigidBody3D

var type: glib.GCreatureType
var res: ResCreature
var hp: int

var time_since_last_damage_taken: float = INF
var time_since_last_damage_taken_visual: float = INF

var hp_bar: Bar
var controller: Controller = Controller.new()
var attack_elapsed: float
var melee_attacking: bool

@onready var node_target_camera: Node3D = %_rotate
@onready var node_sprite: Sprite3D = %_sprite


class Controller:
	var move: Vector2
	var last_move: Vector2


func setup_ai(tree: BeehaveTree) -> void:
	add_child(tree)
	var cooldown_path: String = tree.get_meta("cooldown")
	var cooldown: ActionRandCooldown = tree.get_node(cooldown_path)
	var data: glib.GCreature = glib.v.get_creatures()[type]
	cooldown.cooldown_min = data.get_attack_cooldown_min()
	cooldown.cooldown_max = data.get_attack_cooldown_max()
