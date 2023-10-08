class_name Overworld

static func get_simple_terrain_data(fragment_global_position : Vector3) -> Array:
	var cubes := []
	cubes.resize(FragmentManager.DIMENSIONS.x)
	for x in range(0, FragmentManager.DIMENSIONS.x):
		cubes[x] = []
		cubes[x].resize(FragmentManager.DIMENSIONS.y)
		for y in range(0, FragmentManager.DIMENSIONS.y):
			cubes[x][y] = []
			cubes[x][y].resize(FragmentManager.DIMENSIONS.z)
			for z in range(0, FragmentManager.DIMENSIONS.z):
				var position := fragment_global_position + Vector3(x, y, z)

				if position.y == -1:
					cubes[x][y][z] = Cube.State.grass
					continue

				if position.y < -1 and position.y > -5:
					cubes[x][y][z] = Cube.State.dirt
					continue

				if position.y <= -5:
					cubes[x][y][z] = Cube.State.stone
					continue

				cubes[x][y][z] = Cube.State.air

	return cubes
