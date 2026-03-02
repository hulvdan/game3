class_name Bar
extends Control

@export var margin: int = 4

@onready var _bar: ColorRect = %_bar
@onready var _rally_front: ColorRect = %_rally_front
@onready var _rally_back: ColorRect = %_rally_back
@onready var _margin_container: MarginContainer = %_margin_container


func _ready() -> void:
    for side: String in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
        _margin_container.add_theme_constant_override(side, margin)


func init(color: Color) -> void:
    _bar.color = color


func init_rally_front(c: Color) -> void:
    assert(!_rally_front.visible)
    _rally_front.visible = true
    _rally_front.color = c


func init_rally_back(c: Color) -> void:
    assert(!_rally_back.visible)
    _rally_back.visible = true
    _rally_back.color = c


func set_progress(p: float) -> void:
    assert(p >= 0)
    assert(p <= 1)
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
