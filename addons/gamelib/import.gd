extends EditorImportPlugin

func _get_importer_name():
	return "gamelib_importer"


func _get_visible_name():
	return "Gamelib Importer"


func _get_resource_type():
	return "Gamelib"


func _get_recognized_extensions():
	return ["gamelib"]


func _get_save_extension() -> String:
	return "tres"


func _get_import_options(path, index):
	return []


func json_to_class(json: Dictionary, _class: Object) -> Object:
	var properties: Array = _class.get_property_list()
	for key in json.keys():
		for property in properties:
			if property.name == key and property.usage >= 4096:
				if String(property["class_name"]).is_empty():
					_class.set(key, json[key])
				elif property["class_name"] in ["RefCounted", "Object"]:
					_class.set(key, json_to_class(json[key], _class.get(key)))
				break
	return _class


func _import(
		source_file: String,
		save_path: String,
		options: Dictionary,
		platform_variants: Array[String],
		gen_files: Array[String],
) -> Error:
	#push_error(source_file)
	# print(source_file)
	# print(save_path)
	# push_warning(source_file)
	# push_warning(save_path)
	#push_error(ForgeJSONGD.json_file_to_dict(source_file, ""))
	var file = FileAccess.open(source_file, FileAccess.READ)
	var json: Dictionary = JSON.parse_string(file.get_as_text())
	file.close()
	#var obj = null
	var obj = json_to_class(json, Gamelib.new()) as Gamelib
	if obj == null:
		push_error("Processing %s using JSONSerialization.parse failed" % source_file)
		return FAILED
	var obj2: Gamelib = obj
	var path = "%s.%s" % [save_path, _get_save_extension()]
	var err = ResourceSaver.save(obj2 as Resource, path)
	if err == OK:
		gen_files.append(path)
	return err
