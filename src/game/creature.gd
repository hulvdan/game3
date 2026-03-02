class_name Creature
extends Node3D

## Variables
static var _evaded_attack_indices: Array[int]

@export var node_body: RigidBody3D

var type: glib.GCreatureType
var res: ResCreature
var hp: float
var hp_recoverable_up_to: float
var time_since_hp_rally := INF
var time_since_last_damage_taken := INF
var time_since_last_damage_taken_visual := INF
var hp_bar: Bar
var controller: Controller = Controller.new()
var attack_elapsed: float
var attack_projectiles_spawned: int
var attack_blinked: bool
var attack_dashed: bool
var attack_id: int
var attack_damaged_creatures: Array[Creature]
var attack_damaged_interactables: Array[Interactable]
var current_attack: glib.GAttack
var change_attack_to: glib.GAttack
var change_ability_to: glib.GAbility
var blocked: bool
var impulses: Array[Game.Impulse]
var attack_target_pos: Vector2
var attack_target_dir: Vector2
var speed_modifiers: Dictionary[String, float] = { "base": 0 }
var _attack_ids_marked_as_evaded: Array[EvadedAttack]

@onready var node_target_camera: Node3D = %_rotate
@onready var node_sprite: Sprite3D = %_sprite
@onready var node_shape: CollisionShape3D = %_shape ##


func enqueue_attack(value: glib.GAttack) -> void: ##
	change_attack_to = value
	change_ability_to = null
	##


func enqueue_ability(value: glib.GAbility) -> void: ##
	change_ability_to = value
	change_attack_to = null
	##


func get_speed() -> float: ##
	var result := 1.0
	for x: float in speed_modifiers.values():
		result *= x
	return result
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

		var melee := attack.get_melee()
		var melee_hitbox_dist := 0.0
		if melee:
			var polygon := melee.get_polygon()
			var circle := melee.get_circle()

			if polygon:
				assert(!circle)
			if circle:
				assert(!polygon)

			if polygon:
				melee_hitbox_dist = polygon.get_distance_max() * (polygon.get_anchor_x() + 0.5)
			if circle:
				melee_hitbox_dist = circle.get_radius() * (circle.get_anchor_x() + 0.5)

			attack_dist += melee_hitbox_dist

		for tag in attack.get_tags():
			match tag.get_tag_type():
				glib.GTagType.DASH, glib.GTagType.BLINK:
					attack_dist += tag.get_f3()
					attack_dist -= melee_hitbox_dist / 2

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


class EvadedAttack:
	var id: int
	var destroy_at: float


class Controller:
	var move: Vector2
	var last_move: Vector2
