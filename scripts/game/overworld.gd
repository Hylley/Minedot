extends Node3D

@onready var world  = $World
@onready var player = $Player


func _ready() -> void:
	world.initialize(Vector3i(16, 16, 16), true, false, Test.fragdata_full_solid_stone, player)
