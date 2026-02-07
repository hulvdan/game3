extends EditorImportPlugin

func _get_importer_name():
	return "gamelib_importer"


func _get_visible_name():
	return "Gamelib Importer"


func _get_priority():
	return 1.0


func _get_import_order():
	return IMPORT_ORDER_SCENE


func _get_resource_type():
	return "Gamelib"


func _get_recognized_extensions():
	return ["gamelib"]


func _get_save_extension() -> String:
	return "_gamelib"


func _can_import_threaded() -> bool:
	return false


func _import(
		source_file: String,
		save_path: String,
		options: Dictionary,
		platform_variants: Array[String],
		gen_files: Array[String],
) -> Error:
	push_error("aboba")

	# print(source_file)
	# print(save_path)
	# push_warning(source_file)
	# push_warning(save_path)
	var obj: Gamelib = ForgeJSONGD.json_file_to_class(Gamelib, source_file)
	if not obj:
		push_error("Processing %s using ForgeJSONGD.json_file_to_class returned null" % source_file)
		return FAILED
	var path = "%sgamelib.%s" % [save_path, _get_save_extension()]
	var err = ResourceSaver.save(obj, path)
	if err == OK:
		gen_files.append(path)
	return err
