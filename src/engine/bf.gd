extends Node

func clear_children(node: Node) -> void:
	for c in node.get_children():
		c.queue_free()
