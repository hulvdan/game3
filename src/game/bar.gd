extends Control

class_name Bar

@export var margin: int = 4

var fade: bool = false

@onready var _bar: ColorRect = %_bar
@onready var _rally: ColorRect = %_rally
@onready var _margin_container: MarginContainer = %_margin_container


func _ready() -> void:
	for side: String in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		_margin_container.add_theme_constant_override(side, margin)


class Opts:
	var rally_enabled: bool
	var rally_color: Color


	func with_rally(c: Color) -> Opts:
		assert(!self.rally_enabled)
		self.rally_enabled = true
		self.rally_color = c
		return self


func init(color: Color, fade_: bool, opts: Opts = Opts.new()) -> void:
	fade = fade_
	_bar.color = color
	if opts.rally_enabled:
		_rally.visible = true
		_rally.color = opts.rally_color


func set_progress(p: float) -> void:
	assert(p >= 0)
	assert(p <= 1)
	if fade:
		if p < 1:
			_bar.color.a = 0.4
		else:
			_bar.color.a = 1
	_bar.scale.x = p


func set_rally_progress(p: float) -> void:
	assert(p >= 0)
	assert(p <= 1)
	assert(_rally.visible)
	_rally.scale.x = p
