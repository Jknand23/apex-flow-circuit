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
var is_grinding: bool = false  # Tracks if currently grinding on a rail.
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

# Add this new var for Cadence reference (set in _ready).
@onready var cadence_bar: ProgressBar = get_node("/root/BasicTrackRoot/UI/CadenceBar")  # Path to your ProgressBar.

# Function to get turn input direction.
# Returns: float - -1 (left), 0 (none), 1 (right).
func get_turn_input() -> float:
	var turn_direction: float = 0.0
	if Input.is_action_pressed(input_actions["left"]):
		turn_direction -= 1.0
	if Input.is_action_pressed(input_actions["right"]):
		turn_direction += 1.0
	return turn_direction

# Function to handle acceleration and velocity (updated for additive boost).
# @param delta: float - Time since last physics frame.
func apply_acceleration(delta: float) -> void:
	if not cadence_bar:
		push_error("Cadence bar not found - check node path.")
		return
	
	# Base acceleration (from Day 1) – build speed independently of Cadence.
	if Input.is_action_pressed(input_actions["forward"]):
		current_speed = min(current_speed + ACCELERATION * delta, MAX_SPEED)
	else:
		current_speed = max(current_speed - ACCELERATION * delta, 0.0)  # Decelerate.
	
	# Apply Cadence as an additive boost (up to +MAX_SPEED at 100%).
	var cadence_boost: float = (cadence_bar.current_cadence / 100.0) * MAX_SPEED  # 0 to MAX_SPEED extra.
	var boosted_speed: float = current_speed + cadence_boost
	
	var forward_direction := -global_transform.basis.z.normalized()  # Board forward.
	velocity.x = forward_direction.x * boosted_speed
	velocity.z = forward_direction.z * boosted_speed

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

# Function to apply gravity and jumping (updated to handle grind exit on jump).
# @param delta: float - Time since last physics frame.
func apply_gravity_and_jump(delta: float) -> void:
	if is_grinding:
		velocity.y = 0.0  # No gravity/fall during grind (basic lock-in).
		return
	
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		is_jumping = false  # Reset on land.
	
	if Input.is_action_just_pressed(input_actions["jump"]):
		if is_grinding:
			is_grinding = false  # Exit grind on jump.
		if is_on_floor() or is_grinding:  # Allow jump from ground or grind.
			velocity.y = JUMP_VELOCITY
			is_jumping = true

# Function to check for grind/hazard collisions after move_and_slide().
# Handles detection and state changes.
# @param collision_count: int - Number of slide collisions this frame.
func handle_collisions(collision_count: int) -> void:
	is_grinding = false  # Reset each frame; re-detect if still valid.
	
	for i in collision_count:
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if not collider: continue
		
		if collider.is_in_group("grindable") and not is_on_floor():
			is_grinding = true  # Start/continue grinding if off-ground and hitting rail.
			# Basic reward: Boost cadence slightly (tweak value for balance).
			cadence_bar.current_cadence = min(cadence_bar.current_cadence + 5.0, cadence_bar.max_value)
			cadence_bar.update_bar()
			break  # Only grind one rail at a time.
		
		if collider.is_in_group("hazard"):
			handle_bail()  # Trigger bail on hazard hit.

# Function for bail logic (resets cadence, could add respawn later).
func handle_bail() -> void:
	cadence_bar.current_cadence = 0.0
	cadence_bar.update_bar()
	# TODO: Add respawn or stun effect (e.g., reset position/velocity).

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
	
	handle_collisions(get_slide_collision_count())  # Check for grinds/bails post-slide.
