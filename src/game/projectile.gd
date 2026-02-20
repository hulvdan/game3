extends Node3D

class_name Projectile

class Data:
	var type: glib.GProjectileType
	var owner: glib.GCreatureType


var d: Data
var res: ResProjectile

@onready var sprite: Sprite3D = %_sprite
