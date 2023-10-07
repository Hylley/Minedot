extends StaticBody3D
class_name Fragment

# relative_position -> positions inside the fragment (0 up to 15);
# global_position	-> global world positions;

# Rendering
var cubes := []
var surface := SurfaceTool.new()
var mesh : ArrayMesh = null
var mesh_instance : MeshInstance3D = null
var rng := RandomNumberGenerator.new()

func render() -> void:
	if mesh_instance != null:
		mesh_instance.queue_free()
		mesh_instance = null

	mesh = ArrayMesh.new()
	mesh_instance = MeshInstance3D.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_smooth_group(-1)

	for x in cubes.size():
		for y in cubes[x].size():
			for z in cubes[x][y].size():
				render_cube(cubes[x][y][z], Vector3i(x, y, z))

	surface.generate_normals(false)
	surface.set_material(Cube.MATERIAL)
	surface.commit(mesh)
	mesh_instance.set_mesh(mesh)

	add_child(mesh_instance)
	mesh_instance.create_trimesh_collision()

func render_cube(cube_state : Cube.State, relative_position : Vector3i) -> void:
	if cube_state == null or cube_state == Cube.State.air:
		return

	if is_transparent(relative_position + Vector3i(0, 1, 0)):
		create_face(Cube.TOP_FACE, relative_position,
					Cube.MAP[cube_state][Cube.Details.top_texture], Cube.MAP[cube_state][Cube.Details.rotate_uv_y])
	if is_transparent(relative_position - Vector3i(0, 1, 0)):
		create_face(Cube.BOTTOM_FACE, relative_position,
					Cube.MAP[cube_state][Cube.Details.bottom_texture], Cube.MAP[cube_state][Cube.Details.rotate_uv_y])

	if is_transparent(relative_position + Vector3i(1, 0, 0)):
		create_face(Cube.RIGHT_FACE, relative_position,
					Cube.MAP[cube_state][Cube.Details.right_texture], Cube.MAP[cube_state][Cube.Details.rotate_uv_x])
	if is_transparent(relative_position - Vector3i(1, 0, 0)):
		create_face(Cube.LEFT_FACE, relative_position,
					Cube.MAP[cube_state][Cube.Details.left_texture], Cube.MAP[cube_state][Cube.Details.rotate_uv_x])

	if is_transparent(relative_position + Vector3i(0, 0, 1)):
		create_face(Cube.FRONT_FACE, relative_position,
					Cube.MAP[cube_state][Cube.Details.front_texture], Cube.MAP[cube_state][Cube.Details.rotate_uv_z])
	if is_transparent(relative_position - Vector3i(0, 0, 1)):
		create_face(Cube.BACK_FACE, relative_position,
					Cube.MAP[cube_state][Cube.Details.back_texture], Cube.MAP[cube_state][Cube.Details.rotate_uv_z])

func is_transparent(relative_position : Vector3i) -> bool:
	if Fragment.is_out_of_bounds(relative_position):
		return Cube.MAP[FragmentManager.get_global_cube_state(Vector3i(global_position) + relative_position)][Cube.Details.is_transparent]
	return Cube.MAP[cubes[relative_position.x][relative_position.y][relative_position.z]][Cube.Details.is_transparent]

static func is_out_of_bounds(relative_position : Vector3i) -> bool:
	return relative_position.x < 0 or relative_position.x >= FragmentManager.DIMENSIONS.x or \
	   relative_position.y < 0 or relative_position.y >= FragmentManager.DIMENSIONS.y or \
	   relative_position.z < 0 or relative_position.z >= FragmentManager.DIMENSIONS.z

func create_face(respective_vertices : Array, relative_position : Vector3i, texture_position : Vector2i, rotate_texture : bool) -> void:
	var a : Vector3i = Cube.VERTICES[respective_vertices[0]] + relative_position
	var b : Vector3i = Cube.VERTICES[respective_vertices[1]] + relative_position
	var c : Vector3i = Cube.VERTICES[respective_vertices[2]] + relative_position
	var d : Vector3i = Cube.VERTICES[respective_vertices[3]] + relative_position

	var size := Vector2(1.0 / Cube.TEXTURE_ATLAS_SIZE.x, 1.0 / Cube.TEXTURE_ATLAS_SIZE.y)
	var offset := Vector2(texture_position) / Vector2(Cube.TEXTURE_ATLAS_SIZE)
	var uv := [
		offset + Vector2(0, 0),
		offset + Vector2(0, size.y),
		offset + size,
		offset + Vector2(size.x, 0)
	]
	uv = rotate_uv(uv, relative_position) if rotate_texture else uv

	surface.add_triangle_fan(([a, b, c]), ([uv[0], uv[1], uv[2]]))
	surface.add_triangle_fan(([a, c, d]), ([uv[0], uv[2], uv[3]]))

func rotate_uv(default_uv_array : Array, relative_position : Vector3i) -> Array:
	rng.seed = int(global_position.length_squared() + relative_position.length_squared())
	var pivot := rng.randi() % default_uv_array.size() # Chose a random index from the array
	var rotated_uvs := default_uv_array.slice(pivot, default_uv_array.size()) # Create a new split array with the random index item as the first
	rotated_uvs.append_array(default_uv_array.slice(0, pivot)) # Append at the end the items that came before
	# This will essensialy rotate the uv, in other words, rotate the texture

	if pivot % 2 == 0: # 50 chance to clockwise, 50 to counter-clockwise. But I really dunno if this really affects smt
		rotated_uvs.reverse()

	return rotated_uvs

func change_cube(local_position : Vector3i, cube_state : Cube.State) -> void:
	if cube_state == Cube.State.air: generate_break_cpu_particle(global_position + Vector3(local_position) + Vector3(.5, .5, .5), cubes[local_position.x][local_position.y][local_position.z])
	cubes[local_position.x][local_position.y][local_position.z] = cube_state

	render()

func generate_break_cpu_particle(new_particle_position : Vector3, cube_state : Cube.State):
	var new_particle : Object = FragmentManager.cube_break_particle.instantiate()

	var box := BoxMesh.new()
	box.size = Vector3(.1, .1, .1)
	new_particle.mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, box.get_mesh_arrays())

	var mdt = MeshDataTool.new()
	mdt.create_from_surface(new_particle.mesh, 0)
	mdt.set_material(Cube.MATERIAL)

	var offset := Vector2(Cube.MAP[cube_state][Cube.DETAILS_TEXTURE_FACES[randi() % Cube.DETAILS_TEXTURE_FACES.size()]]) / Vector2(Cube.TEXTURE_ATLAS_SIZE)
	var size := Vector2(1.0 / Cube.TEXTURE_ATLAS_SIZE.x, 1.0 / Cube.TEXTURE_ATLAS_SIZE.y)

	for i in range(mdt.get_vertex_count()):
		var uv := mdt.get_vertex_uv(i)
		uv = uv * size + offset
		mdt.set_vertex_uv(i, uv)

	new_particle.mesh.clear_surfaces()
	mdt.commit_to_surface(new_particle.mesh)

	add_child(new_particle)
	new_particle.global_position = new_particle_position
	new_particle.emitting = true
	get_tree().create_timer(new_particle.lifetime, false).connect("timeout", new_particle.queue_free)
