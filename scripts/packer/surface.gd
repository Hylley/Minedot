extends Node
class_name packer_surface

const air = { # Air block must always be present, and must always be at index 0
	'name'          : "Air block",
	'index'			: 0,
	'is_transparent': true,
	'is_indexable'  : false,
	'is_stackable'  : false
}

var indexer := [air] # List of pointers to all placeables in the game

var MATERIAL := StandardMaterial3D.new()
var TILE_SIZE := 0
var ATLAS_SIZE_RELATIVE : Vector2i

# Settings
const ATLAS_FORMAT = Image.FORMAT_RGBA8
var texture_atlas : ImageTexture
var head = Vector2i(0, 0)

func _init() -> void: # Init is always called before on_ready
	Packer.new_module_loaded.connect(on_new_module_loaded)


func on_new_module_loaded(module_body : Dictionary) -> void:
	TILE_SIZE = module_body.artifacts_tile_size if module_body.artifacts_tile_size > TILE_SIZE else TILE_SIZE

	for state in module_body.state:
		module_body.state[state].index  = indexer.size()
		module_body.state[state].origin = module_body.path
		indexer.append(module_body.state[state])

	update_material()


func update_material() -> void:
	MATERIAL.set_texture(BaseMaterial3D.TEXTURE_ALBEDO, update_atlas())
	MATERIAL.set_texture_filter(BaseMaterial3D.TEXTURE_FILTER_NEAREST)
	MATERIAL.set_transparency(BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR)
	MATERIAL.set_specular(0)
	MATERIAL.set_feature(BaseMaterial3D.FEATURE_AMBIENT_OCCLUSION, true);
	MATERIAL.set_ao_light_affect(1)


func update_atlas() -> Texture2D:
	# This has a problem tho. If one of the surface packs loaded has tiles bigger than the others,
	# there might me weird glitches in the textures. Note to fix that later.

	var positioned_textures := {}
	@warning_ignore('integer_division')
	var full_image_size := Vector2i(1, 1) if texture_atlas == null else Vector2i(texture_atlas.get_width() / TILE_SIZE, texture_atlas.get_height() / TILE_SIZE)

	for placeable in indexer:
		if not 'textures' in placeable: continue

		for face in placeable.textures:
			if typeof(placeable.textures[face]) == TYPE_VECTOR2I: continue

			var texture_path : String = placeable.textures[face]
			var origin_path : String = placeable.origin
			var full_path : String = origin_path + '-' + texture_path

			if not full_path in positioned_textures:
				positioned_textures[full_path] = head
				head = packer_surface.next(head)

				if head.x > full_image_size.x: full_image_size.x = head.x + 1
				if head.y > full_image_size.y: full_image_size.y = head.y + 1

			placeable.textures[face] = positioned_textures[full_path]

	var full_image = Image.create(full_image_size.x * TILE_SIZE, full_image_size.y * TILE_SIZE, false, ATLAS_FORMAT)

	if texture_atlas != null:
		var image := texture_atlas.get_image()
		full_image.blit_rect(image, image.get_used_rect(), Vector2i(0, 0))

	for texture in positioned_textures:
		var position : Vector2i = positioned_textures[texture]
		var full_path : PackedStringArray = texture.split('-')
		var origin_path  : String = full_path[0]
		var texture_path : String = full_path[1]

		var tile := Image.new()
		tile.load_png_from_buffer(packer.unzip(origin_path, 'assets/' + texture_path))
		tile.convert(ATLAS_FORMAT)

		full_image.blit_rect(tile, tile.get_used_rect(), position * TILE_SIZE)

	texture_atlas = ImageTexture.create_from_image(full_image)
	@warning_ignore('integer_division')
	ATLAS_SIZE_RELATIVE =  Vector2i(texture_atlas.get_width() / TILE_SIZE, texture_atlas.get_height() / TILE_SIZE)
	return texture_atlas


static func next(_head : Vector2i) -> Vector2i:
	# This algorithm iterate throug ha grid-like scenario staring from the
	# corners and going to the center:
	#  |X| | |     |X| | |     |X|X| |     |X|X| |     |X|X| |     |X|X|X|
	#  | | | |  →  |X| | |  →  |X| | |  →  |X|X| |  →  |X|X| |  →  |X|X| | ...
	#  | | | |     | | | |     | | | |     | | | |     |X| | |     |X| | |

	if _head.x == _head.y:
		return Vector2i(0, _head.y + 1)
	elif _head.x < _head.y:
		return Vector2i(_head.y, _head.x)
	else:
		return Vector2i(_head.y +  1, _head.x)


func get_state(index : int) -> Dictionary:
	if index < 0 or index >= indexer.size(): return {}
	return indexer[index]
