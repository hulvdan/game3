extends Control

class_name UIActionLabels

@export var _label_curve_y: Curve
@export var _label_offset_y_min: float = 0
@export var _label_offset_y_max: float = 1
@export var _label_duration: float = 1
@export var _label_duration_fade: float = 0.1
@export var _options: Dictionary[String, UIActionLabelOpts]
@export var _damage_number_player_color: Color = Color(1, 0, 0, 1)
@export var _damage_number_mob_color: Color = Color(1, 1, 0, 1)
@export var _packed_label: PackedScene

var _damage_opts: UIActionLabelOpts = UIActionLabelOpts.new()


func _ready() -> void:
	Game.v.player_perfectly_evaded.connect(_make_action_label.bind(_options["player_perfectly_evaded"]))
	Game.v.enemy_started_attack.connect(_make_action_label.bind(_options["enemy_started_attack"]))
	Game.v.damaged.connect(
		func(world_pos: Vector3, value: int, type: Game.WhoGotDamagedType) -> void:
			_damage_opts.text = str(value)
			if type == Game.WhoGotDamagedType.PLAYER:
				_damage_opts.color = _damage_number_player_color
			else:
				_damage_opts.color = _damage_number_mob_color
			_make_action_label(world_pos, _damage_opts)
	)


func _make_action_label(pos: Vector3, opts: UIActionLabelOpts) -> void: ##
	var node: UIActionLabel = _packed_label.instantiate()
	add_child(node)
	node.pos = pos
	if opts.text:
		node.node_label.text = tr(opts.text)
		node.node_label.visible = true
		node.node_label.label_settings.font_color = opts.color
	if opts.texture:
		node.node_texture_rect.texture = opts.texture
		node.node_texture_rect.visible = true
	var tw = create_tween()
	tw.set_trans(Tween.TRANS_SINE)
	tw.set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(node, "modulate:a", 0, 0)
	tw.tween_property(node, "modulate:a", 1, _label_duration_fade)
	tw.tween_property(node, "modulate:a", 1, _label_duration - 2 * _label_duration_fade)
	tw.tween_property(node, "modulate:a", 0, _label_duration_fade)
##


func explicit_update(
		dt: float,
		player_camera_dir: Vector3,
		player_camera_dot: float,
) -> void: ##
	for label: UIActionLabel in get_children():
		var pos: Vector3 = label.pos
		var camera_dot: float = (Game.v.camera.position - pos).dot(player_camera_dir)
		var dot_scale: float = player_camera_dot / camera_dot
		label.scale = Vector2(1, 1) * dot_scale
		label.position = Game.v.camera.unproject_position(pos) - label.size / 2.0
		label.position.y += lerp(
			_label_offset_y_min,
			_label_offset_y_max,
			_label_curve_y.sample(label.elapsed / _label_duration),
		) * dot_scale

		label.elapsed += dt
		if label.elapsed >= _label_duration:
			label.queue_free()
			continue
##
