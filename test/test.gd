extends Node
class_name Test

var world_tscn  = preload('res://scenes/world.tscn')

var vertices : int
func _ready() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MINIMIZED)

	await vertice_test()
	await face_test()

	get_tree().quit()


func vertice_test() -> void:
	await refresh()
	var world : Node3D = world_tscn.instantiate()
	world.CIRCULAR_RANGE = 0
	add_child(world)

	world.initialize(Vector3i(1, 1, 1), true, false, Test.fragdata_full_solid_stone, self)
	await world.first_load

	for fragment_position in world.active_fragments:
		var fragment : StaticBody3D = world.active_fragments[fragment_position]

		print('[Rendering (1x1x1) fragment]')
		vertices = fragment.mesh_instance.mesh.get_faces().size()
		if vertices == 0:
			push_warning('There are no meshes being rendered.')
			return;
		@warning_ignore('integer_division')
		print(str(vertices) + ' vertices adding up to ' + str(vertices / 3) + ' triangles to make ' + str(vertices / 3 / 2) + ' faces of one cube.')
		if vertices > 24 and vertices <=36: push_warning('There are many useless vertices being loaded into memory.\n')
		elif vertices > 36: push_error('What the fuck are you doing??.\n')

	return


func face_test() -> void:
	await refresh()
	var world : Node3D = world_tscn.instantiate()
	world.CIRCULAR_RANGE = 1
	add_child(world)

	world.initialize(Vector3i(1, 1, 1), true, false, Test.fragdata_full_solid_stone, self)

	print('[Rendering two (1x1x1) fragments]')

	await world.first_load
	var total_vertices := 0
	for fragment_position in world.active_fragments:
		var fragment : StaticBody3D = world.active_fragments[fragment_position]
		total_vertices += fragment.mesh_instance.mesh.get_faces().size()

	@warning_ignore('integer_division')
	if total_vertices / float(vertices) >= 2:
		push_warning('Hidden faces are being rendered between cubes.\n')
	else:
		push_warning('Hidden faces are *not* being rendered between cubes!\n')

	return


func refresh():
	for node in get_children():
		self.remove_child(node)
		node.queue_free()


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
