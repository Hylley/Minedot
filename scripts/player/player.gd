extends CharacterBody3D
class_name Player

@onready var head := $Head
@onready var camera := $Head/Camera3D
@onready var raycast := $Head/Camera3D/RayCast3D
@onready var cube_highlight := $CubeHighlight
@onready var inventory := $Inventory
var player_mode := 0
var current_state = null

# Movement ———————————————————————————————————
var speed : float
const WALK_SPEED := 4.
const SPRINT_SPEED := 6.
const JUMP_VELOCITY := 8
var SENSITIVITY : float = UserPreferences.get_preference('gameplay', 'sensitivity', .004)
var gravity : float = ProjectSettings.get_setting("physics/3d/default_gravity")
var active := true

# View bob ———————————————————————————————————
const BOB_FREQ := 2.4
const BOB_AMP := 0.08
var t_bob := 0.0

# Field of view ——————————————————————————————
var BASE_FOV : float = UserPreferences.get_preference('gameplay', 'fov', 90.)
const FOV_CHANGE := 2
const QUICK_ZOOM_FOV_CHANGE := -50
var quick_zoom := false


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	raycast.add_exception(self)
	if player_mode == 3: get_node('CollisionShape3D').disabled = true

	var current_slot = inventory.hotbar.get_slot(0).get_entry()
	if current_slot[Inventory.state]:
		current_state = current_slot[Inventory.state]

func _unhandled_input(event : InputEvent) -> void:
	if event is InputEventMouseMotion and not World.paused and active:
		head.rotate_y(-event.relative.x * SENSITIVITY)
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-90), deg_to_rad(90))


func _input(_event : InputEvent) -> void:
	if Input.is_action_just_pressed('inventory'):
		inventory.toggle_window()
		active = not active

	if World.paused or not active: return

	if Input.is_action_pressed('hotbar_right'):
		var new_entry = inventory.hotbar.hotbar_change(1)
		if new_entry == null or not Inventory.state in new_entry:
			current_state= null
		else:
			current_state = new_entry[Inventory.state]

	if Input.is_action_pressed('hotbar_left'):
		var new_entry = inventory.hotbar.hotbar_change(-1)
		if new_entry == null or not Inventory.state in new_entry:
			current_state= null
		else:
			current_state = new_entry[Inventory.state]

	quick_zoom = Input.is_action_pressed('quick_zoom') and not Input.is_action_just_released('quick_zoom')


func _physics_process(delta : float) -> void:
	if World.paused: return

	handle_movement(delta)
	handle_interaction(delta)


func handle_movement(delta : float) -> void:
	if player_mode == 0:
		if not is_on_floor(): velocity.y -= gravity * delta
		if active and Input.is_action_pressed("jump") and is_on_floor(): velocity.y = JUMP_VELOCITY
	elif player_mode == 3:
		if   active and Input.is_action_pressed("jump")  : velocity.y =  gravity * delta * 10
		elif active and Input.is_action_pressed("crouch"): velocity.y = -gravity * delta * 10
		else: velocity.y = 0

	if Input.is_action_pressed("sprint"):
		speed = SPRINT_SPEED
	else:
		speed = WALK_SPEED

	var input_dir : Vector2 = Input.get_vector("left", "right", "forward", "backward") if active else Vector2.ZERO
	var direction : Vector3 = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized() if active else Vector3.ZERO

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


func handle_interaction(_delta : float) -> void:
	if raycast.is_colliding():
		if raycast.get_collider() == null: return

		var point : Vector3 = raycast.get_collision_point()
		var norma : Vector3 = raycast.get_collision_normal()
		var focusing : Vector3 = floor(point - norma * .5)

		cube_highlight.global_position = focusing + Vector3(.5, .5, .5)
		cube_highlight.visible = true

		if not active: return

		if Input.is_action_just_pressed('hit'):
			cube_highlight.visible = false
			Fragment.WORLD.delete(raycast.get_collider().global_position, focusing)

		if Input.is_action_just_pressed('interact'):
			if current_state == null: return

			var insert_position := Vector3i(focusing + norma)

			if insert_position == Vector3i(floor(global_position)) or \
			   insert_position == Vector3i(floor(global_position)) + Vector3i(0, 1, 0):
				return

			Fragment.WORLD.insert(raycast.get_collider().global_position, insert_position, current_state)
		return
	cube_highlight.visible = false
