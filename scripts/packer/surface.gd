extends Node
class_name Surface

static var MATERIAL := StandardMaterial3D.new()
static var indexer := [] # List of pointers to all placeables dicts in the game
static var TILE_SIZE := 0
static var ATLAS_SIZE : Vector2i
static var ATLAS_SIZE_RELATIVE : Vector2i

# Settings
const ATLAS_FORMAT = Image.FORMAT_RGBA8

func _init() -> void: # Init is always called before on_ready

	indexer.append({ # Air block must always be present, and must always be index 0
		'name'          : "Air block",
		'index'			: 0,
		'is_transparent': true,
		'is_indexable'  : false,
		'is_stackable'  : false
	})

	ResourcePacker.new_module_loaded.connect(on_new_module_loaded)


func on_new_module_loaded(module_body : Dictionary) -> void:
	TILE_SIZE = module_body.artifacts_tile_size if module_body.artifacts_tile_size > TILE_SIZE else TILE_SIZE

	for state in module_body.state:
		module_body.state[state].index  = indexer.size()
		module_body.state[state].origin = module_body.path
		indexer.append(module_body.state[state])


func generate_atlas() -> Texture2D:
	var texture_set         := {}
	var positioned_textures := {}
	var full_image_size     := Vector2i(1, 1)

	for placeable in indexer:
		if not 'textures' in placeable: continue
		for value in placeable.textures.values():
			texture_set[value] = placeable.origin

	var iteration := 1
	while texture_set.size() > 0:
		var avaliable_positions := [ Vector2i(0, 0) ] if iteration == 1 else []

		for i in range(iteration):
			avaliable_positions.append(Vector2i(i, iteration))
			avaliable_positions.append(Vector2i(iteration, i))
		avaliable_positions.append(Vector2i(iteration, iteration))

		while avaliable_positions.size() > 0:
			if texture_set.size() <= 0: break

			var texture  : String   = texture_set.keys()[0]
			var position : Vector2i = avaliable_positions.pop_front()
			positioned_textures[position] = {'path' : texture, 'origin' : texture_set[texture]}
			texture_set.erase(texture)

			if position.x + 1 > full_image_size.x: full_image_size.x = position.x + 1
			if position.y + 1 > full_image_size.y: full_image_size.y = position.y + 1

		iteration += 1

	var full_image = Image.create(full_image_size.x * TILE_SIZE, full_image_size.y * TILE_SIZE, false, ATLAS_FORMAT)

	for position in positioned_textures:
		var texture_path  : String = positioned_textures[position].path
		var texture_orgin : String = positioned_textures[position].origin

		var tile := Image.new()
		tile.load_png_from_buffer(Packer.unzip(texture_orgin, 'assets/state/' + texture_path))
		tile.convert(ATLAS_FORMAT)

		full_image.blit_rect(tile, tile.get_used_rect(), position * TILE_SIZE)


	return ImageTexture.create_from_image(full_image)

func get_data_by_index(index : int) -> Dictionary:
	if index < 0 or index >= indexer.size(): return {}
	return indexer[index]
