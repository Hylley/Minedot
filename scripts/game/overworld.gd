extends Node3D

@onready var world  = $World
@onready var player = $Player


func _ready() -> void:
	world.initialize(Vector3i(16, 16, 16), true, true, Test.fragdata_superflat_stone, player)
	world.first_load.connect(dump_player)

func dump_player():
	player.global_position = world.get_spawn_point() + Vector3(.5, 1, .5)
