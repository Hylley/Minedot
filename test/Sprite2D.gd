extends Sprite2D


func _ready() -> void:
	set_texture(PackerSurface.update_atlas())


func _process(_delta: float) -> void:
	pass
