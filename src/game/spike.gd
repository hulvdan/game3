extends Node3D

class_name Spike

var is_active: bool = false
var activation_elapsed: float = 0
var activation_elapsed_visual: float = 0
var player_is_inside: bool = false
var creatures_to_damage: Array[Creature]

@onready var container_spikes: Node3D = %_container_spikes
@onready var area_trigger: Area3D = %_area_trigger
@onready var area_damage: Area3D = %_area_damage


func init(room: Room) -> void:
	room.target_camera_elements.append_array(container_spikes.get_children())
	container_spikes.visible = false
	area_trigger.body_entered.connect(_on_body_entered_trigger)
	area_trigger.body_exited.connect(_on_body_exited_trigger)
	area_damage.body_entered.connect(_on_body_entered_damage)
	area_damage.body_exited.connect(_on_body_exited_damage)


func _on_body_entered_trigger(creature: Creature) -> void:
	if creature.type == glib.GCreatureType.PLAYER:
		player_is_inside = true


func _on_body_exited_trigger(creature: Creature) -> void:
	if creature.type == glib.GCreatureType.PLAYER:
		player_is_inside = false


func _on_body_entered_damage(creature: Creature) -> void:
	assert(creature not in creatures_to_damage)
	creatures_to_damage.append(creature)


func _on_body_exited_damage(creature: Creature) -> void:
	for i in range(len(creatures_to_damage)):
		if creatures_to_damage[i] == creature:
			creatures_to_damage.remove_at(i)
			return
	assert(false)


func try_activate() -> void:
	if not is_active:
		is_active = true
		container_spikes.visible = true
		#container_spikes_scale.scale.y = 0


func _physics_process(dt: float) -> void:
	if player_is_inside:
		try_activate()

	if is_active:
		activation_elapsed += dt
		if activation_elapsed >= glib.v.get_spikes_duration_seconds():
			is_active = false
			container_spikes.visible = false
			activation_elapsed = 0
			activation_elapsed_visual = 0


func _process(dt: float) -> void:
	if is_active:
		activation_elapsed_visual += dt
		var t: float = min(1, activation_elapsed_visual / glib.v.get_spikes_damage_starts_at())
		t = t * t
		for child: Node3D in container_spikes.get_children():
			child.scale.y = t
