extends Node

func clear_children(node: Node) -> void:
	for c in node.get_children():
		c.queue_free()


func move_body_with_speed(body: RigidBody3D, direction: Vector2, speed: float) -> void:
	var offset: Vector2 = direction * speed
	body.apply_central_force(
		Vector3(offset.x, 0, offset.y) * body.linear_damp * body.mass,
	)
