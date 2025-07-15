# scripts/player_movement.gd
# Basic hoverboard movement for CharacterBody3D. Handles acceleration, turning, jumping.
# Attach to player_board.tscn root. Uses _physics_process for smooth physics.

extends CharacterBody3D

# Constants for tuning (tweak for vibe).
const MAX_SPEED: float = 20.0
const ACCELERATION: float = 5.0
const TURN_SPEED: float = 3.0
const DODGE_STRENGTH: float = 15.0  # Impulse strength for dodge burst.
const AIR_DODGE_MULTIPLIER: float = 0.8  # Multiplier for dodge strength in air (1.0 = same, <1 = weaker).
const DODGE_COOLDOWN: float = 0.5   # Seconds between dodges (prevent spam).
const JUMP_VELOCITY: float = 5.0
const GRAVITY: float = -9.8

# Descriptive state vars.
var current_speed: float = 0.0
var is_jumping: bool = false
var dodge_cooldowns := { "left": 0.0, "right": 0.0 }  # Timers for each dodge direction.

# Map for input actions (expandable, no enums).
var input_actions := {
	"forward": "move_forward",  # Custom action for W.
	"left": "turn_left",        # Custom for A (turning).
	"right": "turn_right",      # Custom for D (turning).
	"jump": "player_jump",      # Custom for Space.
	"dodge_left": "dodge_left", # Custom for Q (left dodge burst).
	"dodge_right": "dodge_right" # Custom for E (right dodge burst).
}

# Function to get turn input direction.
# Returns: float - -1 (left), 0 (none), 1 (right).
func get_turn_input() -> float:
	var turn_direction: float = 0.0
	if Input.is_action_pressed(input_actions["left"]):
		turn_direction -= 1.0
	if Input.is_action_pressed(input_actions["right"]):
		turn_direction += 1.0
	return turn_direction

# Function to handle acceleration and velocity.
# @param delta: float - Time since last physics frame.
func apply_acceleration(delta: float) -> void:
	if Input.is_action_pressed(input_actions["forward"]):
		current_speed = min(current_speed + ACCELERATION * delta, MAX_SPEED)
	else:
		current_speed = max(current_speed - ACCELERATION * delta, 0.0)  # Decelerate.
	
	var forward_direction := -global_transform.basis.z.normalized()  # Board forward.
	velocity.x = forward_direction.x * current_speed
	velocity.z = forward_direction.z * current_speed

# Function to apply turning (rotation).
# @param delta: float - Time since last physics frame.
# @param turn_input: float - Direction from get_turn_input().
func apply_turning(delta: float, turn_input: float) -> void:
	if abs(turn_input) > 0:
		rotate_y(turn_input * TURN_SPEED * delta * -1)  # Invert for natural left/right.

# Function to apply dodge impulse.
# @param direction: float - -1 for left, 1 for right.
func apply_dodge(direction: float) -> void:
	var cooldown_key = "left" if direction < 0 else "right"
	if dodge_cooldowns[cooldown_key] > 0:
		return  # On cooldown.
	
	var effective_strength = DODGE_STRENGTH if is_on_floor() else DODGE_STRENGTH * AIR_DODGE_MULTIPLIER
	var right_direction := global_transform.basis.x.normalized()  # Local right.
	velocity += right_direction * direction * effective_strength
	dodge_cooldowns[cooldown_key] = DODGE_COOLDOWN  # Start cooldown.

# Function to apply gravity and jumping.
# @param delta: float - Time since last physics frame.
func apply_gravity_and_jump(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		is_jumping = false  # Reset on land.
	
	if Input.is_action_just_pressed(input_actions["jump"]) and is_on_floor():
		velocity.y = JUMP_VELOCITY
		is_jumping = true

func _physics_process(delta: float) -> void:
	if not is_on_floor() and velocity.y == 0 and not is_jumping:  # Rare edge case check (ignore during jumps).
		push_error("Physics error: Not on floor with zero Y velocity.")
	
	# Decrement dodge cooldowns every frame.
	for key in dodge_cooldowns:
		if dodge_cooldowns[key] > 0:
			dodge_cooldowns[key] -= delta
	
	var turn_input := get_turn_input()
	
	apply_acceleration(delta)
	apply_turning(delta, turn_input)
	
	# Check for dodge inputs (works on ground or in air).
	if Input.is_action_just_pressed(input_actions["dodge_left"]):
		apply_dodge(-2.0)
	if Input.is_action_just_pressed(input_actions["dodge_right"]):
		apply_dodge(2.0)
	
	apply_gravity_and_jump(delta)
	
	move_and_slide()  # Apply velocity with collisions.
