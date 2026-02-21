@tool
extends Decorator

class_name DecoratorRandCooldown

@export var cooldown_decorator: CooldownDecorator
var cooldown_min: float
var cooldown_max: float


func before_run(_actor: Node, _blackboard: Blackboard) -> void:
	cooldown_decorator.wait_time = randf_range(cooldown_min, cooldown_max)
