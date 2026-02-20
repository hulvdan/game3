extends Node3D

class_name Projectile

class Data:
	var type: glib.GProjectileType
	var owner: glib.GCreatureType
	var arc__created_at: float
	var arc__target: Vector2


var d: Data
var res: ResProjectile

@onready var sprite: Sprite3D = %_sprite
