extends CanvasLayer
class_name Inventory

@onready var window := %Inventory
@onready var hotbar := %Hotbar

func toggle_window() -> void:
	window.set_visible(!window.visible)

	if window.visible: Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
