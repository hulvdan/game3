class_name Collisions

## Variables
static var _sphere_basis := Basis.from_euler(Vector3(0.0, PI / 2, PI / 2))

static var _param: = PhysicsShapeQueryParameters3D.new()
static var _shape_sphere := PhysicsServer3D.sphere_shape_create()
static var _shape_cylinder := PhysicsServer3D.cylinder_shape_create()
static var _shape_polygon := PhysicsServer3D.convex_polygon_shape_create()
static var _cylinder_shape_dict := { "height": 0.0, "radius": 0.01 }
static var _polygon_points: PackedVector3Array

static var _debug_collisions: bool
static var _space: PhysicsDirectSpaceState3D
static var _initialized: bool

static var _color := Color(1, 1, 0, 1)
##


static func init(world_3d: Node3D) -> void: ##
	assert(!_initialized)
	_initialized = true

	_space = world_3d.get_world_3d().direct_space_state
##


static func init_frame() -> void: ##
	_debug_collisions = glib.v.get_debug_collisions()
##


static func set_gizmos_color(color: Color) -> void: ##
	EditorImmediateGizmos.draw_color = color
	_color = color
##


static func query_circle(
		pos: Vector2,
		radius: float,
		mask: int,
		collide_with_bodies: bool,
		collide_with_areas: bool,
		max_returned_objects: int,
) -> Array[Dictionary]: ##
	assert(radius > 0)

	_set_param_common_data(
		_shape_sphere,
		pos,
		_sphere_basis,
		collide_with_bodies,
		collide_with_areas,
		mask,
	)

	PhysicsServer3D.shape_set_data(_shape_sphere, radius)

	if _debug_collisions:
		ImmediateGizmos3D.set_transform(_param.transform)
		ImmediateGizmos3D.line_circle(
			Vector3(0, 0, 0),
			Vector3(1, 0, 0),
			radius,
			_color,
		)

	return _space.intersect_shape(_param, max_returned_objects)
##


static func query_circle_segment(
		pos: Vector2,
		radius_min: float,
		radius_max: float,
		direction_angle: float,
		spread_angle: float,
		mask: int,
		collide_with_bodies: bool,
		collide_with_areas: bool,
		max_returned_objects: int,
) -> Array[Dictionary]: ##
	assert(radius_min >= 0)
	assert(radius_min <= radius_max)
	assert(radius_max > 0)
	assert(spread_angle < PI)

	_polygon_points.clear()
	var c: float = cos(spread_angle / 2.0)
	var s: float = sin(spread_angle / 2.0)
	_polygon_points.append(Vector3(radius_max * c, 0, radius_max * s))
	_polygon_points.append(Vector3(radius_max, 0, 0))
	_polygon_points.append(Vector3(radius_max * c, 0, -radius_max * s))
	if radius_min > 0:
		_polygon_points.append(Vector3(radius_min * c, 0, -radius_min * s))
		_polygon_points.append(Vector3(radius_min * c, 0, radius_min * s))
	else:
		_polygon_points.append(Vector3(0, 0, 0))
	PhysicsServer3D.shape_set_data(_shape_polygon, _polygon_points)

	_set_param_common_data(
		_shape_polygon,
		pos,
		Basis.from_euler(Vector3(0, direction_angle, 0)),
		collide_with_bodies,
		collide_with_areas,
		mask,
	)

	if _debug_collisions:
		ImmediateGizmos3D.set_transform(_param.transform)
		ImmediateGizmos3D.line_polygon(_polygon_points, _color)

	return _space.intersect_shape(_param, max_returned_objects)
##


static func query_ray(
		pos: Vector2,
		angle: float,
		distance: float,
		mask: int,
		collide_with_bodies: bool,
		collide_with_areas: bool,
		max_returned_objects: int,
) -> Array[Dictionary]: ##
	assert(distance > 0)

	_cylinder_shape_dict.height = distance
	PhysicsServer3D.shape_set_data(_shape_cylinder, _cylinder_shape_dict)

	_set_param_common_data(
		_shape_cylinder,
		pos,
		Basis.from_euler(Vector3(0, -angle + PI / 2, 0)) * _sphere_basis,
		collide_with_bodies,
		collide_with_areas,
		mask,
	)

	if _debug_collisions:
		ImmediateGizmos3D.set_transform(_param.transform)
		ImmediateGizmos3D.line_capsule(
			Vector3(0, 0, 0),
			_cylinder_shape_dict.radius as float,
			_cylinder_shape_dict.height as float,
			_color,
		)

	return _space.intersect_shape(_param, max_returned_objects)
##


static func query_rect(
		_pos: Vector2,
		_size: Vector2,
		_angle: float,
		_mask: int,
		_collide_with_bodies: bool,
		_collide_with_areas: bool,
		_max_returned_objects: int,
) -> Array[Dictionary]: ##
	bf.invalid_path()
	return []
##


static func _set_param_common_data(
		rid: RID,
		pos: Vector2,
		basis: Basis,
		collide_with_bodies: bool,
		collide_with_areas: bool,
		mask: int,
) -> void: ##
	_param.shape_rid = rid
	_param.transform.origin = bf.to_xz(pos)
	_param.transform.basis = basis
	_param.collide_with_bodies = collide_with_bodies
	_param.collide_with_areas = collide_with_areas
	_param.collision_mask = mask
##
