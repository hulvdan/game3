extends Node3D

class_name Spike

@onready var container_spikes: Node3D = %_container_spikes
@onready var area: Area3D = %_area

var is_active: bool = false
var activation_elapsed: float = 0
var player_is_inside: bool = false


func init(room: Room) -> void:
	room.target_camera_elements.append_array(container_spikes.get_children())
	container_spikes.visible = false
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)


func _on_body_entered(creature: Creature) -> void:
	if creature.type == glib.GCreatureType.PLAYER:
		player_is_inside = true


func _on_body_exited(creature: Creature) -> void:
	if creature.type == glib.GCreatureType.PLAYER:
		player_is_inside = false


func try_activate() -> void:
	if not is_active:
		is_active = true
		container_spikes.visible = true
		activation_elapsed = 0


func _physics_process(dt: float) -> void:
	if player_is_inside:
		try_activate()

	if is_active:
		activation_elapsed += dt
		if activation_elapsed >= glib.v.get_spikes_duration_seconds():
			is_active = false
			container_spikes.visible = false
