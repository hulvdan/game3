extends Node3D

class_name Creature

@export var node_body: RigidBody3D
@export var node_target_camera: Node3D
@export var node_sprite: Sprite3D

var type: glib.GCreatureType
var res: ResCreature
var hp: int

var time_since_last_damage_taken: float = INF

var hp_bar: Bar


class Controller:
	var move: Vector2


var controller: Controller = Controller.new()

# func _ready() -> void:
# 	time_since_last_damage_taken.resize(glib.GDamageType.COUNT)
# 	time_since_last_damage_taken.fill(INF)
