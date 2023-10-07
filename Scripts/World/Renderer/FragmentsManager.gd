extends Node3D
class_name FragmentManager

const DIMENSIONS := Vector3i(16, 16, 16)
@warning_ignore('integer_division')
const WORLD_OFFSET := Vector3i(-(DIMENSIONS.x / 2), -DIMENSIONS.y, -(DIMENSIONS.z / 2))
static var fragment_scene := load('res://Scenes/World/Fragment.tscn')
static var active_fragments := {}

# Decoration
static var cube_break_particle = load('res://Scenes/World/Decoration/BreakBlockParticle.tscn')

func _ready() -> void:
	instantiate_fragment(Vector3i(0, 0, 0) + WORLD_OFFSET)
	instantiate_fragment(Vector3i(0, 0, DIMENSIONS.z) + WORLD_OFFSET)
	instantiate_fragment(Vector3i(0, 0, -DIMENSIONS.z) + WORLD_OFFSET)
	instantiate_fragment(Vector3i(DIMENSIONS.x, 0, 0) + WORLD_OFFSET)
	instantiate_fragment(Vector3i(-DIMENSIONS.x, 0, 0) + WORLD_OFFSET)

	for fragment in active_fragments: active_fragments[fragment].render()

func instantiate_fragment(world_position : Vector3i) -> void:
	var new_fragment : Object = fragment_scene.instantiate()
	new_fragment.cubes = Overworld.get_simple_terrain_data()
	add_child(new_fragment)
	new_fragment.global_position = world_position
	active_fragments[world_position] = new_fragment

static func place_cube(fragment_position : Vector3i, cube_global_position : Vector3i, cube_state : Cube.State) -> void:
	var cube_relative_position := cube_global_position - fragment_position

	if Fragment.is_out_of_bounds(cube_relative_position):
		fragment_position = predict_fragment_snapped_position(cube_global_position)
		if fragment_position == Vector3i.ZERO: return
		cube_relative_position = cube_relative_position % DIMENSIONS

	var fragment : Object = active_fragments[fragment_position]
	fragment.change_cube(cube_relative_position, cube_state)

	# The f(x) = (2 / k) * x - 1 linear function would be a smater way to
	# implement the same thing shorter. It returns 1 when x == k and -1 when
	# x == 0 so u can just change the if statment for cube_relative_position,x/y/z
	# % 15 == 0 and multiply DIMENSIONS.x/y/z for the function result. That
	# make only one if statement for each vector. But I really don't know if
	#this is better for performance or don't.
	if cube_relative_position.x == 0:
		update_fragment(fragment_position - Vector3i(DIMENSIONS.x, 0, 0))
	elif cube_relative_position.x == 15:
		update_fragment(fragment_position + Vector3i(DIMENSIONS.x, 0, 0))

	if cube_relative_position.y == 0:
		update_fragment(fragment_position - Vector3i(0, DIMENSIONS.y, 0))
	elif cube_relative_position.y == 15:
		update_fragment(fragment_position + Vector3i(0, DIMENSIONS.y, 0))

	if cube_relative_position.z == 0:
		update_fragment(fragment_position - Vector3i(0, 0, DIMENSIONS.z))
	elif cube_relative_position.z == 15:
		update_fragment(fragment_position + Vector3i(0, 0, DIMENSIONS.z))

static func break_cube(fragment_position : Vector3, focusing : Vector3i) -> void:
	FragmentManager.place_cube(fragment_position, focusing, Cube.State.air)

static func predict_fragment_snapped_position(reference_position : Vector3i) -> Vector3i:
	var snapped_position : Vector3i = Vector3i(floor(Vector3(reference_position - WORLD_OFFSET) / Vector3(DIMENSIONS)) * Vector3(DIMENSIONS)) + WORLD_OFFSET

	return snapped_position if snapped_position in active_fragments else Vector3i.ZERO

static func get_global_cube_state(cube_global_position : Vector3i) -> Cube.State:
	var predict := FragmentManager.predict_fragment_snapped_position(cube_global_position)
	if predict == Vector3i.ZERO: return Cube.State.air

	var relative_position : Vector3i = (predict - cube_global_position).abs()
	return active_fragments[predict].cubes[relative_position.x][relative_position.y][relative_position.z]

static func update_fragment(fragment_position : Vector3i):
	if not fragment_position in active_fragments: return
	active_fragments[fragment_position].render()
