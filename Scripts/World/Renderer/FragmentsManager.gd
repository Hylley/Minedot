extends Node3D
class_name FragmentManager

const DIMENSIONS := Vector3i(16, 16, 16); @warning_ignore('integer_division')
const LOAD_RANGE := 32
const HEIGHT_GROW := 6 # Will load half of this numer of fragments at the top and half at the bottom of the center fragment (aka 7 fragments of height)

static var generation_thread : Thread; static var keep_generating = true

static var fragment_scene := preload('res://Scenes/World/Fragment.tscn')
static var active_fragments := {}
# static var inactive_fragments := {}

@onready var player = get_node('/root/World/Player')

# Decoration
static var cube_break_particle = load('res://Scenes/World/Decoration/BreakBlockParticle.tscn')

# Debug
static var one_time_generation = false

# Main methods

func _ready() -> void:
	Overworld.set_seed(randi())
	generation_thread = Thread.new()
	generation_thread.start(world_generation_thread)

func _process(_delta : float) -> void:
	current_plater_fragment_position = FragmentManager.snap_to_grid(player.get_global_position())

func _exit_tree():
	keep_generating = false;
	generation_thread.wait_to_finish()

func world_generation_thread():
	# There is A LOT of room to improvement. Right know the rendering process
	# only accounts for fragments that already exists. Wich means that if a new
	# fragment is added, the other ones will not be called neither notified of
	# this change. Wich basically means that there is a lot of unecessary faces
	# being rendered every time a new fragment is generated.
	# I really don't know how to fix that, since the generation process is
	# dealt in another thread, the code just can't update a fragment that is
	# already in the main process thread.

	var first_load = true
	while keep_generating:
		if not player_switch_fragment():
			if not first_load and one_time_generation: return
			if not first_load: continue
			first_load = false

		# Spiral fragment generation
		var pivot := current_plater_fragment_position
		var direction : Vector2i = Vector2i(1, 0)
		var step := 1
		var steps_in_direction := 1
		var generation_queue := []
		var rendering_queue := []
		var keep_loaded := []

		# Generate new fragments
		for i in range(LOAD_RANGE):
			keep_loaded.append(pivot)
			if not pivot in active_fragments: generation_queue.append(pivot)

			for j in range(int(HEIGHT_GROW / 2.)):
				var top_fragment_position := pivot + Vector3i(0, j + 1, 0) * DIMENSIONS; keep_loaded.append(top_fragment_position)
				var bottom_fragment_position := pivot - Vector3i(0, j + 1, 0) * DIMENSIONS; keep_loaded.append(bottom_fragment_position)
				if not top_fragment_position in active_fragments: generation_queue.append(top_fragment_position)
				if not bottom_fragment_position in active_fragments: generation_queue.append(bottom_fragment_position)

			pivot += Vector3i(direction.x, 0, direction.y) * DIMENSIONS
			steps_in_direction -= 1
			if steps_in_direction == 0: # Spiral iteration logic
				# Change direction and reset steps
				if direction == Vector2i(1, 0):  # Right
					direction = Vector2i(0, 1)
				elif direction == Vector2i(0, 1):
					direction = Vector2i(-1, 0)
					step += 1
				elif direction == Vector2i(-1, 0):  # Left
					direction = Vector2i(0, -1)
				elif direction == Vector2i(0, -1):  # Up
					direction = Vector2i(1, 0)
					step += 1
				steps_in_direction = step  # Reset steps for the new direction

		for fragment in generation_queue:
				var fragment_instance := FragmentManager.instantiate_fragment(fragment)
				fragment_instance.update_terrain(Overworld.get_abstract_terrain_data(fragment))
				rendering_queue.append(fragment_instance)

		for fragment in rendering_queue:
			fragment.render()
			fragment.set_process_thread_group(ProcessThreadGroup.PROCESS_THREAD_GROUP_MAIN_THREAD)

			call_deferred('add_child', fragment)

		# Delete the far-away ones
		for fragment in active_fragments.keys():
			if fragment in keep_loaded: continue
			active_fragments[fragment].queue_free()
			active_fragments.erase(fragment)
# Abstractions

var current_plater_fragment_position : Vector3i
var last_player_fragment_position    : Vector3i
func player_switch_fragment() -> bool:
	var result := current_plater_fragment_position != last_player_fragment_position
	last_player_fragment_position = current_plater_fragment_position
	return result

# Fragment manipulation

static func instantiate_fragment(world_position : Vector3i) -> Object:
	if world_position in active_fragments: print("Error: Fragment already exists at ", world_position)

	var new_fragment : Object = fragment_scene.instantiate()
	new_fragment.set_as_top_level(true)
	new_fragment.set_world_position(world_position)
	new_fragment.set_visible(false)
	active_fragments[world_position] = new_fragment

	return new_fragment

static func snap_to_grid(reference_position : Vector3i) -> Vector3i:
	var division := Vector3(reference_position) / Vector3(DIMENSIONS)
	var flooored : Vector3 = floor(division)
	var multiply := flooored * Vector3(DIMENSIONS)

	return Vector3i(multiply)

static func update_fragment_if_exists(fragment_position : Vector3i):
	if not fragment_position in active_fragments: return
	active_fragments[fragment_position].render()


# Cube methods

static func place_cube(fragment_position : Vector3i, cube_global_position : Vector3i, cube_state : Cube.State) -> void:
	var cube_relative_position := cube_global_position - fragment_position

	if Fragment.is_out_of_bounds(cube_relative_position):
		fragment_position = snap_to_grid(cube_global_position)
		if not fragment_position in active_fragments: return
		cube_relative_position = cube_relative_position % DIMENSIONS

	var fragment : Object = active_fragments[fragment_position]
	fragment.change_cube(cube_relative_position, cube_state)

	# The f(x) = (2 / k) * x - 1 linear function would be a smater way to
	# implement the same thing shorter. It returns 1 when x == k and -1 when
	# x == 0 so u can just change the if statment for cube_relative_position,x/y/z
	# % 15 == 0 and multiply DIMENSIONS.x/y/z for the function result. That
	# make only one if statement for each vector. But I really don't know if
	# this is better for performance or don't.
	if cube_relative_position.x == 0:
		FragmentManager.update_fragment_if_exists(fragment_position - Vector3i(DIMENSIONS.x, 0, 0))
	elif cube_relative_position.x == 15:
		FragmentManager.update_fragment_if_exists(fragment_position + Vector3i(DIMENSIONS.x, 0, 0))

	if cube_relative_position.y == 0:
		FragmentManager.update_fragment_if_exists(fragment_position - Vector3i(0, DIMENSIONS.y, 0))
	elif cube_relative_position.y == 15:
		FragmentManager.update_fragment_if_exists(fragment_position + Vector3i(0, DIMENSIONS.y, 0))

	if cube_relative_position.z == 0:
		FragmentManager.update_fragment_if_exists(fragment_position - Vector3i(0, 0, DIMENSIONS.z))
	elif cube_relative_position.z == 15:
		FragmentManager.update_fragment_if_exists(fragment_position + Vector3i(0, 0, DIMENSIONS.z))

static func break_cube(fragment_position : Vector3, focusing : Vector3i) -> void:
	FragmentManager.place_cube(fragment_position, focusing, Cube.State.air)

static func get_global_cube_state(cube_global_position : Vector3i) -> Cube.State:
	var predict := FragmentManager.snap_to_grid(cube_global_position)
	if not predict in active_fragments: return Cube.State.air

	var relative_position : Vector3i = cube_global_position - predict
	return active_fragments[predict].cubes[relative_position.x][relative_position.y][relative_position.z]
