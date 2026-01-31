extends MetricsBase

class_name MetricsGA

var _js_window = null

@export var game_id: String
@export var game_secret: String

@warning_ignore_start('unsafe_method_access')


func _ready() -> void:
	if OS.has_feature('web'):
		_js_window = JavaScriptBridge.get_interface("window")

		_js_window.GameAnalytics("setEnabledInfoLog", true)
		_js_window.GameAnalytics("setEnabledVerboseLog", true)

		_js_window.GameAnalytics("configureBuild", CodegenVersion.VERSION)

		# _js_window.GameAnalytics("configureAvailableResourceCurrencies", ["gems", "gold"])
		# _js_window.GameAnalytics("configureAvailableResourceItemTypes", ["boost", "gold"])
		# _js_window.GameAnalytics("configureAvailableCustomDimensions01", ["ninja", "samurai"])
		# _js_window.GameAnalytics("configureAvailableCustomDimensions02", ["whale", "dolphin"])
		# _js_window.GameAnalytics("configureAvailableCustomDimensions03", ["horde", "alliance"])

		_js_window.GameAnalytics("initialize", game_id, game_secret)

		metric('aboba')


func metric(id: String) -> void:
	if _js_window:
		_js_window.GameAnalytics("addDesignEvent", { "eventId": id })


func metricv(id: String, value: int) -> void:
	if _js_window:
		_js_window.GameAnalytics("addDesignEvent", { "eventId": id, "value": value })

@warning_ignore_restore('unsafe_method_access')
