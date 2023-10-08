class_name Cube

const TEXTURE_ATLAS_SIZE := Vector2i(3, 2)
const MATERIAL := preload("res://Assets/Textures/standard_material_3d.tres")

const VERTICES := [
	Vector3i(0, 0, 0),
	Vector3i(1, 0, 0),
	Vector3i(0, 1, 0),
	Vector3i(1, 1, 0),
	Vector3i(0, 0, 1),
	Vector3i(1, 0, 1),
	Vector3i(0, 1, 1),
	Vector3i(1, 1, 1)
]

# This maps each face of the cube with their vertices
const TOP_FACE    := [2, 3, 7, 6]
const BOTTOM_FACE := [0, 4, 5, 1]
const LEFT_FACE   := [6, 4, 0, 2]
const RIGHT_FACE  := [3, 1, 5, 7]
const FRONT_FACE  := [7, 5, 4, 6]
const BACK_FACE   := [2, 0, 1, 3]

enum State
{
	air,
	grass,
	dirt,
	stone,
	glass
}

enum Details
{
	top_texture,
	bottom_texture,
	left_texture,
	right_texture,
	front_texture,
	back_texture,
	is_transparent,
	rotate_uv_x,
	rotate_uv_y,
	rotate_uv_z
}
const DETAILS_TEXTURE_FACES := [Cube.Details.top_texture, Cube.Details.bottom_texture, Cube.Details.left_texture, Cube.Details.right_texture, Cube.Details.front_texture, Cube.Details.back_texture]

const MAP := \
{
	State.air:
	{
		Details.is_transparent: true
	},
	State.grass:
	{
		Details.is_transparent : false,
		Details.top_texture  : Vector2i(0, 0), Details.bottom_texture: Vector2i(2, 0), # Coordinates into the atlas texture file
		Details.left_texture : Vector2i(1, 0), Details.right_texture : Vector2i(1, 0),
		Details.front_texture: Vector2i(1, 0), Details.back_texture  : Vector2i(1, 0),
		Details.rotate_uv_x: false, Details.rotate_uv_y: true, Details.rotate_uv_z: false
	},
	State.dirt:
	{
		Details.is_transparent : false,
		Details.top_texture  : Vector2i(2, 0), Details.bottom_texture: Vector2i(2, 0),
		Details.left_texture : Vector2i(2, 0), Details.right_texture : Vector2i(2, 0),
		Details.front_texture: Vector2i(2, 0), Details.back_texture  : Vector2i(2, 0),
		Details.rotate_uv_x: true, Details.rotate_uv_y: true, Details.rotate_uv_z: true
	},
	State.stone:
	{
		Details.is_transparent : false,
		Details.top_texture  : Vector2i(0, 1), Details.bottom_texture: Vector2i(0, 1),
		Details.left_texture : Vector2i(0, 1), Details.right_texture : Vector2i(0, 1),
		Details.front_texture: Vector2i(0, 1), Details.back_texture  : Vector2i(0, 1),
		Details.rotate_uv_x: true, Details.rotate_uv_y: true, Details.rotate_uv_z: true
	},
	State.glass:
	{
		Details.is_transparent : true,
		Details.top_texture  : Vector2i(1, 1), Details.bottom_texture: Vector2i(1, 1),
		Details.left_texture : Vector2i(1, 1), Details.right_texture : Vector2i(1, 1),
		Details.front_texture: Vector2i(1, 1), Details.back_texture  : Vector2i(1, 1),
		Details.rotate_uv_x: false, Details.rotate_uv_y: false, Details.rotate_uv_z: false
	}
}
