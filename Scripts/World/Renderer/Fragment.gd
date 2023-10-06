@tool
extends StaticBody3D
class_name Fragment

# relative_position = positions inside the fragment (0 up to 15);
# global_position	= global world positions;

var cubes = []
var surface = SurfaceTool.new()
var mesh = null
var mesh_instance = null

func render():
	if mesh_instance != null:
		mesh_instance.queue_free()
		mesh_instance = null

	mesh = ArrayMesh.new()
	mesh_instance = MeshInstance3D.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_smooth_group(-1) # Comment this line for dinamic lightning

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

func render_cube(cube_state : Cube.State, relative_position : Vector3i):
	if cube_state == null or cube_state == Cube.State.air:
		return

	if is_transparent(relative_position + Vector3i(0, 1, 0)):
		create_face(Cube.TOP_FACE, relative_position,
					Cube.MAP[cube_state][Cube.Details.top_texture])
	if is_transparent(relative_position - Vector3i(0, 1, 0)):
		create_face(Cube.BOTTOM_FACE, relative_position,
					Cube.MAP[cube_state][Cube.Details.bottom_texture])

	if is_transparent(relative_position + Vector3i(1, 0, 0)):
		create_face(Cube.RIGHT_FACE, relative_position,
					Cube.MAP[cube_state][Cube.Details.right_texture])
	if is_transparent(relative_position - Vector3i(1, 0, 0)):
		create_face(Cube.LEFT_FACE, relative_position,
					Cube.MAP[cube_state][Cube.Details.left_texture])

	if is_transparent(relative_position + Vector3i(0, 0, 1)):
		create_face(Cube.FRONT_FACE, relative_position,
					Cube.MAP[cube_state][Cube.Details.front_texture])
	if is_transparent(relative_position - Vector3i(0, 0, 1)):
		create_face(Cube.BACK_FACE, relative_position,
					Cube.MAP[cube_state][Cube.Details.back_texture])

func is_transparent(relative_position : Vector3i):
	if Fragment.is_out_of_bounds(relative_position): return true
	return Cube.MAP[cubes[relative_position.x][relative_position.y][relative_position.z]][Cube.Details.is_transparent]

static func is_out_of_bounds(relative_position : Vector3i) -> bool:
	return relative_position.x < 0 or relative_position.x >= FragmentManager.DIMENSIONS.x or \
	   relative_position.y < 0 or relative_position.y >= FragmentManager.DIMENSIONS.y or \
	   relative_position.z < 0 or relative_position.z >= FragmentManager.DIMENSIONS.z

func create_face(respective_vertices : Array, relative_position : Vector3i, texture_position : Vector2i):
	var a = Cube.VERTICES[respective_vertices[0]] + relative_position
	var b = Cube.VERTICES[respective_vertices[1]] + relative_position
	var c = Cube.VERTICES[respective_vertices[2]] + relative_position
	var d = Cube.VERTICES[respective_vertices[3]] + relative_position

	var uv = uv_calc(
		Vector2(texture_position) / Vector2(Cube.TEXTURE_ATLAS_SIZE),
		Vector2(1.0 / Cube.TEXTURE_ATLAS_SIZE.x, 1.0 / Cube.TEXTURE_ATLAS_SIZE.y)
	)

	surface.add_triangle_fan(([a, b, c]), ([uv[0], uv[1], uv[2]]))
	surface.add_triangle_fan(([a, c, d]), ([uv[0], uv[2], uv[3]]))

func uv_calc(offset : Vector2, size : Vector2):
	var uvs = [
		offset + Vector2(0, 0),
		offset + Vector2(0, size.y),
		offset + size,
		offset + Vector2(size.x, 0)
	]

	return uvs

