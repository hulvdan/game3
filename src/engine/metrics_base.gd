@abstract
extends Node

class_name MetricsBase

@abstract
func metric(_id: String) -> void


@abstract
func metricv(_id: String, _value: int) -> void
