@tool
extends Node3D
class_name FragmentManager

const WORLD_OFFSET = Vector3i(-8, -16, -8)
const DIMENSIONS = Vector3i(16, 16, 16)

static var fragment_scene = load('res://Scenes/World/fragment.tscn')
static var active_fragments = {}

func instantiate_fragment(world_position : Vector3i):
	var new_fragment = fragment_scene.instantiate()
	# var new_fragment_position = world_position + WORLD_OFFSET
	new_fragment.cubes = Overworld.get_simple_terrain_data()
	add_child(new_fragment)
	new_fragment.global_position = world_position + WORLD_OFFSET
	new_fragment.render()

func _ready():
	instantiate_fragment(Vector3i(0, 0, 0))
