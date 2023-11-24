extends Node

var config := ConfigFile.new()

func _ready() -> void:
	if config.load("user://preferences.cfg") == OK: return

	config.save("user://preferences.cfg")
	config.load("user://preferences.cfg")

func get_preference(section : String, setting : String, default):
	return config.get_value(section, setting, default)

func set_preference(section : String, setting : String, value):
	config.set_value(section, setting, value)
	config.save("user://preferences.cfg")
