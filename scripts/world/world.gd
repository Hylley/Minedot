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

var CIRCULAR_RANGE  : int = UserPreferences.get_preference('performance', 'circular_range', 64)
var HEIGHT_GROW : int = UserPreferences.get_preference('performance', 'height_grow', 6)

var TILE_HORIZONTAL : bool
var TILE_VERTICAL : bool
var PIVOT : Node3D
var current_pivot_snapped_position := Vector3i(0, 0, 0)
var grab_data : Callable # The world will call for this method to get data to load in fragments

# Resources ———————————————————————————————————
static var fragment_tscn := load('res://scenes/world_fragment.tscn')
signal first_load

# Generation methods ——————————————————————————

func initialize(fragment_size : Vector3i, tile_h : bool, tile_v : bool, data_source : Callable, pivot : Node3D) -> void:
	if initialized: push_warning(self.to_string() + ' has been initialized before; this may cause unexpected behavior.')

	Fragment.SIZE = fragment_size
	self.TILE_HORIZONTAL = tile_h
	self.TILE_VERTICAL = tile_v
	self.PIVOT = pivot

	self.grab_data = data_source

	initialized = true
	pause()

	gen_thread = Thread.new()
	gen_thread.start(generate)


func generate() -> void:
	var view := []
	var first_run := true # First load flag

	while active:
		if not first_run and paused: continue

		view.clear()
		view.append(current_pivot_snapped_position)

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
		for fragment_position in active_fragments:
			if fragment_position in view:
				if not active_fragments[fragment_position].rendered:
					active_fragments[fragment_position].render(grab_data.call(fragment_position, Fragment.SIZE), fragment_position, self)
				continue
			active_fragments[fragment_position].queue_free()
			active_fragments.erase(fragment_position)

		if first_run:
				first_run = false
				call_deferred('emit_signal', 'first_load')
				unpause()


func get_available_spawn_point() -> Vector3:
	for fragment_position in active_fragments.keys():
		var fragment_object : Fragment = active_fragments[fragment_position]

		for x in range(Fragment.SIZE.x):
			for y in range(Fragment.SIZE.y - 1, -1, -1):
				for z in range(Fragment.SIZE.z):
					var state : Placeable.state = fragment_object.get_state(Vector3i(x, y, z))
					var state_up : Placeable.state = fragment_object.get_state(Vector3i(x, y + 1, z))
					var state_down : Placeable.state = fragment_object.get_state(Vector3i(x, y + 2, z))

					if state == Placeable.state.air or \
					   state_up != Placeable.state.air or \
					   state_down != Placeable.state.air: continue

					return Vector3(fragment_position) + Vector3(x, y + 1, z)

	push_warning('Unable to find available spawn locations at x = 0, z = 0')
	return Vector3(0, 0, 0)


func _process(_delta : float) -> void:
	if not initialized or paused: return

	current_pivot_snapped_position = World.snap_to_grid(PIVOT.get_global_position(), TILE_HORIZONTAL, TILE_VERTICAL)

func _exit_tree() -> void:
	active = false; pause();
	gen_thread.wait_to_finish()


func pause():    paused = true
func unpause():  paused = false
func togpause(): paused = !paused # This is my favourite


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
