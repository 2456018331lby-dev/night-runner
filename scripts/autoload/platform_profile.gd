extends Node

var is_mobile: bool = false
var is_desktop: bool = false


func _ready() -> void:
	var platform_name := OS.get_name()
	is_mobile = platform_name == "Android" or platform_name == "iOS"
	is_desktop = not is_mobile


func should_show_touch_controls() -> bool:
	return is_mobile

