extends CharacterBody3D

# Player Parts.
@onready var head  = $Neck/Head
@onready var crouching_collision: CollisionShape3D = $CrouchingCollision
@onready var standing_collision: CollisionShape3D = $StandingCollision
@onready var ray_cast_3d: RayCast3D = $RayCast3D
@onready var neck: Node3D = $Neck
@onready var camera: Camera3D = $Neck/Head/Eyes/Camera3D
@onready var eyes: Node3D = $Neck/Head/Eyes

# Variable Defaults.
var current_speed = 5.0
@export var walking_speed = 5.0
@export var dash_speed = 8.0
@export var crouch_speed = 3.0
@export var jump_velocity = 4.5
@export var crouch_depth = -0.5
@export var free_look_tilt = 0.3
@export var slide_speed = 8.0

# Constants.
const lerp_speed = 9
const mouse_sens = 0.4

# States.
var walking = false
var dashing = false
var crouching = false
var free_looking = false
var sliding = false

# Slide Variables.
@export var slide_timer = 0.0
@export var slide_timer_max = 1.0
var slide_vector = Vector2.ZERO

# Head bobbing variables.
const head_bobbing_sprinting_speed = 22
const head_bobbing_walking_speed = 14
const head_bobbing_crouching_speed = 10

const head_bobbing_sprinting_intensity = 0.2
const head_bobbing_walking_intensity = 0.1
const head_bobbing_crouching_intensity = 0.05

var head_bobbing_vector = Vector2.ZERO
var head_bobbing_index = 0.0
var current_head_bobbing_intensity

# Allow camera rotation via mouse movement.
func _input(event):
	if event is InputEventMouseMotion:
		if free_looking:
			neck.rotate_y(deg_to_rad(-event.relative.x * mouse_sens))
			neck.rotation.y = clamp(neck.rotation.y, deg_to_rad(-120), deg_to_rad(120))
		else:
			rotate_y(deg_to_rad(-event.relative.x * mouse_sens))
			head.rotate_x(deg_to_rad(-event.relative.y * mouse_sens))
			head.rotation.x = clamp(head.rotation.x, deg_to_rad(-89), deg_to_rad(89))
		
# Capture the mouse.
func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

# Main movement loop.
func _physics_process(delta: float) -> void:
	# Check for movement.
	var input_dir := Input.get_vector("Left", "Right", "Forward", "Backward")
	
	# Crouching.
	if Input.is_action_pressed("Crouch") or sliding:
		current_speed = crouch_speed
		head.position.y = lerp(head.position.y,crouch_depth, delta*lerp_speed)
		
		standing_collision.disabled = true
		crouching_collision.disabled = false
		
		# Sliding start logic.
		if dashing && input_dir != Vector2.ZERO:
			sliding = true
			slide_timer = slide_timer_max
			slide_vector = input_dir
		
		walking = false
		dashing = false
		crouching = true
		
	# Standing.
	elif !ray_cast_3d.is_colliding():
		standing_collision.disabled = false
		crouching_collision.disabled = true
		head.position.y = lerp(head.position.y, 0.0, delta * lerp_speed)
		# Dashing.
		if Input.is_action_pressed("Dash"):
			current_speed = dash_speed
			
			walking = false
			dashing = true
			crouching = false
			
		# Walking.
		else:
			current_speed = walking_speed
			
			walking = true
			dashing = false
			crouching = false
	
	# Handle free looking.
	if Input.is_action_pressed("Freelook"):
		free_looking = true
		camera.rotation.z = -deg_to_rad(neck.rotation.y * free_look_tilt)
		
	else:
		free_looking = false
		neck.rotation.y = lerp(neck.rotation.y, 0.0, delta * lerp_speed)
		camera.rotation.z = 0.0
		
	# Handle Sliding.
	
	if sliding:
		camera.rotation.z = lerp(camera.rotation.z, -deg_to_rad(7.0), delta * lerp_speed)
		slide_timer -= delta
		if slide_timer <= 0:
			sliding = false
		
	# Handle headbob.
	if dashing:
		current_head_bobbing_intensity = head_bobbing_sprinting_intensity
		head_bobbing_index += head_bobbing_sprinting_speed * delta
	elif walking:
		current_head_bobbing_intensity = head_bobbing_walking_intensity
		head_bobbing_index += head_bobbing_walking_speed * delta
	elif crouching:
		current_head_bobbing_intensity = head_bobbing_crouching_intensity
		head_bobbing_index += head_bobbing_crouching_speed * delta
		
	if is_on_floor() && !sliding && input_dir != Vector2.ZERO:
		head_bobbing_vector.y = sin(head_bobbing_index)
		head_bobbing_vector.x = sin(head_bobbing_index/2) + 0.5
		
		eyes.position.y = lerp(eyes.position.y, head_bobbing_vector.y * (current_head_bobbing_intensity/2), delta * lerp_speed)
		eyes.position.x = lerp(eyes.position.x, head_bobbing_vector.x * current_head_bobbing_intensity, delta * lerp_speed)
		
	else:
		eyes.position.y = lerp(eyes.position.y, 0.0, delta * lerp_speed)
		eyes.position.x = lerp(eyes.position.x, 0.0, delta * lerp_speed)
	
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_velocity
		sliding = false

	# Get the input direction and handle the movement.
	
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if sliding:
		direction = (transform.basis * Vector3(slide_vector.x, 0,slide_vector.y)).normalized()
	
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
		
		if sliding:
			velocity.x = direction.x * (slide_timer + 0.8) * slide_speed
			velocity.z = direction.z * (slide_timer + 0.8) * slide_speed
		
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)

	move_and_slide()
