extends Node

enum DirectionFlags {
	NOT_SET = 0,
	RIGHT = 1,
	DOWN = 2,
	LEFT = 4,
	UP = 8,
}

# const INT_MAX = 9223372036854775807 # 2^63 - 1
# const INT_MIN = -9223372036854775808 # -2^63
const DIRECTION_OFFSETS: Array[Vector2i] = [
	Vector2i(1, 0),
	Vector2i(0, 1),
	Vector2i(-1, 0),
	Vector2i(0, -1),
]

static var _remove_indices: Array[int]


func vector2_direction_or_random(from: Vector2, to: Vector2) -> Vector2: ##
	if from == to:
		return Vector2(1, 0).rotated(randf() * 2.0 * PI)
	return from.direction_to(to)
	##


func vector2_xz_direction_or_random(from: Vector3, to: Vector3) -> Vector2: ##
	if xz(from) == xz(to):
		return Vector2(1, 0).rotated(randf() * 2.0 * PI)
	return xz(from).direction_to(xz(to))
	##


func clear_children(node: Node) -> void: ##
	for c in node.get_children():
		c.queue_free()
	##


func move_body_with_speed(body: RigidBody3D, direction: Vector2, speed: float) -> void: ##
	var offset := direction * speed
	body.apply_central_force(to_xz(offset) * body.linear_damp * body.mass)
	##


func impulse(body: RigidBody3D, dist: float, dir: Vector3) -> void: ##
	assert(body)
	assert(dist >= 0)
	assert(dir != Vector3.INF)
	var impulse_strength := dist * body.linear_damp * body.mass
	body.apply_impulse(dir * impulse_strength)
	##


func set_pos_2d(node: Node3D, pos: Vector2) -> void: ##
	node.transform.origin.x = pos.x
	node.transform.origin.z = pos.y
	##


func scale_2d(node: Node3D, scale: Vector2) -> void: ##
	node.transform = node.transform.scaled(Vector3(scale.x, 1, scale.y))
	##


func xz(value: Vector3) -> Vector2: ##
	return Vector2(value.x, value.z)
	##


func to_xz(value: Vector2) -> Vector3: ##
	return Vector3(value.x, 0, value.y)
	##


func get_roll_speed(dist: float, dur: float, elapsed: float, x: float) -> float: ##
	# v(t) of player during roll = A - B * t^x
	# v(0) = A; v(dist) = 0.

	assert(dur > 0)
	assert(elapsed >= 0)
	assert(elapsed <= 2 * dur) # Слабый assert. Откидываю только заоблачные значения.
	#assert(x > 0)

	return dist * (x + 1) / (x * pow(dur, x) * dur) * (pow(dur, x) - pow(elapsed, x))
	##


func invalid_path() -> void: ##
	@warning_ignore("assert_always_false")
	assert(0)
	##


# arr: Array[T], value: T
func remove_single(arr: Array, value: Variant) -> void: ##
	assert(len(arr))
	var index := arr.find(value)
	assert(index >= 0)
	if index >= 0:
		arr.remove_at(index)
	##


func unstable_remove_at(arr: Array, index: int) -> void: ##
	assert(len(arr))
	assert(index >= 0)
	if index >= 0:
		var last_index := arr.size() - 1
		arr[index] = arr[last_index]
		arr.remove_at(last_index)
	##


# arr: Array[T], value: T
func unstable_remove_single(arr: Array, value: Variant) -> void: ##
	unstable_remove_at(arr, arr.find(value))
	##


func remove_indices(arr: Array, sorted_indices: Array[int]) -> void: ##
	for i in range(len(sorted_indices) - 1):
		assert(sorted_indices[i] < sorted_indices[i + 1])
	for i in sorted_indices:
		assert(i >= 0)
		assert(i < len(arr))

	for i2 in range(len(sorted_indices)):
		var v := sorted_indices[len(sorted_indices) - i2 - 1]
		arr.remove_at(v)
	sorted_indices.clear()
	##


func unstable_remove_indices(arr: Array, sorted_indices: Array[int]) -> void: ##
	for i in range(len(sorted_indices) - 1):
		assert(sorted_indices[i] < sorted_indices[i + 1])
	for i in sorted_indices:
		assert(i >= 0)
		assert(i < len(arr))

	for i2 in range(len(sorted_indices)):
		var v := sorted_indices[len(sorted_indices) - i2 - 1]
		unstable_remove_at(arr, v)
	sorted_indices.clear()
	##


# arr: Array[T], value: T
func remove_all(arr: Array, value: Variant) -> void: ##
	assert(!_remove_indices)
	for i in range(len(arr)):
		if arr[i] == value:
			_remove_indices.append(i)
	remove_indices(arr, _remove_indices)
	##


# arr: Array[T], value: T
func unstable_remove_all(arr: Array, value: Variant) -> void: ##
	assert(!_remove_indices)
	for i in range(len(arr)):
		if arr[i] == value:
			_remove_indices.append(i)
	unstable_remove_indices(arr, _remove_indices)
	##


# arr: Array[T], key: Callable[[T], bool]
func remove_all_by_key(arr: Array, key: Callable) -> void: ##
	assert(!_remove_indices)
	for i in range(len(arr)):
		if key.call(arr[i]):
			_remove_indices.append(i)
	remove_indices(arr, _remove_indices)
	##


# arr: Array[T], key: Callable[[T], bool]
func unstable_remove_all_by_key(arr: Array, key: Callable) -> void: ##
	assert(!_remove_indices)
	for i in range(len(arr)):
		if key.call(arr[i]):
			_remove_indices.append(i)
	unstable_remove_indices(arr, _remove_indices)
	##
