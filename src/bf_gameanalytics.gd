# var GameAnalytics
#
#
# func _ready() -> void:
# 	# ... other code from your project ...
# 	if (Engine.has_singleton("GameAnalytics")):
# 		GameAnalytics = Engine.get_singleton("GameAnalytics")
# 		GameAnalytics.setEnabledInfoLog(true)
# 		GameAnalytics.setEnabledVerboseLog(true)
#
# 		GameAnalytics.configureBuild("0.1.1")
#
# 		# GameAnalytics.configureAvailableCustomDimensions01(["ninja", "samurai"])
# 		# GameAnalytics.configureAvailableCustomDimensions02(["whale", "dolphin"])
# 		# GameAnalytics.configureAvailableCustomDimensions03(["horde", "alliance"])
# 		# GameAnalytics.configureAvailableResourceCurrencies(["gold", "gems"])
# 		# GameAnalytics.configureAvailableResourceItemTypes(["boost", "lives"])
#
# 		GameAnalytics.init([gamekey], [secretkey])
