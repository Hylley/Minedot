class_name Overworld

static func get_simple_terrain_data() -> Array:
	var cubes := []
	cubes.resize(FragmentManager.DIMENSIONS.x)
	for x in range(0, FragmentManager.DIMENSIONS.x):
		cubes[x] = []
		cubes[x].resize(FragmentManager.DIMENSIONS.y)
		for y in range(0, FragmentManager.DIMENSIONS.y):
			cubes[x][y] = []
			cubes[x][y].resize(FragmentManager.DIMENSIONS.z)
			for z in range(0, FragmentManager.DIMENSIONS.z):
				if y > 9:
					cubes[x][y][z] = Cube.State.air
					continue

				if y == 9:
					cubes[x][y][z] = Cube.State.grass
					continue

				cubes[x][y][z] = Cube.State.stone

	return cubes
