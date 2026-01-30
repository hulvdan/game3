var is_supported : get = _is_supported_getter
var is_get_list_supported : get = _is_get_list_supported_getter
var is_native_popup_supported : get = _is_native_popup_supported_getter

func _is_supported_getter():
	return false

func _is_get_list_supported_getter():
	return false

func _is_native_popup_supported_getter():
	return false


func unlock(options = null, callback = null):
	if callback != null:
		callback.call(false)

func get_list(options = null, callback = null):
	if callback != null:
		callback.call(false, [])

func show_native_popup(options = null, callback = null):
	if callback != null:
		callback.call(false)
