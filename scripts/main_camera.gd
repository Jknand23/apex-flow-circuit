extends Camera3D

# Simple camera controller for testing scenes
# Use WASD to move, mouse to look around

@export var movement_speed: float = 10.0
@export var mouse_sensitivity: float = 0.001

var mouse_captured: bool = false

func _ready():
	print("Camera controller loaded! Click to capture mouse, ESC to release")

func _input(event):
	# Capture/release mouse on click
	if event is InputEventMouseButton and event.pressed:
		if not mouse_captured:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			mouse_captured = true
	
	# Release mouse with ESC
	if event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		mouse_captured = false
	
	# Mouse look (only when captured)
	if event is InputEventMouseMotion and mouse_captured:
		rotate_y(-event.relative.x * mouse_sensitivity)
		rotate_object_local(Vector3.RIGHT, -event.relative.y * mouse_sensitivity)

func _physics_process(delta):
	# WASD movement (only when mouse is captured)
	if not mouse_captured:
		return
	
	var input_vector = Vector3.ZERO
	
	if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
		input_vector.z -= 1
	if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
		input_vector.z += 1
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		input_vector.x -= 1
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		input_vector.x += 1
	if Input.is_key_pressed(KEY_Q):
		input_vector.y -= 1
	if Input.is_key_pressed(KEY_E):
		input_vector.y += 1
	
	# Move relative to camera's orientation
	if input_vector.length() > 0:
		input_vector = input_vector.normalized()
		global_translate(transform.basis * input_vector * movement_speed * delta) 
