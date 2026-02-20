extends Node3D

class_name Creature

@export var node_body: RigidBody3D

var type: glib.GCreatureType
var res: ResCreature
var hp: int

var time_since_last_damage_taken: float = INF
var time_since_last_damage_taken_visual: float = INF

var hp_bar: Bar

@onready var node_target_camera: Node3D = %_rotate
@onready var node_sprite: Sprite3D = %_sprite


class Controller:
	var move: Vector2
	var last_move: Vector2


var controller: Controller = Controller.new()
