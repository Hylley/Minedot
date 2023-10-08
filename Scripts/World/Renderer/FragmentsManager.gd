extends Node3D
class_name FragmentManager

const DIMENSIONS := Vector3i(16, 16, 16); @warning_ignore('integer_division')
const WORLD_OFFSET := Vector3i(-(DIMENSIONS.x / 2), -DIMENSIONS.y, -(DIMENSIONS.z / 2))
const LOAD_RANGE := 30
const HEIGHT_GROW := 6 # Will load half of this numer of fragments at the top and half at the bottom of the center fragment (aka 7 fragments of height)
const MAXIMUM_RENDER_THREADS = 7

static var fragment_scene := load('res://Scenes/World/Fragment.tscn')
static var active_fragments := {}
static var inactive_fragments := {}
static var active_threads := []

@onready var player = get_node('/root/World/Player')

# Decoration
static var cube_break_particle = load('res://Scenes/World/Decoration/BreakBlockParticle.tscn')

func _ready() -> void:
	var pivot = Vector3i.ZERO
	var direction : Vector2i = Vector2i(1, 0)
	var step := 1
	var steps_in_direction := 1

	for i in range(LOAD_RANGE):
		instantiate_fragment(pivot * 16 + WORLD_OFFSET);
		for j in range(HEIGHT_GROW / 2):
			instantiate_fragment((pivot + Vector3i(0, j, 0)) * 16 + WORLD_OFFSET)
			instantiate_fragment((pivot - Vector3i(0, j, 0)) * 16 + WORLD_OFFSET)

		pivot += Vector3i(direction.x, 0, direction.y)
		steps_in_direction -= 1

		if steps_in_direction == 0:
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

	for fragment in active_fragments: active_fragments[fragment].render()

var last_player_fragment_position : Vector3i
var current_plater_fragment_position : Vector3i
func _process(_delta : float) -> void:
	for thread in active_threads:
		#print(thread.is_alive)
		if thread.is_alive(): continue
		active_threads.erase(thread)

	current_plater_fragment_position = FragmentManager.snap_to_grid(player.global_position)
	if current_plater_fragment_position == last_player_fragment_position: return

	var pivot := current_plater_fragment_position
	var direction : Vector2i = Vector2i(1, 0)
	var step := 1
	var steps_in_direction := 1

	var keep_active := []
	for i in range(LOAD_RANGE):
		keep_active.append(pivot)
		if not pivot in active_fragments:
			recycle_inactive_fragment(pivot)

		for j in range(HEIGHT_GROW / 2):
			var top_fragment_position := pivot + Vector3i(0, j, 0) * DIMENSIONS
			var bot_fragment_position := pivot - Vector3i(0, j, 0) * DIMENSIONS
			keep_active.append(top_fragment_position)
			keep_active.append(bot_fragment_position)

			if not top_fragment_position in active_fragments:
				recycle_inactive_fragment(top_fragment_position)#.render()

			if not bot_fragment_position in active_fragments:
				recycle_inactive_fragment(bot_fragment_position)#.render()

		pivot += Vector3i(direction.x, 0, direction.y) * DIMENSIONS
		steps_in_direction -= 1

		if steps_in_direction == 0:
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

	for fragment in active_fragments.keys():
		if fragment in keep_active: continue
		inactive_fragments[fragment] = active_fragments[fragment]
		inactive_fragments[fragment].visible = false

		active_fragments.erase(fragment)

	last_player_fragment_position = current_plater_fragment_position


# Fragments methods

func instantiate_fragment(world_position : Vector3i) -> Object:
	if world_position in active_fragments: return

	var new_fragment : Object = fragment_scene.instantiate()
	add_child(new_fragment)
	new_fragment.global_position = world_position
	new_fragment.update_terrain()
	active_fragments[world_position] = new_fragment

	return new_fragment

func recycle_inactive_fragment(world_position : Vector3i):
	if inactive_fragments.size() <= 0: return
	var thread = get_render_thread(); if thread == null: return

	var recycled_fragment : Vector3i = inactive_fragments.keys()[0]
	active_fragments[world_position] = inactive_fragments[recycled_fragment]
	inactive_fragments.erase(recycled_fragment)
	active_fragments[world_position].global_position = world_position
	active_fragments[world_position].update_terrain()
	active_fragments[world_position].render(thread)
	# thread.wait_to_finish()

func get_render_thread():
	print('Active threads: ', active_threads.size())
	if active_threads.size() >= MAXIMUM_RENDER_THREADS: return null

	var new_thread := Thread.new()
	active_threads.append(new_thread)

	return new_thread

static func snap_to_grid(reference_position : Vector3i) -> Vector3i:
	return Vector3i(floor(Vector3(reference_position - WORLD_OFFSET) / Vector3(DIMENSIONS)) * Vector3(DIMENSIONS)) + WORLD_OFFSET

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

	var relative_position : Vector3i = (predict - cube_global_position).abs()
	return active_fragments[predict].cubes[relative_position.x][relative_position.y][relative_position.z]
