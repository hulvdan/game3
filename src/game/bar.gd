extends Control

class_name Bar

@export var margin: int = 4

@onready var _bar: ColorRect = %_bar
@onready var _margin_container: MarginContainer = %_margin_container
var _fade: bool = false


func _ready() -> void:
	for side: String in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		_margin_container.add_theme_constant_override(side, margin)


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
