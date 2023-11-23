extends Node3D
class_name World

# Variables ———————————————————————————————————
var initialized : bool
var active : bool = true
static var paused : bool

# Rendering ———————————————————————————————————
var gen_thread := Thread.new()
static var active_fragments := {}
static var random := RandomNumberGenerator.new()

var CIRCULAR_RANGE  : int = UserPreferences.get_preference('performance', 'circular_range', 255)
var HEIGHT_GROW : int = UserPreferences.get_preference('performance', 'height_grow', 6)

var TILE_HORIZONTAL : bool
var TILE_VERTICAL : bool
var PIVOT : Node3D
var current_pivot_snapped_position := Vector3i.ZERO
var grab_data : Callable # The world will call for this method to get data to load in fragments

# Resources ———————————————————————————————————
static var fragment_tscn := load('res://scenes/world_fragment.tscn')


# Generation methods ——————————————————————————

func initialize(fragment_size : Vector3i, tile_h : bool, tile_v : bool, data_source : Callable, pivot : Node3D) -> void:
	if initialized: push_warning(self.to_string() + ' has been initialized before; this may cause unexpected behavior.')

	Fragment.SIZE = fragment_size
	self.TILE_HORIZONTAL = tile_h
	self.TILE_VERTICAL = tile_v
	self.PIVOT = pivot

	self.grab_data = data_source

	initialized = true

	gen_thread.start(generate)


func generate() -> void:
	var view := []

	while active:
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

		# Queue free fragments that are no longer in view
		for key in active_fragments.keys():
			if key in view:
				if not active_fragments[key].rendered:
					active_fragments[key].render(grab_data.call(key, Fragment.SIZE), key, self)
				continue
			active_fragments[key].queue_free()
			active_fragments.erase(key)

		# Instantiate fragments that are visible but not rendered yet
		for fragment in view:
			if active_fragments.has(fragment): continue
			var fragment_object : StaticBody3D = fragment_tscn.instantiate()
			active_fragments[fragment] = fragment_object


func _process(_delta : float) -> void:
	if not initialized or paused: return

	current_pivot_snapped_position = World.snap_to_grid(PIVOT.get_global_position())
	if not TILE_VERTICAL: current_pivot_snapped_position.y = 0
	if not TILE_HORIZONTAL:
		current_pivot_snapped_position.x = 0
		current_pivot_snapped_position.z = 0

func _exit_tree() -> void:
	active = false; pause();
	gen_thread.wait_to_finish()


func pause():    paused = true
func unpause():  paused = false
func togpause(): paused = !paused # This is my favourite


# Static methods —————————————————————————

static func snap_to_grid(reference_position : Vector3i) -> Vector3i:
	var division := Vector3(reference_position) / Vector3(Fragment.SIZE)
	var flooored : Vector3 = floor(division)
	var multiply := flooored * Vector3(Fragment.SIZE)

	return Vector3i(multiply)
