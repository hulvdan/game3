@tool
extends Node

class_name Gamelib

@export var reload: bool = false
@export var collectibles: Array[ResCollectible]

var gamelib_modified_time: int = -1
var script_modified_time: int = -1

const gamelib_path = "res://src/game/gamelib.yml"


class GLIB_Gamelib:
	var collectibles: Array[String]
	var aboba: String


func _ready() -> void:
	reload = Engine.is_editor_hint()


func _reload_gamelib() -> void:
	print("_reload_gamelib!")
	ForgeJSONGD.only_exported_values = false
	var _a: GLIB_Gamelib = ForgeJSONGD.json_file_to_class(GLIB_Gamelib, "res://src/game/gamelib.json")
	# print_debug("_reload_gamelib!")
	print(_a.aboba)
	print(_a.collectibles[0])

	collectibles.clear()
	collectibles = []
	for c in _a.collectibles:
		var cc = ResCollectible.new()
		cc.type = c
		collectibles.append(cc)


func _process(_delta: float) -> void:
	if not Engine.is_editor_hint():
		return

	var mtime_gamelib = FileAccess.get_modified_time(gamelib_path)
	if mtime_gamelib != gamelib_modified_time:
		reload = true

	var script_path: String = get_script().resource_path
	var mtime_script = FileAccess.get_modified_time(script_path)
	if mtime_script != script_modified_time:
		reload = true

	if reload:
		reload = false
		push_warning('RELOAD')
		gamelib_modified_time = mtime_gamelib
		script_modified_time = mtime_script
		_reload_gamelib()
