@tool
class_name ActionRandCooldown
extends ActionLeaf

@export var cooldown_decorator: CooldownDecorator

var cooldown_min: float
var cooldown_max: float


func tick(_actor: Node, _blackboard: Blackboard) -> int:
    assert(cooldown_decorator)
    cooldown_decorator.wait_time = randf_range(cooldown_min, cooldown_max)
    return SUCCESS
