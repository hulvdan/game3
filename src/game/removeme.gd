@tool
extends Node

static var gamelib_modified_time: int = -1


func _process(_delta: float) -> void:
	if not Engine.is_editor_hint():
		return

	const gamelib_path = "res://src/game/gamelib.yml"
	var mtime = FileAccess.get_modified_time(gamelib_path)
	if mtime == gamelib_modified_time:
		return

	gamelib_modified_time = mtime

	var f = FileAccess.open(gamelib_path, FileAccess.READ)
	if not f:
		push_error("Couldn't open {gamelib_path}")
		return

	push_error("Loaded {gamelib_path}")
	print("gamelib loaded!")
