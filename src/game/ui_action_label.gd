extends Control

class_name UIActionLabel

@export var curve_y: Curve
@export var offset_x_min: float = 0
@export var offset_x_max: float = 1
@export var offset_y_min: float = 0
@export var offset_y_max: float = 1
@export var duration: float = 1

var pos: Vector3
var elapsed: float

@onready var node_label: Label = %_label
@onready var node_texture_rect: TextureRect = %_texture_rect


func get_world_pos() -> Vector3:
	var t: float = elapsed / duration
	var y: float = lerp(offset_y_min, offset_y_max, curve_y.sample(t))
	return Vector3(pos.x, 0, pos.y)
