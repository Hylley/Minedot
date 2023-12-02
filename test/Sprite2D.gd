extends Sprite2D


func _ready() -> void:
	set_texture(Packer.generate_atlas())


func _process(_delta: float) -> void:
	pass
