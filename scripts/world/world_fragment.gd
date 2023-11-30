extends Node3D
class_name Fragment

# Variables ———————————————————————————————————

static var SIZE  : Vector3i
static var WORLD : World
var cubes := []
var rendered : bool

# Rendering variables —————————————————————————

var mesh : ArrayMesh
var surface : SurfaceTool
var mesh_instance : MeshInstance3D

# Constants  ——————————————————————————————————

const VERTICES := \
[
	Vector3i(0, 0, 0),
	Vector3i(1, 0, 0),
	Vector3i(0, 1, 0),
	Vector3i(1, 1, 0),
	Vector3i(0, 0, 1),
	Vector3i(1, 0, 1),
	Vector3i(0, 1, 1),
	Vector3i(1, 1, 1)
]

const TOP_FACE    := [2, 3, 7, 6]
const BOTTOM_FACE := [0, 4, 5, 1]
const LEFT_FACE   := [6, 4, 0, 2]
const RIGHT_FACE  := [3, 1, 5, 7]
const FRONT_FACE  := [7, 5, 4, 6]
const BACK_FACE   := [2, 0, 1, 3]

# Rendering methods ————————————————————————————

func render(world_position : Vector3i, parent : Node3D = null) -> void:
	if cubes == []: return

	if mesh_instance != null:
		mesh_instance.queue_free()
		mesh_instance = null

	mesh = ArrayMesh.new()
	surface = SurfaceTool.new()
	mesh_instance = MeshInstance3D.new()

	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_smooth_group(-1)

	for x in cubes.size():
		for y in cubes[x].size():
			for z in cubes[x][y].size():
				render_cube(cubes[x][y][z], Vector3i(x, y, z), world_position)

	surface.generate_normals(false)
	surface.set_material(Resources.MATERIAL)
	surface.commit(mesh)
	mesh_instance.set_mesh(mesh)
	add_child(mesh_instance)

	if mesh.get_surface_count() != 0: mesh_instance.call_deferred('create_trimesh_collision')

	visible = true
	rendered = true

	if parent != null: call_deferred('switch_to_main_thread', parent, world_position)


func switch_to_main_thread(parent : Object, world_position : Vector3i) -> void:
	parent.add_child(self)
	set_as_top_level(true)
	set_process_thread_group(ProcessThreadGroup.PROCESS_THREAD_GROUP_MAIN_THREAD)
	set_global_position(world_position)


func refresh(world_position : Vector3i) -> void:
	if not rendered: return
	self.render(world_position)


func render_cube(state_index : int, relative_position : Vector3i, world_position : Vector3i) -> void:
	var state := Resources.state(state_index)
	if state == Resources.module.air: return

	var top_cube := relative_position + Vector3i(0, 1, 0)
	var bot_cube := relative_position - Vector3i(0, 1, 0)
	var rig_cube := relative_position + Vector3i(1, 0, 0)
	var lef_cube := relative_position - Vector3i(1, 0, 0)
	var frn_cube := relative_position + Vector3i(0, 0, 1)
	var bak_cube := relative_position - Vector3i(0, 0, 1)

	if Fragment.is_transparent(get_state(top_cube, world_position)):
		create_face(TOP_FACE, relative_position,
					state.textures.upper_texture, state.rotation_rules.upper_texture)
	if Fragment.is_transparent(get_state(bot_cube, world_position)):
		create_face(BOTTOM_FACE, relative_position,
					state.textures.lower_texture, state.rotation_rules.lower_texture)

	if Fragment.is_transparent(get_state(rig_cube, world_position)):
		create_face(RIGHT_FACE, relative_position,
					state.textures.right_texture, state.rotation_rules.right_texture)
	if Fragment.is_transparent(get_state(lef_cube, world_position)):
		create_face(LEFT_FACE, relative_position,
					state.textures.left_texture, state.rotation_rules.left_texture)

	if Fragment.is_transparent(get_state(frn_cube, world_position)):
		create_face(FRONT_FACE, relative_position,
					state.textures.front_texture, state.rotation_rules.front_texture)
	if Fragment.is_transparent(get_state(bak_cube, world_position)):
		create_face(BACK_FACE, relative_position,
					state.textures.back_texture, state.rotation_rules.back_texture)


func create_face(respective_vertices : Array, relative_position : Vector3i, texture_position : Vector2i, rotate_texture : bool) -> void:
	var a : Vector3i = VERTICES[respective_vertices[0]] + relative_position
	var b : Vector3i = VERTICES[respective_vertices[1]] + relative_position
	var c : Vector3i = VERTICES[respective_vertices[2]] + relative_position
	var d : Vector3i = VERTICES[respective_vertices[3]] + relative_position

	var size := Vector2(1.0 / Resources.RELATIVE_ATLAS_SIZE.x, 1.0 / Resources.RELATIVE_ATLAS_SIZE.y)
	var offset := Vector2(texture_position) / Vector2(Resources.RELATIVE_ATLAS_SIZE)
	var uv := [
		offset + Vector2(0, 0),
		offset + Vector2(0, size.y),
		offset + size,
		offset + Vector2(size.x, 0)
	]
	uv = Fragment.rotate_uv(uv, relative_position) if rotate_texture and UserPreferences.get_preference('decoration', 'rotate_texture', true) else uv

	surface.add_triangle_fan(([a, b, c]), ([uv[0], uv[1], uv[2]]))
	surface.add_triangle_fan(([a, c, d]), ([uv[0], uv[2], uv[3]]))


func get_state(relative_position : Vector3i, world_position : Vector3i) -> int:
	if Fragment.is_out_of_bounds(relative_position):
		return Fragment.WORLD.get_state_global(Vector3(world_position + relative_position))
	return cubes[relative_position.x][relative_position.y][relative_position.z]


func set_state(relative_position : Vector3i, world_position : Vector3i, new_state : int) -> void:
	cubes[relative_position.x][relative_position.y][relative_position.z] = new_state
	render(world_position)

# Static methods —————————————————————————

static func is_out_of_bounds(relative_position : Vector3i) -> bool:
	return relative_position.x < 0 or relative_position.x >= Fragment.SIZE.x or \
	   relative_position.y < 0 or relative_position.y >= Fragment.SIZE.y or \
	   relative_position.z < 0 or relative_position.z >= Fragment.SIZE.z


static func is_transparent(state_index : int) -> bool:
	return Resources.state(state_index).is_transparent


static func rotate_uv(default_uv_array : Array, cube_world_position : Vector3i) -> Array:
	World.random.seed = int(cube_world_position.length_squared())
	var pivot := World.random.randi() % default_uv_array.size() # Chose a random index from the array

	var rotated_uvs := default_uv_array.slice(pivot, default_uv_array.size()) # Create a new split array with the random index item as the first
	rotated_uvs.append_array(default_uv_array.slice(0, pivot)) # Append at the end the items that came before
	# This will rotate the uv, essensialy, rotate the texture
	if pivot % 2 == 0: rotated_uvs.reverse()

	return rotated_uvs
