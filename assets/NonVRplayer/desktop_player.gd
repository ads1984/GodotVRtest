extends CharacterBody3D

@export var move_speed := 4.0
@export var mouse_sensitivity := 0.002
var pitch: float = 0.0
@onready var camera: Camera3D = $Camera3D

func _ready() -> void:
	# Capture the mouse so we can look around
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		# Horizontal look
		rotate_y(-event.relative.x * mouse_sensitivity)
		# Vertical look
		pitch = clamp(pitch - event.relative.y * mouse_sensitivity, -1.5, 1.5)
		camera.rotation.x = pitch

func _physics_process(delta: float) -> void:
	# Gather input for movement; works with keyboard and gamepad
	var move_dir: Vector2 = Input.get_vector("move_left", "move_right",
											 "move_forward", "move_backward")
	# Convert 2D input into world space
	var direction: Vector3 = (transform.basis * Vector3(move_dir.x, 0.0, move_dir.y)).normalized()
	velocity.x = direction.x * move_speed
	velocity.z = direction.z * move_speed
	# Apply simple gravity
	velocity.y -= 9.8 * delta
	# Jump
	if is_on_floor() and Input.is_action_just_pressed("jump"):
		velocity.y = 6.0
	move_and_slide()
