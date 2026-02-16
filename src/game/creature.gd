extends Node3D

class_name Creature

@export var node_body: RigidBody3D
@export var node_target_camera: Node3D
@export var node_sprite: Sprite3D

var type: glib.GCreatureType
var res: ResCreature
var hp: int
var this_frame_taken_damage: int = 0

var hp_bar: Bar


class Controller:
	var move: Vector2


var controller: Controller = Controller.new()
