extends Node

class_name Spike

@onready var container_spikes: Node3D = %_container_spikes


func set_progress(p: float) -> void:
	assert(p >= 0)
	assert(p <= 1)
	container_spikes.visible = p > 0
