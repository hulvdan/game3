extends Node3D

class_name Projectile

var res: ResProjectile
var owner_creature_type: glib.GCreatureType
var speed: float
var damage: int

@onready var sprite: Sprite3D = %_sprite
