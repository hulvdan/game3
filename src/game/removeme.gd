@tool
extends Node

@export var collectibles: Array[Collectible]

static var gamelib_modified_time: int = -1
static var script_modified_time: int = -1

const gamelib_path = "res://src/game/gamelib.yml"


func _reload_gamelib() -> void:
	var f = FileAccess.open(gamelib_path, FileAccess.READ)
	assert(f, "Couldn't open %s" % gamelib_path)
	var yaml_text = f.get_as_text()
	f.close()
	var _parsed = YAML.new().parse(yaml_text)
	print("_reload_gamelib!")


func _process(_delta: float) -> void:
	if not Engine.is_editor_hint():
		return

	var should_reload = false

	var mtime_gamelib = FileAccess.get_modified_time(gamelib_path)
	if mtime_gamelib != gamelib_modified_time:
		should_reload = true

	var script_path: String = get_script().resource_path
	var mtime_script = FileAccess.get_modified_time(script_path)
	if mtime_script != script_modified_time:
		should_reload = true

	if not should_reload:
		return

	gamelib_modified_time = mtime_gamelib
	script_modified_time = mtime_script

	_reload_gamelib()
