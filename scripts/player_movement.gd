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
const WALL_GRAVITY_MULTIPLIER: float = 4.0  # Make wall gravity stronger but not overwhelming
const GRAVITY_TRANSITION_SPEED: float = 10.0  # Increased for faster transitions, especially for walls
const ROTATION_TRANSITION_SPEED: float = 12.0  # Increased further for quicker rotation to full alignment
@export var enable_wall_rotation: bool = true  # Toggle player rotation during wall riding
const AIR_RESISTANCE: float = 4.5  # How much horizontal speed reduces in air per second

# Descriptive state vars.
var current_speed: float = 0.0
var is_jumping: bool = false
var is_grinding: bool = false  # Tracks if currently grinding on a rail.
var dodge_cooldowns := { "left": 0.0, "right": 0.0 }  # Timers for each dodge direction.
var current_gravity_direction: Vector3 = Vector3.DOWN  # Current gravity direction
var target_gravity_direction: Vector3 = Vector3.DOWN  # Target gravity direction for smooth transitions

# Map for input actions (expandable, no enums).
var input_actions := {
	"forward": "move_forward",  # Custom action for W.
	"left": "turn_left",        # Custom for A (turning).
	"right": "turn_right",      # Custom for D (turning).
	"jump": "player_jump",      # Custom for Space.
	"dodge_left": "dodge_left", # Custom for Q (left dodge burst).
	"dodge_right": "dodge_right" # Custom for E (right dodge burst).
}

# Node references with error checking
@onready var cadence_bar: ProgressBar = get_node("/root/BasicTrackRoot/UI/CadenceBar")
var trail: MeshInstance3D  # Will be set in _ready() with error checking

func _ready() -> void:
	# Add player to group for detection by interactive elements
	add_to_group("player")
	print("Player added to group 'player'. Player groups: ", get_groups())
	
	# Search recursively for the Trail node
	trail = find_trail_recursive(self)
	if trail:
		print("Found trail at path: ", get_path_to(trail))
	else:
		print("Trail not found anywhere in the scene tree")
	
	# Connect to gravity zones in the scene
	_connect_gravity_zones()

# Recursive function to find Trail node anywhere in the tree
func find_trail_recursive(node: Node) -> MeshInstance3D:
	# Check if this node is the trail
	if node is MeshInstance3D and node.name == "Trail":
		return node
	
	# Check all children recursively
	for child in node.get_children():
		var result = find_trail_recursive(child)
		if result:
			return result
	
	return null

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
	# Only allow acceleration/deceleration when on ground
	if is_on_floor():
		if Input.is_action_pressed(input_actions["forward"]):
			current_speed = min(current_speed + ACCELERATION * delta, MAX_SPEED)
		else:
			current_speed = max(current_speed - ACCELERATION * delta, 0.0)  # Decelerate.
	else:
		# In air: apply gentle air resistance only
		current_speed = max(current_speed - AIR_RESISTANCE * delta, 0.0)  # Natural air resistance
	
	# Apply Cadence as an additive boost (up to +MAX_SPEED at 100%).
	var cadence_boost: float = (cadence_bar.current_cadence / 100.0) * MAX_SPEED  # 0 to MAX_SPEED extra.
	var boosted_speed: float = current_speed + cadence_boost
	
	var forward_direction := -global_transform.basis.z.normalized()  # Board forward.
	
	# When wall riding, project movement along the wall surface
	var is_wall_riding = abs(current_gravity_direction.x) > 0.1 or abs(current_gravity_direction.z) > 0.1
	if is_wall_riding and is_on_floor():
		# Get the wall normal (opposite of gravity direction for walls)
		var wall_normal = -current_gravity_direction.normalized()
		# Project forward direction onto the wall plane
		forward_direction = forward_direction - wall_normal * forward_direction.dot(wall_normal)
		forward_direction = forward_direction.normalized()
		
		# Apply movement along the wall
		velocity = forward_direction * boosted_speed
	else:
		# Normal movement
		velocity.x = forward_direction.x * boosted_speed
		velocity.z = forward_direction.z * boosted_speed

