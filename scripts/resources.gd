extends Node

static var MATERIAL := StandardMaterial3D.new()
static var TEXTURE_SIZE : Vector2i
static var TILE_SIZE : int
@warning_ignore('integer_division')
static var RELATIVE_ATLAS_SIZE := Vector2i(TEXTURE_SIZE.x / TILE_SIZE, TEXTURE_SIZE.y / TILE_SIZE)

static var module : Dictionary

func _ready() -> void:
	add_resource('res://minedot.zip')


func add_resource(path : String) -> void:
	var map = JSON.parse_string(get_file_from_zip(path, 'map.json').get_string_from_utf8())

	module = map
	module.path = path
	module.offset = Vector2i(0, 0)

	var placeable_atlas = get_file_from_zip(path, 'assets/' + module.placeable_atlas)
	var image := Image.new(); image.load_png_from_buffer(placeable_atlas)
	var texture = ImageTexture.create_from_image(image)

	MATERIAL.set_texture(BaseMaterial3D.TEXTURE_ALBEDO, texture)
	TEXTURE_SIZE = Vector2i(MATERIAL.albedo_texture.get_width(), MATERIAL.albedo_texture.get_height())
	TILE_SIZE = module.placeable_tile_size


func state(i : int) -> Dictionary:
	return module.states[module.states.keys()[i]]


func get_file_from_zip(path, file):
	var reader := ZIPReader.new()

	if reader.open(path) != OK:
		push_error('Could not open resource: ' + file + ' of ' + path + ';')
		return PackedByteArray()

	var res := reader.read_file(file)
	reader.close()
	return res
