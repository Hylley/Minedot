extends Node3D
class_name World

# Variables ———————————————————————————————————
var initialized : bool
var active : bool = true
static var paused : bool

# Rendering ———————————————————————————————————
var gen_thread : Thread
var active_fragments := {}
static var random := RandomNumberGenerator.new()

var CIRCULAR_RANGE  : int = UserPreferences.get_preference('performance', 'circular_range', 32)
var HEIGHT_GROW : int = UserPreferences.get_preference('performance', 'height_grow', 6)

var TILE_HORIZONTAL : bool
var TILE_VERTICAL : bool
var PIVOT : Node3D
var current_pivot_snapped_position := Vector3i(0, 0, 0)
var past_pivot_snapped_position:= Vector3i(0, 0, 0)
var rules : Callable # The world will call for this method to get data to load in fragments

# Resources ———————————————————————————————————
static var fragment_tscn := load('res://scenes/world_fragment.tscn')
signal first_load

# Generation methods ——————————————————————————

func initialize(fragment_size : Vector3i, tile_h : bool, tile_v : bool, _rules : Callable, pivot : Node3D) -> void:
	if initialized: push_warning(self.to_string() + ' has been initialized before; this may cause unexpected behavior.')

	Fragment.SIZE = fragment_size
	Fragment.WORLD = self
	self.TILE_HORIZONTAL = tile_h
	self.TILE_VERTICAL = tile_v
	self.PIVOT = pivot

	self.rules = _rules

	initialized = true
	pause()

	gen_thread = Thread.new()
	gen_thread.start(generate)


func generate() -> void:
	var view := []
	var first_run := true # First load flag

	while active:
		if not first_run:
			if paused: continue
			if current_pivot_snapped_position == past_pivot_snapped_position: continue

		view.clear()
		view.append(current_pivot_snapped_position)
		past_pivot_snapped_position = current_pivot_snapped_position

		var head = current_pivot_snapped_position;
		var direction : Vector2i = Vector2i(1, 0)
		var step := 1; var steps_in_direction := 1

		for i in range(CIRCULAR_RANGE):
			if TILE_VERTICAL:
				for j in range(int(HEIGHT_GROW / 2.)):
					var top_fragment_position : Vector3i = head + Vector3i(0, j + 1, 0) * Fragment.SIZE
					view.append(top_fragment_position)

					var bottom_fragment_position : Vector3i = head - Vector3i(0, j + 1, 0) * Fragment.SIZE;
					view.append(bottom_fragment_position)

			if TILE_HORIZONTAL:
				head += Vector3i(direction.x, 0, direction.y) * Fragment.SIZE
				view.append(head)
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

		# Instantiate fragments that are visible but not rendered yet
		for fragment in view:
			if active_fragments.has(fragment): continue
			var fragment_object : StaticBody3D = fragment_tscn.instantiate()
			active_fragments[fragment] = fragment_object

		# Queue free fragments that are no longer in view and render the new ones
		for fragment_position in active_fragments.keys():
			if fragment_position in view:
				var fragment : Fragment = active_fragments[fragment_position]
				if not fragment.rendered: fragment.cubes = World.generatrix(fragment_position, Fragment.SIZE, rules)

				continue

			active_fragments[fragment_position].queue_free()
			active_fragments.erase(fragment_position)

		for fragment_position in active_fragments:
				var fragment : Fragment = active_fragments[fragment_position]
				if fragment.rendered: continue
				fragment.render(fragment_position, self)
				# refresh_surroundings(fragment_position)

		if first_run:
				first_run = false
				call_deferred('emit_signal', 'first_load')
				unpause()


func _process(_delta : float) -> void:
	if not initialized or paused: return

	current_pivot_snapped_position = World.snap_to_grid(PIVOT.get_global_position(), TILE_HORIZONTAL, TILE_VERTICAL)

func _exit_tree() -> void:
	active = false; pause();
	Fragment.WORLD = null; Fragment.SIZE = Vector3i.ZERO
	gen_thread.wait_to_finish()


func pause():    paused = true
func unpause():  paused = false
func togpause(): paused = !paused # This is my favourite


# API methods —————————————————————————

func delete(fragment_position : Vector3i, state_global_position : Vector3i) -> void:
	insert(fragment_position, state_global_position, Placeable.state.air)
	# Particle logic here