# Function to apply turning (rotation).
# @param delta: float - Time since last physics frame.
# @param turn_input: float - Direction from get_turn_input().
func apply_turning(delta: float, turn_input: float) -> void:
	if abs(turn_input) > 0:
		var turn_angle = turn_input * TURN_SPEED * delta * -1
		rotate(up_direction.normalized(), turn_angle)

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
		# Smooth gravity transition
		if current_gravity_direction != target_gravity_direction:
			current_gravity_direction = current_gravity_direction.lerp(target_gravity_direction, GRAVITY_TRANSITION_SPEED * delta)
			current_gravity_direction = current_gravity_direction.normalized()
			print("Gravity transition: ", current_gravity_direction)
			
			# Rotate player to align with surface
			if enable_wall_rotation:
				_align_player_to_surface(delta)
		
		# Apply gravity in current direction (stronger for wall riding)
		var gravity_strength = abs(GRAVITY)
		# Apply strong wall gravity if there's any horizontal component
		if abs(current_gravity_direction.x) > 0.01 or abs(current_gravity_direction.z) > 0.01:
			gravity_strength *= WALL_GRAVITY_MULTIPLIER  # 4x stronger for wall riding
			print("Wall riding gravity applied: ", current_gravity_direction, " strength: ", gravity_strength)
		
		# Apply gravity
		velocity += current_gravity_direction * gravity_strength * delta
		
		# Limit maximum speed along gravity direction
		var velocity_along_gravity = velocity.dot(current_gravity_direction.normalized())
		if velocity_along_gravity > 15.0:  # Note: positive since direction is down
			velocity -= current_gravity_direction.normalized() * (velocity_along_gravity - 15.0)
	else:
		is_jumping = false  # Reset on land.
	
	if Input.is_action_just_pressed(input_actions["jump"]):
		if is_grinding:
			is_grinding = false  # Exit grind on jump.
		if is_on_floor() or is_grinding:  # Allow jump from ground or grind.
			velocity += up_direction * JUMP_VELOCITY
			is_jumping = true
			print("GENERAL JUMP: Applied along ", up_direction, " velocity: ", JUMP_VELOCITY)

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

# Function to update trail based on cadence.
# Called every frame to sync trail length and glow with speed.
func update_trail() -> void:
	if not trail or not cadence_bar:
		return
	
	var norm_cadence = cadence_bar.current_cadence / cadence_bar.MAX_CADENCE
	
	# Make scaling more dramatic (0.1x to 5x length)
	trail.scale.z = lerp(0.1, 100.0, norm_cadence)
	
	# Make sure trail is visible
	trail.visible = true
	
	# Fade trail opacity with cadence
	if trail.material_override:
		trail.material_override.albedo_color.a = lerp(0.5, 1.0, norm_cadence)
		
		# Change color intensity for glow effect
		var glow_intensity = lerp(1.0, 3.0, norm_cadence)
		trail.material_override.emission = Color(0, 1, 1) * glow_intensity

## Connects to all gravity flip zones and wall riding zones in the scene
func _connect_gravity_zones() -> void:
	# Wait for scene to be ready
	await get_tree().process_frame
	
	# Find all gravity zones in the scene
	var zones = get_tree().get_nodes_in_group("gravity_zones")
	print("Found ", zones.size(), " gravity zones in scene")
	
	for zone in zones:
		print("Checking zone: ", zone.name, " - signals: ", zone.get_signal_list())
		if zone.has_signal("gravity_flipped"):
			zone.gravity_flipped.connect(_on_gravity_flipped)
			print("Connected to gravity zone: ", zone.name)
		elif zone.has_signal("wall_riding_changed"):
			zone.wall_riding_changed.connect(_on_gravity_flipped)
			print("Connected to wall riding zone: ", zone.name)
		else:
			print("Zone ", zone.name, " has no recognized gravity signals")

