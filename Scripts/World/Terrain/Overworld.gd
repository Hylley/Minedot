class_name Overworld

static var noise = FastNoiseLite.new()
#noise.noise_type = FastNoiseLite.NoiseType.TYPE_SIMPLEX;

static func set_seed(_seed):
	noise.seed = _seed

static func get_abstract_terrain_data(fragment_global_position : Vector3):
	var cubes = []
	cubes.resize(FragmentManager.DIMENSIONS.x)
	for x in range(0, FragmentManager.DIMENSIONS.x):
		cubes[x] = []
		cubes[x].resize(FragmentManager.DIMENSIONS.y)
		for y in range(0, FragmentManager.DIMENSIONS.y):
			cubes[x][y] = []
			cubes[x][y].resize(FragmentManager.DIMENSIONS.z)
			for z in range(0, FragmentManager.DIMENSIONS.z):
				# Top layer = 15, bottom layer = 0
				var position := fragment_global_position + Vector3(x, y, z)
				var height = int((noise.get_noise_2d(position.x, position.z) + 1)/2 * FragmentManager.DIMENSIONS.y)

				if position.y < height / 2.:
					cubes[x][y][z] = Cube.State.stone
					continue
				if position.y < height:
					cubes[x][y][z] = Cube.State.dirt
					continue
				if position.y == height:
					cubes[x][y][z] = Cube.State.grass
					continue
				cubes[x][y][z] = Cube.State.air

	return cubes

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
