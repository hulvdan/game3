extends MetricsBase

class_name MetricsGA

@export var game_id: String
@export var game_secret: String

var _js_window = null

@warning_ignore_start('unsafe_method_access')


func _ready() -> void:
	if OS.has_feature('web'):
		_js_window = JavaScriptBridge.get_interface("window")

		# _js_window.GameAnalytics("setEnabledInfoLog", true)
		# _js_window.GameAnalytics("setEnabledVerboseLog", true)

		_js_window.GameAnalytics("configureBuild", CodegenVersion.VERSION)

		# _js_window.GameAnalytics("configureAvailableResourceCurrencies", ["gems", "gold"])
		# _js_window.GameAnalytics("configureAvailableResourceItemTypes", ["boost", "gold"])
		# _js_window.GameAnalytics("configureAvailableCustomDimensions01", ["ninja", "samurai"])
		# _js_window.GameAnalytics("configureAvailableCustomDimensions02", ["whale", "dolphin"])
		# _js_window.GameAnalytics("configureAvailableCustomDimensions03", ["horde", "alliance"])

		_js_window.GameAnalytics("initialize", game_id, game_secret)


func metric(id: String) -> void:
	if _js_window:
		_js_window.GameAnalytics("addDesignEvent", id)


func metricv(id: String, value: float) -> void:
	if _js_window:
		_js_window.GameAnalytics("addDesignEvent", id, value)

@warning_ignore_restore('unsafe_method_access')
