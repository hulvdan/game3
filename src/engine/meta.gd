extends Node

@export var metrics: MetricsBase
@export var platform: PlatformBase


func metric(id: String) -> void:
	metrics.metric(id)


func metricv(id: String, value: int) -> void:
	metrics.metricv(id, value)


func show_ad_inter() -> void:
	platform.show_ad_inter()


func show_ad_reward() -> void:
	platform.show_ad_reward()


func mark_gameplay() -> void:
	platform.mark_ready()


func mark_ready() -> void:
	platform.mark_ready()
