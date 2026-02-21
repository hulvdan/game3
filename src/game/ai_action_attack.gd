@tool
extends ActionLeaf

class_name ActionAttack

@export var attack_duration: float = 1.0

@export var emoji_duration: float = 1
@export var emoji_y_curve: Curve
@export var emoji_offset_x_min: float = 0
@export var emoji_offset_x_max: float = 1
@export var emoji_offset_y_min: float = 0
@export var emoji_offset_y_max: float = 1
@export var packed_emoji_ai_attack: PackedScene

var elapsed_since_start: float = 0.0
var projectile_spawned: bool


func tween_method(emoji: Sprite3D, t: float) -> void:
	var x: float = lerp(emoji_offset_x_min, emoji_offset_x_max, t)
	var y: float = lerp(emoji_offset_y_min, emoji_offset_y_max, emoji_y_curve.sample(t))
	emoji.transform.origin = Vector3(x, y, 0.1)


func tween_method_destroy(emoji: Sprite3D) -> void:
	emoji.queue_free()
	emoji = null


func tick(actor_: Node, _blackboard: Blackboard) -> int:
	var actor: Creature = actor_
	var data = glib.v.get_creatures()[actor.type]

	if !elapsed_since_start && packed_emoji_ai_attack:
		var emoji: Sprite3D = packed_emoji_ai_attack.instantiate()
		actor.node_sprite.add_child(emoji)
		var tw: Tween = create_tween()
		tw.tween_method(
			func(t: float) -> void:
				tween_method(emoji, t),
			0.0,
			1.0,
			emoji_duration,
		)
		tw.tween_callback(tween_method_destroy.bind(emoji))

	# var target_pos: Vector2 = bf.from_xz(Room.v.player.transform.origin)
	# var pos = bf.from_xz((actor as Node3D).transform.origin)
	# var dpos: Vector2 = target_pos - pos
	elapsed_since_start += get_physics_process_delta_time()

	if (
		!projectile_spawned
		&& data.get_attack_projectile_type()
		&& (data.get_attack_projectile_spawn_at() < elapsed_since_start)
	):
		projectile_spawned = true
		var d: Projectile.Data = Projectile.Data.new()
		d.type = data.get_attack_projectile_type() as glib.GProjectileType
		d.owner = actor.type
		Game.v.make_projectile(
			data.get_attack_projectile_type(),
			bf.from_xz(actor.transform.origin),
			bf.from_xz(Room.v.player.transform.origin),
			d,
		)

	if elapsed_since_start >= attack_duration:
		# Finished attacking.
		elapsed_since_start = 0.0
		projectile_spawned = false
		return SUCCESS

	return RUNNING
