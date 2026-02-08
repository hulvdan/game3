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


func dict_to_class(dict: Dictionary, res: Resource) -> Resource:
	var property_names = []
	for prop in res.get_property_list():
		property_names.append(prop.name)

	for key in dict.keys():
		var property_index = property_names.find(key)
		if property_index < 0:
			push_error('Found excessive key: %s' % key)
			continue

		var property = res.get_property_list()[property_index]

		var value = dict[key]
		var current_prop = res.get(key)
		push_error(Gamelib.new().get_property_list()[3])

		# If the property itself is a Resource and dict contains a dictionary
		if typeof(value) == TYPE_DICTIONARY and current_prop is Resource:
			dict_to_class(value, current_prop)

		# If the property is an Array, check for nested dictionaries
		elif typeof(value) == TYPE_ARRAY and current_prop is Array:
			var new_array = []
			for i in value:
				if typeof(i) == TYPE_DICTIONARY and current_prop.size() > 0 and current_prop[0] is Resource:
					var nested_res = current_prop[0].duplicate()
					new_array.append(dict_to_class(i, nested_res))
				else:
					new_array.append(i)
			res.set(key, new_array)

		# Otherwise, just set the property
		else:
			res.set(key, value)
	return res


func dict_to_class2(dict: Dictionary, _class: Object) -> Object:
	if _class == null:
		return _class
	var properties: Array = _class.get_property_list()

	for key in dict.keys():
		for property in properties:
			if property.name == key and property.usage >= 4096:
				var value = dict[key]

				# --- Array handling ---
				if property.type == TYPE_ARRAY and value is Array:
					var arr: Array = []

					# hint_string contains the class name of array elements
					var element_class_name: String = property.hint_string

					for item in value:
						push_error(property.hint_string)
						if element_class_name != "":
							# Create new instance of the element class
							var element = ClassDB.instantiate(element_class_name)

							# If it’s a Dictionary, convert recursively
							if item is Dictionary:
								arr.append(dict_to_class(item, element))
							else:
								arr.append(item)
						else:
							arr.append(item)

					_class.set(key, arr)
					break

				# --- Normal object field ---
				elif String(property["class_name"]).is_empty():
					_class.set(key, value)

				# --- Nested object ---
				elif property["class_name"] in ["RefCounted", "Object"]:
					var current_obj = _class.get(key)
					_class.set(key, dict_to_class(value, current_obj))

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
	var dict: Dictionary = JSON.parse_string(file.get_as_text())
	file.close()
	#var obj = null
	var obj = dict_to_class(dict, Gamelib.new()) as Gamelib
	if obj == null:
		push_error("Processing %s using JSONSerialization.parse failed" % source_file)
		return FAILED
	var obj2: Gamelib = obj
	var path = "%s.%s" % [save_path, _get_save_extension()]
	var err = ResourceSaver.save(obj2 as Resource, path)
	if err == OK:
		gen_files.append(path)
	return err
