extends Node3D

class_name Creature

@export var sprite: Sprite3D
@export var data: CreatureData


func _ready() -> void:
	sprite.texture = data.texture
