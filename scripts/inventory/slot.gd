@tool
extends NinePatchRect
class_name Slot

@onready var icon  := %Icon
@onready var count := %Count


func set_icon(new_texture : Texture2D) -> void: icon.set_texture(new_texture)
func set_count(new_count : int) -> void: count.set_text(str(new_count))
func show_frame() -> void: self.set_self_modulate(Color(Color.WHITE, 1))
func hide_frame() -> void: self.set_self_modulate(Color(Color.WHITE, 0))
