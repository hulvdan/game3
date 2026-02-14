extends Node

class_name Room

@onready var container_creatures: Node = $_container_creatures
@onready var container_floor: Node = $_container_floor
@onready var container_doors: Node = $_container_doors

var target_camera_elements: Array[Node3D]
