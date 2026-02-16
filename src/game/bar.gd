extends Control

class_name Bar

@onready var _bar: ColorRect = %_bar
var _fade: bool = false


func init(color: Color, fade: bool) -> void:
	_fade = fade
	_bar.color = color


func set_progress(p: float) -> void:
	assert(p >= 0)
	assert(p <= 1)
	if _fade:
		if p < 1:
			_bar.color.a = 0.4
		else:
			_bar.color.a = 1
	_bar.scale.x = p
