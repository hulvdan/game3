extends PlatformBase

class_name PlatformPlaygama

# ref https://wiki.playgama.com/playgama/sdk/engines/godot/advertising/interstitial
# signal on_ad_
# func _ready():
# 	Bridge.advertisement.connect("interstitial_state_changed", Callable(self, "_on_interstitial_state_changed"))

func show_ad_inter() -> void:
	if Bridge.advertisement.is_interstitial_supported:
		Bridge.advertisement.show_interstitial()


func show_ad_reward() -> void:
	pass


func mark_gameplay() -> void:
	pass


func mark_ready() -> void:
	pass
