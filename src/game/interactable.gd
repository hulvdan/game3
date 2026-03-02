class_name Interactable
extends Node3D

## Variables
@export var node_body: RigidBody3D

var type: glib.GInteractableType
var res: ResInteractable
var hp: int
var spawned_projectile := false
var impulses: Array[Game.Impulse]

@onready var node_target_camera: Node3D = %_target_camera
@onready var node_sprite: Sprite3D = %_sprite ##
