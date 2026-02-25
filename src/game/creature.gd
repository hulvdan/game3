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
var melee_attacking: bool
var melee_attack_id: int
var melee_damaged_creatures: Array[Creature]


class EvadedAttack:
	var id: int
	var destroy_at: float


var _evaded_attacks: Array[EvadedAttack]
var melee_target_pos: Vector2
var melee_target_dir: Vector2
var speed_modifiers: Dictionary[String, float] = { "base": 0 }

@onready var node_target_camera: Node3D = %_rotate
@onready var node_sprite: Sprite3D = %_sprite
@onready var node_shape: CollisionShape3D = %_shape
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
	var cooldown_path: String = tree.get_meta("cooldown")
	var cooldown: ActionRandCooldown = tree.get_node(cooldown_path)
	cooldown.cooldown_min = data.get_attack_cooldown_min()
	cooldown.cooldown_max = data.get_attack_cooldown_max()

	var chase_path: String = tree.get_meta("chase")
	var chase: ActionChase = tree.get_node(chase_path)

	var attack_dist: = data.get_attack_distance()
	if data.get_melee__attack_polygon():
		attack_dist += data.get_melee__attack_polygon().get_distance_max()
	for tag in data.get_melee__tags():
		match tag.get_meleetag_type():
			glib.GMeleeTagType.DASH:
				var dash_dist := tag.get_valuef1()
				attack_dist += dash_dist
				attack_dist -= data.get_melee__attack_polygon().get_distance_max()

	chase.set_attack_distance(attack_dist)
##


func evade_attack(id: int) -> void: ##
	var x := EvadedAttack.new()
	x.id = id
	x.destroy_at = glib.v.get_blocked_attack_damages_again_after()
	_evaded_attacks.append(x)
##


func is_attack_evaded(id: int) -> bool: ##
	for x: EvadedAttack in _evaded_attacks:
		if x.id == id:
			return true
	return false
##


func explicit_process(_dt: float) -> void: ##
	for i in range(len(_evaded_attacks)):
		if _evaded_attacks[i].destroy_at >= Room.v.start_elapsed:
			_evaded_attack_indices.append(i)
	for i in range(len(_evaded_attack_indices)):
		bf.unstable_remove_at(_evaded_attacks, len(_evaded_attack_indices) - i - 1)
	_evaded_attack_indices.clear()
##
