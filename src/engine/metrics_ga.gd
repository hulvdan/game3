class_name MetricsGA
extends MetricsBase

@export var game_id: String
@export var game_secret: String

var _js_window = null


@warning_ignore_start("unsafe_method_access")
func _ready() -> void:
    if OS.has_feature("web"):
        _js_window = JavaScriptBridge.get_interface("window")
        _js_window.GameAnalytics("configureBuild", CodegenVersion.VERSION)
        _js_window.GameAnalytics("initialize", game_id, game_secret)


func metric(id: String) -> void:
    if _js_window:
        _js_window.GameAnalytics("addDesignEvent", id)


func metricv(id: String, value: float) -> void:
    if _js_window:
        _js_window.GameAnalytics("addDesignEvent", id, value)
@warning_ignore_restore("unsafe_method_access")
