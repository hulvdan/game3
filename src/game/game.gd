extends Node

class_name Game

#const G = preload("res://src/codegen/nolint/glib.gd")

static var _async_scene_loaded = false

@export var elements: Array[Node3D]

@export var camera_distance: float
@export var camera_angle: float

@export var creature_player: ResCreature
@export var mobs_to_spawn: Array[ResMobToSpawn]

@export var packed_creature: PackedScene

@export_file("*.binpb") var glib_filepath: String

var player: Node3D

@onready var camera: Camera3D = $_camera
@onready var container_creatures: Node = $_container_creatures


func _get_validation_conditions() -> Array[ValidationCondition]:
	return [
		ValidationCondition.scene_is_of_type(packed_creature, Creature),
		ValidationCondition.simple(camera_distance > 0, 'camera_distance > 0'),
		ValidationCondition.simple(camera_angle > 0, 'camera_angle > 0'),
	]


func _make_creature(res: ResCreature, pos: Vector2) -> Node3D:
	var creature: Creature = packed_creature.instantiate()
	creature.transform.origin.x = pos.x
	creature.transform.origin.z = pos.y
	creature.res = res
	creature.sprite.texture = creature.res.texture

	elements.append(creature)
	container_creatures.add_child(creature)
	return creature


func _ready() -> void:
	assert(camera)
	assert(container_creatures)
	for c: Node in container_creatures.get_children():
		container_creatures.remove_child(c)
	assert(camera_distance > 0)
	assert(camera_angle > 0)

	player = _make_creature(creature_player, Vector2(0, 0))
	for mob in mobs_to_spawn:
		_make_creature(mob.res, mob.pos)

	for element: Node3D in elements:
		assert(element)


func _physics_process(delta: float) -> void:
	if Meta.async_data_loaded and not _async_scene_loaded:
		_async_scene_loaded = true
		var r = load("res://assets/async_data.tscn")
		@warning_ignore("unsafe_method_access")
		var n: Node = r.instantiate()
		add_child(n)

	var player_move_direction = Input.get_vector("move_l", "move_r", "move_u", "move_d")
	var offset = player_move_direction * delta
	player.transform.origin.x += offset.x
	player.transform.origin.z += offset.y

	var camera_dir = Vector3(0, sin(camera_angle), cos(camera_angle))
	camera.transform.origin = player.transform.origin + camera_dir * camera_distance
	camera.transform = camera.transform.looking_at(player.transform.origin)

	for element: Node3D in elements:
		element.transform.basis = camera.transform.basis


func _process(_delta: float) -> void:
	pass
