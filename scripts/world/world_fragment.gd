extends Node3D
class_name Fragment

# Variables ———————————————————————————————————
static var SIZE : Vector3i
var cubes := []

# Rendering variables —————————————————————————
var mesh : ArrayMesh
var mesh_instance : MeshInstance3D
var surface := SurfaceTool.new()

# Rendering methods ————————————————————————————

func render(_cubes : Array) -> void:
	cubes = _cubes

	if mesh_instance == null: mesh_instance = get_node('MeshInstance3D')
	else: mesh_instance.set_mesh(null)

	mesh = ArrayMesh.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_smooth_group(-1)

	for x in cubes.size():
		for y in cubes[x].size():
			for z in cubes[x][y].size():
				render_cube(cubes[x][y][z], Vector3i(x, y, z))

	surface.generate_normals(false)
	surface.set_material(Placeable.MATERIAL)
	surface.commit(mesh)
	mesh_instance.set_mesh(mesh)

	if mesh.get_surface_count() != 0: mesh_instance.call_deferred('create_trimesh_collision')

	visible = true


func render_cube(cube : Placeable.state, relative_position : Vector3i) -> void:
	if cube == null or cube == Placeable.state.air: return

	var top_cube := relative_position + Vector3i(0, 1, 0)
	var bot_cube := relative_position - Vector3i(0, 1, 0)
	var rig_cube := relative_position + Vector3i(1, 0, 0)
	var lef_cube := relative_position - Vector3i(1, 0, 0)
	var frn_cube := relative_position + Vector3i(0, 0, 1)
	var bak_cube := relative_position - Vector3i(0, 0, 1)

	if Fragment.is_transparent(get_state(top_cube)):
		create_face(Placeable.TOP_FACE, relative_position,
					Placeable.MAP[cube][Placeable.top_texture], Placeable.MAP[cube][Placeable.rotate_uv_y])
	if Fragment.is_transparent(get_state(bot_cube)):
		create_face(Placeable.BOTTOM_FACE, relative_position,
					Placeable.MAP[cube][Placeable.bottom_texture], Placeable.MAP[cube][Placeable.rotate_uv_y])

	if Fragment.is_transparent(get_state(rig_cube)):
		create_face(Placeable.RIGHT_FACE, relative_position,
					Placeable.MAP[cube][Placeable.right_texture], Placeable.MAP[cube][Placeable.rotate_uv_x])
	if Fragment.is_transparent(get_state(lef_cube)):
		create_face(Placeable.LEFT_FACE, relative_position,
					Placeable.MAP[cube][Placeable.left_texture], Placeable.MAP[cube][Placeable.rotate_uv_x])

	if Fragment.is_transparent(get_state(frn_cube)):
		create_face(Placeable.FRONT_FACE, relative_position,
					Placeable.MAP[cube][Placeable.front_texture], Placeable.MAP[cube][Placeable.rotate_uv_z])
	if Fragment.is_transparent(get_state(bak_cube)):
		create_face(Placeable.BACK_FACE, relative_position,
					Placeable.MAP[cube][Placeable.back_texture], Placeable.MAP[cube][Placeable.rotate_uv_z])


func create_face(respective_vertices : Array, relative_position : Vector3i, texture_position : Vector2i, rotate_texture : bool) -> void:
	var a : Vector3i = Placeable.VERTICES[respective_vertices[0]] + relative_position
	var b : Vector3i = Placeable.VERTICES[respective_vertices[1]] + relative_position
	var c : Vector3i = Placeable.VERTICES[respective_vertices[2]] + relative_position
	var d : Vector3i = Placeable.VERTICES[respective_vertices[3]] + relative_position

	var size := Vector2(1.0 / Placeable.RELATIVE_ATLAS_SIZE.x, 1.0 / Placeable.RELATIVE_ATLAS_SIZE.y)
	var offset := Vector2(texture_position) / Vector2(Placeable.RELATIVE_ATLAS_SIZE)
	var uv := [
		offset + Vector2(0, 0),
		offset + Vector2(0, size.y),
		offset + size,
		offset + Vector2(size.x, 0)
	]
	uv = Fragment.rotate_uv(uv, relative_position) if rotate_texture and UserPreferences.get_preference('decoration', 'rotate_texture', true) else uv

	surface.add_triangle_fan(([a, b, c]), ([uv[0], uv[1], uv[2]]))
	surface.add_triangle_fan(([a, c, d]), ([uv[0], uv[2], uv[3]]))


func get_state(relative_position):
	if Fragment.is_out_of_bounds(relative_position): return Placeable.state.air
	return cubes[relative_position.x][relative_position.y][relative_position.z]


# Static methods —————————————————————————

static func is_out_of_bounds(relative_position : Vector3i) -> bool:
	return relative_position.x < 0 or relative_position.x >= Fragment.SIZE.x or \
	   relative_position.y < 0 or relative_position.y >= Fragment.SIZE.y or \
	   relative_position.z < 0 or relative_position.z >= Fragment.SIZE.z


static func is_transparent(cube : Placeable.state) -> bool:
	return Placeable.MAP[cube][Placeable.is_transparent]


static func rotate_uv(default_uv_array : Array, cube_world_position : Vector3i) -> Array:
	World.random.seed = int(cube_world_position.length_squared())
	var pivot := World.random.randi() % default_uv_array.size() # Chose a random index from the array

	var rotated_uvs := default_uv_array.slice(pivot, default_uv_array.size()) # Create a new split array with the random index item as the first
	rotated_uvs.append_array(default_uv_array.slice(0, pivot)) # Append at the end the items that came before
	# This will rotate the uv, essensialy, rotate the texture
	if pivot % 2 == 0: rotated_uvs.reverse()

	return rotated_uvs
