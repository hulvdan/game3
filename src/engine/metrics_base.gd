extends Node

class_name MetricsBase

func metric(_id: String) -> void:
	push_error("MetricsBase.metric() not implemented")


func metricv(_id: String, _value: int) -> void:
	push_error("MetricsBase.metricv() not implemented")
