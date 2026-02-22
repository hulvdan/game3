extends Node3D

class_name Projectile

class Data:
	var type: glib.GProjectileType
	var owner: glib.GCreatureType
	var pos: Vector2
	var target: Vector2


var elapsed: float
var d: Data
var res: ResProjectile
var zones: Array[Node3D]
var damaged_creatures: Array[Creature]
var straight__pierced: int
var attack_id: int
var calculated__dir: Vector2

@onready var sprite: Sprite3D = %_sprite
