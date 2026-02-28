extends Node3D

class_name Spike

@export var curve: Curve

var is_active: bool = false
var attack_id: int = 0
var striked: bool = false
var activation_elapsed: float = 0
var activation_elapsed_visual: float = 0
var player_is_inside: bool = false
var creatures_to_damage: Array[Creature]

@onready var container_spikes: Node3D = %_container_spikes
@onready var area_trigger: Area3D = %_area_trigger
@onready var area_damage: Area3D = %_area_damage


func init(_room: Room) -> void: ##
	for node: Node3D in container_spikes.get_children():
		node.add_to_group(Game.GROUP_TARGET_CAMERA)
	area_trigger.body_entered.connect(_on_body_entered_trigger)
	area_trigger.body_exited.connect(_on_body_exited_trigger)
	area_damage.body_entered.connect(_on_body_entered_damage)
	area_damage.body_exited.connect(_on_body_exited_damage)
	_set_scale(curve.sample(0))
##


func _on_body_entered_trigger(creature: Creature) -> void: ##
	if creature.type == glib.GCreatureType.PLAYER:
		player_is_inside = true
##


func _on_body_exited_trigger(creature: Creature) -> void: ##
	if creature.type == glib.GCreatureType.PLAYER:
		player_is_inside = false
##


func _on_body_entered_damage(creature: Creature) -> void: ##
	assert(creature not in creatures_to_damage)
	creatures_to_damage.append(creature)
##


func _on_body_exited_damage(creature: Creature) -> void: ##
	bf.remove_single(creatures_to_damage, creature)
##


func try_activate() -> void:
	if not is_active:
		is_active = true
		attack_id = Room.v.get_next_attack_id()


func _physics_process(dt: float) -> void:
	if player_is_inside:
		try_activate()

	if is_active:
		activation_elapsed += dt
		if activation_elapsed >= glib.v.get_spikes().get_duration_seconds():
			striked = false
			is_active = false
			attack_id = 0
			activation_elapsed = 0
			activation_elapsed_visual = 0
			_set_scale(curve.sample(0))


func _process(dt: float) -> void:
	if is_active:
		activation_elapsed_visual += dt
		var t: float = activation_elapsed_visual / glib.v.get_spikes().get_damage_starts_at()
		t = clamp(t, 0, 1)
		_set_scale(curve.sample(t))


func _set_scale(value: float) -> void:
	for child: Node3D in container_spikes.get_children():
		child.scale.y = value
