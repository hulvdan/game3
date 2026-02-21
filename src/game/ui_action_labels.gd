extends Control

class_name UIActionLabels

@export var _options: Dictionary[String, UIActionLabelOpts]
@export var _packed_label: PackedScene


func _ready() -> void:
	Game.v.player_evaded.connect(_make_action_label.bind(_options["player_evaded"]))
	Game.v.enemy_started_attack.connect(_make_action_label.bind(_options["enemy_started_attack"]))


func _make_action_label(pos: Vector3, opts: UIActionLabelOpts) -> void: ##
	var node: UIActionLabel = _packed_label.instantiate()
	add_child(node)
	node.pos = pos
	if opts.text:
		node.node_label.text = opts.text
		node.node_label.visible = true
	if opts.texture:
		node.node_texture_rect.texture = opts.texture
		node.node_texture_rect.visible = true
##


func explicit_update(dt: float, player_camera_dir: Vector3, player_camera_dot: float) -> void: ##
	for label: UIActionLabel in get_children():
		var label_world_pos: Vector3 = label.get_world_pos()
		var camera_dot: float = (Game.v.camera.position - label_world_pos).dot(player_camera_dir)
		label.scale = Vector2(1, 1) * (player_camera_dot / camera_dot)
		label.position = Game.v.camera.unproject_position(label_world_pos) - label.size / 2.0

		label.elapsed += dt
		if label.elapsed >= label.duration:
			label.queue_free()
			continue
##
