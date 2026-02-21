extends Node

# const INT_MAX = 9223372036854775807 # 2^63 - 1
# const INT_MIN = -9223372036854775808 # -2^63

const DIRECTION_OFFSETS: Array[Vector2i] = [
	Vector2i(1, 0),
	Vector2i(0, 1),
	Vector2i(-1, 0),
	Vector2i(0, -1),
]

enum DirectionFlags {
	NOT_SET = 0,
	RIGHT = 1,
	DOWN = 2,
	LEFT = 4,
	UP = 8,
}


func clear_children(node: Node) -> void:
	for c in node.get_children():
		c.queue_free()


func move_body_with_speed(body: RigidBody3D, direction: Vector2, speed: float) -> void:
	var offset: Vector2 = direction * speed
	body.apply_central_force(to_xz(offset) * body.linear_damp * body.mass)


func set_pos_2d(node: Node3D, pos: Vector2) -> void: ##
	node.transform.origin.x = pos.x
	node.transform.origin.z = pos.y
##


func scale_2d(node: Node3D, scale: Vector2) -> void:
	node.transform = node.transform.scaled(Vector3(scale.x, 1, scale.y))


func from_xz(value: Vector3) -> Vector2:
	return Vector2(value.x, value.z)


func to_xz(value: Vector2) -> Vector3:
	return Vector3(value.x, 0, value.y)


func get_roll_speed(dist: float, dur: float, elapsed: float, x: float) -> float: ##
	# v(t) of player during roll = A - B * t^x
	# v(0) = A; v(dist) = 0.
	return dist * (x + 1) / (x * pow(dur, x) * dur) * (pow(dur, x) - pow(elapsed, x))
##


func invalid_path() -> void: ##
	@warning_ignore("assert_always_false")
	assert(0)
##


func remove(arr: Array, value: Variant) -> void: ##
	var index: int = arr.find(value)
	assert(index >= 0)
	if index >= 0:
		arr.remove_at(index)
##


func unstable_remove_at(arr: Array, index: int) -> void: ##
	assert(index >= 0)
	if index >= 0:
		var last_index: int = arr.size() - 1
		arr[index] = arr[last_index]
		arr.remove_at(last_index)
##


func unstable_remove(arr: Array, value: Variant) -> void: ##
	unstable_remove_at(arr, arr.find(value))
##
