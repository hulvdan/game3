extends Node

@export var metrics: MetricsBase


func metric(id: String) -> void:
	metrics.metric(id)


func metricv(id: String, value: int) -> void:
	metrics.metricv(id, value)


func show_ad_inter() -> void:
	pass


func show_ad_reward() -> void:
	pass


func mark_gameplay() -> void:
	pass


func mark_ready() -> void:
	pass
