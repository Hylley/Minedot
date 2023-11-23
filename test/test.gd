extends Node

@onready var world  = $World

func data_1x(_fragment_global_position : Vector3):
	var cubes = []
	cubes.resize(1); cubes[0] = []
	cubes[0].resize(1); cubes[0][0] = []
	cubes[0][0].resize(1);
	cubes[0][0][0] = Placeable.state.stone
	return cubes

func _ready() -> void:
	render_test()

func render_test():
	world.initialize(Vector3i(1, 1, 1), true, true, data_1x, self)
	var fragment : StaticBody3D = world.test_render()

	print('[Rendering (1x1x1) fragment]')
	var vertices : int = fragment.mesh_instance.mesh.get_faces().size()
	@warning_ignore('integer_division')
	print(str(vertices) + ' vertices adding up to ' + str(vertices / 3) + ' triangles to make ' + str(vertices / 3 / 2) + ' faces of one cube.')

	if vertices == 0:
		print('There are no meshes being rendered.')
		return;

	if vertices > 8: print('There are too many useless vertices being loaded into memory.')

	print('')
