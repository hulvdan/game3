extends MetricsBase

class_name MetricsGA

var _game_analytics = null

@export var game_id: String
@export var game_secret: String


func _ready() -> void:
	if Engine.has_singleton("GameAnalytics"):
		_game_analytics = Engine.get_singleton("GameAnalytics")
		_game_analytics.setEnabledInfoLog(true)
		_game_analytics.setEnabledVerboseLog(true)

		_game_analytics.configureBuild("0.1.1")

		# _game_analytics.configureAvailableCustomDimensions01(["ninja", "samurai"])
		# _game_analytics.configureAvailableCustomDimensions02(["whale", "dolphin"])
		# _game_analytics.configureAvailableCustomDimensions03(["horde", "alliance"])
		# _game_analytics.configureAvailableResourceCurrencies(["gold", "gems"])
		# _game_analytics.configureAvailableResourceItemTypes(["boost", "lives"])

		_game_analytics.init(game_id, game_secret)


func metric(id: String) -> void:
	_game_analytics.addDesignEvent({ 'eventId': id })


func metricv(id: String, value: int) -> void:
	_game_analytics.addDesignEvent({ 'eventId': id, value: value })
