extends Node3D

class_name Projectile

class Data:
	var type: glib.GProjectileType
	var owner: glib.GCreatureType
	var origin: Vector2
	var target: Vector2


var elapsed: float
var d: Data
var res: ResProjectile
var zone: Node3D

@onready var sprite: Sprite3D = %_sprite
