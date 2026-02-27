extends Node3D

class_name Creature

## Variables
static var _evaded_attack_indices: Array[int]

@export var node_body: RigidBody3D

var type: glib.GCreatureType
var res: ResCreature
var hp: int

var time_since_last_damage_taken: float = INF
var time_since_last_damage_taken_visual: float = INF

var hp_bar: Bar
var controller: Controller = Controller.new()

var attack_elapsed: float
var attack_projectiles_spawned: int
var attack_blinked: bool

var melee_attack: glib.GAttack
var melee_attack_id: int
var melee_damaged_creatures: Array[Creature]

var blocked: bool


class Impulse:
	var dir: Vector2
	var dist: float
	var created_at: float


var impulses: Array[Impulse]


class EvadedAttack:
	var id: int
	var destroy_at: float


var attack_target_pos: Vector2
var attack_target_dir: Vector2
var speed_modifiers: Dictionary[String, float] = { "base": 0 }

var _attack_ids_marked_as_evaded: Array[EvadedAttack]

@onready var node_target_camera: Node3D = %_rotate
@onready var node_sprite: Sprite3D = %_sprite
@onready var node_shape: CollisionShape3D = %_shape
##


func add_impulse(dir: Vector2, dist: float) -> void: ##
	assert(dist >= 0)
	if dist <= 0:
		return
	var x := Impulse.new()
	x.dir = dir
	x.dist = dist
	x.created_at = Room.v.start_elapsed
	impulses.append(x)
##


func get_speed() -> float: ##
	var result := 1.0
	for x: float in speed_modifiers.values():
		result *= x
	return result
##


class Controller: ##
	var move: Vector2
	var last_move: Vector2
##


func setup_ai(tree: BeehaveTree) -> void: ##
	var data: glib.GCreature = glib.v.get_creatures()[type]

	add_child(tree)

	var gn = func(x: String) -> Node:
		var p: String = tree.get_meta(x)
		return tree.get_node(p)

	var action_cooldown: ActionRandCooldown = gn.call("cooldown")
	var action_chase: ActionChase = gn.call("chase")
	var action_attack: ActionAttack = gn.call("attack")
	action_attack.cooldown = action_cooldown

	# FIXME: Only 1st attack gets used
	for attack in data.get_attacks():
		var attack_dist: = attack.get_distance()
		var polygon := attack.get_melee__polygon()
		var circle := attack.get_melee__circle()

		if polygon:
			assert(!circle)
		if circle:
			assert(!polygon)

		var hitbox_dist: float
		if polygon:
			hitbox_dist = polygon.get_distance_max() * (polygon.get_anchor_x() + 0.5)
		if circle:
			hitbox_dist = circle.get_radius() * (circle.get_anchor_x() + 0.5)

		attack_dist += hitbox_dist

		for tag in attack.get_tags():
			match tag.get_attacktag_type():
				glib.GAttackTagType.DASH, glib.GAttackTagType.BLINK:
					attack_dist += tag.get_f3()
					attack_dist -= hitbox_dist / 2

		action_chase.set_attack_distance(attack_dist)
		break
##


func mark_attack_as_evaded(id: int) -> void: ##
	if !id:
		return
	var x := EvadedAttack.new()
	x.id = id
	x.destroy_at = glib.v.get_blocked_attack_damages_again_after()
	_attack_ids_marked_as_evaded.append(x)
##


func is_attack_evaded(id: int) -> bool: ##
	for x: EvadedAttack in _attack_ids_marked_as_evaded:
		if x.id == id:
			return true
	return false
##


func explicit_process(_dt: float) -> void: ##
	for i in range(len(_attack_ids_marked_as_evaded)):
		if _attack_ids_marked_as_evaded[i].destroy_at >= Room.v.start_elapsed:
			_evaded_attack_indices.append(i)
	for i in range(len(_evaded_attack_indices)):
		bf.unstable_remove_at(_attack_ids_marked_as_evaded, len(_evaded_attack_indices) - i - 1)
	_evaded_attack_indices.clear()
##
