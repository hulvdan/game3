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

	if !actor.attack_elapsed:
		Game.v.enemy_started_attack.emit(actor.transform.origin)
		actor.melee_attacking = true
		actor.melee_attack_id = Room.v.get_next_attack_id()
		actor.melee_damaged_creatures.clear()

	if actor.melee_attacking and actor.attack_elapsed <= data.get_melee__attack_stops_tracking_at():
		actor.melee_target_pos = Room.v.player.transform.origin

	actor.attack_elapsed += get_physics_process_delta_time()

	if (
		!projectile_spawned
		&& data.get_attack_projectile_type()
		&& (data.get_attack_projectile_spawn_at() < actor.attack_elapsed)
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

	if actor.attack_elapsed >= attack_duration:
		# Finished attacking.
		actor.attack_elapsed = 0.0
		projectile_spawned = false
		actor.melee_attacking = false
		return SUCCESS

	return RUNNING
