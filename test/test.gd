extends Node
class_name Test

@onready var world  = $World

func _ready() -> void:
	render_test()

func render_test() -> void:
	world.initialize(Vector3i(1, 1, 1), true, true, Test.fragdata_full_solid_stone, self)
	var fragment : StaticBody3D = world.test_render()

	print('[Rendering (1x1x1) fragment]')
	var vertices : int = fragment.mesh_instance.mesh.get_faces().size()
	@warning_ignore('integer_division')
	print(str(vertices) + ' vertices adding up to ' + str(vertices / 3) + ' triangles to make ' + str(vertices / 3 / 2) + ' faces of one cube.')

	if vertices < 3:
		print('There are no faces being rendered.')
		return;

	if vertices > 24: print('There are too many useless vertices being loaded into memory.')

	print('')


# Static methods ————————————————————————————

static func fragdata_random_stone(_fragment_global_position : Vector3i, size : Vector3i) -> Array:
	var cubes = []; cubes.resize(size.x)
	for x in range(0, size.x):
		cubes[x] = []; cubes[x].resize(size.y)
		for y in range(0, size.y):
			cubes[x][y] = []; cubes[x][y].resize(size.z)
			for z in range(0, size.z):
				if randi() % 2 == 0:
					cubes[x][y][z] = Placeable.state.stone
				else:
					cubes[x][y][z] = Placeable.state.air

	return cubes


static func fragdata_full_solid_stone(_fragment_global_position : Vector3i, size : Vector3i):
	var cubes = []; cubes.resize(size.x)
	for x in range(0, size.x):
		cubes[x] = []; cubes[x].resize(size.y)
		for y in range(0, size.y):
			cubes[x][y] = []; cubes[x][y].resize(size.z)
			for z in range(0, size.z):
				cubes[x][y][z] = Placeable.state.stone

	return cubes
