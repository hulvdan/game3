extends Node3D

class_name Interactable

## Variables
@export var node_body: RigidBody3D

var type: glib.GInteractableType

@onready var node_target_camera: Node3D = %_target_camera
@onready var node_sprite: Sprite3D = %_sprite
##
