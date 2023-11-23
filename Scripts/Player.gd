extends CharacterBody3D
class_name Player

@onready var head := $Head
@onready var camera := $Head/Camera3D
var player_mode := 3

# Movement ———————————————————————————————————
var speed : float
const WALK_SPEED := 5.
const SPRINT_SPEED := 8.
const JUMP_VELOCITY := 8
var SENSITIVITY : float = UserPreferences.get_preference('gameplay', 'sensitivity', .004)
var gravity : float = ProjectSettings.get_setting("physics/3d/default_gravity")

# View bob ———————————————————————————————————
const BOB_FREQ := 2.4
const BOB_AMP := 0.08
var t_bob := 0.0

# Field of view ——————————————————————————————
const BASE_FOV := 90.0
const FOV_CHANGE := 2
const QUICK_ZOOM_FOV_CHANGE := -50
var quick_zoom := false

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	if player_mode == 3: get_node('CollisionShape3D').disabled = true

func _unhandled_input(event : InputEvent) -> void:
	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * SENSITIVITY)
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-90), deg_to_rad(90))

func _input(_event : InputEvent) -> void:
	quick_zoom = Input.is_action_pressed('Quick Zoom') and not Input.is_action_just_released('Quick Zoom')

func _physics_process(delta : float) -> void:
	handle_movement(delta)

func handle_movement(delta : float) -> void:
	if player_mode == 0:
		if not is_on_floor(): velocity.y -= gravity * delta
		if Input.is_action_pressed("Jump") and is_on_floor(): velocity.y = JUMP_VELOCITY
	elif player_mode == 3:
		if    Input.is_action_pressed("Jump"):   velocity.y =  gravity * delta * 10
		elif  Input.is_action_pressed("Crouch"): velocity.y = -gravity * delta * 10
		else: velocity.y = 0

	if Input.is_action_pressed("Sprint"):
		speed = SPRINT_SPEED
	else:
		speed = WALK_SPEED

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

	t_bob += delta * velocity.length() * float(is_on_floor())
	var head_bob := Vector3.ZERO
	head_bob.y = sin(t_bob * BOB_FREQ) * BOB_AMP
	head_bob.x = cos(t_bob * BOB_FREQ / 2) * BOB_AMP
	camera.transform.origin = head_bob

	if not quick_zoom:
		var velocity_clamped : float = clamp(velocity.length(), 0.5, SPRINT_SPEED * 2)
		var target_fov := BASE_FOV + FOV_CHANGE * velocity_clamped
		camera.fov = lerp(camera.fov, target_fov, delta * 8.0)
	else:
		var target_fov := BASE_FOV + QUICK_ZOOM_FOV_CHANGE
		camera.fov = lerp(camera.fov, target_fov, .1)

	move_and_slide()
