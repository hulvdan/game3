class_name Collisions

static var _param: = PhysicsShapeQueryParameters3D.new()
static var _shape_sphere := PhysicsServer3D.sphere_shape_create()
static var _shape_cylinder := PhysicsServer3D.cylinder_shape_create()
static var _shape_polygon := PhysicsServer3D.convex_polygon_shape_create()
static var _cylinder_shape_dict := { "height": 0.0, "radius": 0.01 }

static var _debug_collisions: bool
static var _space: PhysicsDirectSpaceState3D
static var _initialized: bool


static func init(world_3d: Node3D) -> void:
	assert(!_initialized)
	_initialized = true

	_space = world_3d.get_world_3d().direct_space_state
	_param.collide_with_areas = false
	_param.collide_with_bodies = true


static func init_frame() -> void:
	_debug_collisions = glib.v.get_debug_collisions()

# static func query_circle(
# 		pos: Vector2,
# 		radius: float,
# 		mask: int,
# 		max_returned_objects: int,
# ) -> Array[Node]: ##
# 	_param.transform.origin = bf.to_xz(pos)
# 	_param.transform.basis = projectile.transform.basis * Basis.from_euler(Vector3(0.0, PI / 2, PI / 2))

# 	return space.intersect_shape(param_shape, max_returned_objects)
# ##

# static func query_circle_segment(
# 		pos: Vector2,
# 		radius: float,
# 		angle: float,
# 		mask: int,
# 		max_returned_objects: int,
# ) -> Array[Node]: ##
# 	return space.intersect_shape(param_shape, max_returned_objects)
# ##


static func query_ray(
		pos: Vector2,
		angle: float,
		distance: float,
		mask: int,
		max_returned_objects: int,
		collide_with_bodies: bool,
		collide_with_areas: bool,
) -> Array[Dictionary]: ##
	_cylinder_shape_dict.height = distance

	PhysicsServer3D.shape_set_data(_shape_cylinder, _cylinder_shape_dict)
	_param.shape_rid = _shape_cylinder
	_param.transform.origin = bf.to_xz(pos)
	_param.transform.basis = Basis.from_euler(Vector3(0, angle, 0)) * Basis.from_euler(Vector3(0.0, PI / 2, PI / 2))
	_param.collide_with_bodies = collide_with_bodies
	_param.collide_with_areas = collide_with_areas

	if _debug_collisions:
		ImmediateGizmos3D.set_transform(_param.transform)
		ImmediateGizmos3D.line_capsule(
			Vector3(0, 0, 0),
			_cylinder_shape_dict.radius as float,
			_cylinder_shape_dict.height as float,
			Color.BLUE,
		)

	_param.collision_mask = mask
	return _space.intersect_shape(_param, max_returned_objects)
##
