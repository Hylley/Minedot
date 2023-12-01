@tool
extends NinePatchRect
class_name Slot

enum type
{
	placeable,
	artifact
}

@onready var icon_placeholder  := %Icon
@onready var count_label := %Count
var entry : int = -1

func define(_entry : int, _type : type, count : int) -> void:
	if _type == type.placeable:
		var state : Dictionary = Resources.state(_entry)
		if not state.index_in_inventory:
			push_warning('Trying to index an indexable item in inventory: ' + Resources.state(_entry).full_title)
			return

		if state.is_stackable: set_count(count)

		set_icon(Resources.get_state_texture2d(state.textures.upper_texture))
	elif _type == type.artifact: pass

func get_entry():
	if entry >= 0: return entry
	else: return null

func set_icon(new_texture : Texture2D) -> void: icon_placeholder.set_texture(new_texture)
func set_count(new_count : int) -> void: count_label.set_text(str(new_count))
func show_frame() -> void: self.set_self_modulate(Color(Color.WHITE, 1))
func hide_frame() -> void: self.set_self_modulate(Color(Color.WHITE, 0))
