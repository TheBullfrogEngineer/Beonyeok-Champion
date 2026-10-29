extends CharacterBody3D

# Player Parts.
@onready var head  = $Head
@onready var crouching_collision: CollisionShape3D = $CrouchingCollision
@onready var standing_collision: CollisionShape3D = $StandingCollision
@onready var ray_cast_3d: RayCast3D = $RayCast3D

# Variable Defaults.
var current_speed = 5.0
@export var walking_speed = 5.0
@export var dash_speed = 8.0
@export var crouch_speed = 3.0
@export var jump_velocity = 4.5
@export var crouch_depth = -0.5

# Constants.
const lerp_speed = 10
const mouse_sens = 0.4

# Allow camera rotation via mouse movement.
func _input(event):
	if event is InputEventMouseMotion:
		rotate_y(deg_to_rad(-event.relative.x * mouse_sens))
		head.rotate_x(deg_to_rad(-event.relative.y * mouse_sens))
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-89), deg_to_rad(89))
		
# Capture the mouse.
func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

# Main movement loop.
func _physics_process(delta: float) -> void:
	if Input.is_action_pressed("Crouch"):
		current_speed = crouch_speed
		head.position.y = lerp(head.position.y, 1.8 + crouch_depth, delta*lerp_speed)
		standing_collision.disabled = true
		crouching_collision.disabled = false
		
	elif !ray_cast_3d.is_colliding():
		standing_collision.disabled = false
		crouching_collision.disabled = true
		head.position.y = lerp(head.position.y, 1.8, delta * lerp_speed)
		
		if Input.is_action_pressed("Dash"):
			current_speed = dash_speed
		else:
			current_speed = walking_speed
	
	
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_velocity

	# Get the input direction and handle the movement.
	var input_dir := Input.get_vector("Left", "Right", "Forward", "Backward")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)

	move_and_slide()
