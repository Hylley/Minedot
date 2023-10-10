extends CharacterBody3D
class_name Player

@onready var head := $Head
@onready var camera := $Head/Camera3D
@onready var raycast := $Head/Camera3D/RayCast3D
@onready var cube_highlight := $CubeHighlight

# Movement
var speed : float
const WALK_SPEED := 5.
const SPRINT_SPEED := 8.
const JUMP_VELOCITY := 8
const SENSITIVITY := .004
const gravity := 30
var gamemode = 3

# View bob
const BOB_FREQ := 2.4
const BOB_AMP := 0.08
var t_bob := 0.0

# Field of view
const BASE_FOV := 90.0
const FOV_CHANGE := 2
const QUICK_ZOOM_FOV_CHANGE := -50
var quick_zoom := false

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	raycast.add_exception(self)

	if gamemode == 3:
		get_node('CollisionShape3D').disabled = true

func _unhandled_input(event) -> void:
	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * SENSITIVITY)
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-90), deg_to_rad(90))

func _input(_event) -> void:
	quick_zoom = Input.is_action_pressed('Quick Zoom') and not Input.is_action_just_released('Quick Zoom')

func _physics_process(delta) -> void:
	handle_movement(delta)
	handle_interaction() # Break block, add block, interact etc ...

func handle_movement(delta) -> void:
	if gamemode == 0:
		if not is_on_floor(): velocity.y -= gravity * delta

		# Handle Jump.
		if Input.is_action_pressed("Jump") and is_on_floor():
			velocity.y = JUMP_VELOCITY
	elif gamemode == 3:
		if    Input.is_action_pressed("Jump"):   velocity.y =  gravity * delta * 10
		elif  Input.is_action_pressed("Crouch"): velocity.y = -gravity * delta * 10
		else: velocity.y = 0

	# Handle Sprint.
	if Input.is_action_pressed("Sprint"):
		speed = SPRINT_SPEED
	else:
		speed = WALK_SPEED

	# Get the input direction and handle the movement/deceleration.
	var input_dir : Vector2 = Input.get_vector("Left", "Right", "Forward", "Backward")
	var direction : Vector3 = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if is_on_floor():
		if direction:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else:
			velocity.x = lerp(velocity.x, direction.x * speed, delta * 7.0)
			velocity.z = lerp(velocity.z, direction.z * speed, delta * 7.0)
	else:
		velocity.x = lerp(velocity.x, direction.x * speed, delta * 3.0)
		velocity.z = lerp(velocity.z, direction.z * speed, delta * 3.0)

	# Head bob
	t_bob += delta * velocity.length() * float(is_on_floor())
	var head_bob := Vector3.ZERO
	head_bob.y = sin(t_bob * BOB_FREQ) * BOB_AMP
	head_bob.x = cos(t_bob * BOB_FREQ / 2) * BOB_AMP
	camera.transform.origin = head_bob

	# FOV
	if not quick_zoom:
		var velocity_clamped : float = clamp(velocity.length(), 0.5, SPRINT_SPEED * 2)
		var target_fov := BASE_FOV + FOV_CHANGE * velocity_clamped
		camera.fov = lerp(camera.fov, target_fov, delta * 8.0)
	else:
		var target_fov := BASE_FOV + QUICK_ZOOM_FOV_CHANGE
		camera.fov = lerp(camera.fov, target_fov, .1)

	move_and_slide()

func handle_interaction() -> void:
	# Raycast
	if raycast.is_colliding():
		if raycast.get_collider() == null: return

		var point : Vector3 = raycast.get_collision_point()
		var norma : Vector3 = raycast.get_collision_normal()
		var focusing : Vector3 = floor(point - norma * .5)

		cube_highlight.global_position = focusing + Vector3(.5, .5, .5)
		cube_highlight.visible = true

		if Input.is_action_just_pressed('Hit'):
			FragmentManager.break_cube(raycast.get_collider().global_position, focusing)

		if Input.is_action_just_pressed('Interact'):
			FragmentManager.place_cube(raycast.get_collider().global_position, focusing + norma, Cube.State.grass)

	else:
		cube_highlight.visible = false
