@tool
extends NinePatchRect
class_name Slot

@onready var icon_placeholder  := %Icon
@onready var count_label := %Count
var entry : int = -1

func define(_entry, count) -> void:
	if _entry < 0 or _entry >= Inventory.entries.size():
		push_error('Invalid inventory entry: ' + str(_entry) + ';')

	entry = _entry

	var item_name : String = Inventory.keys[entry]
	var item_details : Dictionary = Inventory.entries[item_name]

	if item_details[Inventory.is_stackable]:
		set_count(count)

	if Inventory.state in item_details:
		set_icon(Placeable.get_state_texture2d(Placeable.MAP[item_details[Inventory.state]][Placeable.top_texture]))

	return

func get_entry():
	if entry >= 0:
		return Inventory.entries[Inventory.keys[entry]]
	else: return null
func set_icon(new_texture : Texture2D) -> void: icon_placeholder.set_texture(new_texture)
func set_count(new_count : int) -> void: count_label.set_text(str(new_count))
func show_frame() -> void: self.set_self_modulate(Color(Color.WHITE, 1))
func hide_frame() -> void: self.set_self_modulate(Color(Color.WHITE, 0))