## Handles gravity direction changes from zones
## @param body The body entering the zone (should be this player)
## @param gravity_direction The new gravity direction vector
func _on_gravity_flipped(body: Node3D, gravity_direction: Vector3) -> void:
	print("Gravity signal received - Body: ", body.name, " Target gravity: ", gravity_direction)
	if body == self:
		target_gravity_direction = gravity_direction.normalized()
		# For wall riding (horizontal gravity), make transition instant and add initial pull
		if abs(target_gravity_direction.y) < 0.1:
			current_gravity_direction = target_gravity_direction
			var initial_pull = 5.0  # Initial velocity towards wall
			velocity += target_gravity_direction * initial_pull
			print("Wall riding started - instant gravity: ", current_gravity_direction, " initial pull: ", initial_pull)
		print("✓ GRAVITY CHANGING to: ", target_gravity_direction)
	else:
		print("✗ Body is not player, ignoring signal")

## Smoothly aligns the player to the surface they're riding on
## @param delta Time delta for smooth interpolation
func _align_player_to_surface(delta: float) -> void:
	# Calculate new up direction based on gravity (opposite of gravity is up)
	var new_up = -current_gravity_direction.normalized()
	
	# Get current transform components
	var current_transform = global_transform
	var current_up = current_transform.basis.y.normalized()
	var current_forward = -current_transform.basis.z.normalized()
	
	# If already aligned, skip
	if new_up.is_equal_approx(current_up):
		return
	
	# Calculate the rotation axis (perpendicular to both current and target up)
	var rotation_axis = current_up.cross(new_up).normalized()
	
	# If vectors are opposite, we need a different approach
	if rotation_axis.length() < 0.01:
		# Use current forward as rotation axis for 180 degree flip
		rotation_axis = current_forward
	
	# Calculate rotation angle
	var angle = current_up.angle_to(new_up)
	
	# Create target transform
	var target_basis = current_transform.basis.rotated(rotation_axis, angle)
	
	# Smooth interpolation
	var lerp_factor = min(ROTATION_TRANSITION_SPEED * delta, 1.0)
	var current_quat = current_transform.basis.get_rotation_quaternion()
	var target_quat = target_basis.get_rotation_quaternion()
	var interpolated_quat = current_quat.slerp(target_quat, lerp_factor)
	
	# Apply the interpolated rotation while preserving scale
	var scale = current_transform.basis.get_scale()
	global_transform.basis = Basis(interpolated_quat).scaled(scale)
	
	print("Aligning player - Current up: ", current_up, " Target up: ", new_up, " Angle: ", rad_to_deg(angle), " degrees")

## Handles wall riding collision behavior to prevent bouncing
func _handle_wall_collisions() -> void:
	# Check if we're hitting walls while wall riding
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		var normal = collision.get_normal()
		
		# If we hit a wall in the direction we're being pulled
		var wall_direction = current_gravity_direction.normalized()
		var collision_alignment = normal.dot(-wall_direction)
		
		if collision_alignment > 0.7:  # Wall is aligned with our gravity direction
			# Dampen bouncing by reducing velocity away from wall
			var velocity_away_from_wall = velocity.dot(normal)
			if velocity_away_from_wall > 0:  # Moving away from wall
				velocity -= normal * velocity_away_from_wall * 0.8  # Reduce bounce
				print("Wall contact - dampening bounce, wall normal: ", normal)

func _physics_process(delta: float) -> void:
	if not is_on_floor() and velocity.y == 0 and not is_jumping:  # Rare edge case check (ignore during jumps).
		push_error("Physics error: Not on floor with zero Y velocity.")
	
	# Debug player position every few frames
	if Engine.get_process_frames() % 60 == 0:  # Every 60 frames (1 second at 60fps)
		print("Player position: ", global_position, " Current gravity: ", current_gravity_direction)
	
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
	
	# Set up_direction based on current gravity for proper floor/wall detection
	up_direction = -current_gravity_direction.normalized()
	
	move_and_slide()  # Apply velocity with collisions.
	
	# Special handling for wall riding collisions
	if abs(current_gravity_direction.x) > 0.01 or abs(current_gravity_direction.z) > 0.01:
		_handle_wall_collisions()
	
	handle_collisions(get_slide_collision_count())  # Check for grinds/bails post-slide.

func _process(_delta: float) -> void:
	update_trail()

## Returns the current gravity direction for debugging
func get_gravity_direction() -> Vector3:
	return current_gravity_direction
