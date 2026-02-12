extends Node

enum Direction {
	RIGHT = 1,
	UP = 2,
	LEFT = 4,
	DOWN = 8,
}

const DIRECTION_OFFSETS: Array[Vector2i] = [
	Vector2i(1, 0),
	Vector2i(0, 1),
	Vector2i(-1, 0),
	Vector2i(0, -1),
]


func clear_children(node: Node) -> void:
	for c in node.get_children():
		c.queue_free()


func move_body_with_speed(body: RigidBody3D, direction: Vector2, speed: float) -> void:
	var offset: Vector2 = direction * speed
	body.apply_central_force(
		Vector3(offset.x, 0, offset.y) * body.linear_damp * body.mass,
	)


func set_pos_2d(node: Node3D, pos: Vector2) -> void:
	node.transform.origin.x = pos.x
	node.transform.origin.z = pos.y


func scale_2d(node: Node3D, scale: Vector2) -> void:
	node.transform = node.transform.scaled(Vector3(scale.x, 1, scale.y))


func duplicate_shader_material(sprite: Sprite2D) -> ShaderMaterial:
	var mat: ShaderMaterial = sprite.material.duplicate()
	sprite.material = mat
	return mat
