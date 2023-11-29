class_name Placeable

const MATERIAL := preload("res://assets/textures/texture_atlas.tres")
static var TEXTURE_SIZE := Vector2i(MATERIAL.albedo_texture.get_width(), MATERIAL.albedo_texture.get_height())
static var TILE_SIZE = 16
@warning_ignore('integer_division')
static var RELATIVE_ATLAS_SIZE := Vector2i(TEXTURE_SIZE.x / TILE_SIZE, TEXTURE_SIZE.y / TILE_SIZE)


static func get_state_texture2d(_offset : Vector2i) -> Texture2D:
	var atlas_texture = AtlasTexture.new()
	atlas_texture.set_atlas(Placeable.MATERIAL.albedo_texture)
	atlas_texture.set_region(Rect2(_offset.x * Placeable.TILE_SIZE, _offset.y * Placeable.TILE_SIZE, Placeable.TILE_SIZE, Placeable.TILE_SIZE))

	return atlas_texture


# Keys —————————————————————————

enum type
{
	cube
}

enum state
{
	air,
	grass,
	dirt,
	stone,
	glass
}

enum
{
	is_transparent,

	top_texture,
	bottom_texture,
	left_texture,
	right_texture,
	front_texture,
	back_texture,
	unique_texture,

	rotate_uv_x,
	rotate_uv_y,
	rotate_uv_z,

	break_audio,
	place_audio,
	walk_audio
}

# Cubes —————————————————————————

const VERTICES := \
[
	Vector3i(0, 0, 0),
	Vector3i(1, 0, 0),
	Vector3i(0, 1, 0),
	Vector3i(1, 1, 0),
	Vector3i(0, 0, 1),
	Vector3i(1, 0, 1),
	Vector3i(0, 1, 1),
	Vector3i(1, 1, 1)
]

const TOP_FACE    := [2, 3, 7, 6]
const BOTTOM_FACE := [0, 4, 5, 1]
const LEFT_FACE   := [6, 4, 0, 2]
const RIGHT_FACE  := [3, 1, 5, 7]
const FRONT_FACE  := [7, 5, 4, 6]
const BACK_FACE   := [2, 0, 1, 3]

# Mapping —————————————————————————

const MAP := \
{
	state.air:
	{
		is_transparent: true
	},
	state.grass:
	{
		is_transparent : false,
		top_texture  : Vector2i(0, 0), bottom_texture: Vector2i(2, 0), # Coordinates into the atlas texture file
		left_texture : Vector2i(1, 0), right_texture : Vector2i(1, 0),
		front_texture: Vector2i(1, 0), back_texture  : Vector2i(1, 0),
		rotate_uv_x: false, rotate_uv_y: true, rotate_uv_z: false
	},
	state.dirt:
	{
		is_transparent : false,
		top_texture  : Vector2i(2, 0), bottom_texture: Vector2i(2, 0),
		left_texture : Vector2i(2, 0), right_texture : Vector2i(2, 0),
		front_texture: Vector2i(2, 0), back_texture  : Vector2i(2, 0),
		rotate_uv_x: true, rotate_uv_y: true, rotate_uv_z: true
	},
	state.stone:
	{
		is_transparent : false,
		top_texture  : Vector2i(0, 1), bottom_texture: Vector2i(0, 1),
		left_texture : Vector2i(0, 1), right_texture : Vector2i(0, 1),
		front_texture: Vector2i(0, 1), back_texture  : Vector2i(0, 1),
		rotate_uv_x: true, rotate_uv_y: true, rotate_uv_z: true
	},
	state.glass:
	{
		is_transparent : true,
		top_texture  : Vector2i(1, 1), bottom_texture: Vector2i(1, 1),
		left_texture : Vector2i(1, 1), right_texture : Vector2i(1, 1),
		front_texture: Vector2i(1, 1), back_texture  : Vector2i(1, 1),
		rotate_uv_x: false, rotate_uv_y: false, rotate_uv_z: false
	}
}
