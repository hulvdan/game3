extends Control

class_name Bar

@export var margin: int = 4

var fade: bool = false

@onready var _bar: ColorRect = %_bar
@onready var _rally_front: ColorRect = %_rally_front
@onready var _rally_back: ColorRect = %_rally_back
@onready var _margin_container: MarginContainer = %_margin_container


func _ready() -> void:
	for side: String in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		_margin_container.add_theme_constant_override(side, margin)


class Opts:
	var rally_front_enabled: bool
	var rally_front_color: Color

	var rally_back_enabled: bool
	var rally_back_color: Color


	func with_rally_front(c: Color) -> Opts:
		assert(!self.rally_front_enabled)
		self.rally_front_enabled = true
		self.rally_front_color = c
		return self


	func with_rally_back(c: Color) -> Opts:
		assert(!self.rally_back_enabled)
		self.rally_back_enabled = true
		self.rally_back_color = c
		return self


func init(color: Color, fade_: bool, opts: Opts = Opts.new()) -> void:
	fade = fade_
	_bar.color = color
	if opts.rally_front_enabled:
		_rally_front.visible = true
		_rally_front.color = opts.rally_front_color


func set_progress(p: float) -> void:
	assert(p >= 0)
	assert(p <= 1)
	if fade:
		if p < 1:
			_bar.color.a = 0.4
		else:
			_bar.color.a = 1
	_bar.scale.x = p


func set_rally_front_progress(p: float) -> void:
	assert(p >= 0)
	assert(p <= 1)
	assert(_rally_front.visible)
	_rally_front.scale.x = p


func set_rally_back_progress(p: float) -> void:
	assert(p >= 0)
	assert(p <= 1)
	assert(_rally_back.visible)
	_rally_back.scale.x = p
