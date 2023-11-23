extends Node3D
class_name World

# Variables ———————————————————————————————————
var initialized : bool
static var paused : bool

# Rendering ———————————————————————————————————
static var gen_thread := Thread.new()
static var random := RandomNumberGenerator.new()

var LOAD_RANGE  : int = UserPreferences.get_preference('performance', 'circular_range', 255)
var HEIGHT_GROW : int = UserPreferences.get_preference('performance', 'height_grow', 6)

var TILE_X : bool
var TILE_Y : bool
var PIVOT : Node3D
var grab_data_for : Callable # The world will call for this method to get data to load in fragments

# Resources ———————————————————————————————————
static var fragment_tscn := load('res://scenes/world_fragment.tscn')

func initialize(fragment_size : Vector3i, tile_x : bool, tile_y : bool, data_source : Callable, pivot : Node3D) -> void:
	if initialized: push_warning(self.to_string() + ' has been initialized before; this may cause unexpected behavior.')

	Fragment.SIZE = fragment_size
	self.TILE_X = tile_x
	self.TILE_Y = tile_y
	self.PIVOT = pivot

	self.grab_data_for = data_source

	initialized = true


func _process(_delta: float) -> void:
	if not initialized: return;


func _exit_tree():
	pause()
	World.gen_thread.wait_to_finish()
	World.gen_thread = null


func pause():    paused = true
func unpause():  paused = false
func togpause(): paused = !paused # This is my favourite


func test_render() -> StaticBody3D:
	var fragment : StaticBody3D = fragment_tscn.instantiate()
	add_child(fragment)

	fragment.set_as_top_level(true)
	fragment.set_global_position(Vector3(0, 0, 0))
	fragment.set_visible(false)

	fragment.render(grab_data_for.call(Vector3(0, 0, 0)))

	return fragment
