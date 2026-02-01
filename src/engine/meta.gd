extends Node

class_name Meta

static var async_data_loaded: bool = false

@export var metrics: MetricsBase
@export var platform: PlatformBase


func _on_request_completed(
		_result: int,
		response_code: int,
		_headers: PackedStringArray,
		body: PackedByteArray,
) -> void:
	if response_code != 200:
		printerr('Failed to download async_data.pck')
		return

	var file = FileAccess.open("user://async_data.pck", FileAccess.WRITE)
	if not file:
		printerr('Failed to open async_data.pck for writing')
		return

	var stored: bool = file.store_buffer(body)
	file.close()

	if not stored:
		printerr('Failed to write to async_data.pck')
		return

	async_data_loaded = ProjectSettings.load_resource_pack("user://async_data.pck")
	if async_data_loaded:
		print('Loaded async_data.pck', async_data_loaded)
	else:
		printerr('Failed to load async_data.pck')


func _ready() -> void:
	if OS.has_feature('web'):
		var http: HTTPRequest = HTTPRequest.new()

		add_child(http)

		@warning_ignore("unsafe_method_access")
		http.request_completed.connect(_on_request_completed)

		var base: String = JavaScriptBridge.eval("document.baseURI.substring(0, document.baseURI.lastIndexOf('/') + 1)")
		http.request(base + 'async_data.pck')
	else:
		async_data_loaded = true


func metric(id: String) -> void:
	metrics.metric(id)


func metricv(id: String, value: int) -> void:
	metrics.metricv(id, value)


func show_ad_inter() -> void:
	platform.show_ad_inter()


func show_ad_reward() -> void:
	platform.show_ad_reward()


func mark_gameplay() -> void:
	platform.mark_ready()


func mark_ready() -> void:
	platform.mark_ready()