func insert(fragment_position : Vector3i, state_global_position : Vector3i, state : Placeable.state) -> void:
	var relative_position := state_global_position - fragment_position

	if Fragment.is_out_of_bounds(relative_position):
		fragment_position = World.snap_to_grid(state_global_position)
		if not fragment_position in active_fragments:
			push_warning('Unable to edit non-existent fragment ' + str(fragment_position) + '.')
			return
		relative_position = relative_position % Fragment.SIZE

	active_fragments[fragment_position].set_state(relative_position, fragment_position, state)

	if relative_position.x == 0:
		refresh_fragment_if_exists(fragment_position - Vector3i(Fragment.SIZE.x, 0, 0))
	elif relative_position.x == Fragment.SIZE.x - 1:
		refresh_fragment_if_exists(fragment_position + Vector3i(Fragment.SIZE.x, 0, 0))

	if relative_position.y == 0:
		refresh_fragment_if_exists(fragment_position - Vector3i(0, Fragment.SIZE.y, 0))
	elif relative_position.y == Fragment.SIZE.y - 1:
		refresh_fragment_if_exists(fragment_position + Vector3i(0, Fragment.SIZE.y, 0))

	if relative_position.z == 0:
		refresh_fragment_if_exists(fragment_position - Vector3i(0, 0, Fragment.SIZE.z))
	elif relative_position.z == Fragment.SIZE.z - 1:
		refresh_fragment_if_exists(fragment_position + Vector3i(0, 0, Fragment.SIZE.z))


func get_state_global(world_position : Vector3) -> Placeable.state:
	var snapped_position := World.snap_to_grid(world_position)

	var fragment := get_fragment(snapped_position)
	if fragment == null and TILE_HORIZONTAL:     return rules.call(world_position)
	if fragment == null and not TILE_HORIZONTAL: return Placeable.state.air

	var local_position = Vector3i(world_position) - snapped_position
	return fragment.get_state(local_position, snapped_position)


func get_fragment(snapped_position : Vector3i) -> Fragment:
	if not snapped_position in active_fragments: return null
	return active_fragments[snapped_position]


func refresh_fragment_if_exists(fragment_position : Vector3i):
	if not fragment_position in active_fragments: return
	active_fragments[fragment_position].call_deferred('refresh', fragment_position)


func refresh_surroundings(fragment_position : Vector3i) -> void:
	refresh_fragment_if_exists(fragment_position + Vector3i(Fragment.SIZE.x, 0, 0)) # Right fragment
	refresh_fragment_if_exists(fragment_position - Vector3i(Fragment.SIZE.x, 0, 0)) # Left fragment
	refresh_fragment_if_exists(fragment_position + Vector3i(0, Fragment.SIZE.y, 0)) # Top fragment
	refresh_fragment_if_exists(fragment_position - Vector3i(0, Fragment.SIZE.y, 0)) # Bottom fragment
	refresh_fragment_if_exists(fragment_position + Vector3i(0, 0, Fragment.SIZE.z)) # Front fragment
	refresh_fragment_if_exists(fragment_position - Vector3i(0, 0, Fragment.SIZE.z)) # Back fragment


func get_spawn_point() -> Vector3:
	for fragment_position in active_fragments.keys():
		var fragment_object : Fragment = active_fragments[fragment_position]

		for x in range(Fragment.SIZE.x):
			for y in range(Fragment.SIZE.y - 1, -1, -1):
				for z in range(Fragment.SIZE.z):
					var state : Placeable.state = fragment_object.get_state(Vector3i(x, y, z), fragment_position)
					var state_up : Placeable.state = fragment_object.get_state(Vector3i(x, y + 1, z), fragment_position)
					var state_down : Placeable.state = fragment_object.get_state(Vector3i(x, y + 2, z), fragment_position)

					if state == Placeable.state.air or \
					   state_up != Placeable.state.air or \
					   state_down != Placeable.state.air: continue

					return Vector3(fragment_position) + Vector3(x, y + 1, z)

	push_warning('Unable to find available spawn locations')
	return Vector3(0, 0, 0)


# Static methods —————————————————————————

static func snap_to_grid(reference_position : Vector3i, tile_h : bool = true, tile_v : bool = true) -> Vector3i:
	var division := Vector3(reference_position) / Vector3(Fragment.SIZE)
	var flooored : Vector3 = floor(division)
	var multiply := flooored * Vector3(Fragment.SIZE)

	if not tile_v: multiply.y = 0
	if not tile_h:
		multiply.x = 0
		multiply.z = 0

	return Vector3i(multiply)


static func generatrix(world_position : Vector3i, size : Vector3i, _rules : Callable) -> Array:
	var cubes = []; cubes.resize(size.x)
	for x in range(0, size.x):
		cubes[x] = []; cubes[x].resize(size.y)
		for y in range(0, size.y):
			cubes[x][y] = []; cubes[x][y].resize(size.z)
			for z in range(0, size.z):
				cubes[x][y][z] = _rules.call(world_position + Vector3i(x, y, z))
	return cubes
