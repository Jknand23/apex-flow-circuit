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
const AIR_RESISTANCE: float = 2.5  # How much horizontal speed reduces in air per second (global)
const BOUNCE_PAD_AIR_RESISTANCE: float = 3.5  # Additional air resistance after bounce pads
const AIR_RESISTANCE_DURATION: float = 3.0  # Seconds to apply extra air resistance after bounce pad

# Descriptive state vars.
var current_speed: float = 0.0
var is_jumping: bool = false
var is_grinding: bool = false  # Tracks if currently grinding on a rail.
var dodge_cooldowns := { "left": 0.0, "right": 0.0 }  # Timers for each dodge direction.
var current_gravity_direction: Vector3 = Vector3.DOWN  # Current gravity direction
var target_gravity_direction: Vector3 = Vector3.DOWN  # Target gravity direction for smooth transitions
var wall_ride_anchor: Area3D = null  # Reference to current wall ride anchor
var bounce_pad_air_resistance_timer: float = 0.0  # Timer for extra air resistance after bounce pad
var current_gravity_multiplier: float = 1.0  # Current gravity strength multiplier from zones

# Multiplayer sync variables
var sync_position: Vector3 = Vector3.ZERO
var sync_rotation: float = 0.0
var sync_velocity: Vector3 = Vector3.ZERO
const SYNC_RATE: float = 0.05  # Sync every 50ms
var sync_timer: float = 0.0

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
@onready var cadence_bar: ProgressBar = get_node_or_null("/root/BasicTrackRoot/UI/CadenceBar")
var trail: MeshInstance3D  # Will be set in _ready() with error checking
var gravity_indicator_label: Label  # Optional UI indicator for enhanced gravity

func _ready() -> void:
	# Add player to group for detection by interactive elements
	add_to_group("player")
	
	# Search recursively for the Trail node
	trail = find_trail_recursive(self)
	
	# Connect to gravity zones in the scene
	_connect_gravity_zones()
	
	# Try to find gravity indicator UI (optional)
	gravity_indicator_label = get_node_or_null("/root/BasicTrackRoot/UI/GravityIndicator")

## Sets the cadence bar reference (used in multiplayer to assign correct UI)
## @param bar The ProgressBar node to use for cadence display
func set_cadence_bar(bar: ProgressBar) -> void:
	cadence_bar = bar

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

## Enhanced ground detection that checks for ANY ground contact
## Uses collision detection to determine if any part of the player is touching surfaces
## @return bool True if any part of the player is touching the ground/surfaces
func is_touching_ground() -> bool:
	# First check the standard is_on_floor() for basic ground contact
	if is_on_floor():
		return true
	
	# Additionally check if we're colliding with any surfaces that could be considered "ground"
	# This includes walls during wall riding and any other collision surfaces
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		if collision:
			var normal = collision.get_normal()
			var collider = collision.get_collider()
			
			# Check if the collision normal is reasonably aligned with our "up" direction
			# This allows for wall riding and partial ground contact detection
			var up_alignment = normal.dot(up_direction.normalized())
			
			# Consider it ground contact if:
			# 1. Normal points "up" relative to our orientation (standard ground: up_alignment > 0.3)
			# 2. OR we're wall riding and any surface contact counts (for wall riding stability)
			var is_wall_riding = abs(current_gravity_direction.x) > 0.1 or abs(current_gravity_direction.z) > 0.1
			
			if up_alignment > 0.3 or (is_wall_riding and abs(up_alignment) > 0.1):
				# Exclude grindable rails from ground detection (they have special handling)
				if collider and not collider.is_in_group("grindable"):
					return true
	
	# Backup method: Use raycast to detect ground below player
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(
		global_position,
		global_position + current_gravity_direction.normalized() * 2.0  # Cast 2 units in gravity direction
	)
	query.exclude = [self]  # Don't hit ourselves
	query.collision_mask = 0xFFFFFFFF  # Check all collision layers
	
	var result = space_state.intersect_ray(query)
	if result:
		# Don't exclude grindable rails here since we want to detect when sitting on ground near rails
		if result.collider and not result.collider.is_in_group("grindable"):
			return true
	
	# Check if we're grinding (grinding rails count as "ground" for air resistance purposes)
	if is_grinding:
		return true
	
	return false

# Function to get turn input direction.
# Returns: float - -1 (left), 0 (none), 1 (right).
func get_turn_input() -> float:
	var turn_direction: float = 0.0
	if Input.is_action_pressed(input_actions["left"]):
		turn_direction -= 1.0
	if Input.is_action_pressed(input_actions["right"]):
		turn_direction += 1.0
	return turn_direction

# Function to handle acceleration and velocity (updated for global air resistance).
# @param delta: float - Time since last physics frame.
# @param process_input: bool - Whether to process player input (false for remote players).
func apply_acceleration(delta: float, process_input: bool = true) -> void:
	if not cadence_bar:
		push_error("Cadence bar not found - check node path.")
		return
	
	# Base acceleration (from Day 1) – build speed independently of Cadence.
	# Only allow acceleration/deceleration when touching ground (using enhanced detection)
	var touching_ground = is_touching_ground()
	
	if touching_ground:
		if process_input and Input.is_action_pressed(input_actions["forward"]):
			current_speed = min(current_speed + ACCELERATION * delta, MAX_SPEED)
		else:
			current_speed = max(current_speed - ACCELERATION * delta, 0.0)  # Decelerate.
	else:
		# In air: apply global air resistance to simulate realistic physics
		current_speed = max(current_speed - AIR_RESISTANCE * delta, 0.0)
		
		# Apply additional air resistance if we recently hit a bounce pad
		if bounce_pad_air_resistance_timer > 0.0:
			current_speed = max(current_speed - BOUNCE_PAD_AIR_RESISTANCE * delta, 0.0)
	
	# Apply Cadence as an additive boost (up to +MAX_SPEED at 100%).
	var cadence_boost: float = (cadence_bar.current_cadence / 100.0) * MAX_SPEED  # 0 to MAX_SPEED extra.
	var boosted_speed: float = current_speed + cadence_boost
	
	var forward_direction := -global_transform.basis.z.normalized()  # Board forward.
	
	# When wall riding, project movement along the wall surface
	var is_wall_riding = abs(current_gravity_direction.x) > 0.1 or abs(current_gravity_direction.z) > 0.1
	if is_wall_riding and is_touching_ground():
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
	
	var effective_strength = DODGE_STRENGTH if is_touching_ground() else DODGE_STRENGTH * AIR_DODGE_MULTIPLIER
	var right_direction := global_transform.basis.x.normalized()  # Local right.
	velocity += right_direction * direction * effective_strength
	dodge_cooldowns[cooldown_key] = DODGE_COOLDOWN  # Start cooldown.

# Function to apply gravity and jumping (updated to handle grind exit on jump).
# @param delta: float - Time since last physics frame.
# @param process_input: bool - Whether to process player input (false for remote players).
func apply_gravity_and_jump(delta: float, process_input: bool = true) -> void:
	if is_grinding:
		velocity.y = 0.0  # No gravity/fall during grind (basic lock-in).
		return
	
	if not is_touching_ground():
		# Smooth gravity transition
		if current_gravity_direction != target_gravity_direction:
			current_gravity_direction = current_gravity_direction.lerp(target_gravity_direction, GRAVITY_TRANSITION_SPEED * delta)
			current_gravity_direction = current_gravity_direction.normalized()
			
			# Rotate player to align with surface
			if enable_wall_rotation:
				_align_player_to_surface(delta)
		
		# Apply gravity in current direction (stronger for wall riding)
		var gravity_strength = abs(GRAVITY)
		
		# Apply wall gravity multiplier if there's any horizontal component
		if abs(current_gravity_direction.x) > 0.01 or abs(current_gravity_direction.z) > 0.01:
			gravity_strength *= WALL_GRAVITY_MULTIPLIER  # 4x stronger for wall riding
		
		# Apply enhanced gravity multiplier from zones
		gravity_strength *= current_gravity_multiplier
		
		# Apply gravity
		velocity += current_gravity_direction * gravity_strength * delta
		
		# Limit maximum speed along gravity direction
		var velocity_along_gravity = velocity.dot(current_gravity_direction.normalized())
		if velocity_along_gravity > 15.0:  # Note: positive since direction is down
			velocity -= current_gravity_direction.normalized() * (velocity_along_gravity - 15.0)
	else:
		is_jumping = false  # Reset on land.
	
	if process_input and Input.is_action_just_pressed(input_actions["jump"]):
		if is_grinding:
			is_grinding = false  # Exit grind on jump.
		if is_touching_ground() or is_grinding:  # Allow jump from ground or grind using enhanced detection.
			velocity += up_direction * JUMP_VELOCITY
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
		# elif collider.is_in_group("grindable") and is_on_floor():
		# 	print("Hit grindable but ON FLOOR - jump higher!")  # Debug
		
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
	# Wait for scene to be ready with multiple frames for safety
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Find all gravity zones in the scene
	var zones = get_tree().get_nodes_in_group("gravity_zones")
	var enhanced_zones = get_tree().get_nodes_in_group("enhanced_gravity_zones")
	
	# Combine both zone types
	zones.append_array(enhanced_zones)
	
	for zone in zones:
		if zone.has_signal("gravity_flipped"):
			zone.gravity_flipped.connect(_on_gravity_flipped)
		elif zone.has_signal("wall_riding_changed"):
			zone.wall_riding_changed.connect(_on_gravity_flipped)
		elif zone.has_signal("gravity_enhanced"):
			zone.gravity_enhanced.connect(_on_gravity_enhanced)

## Handles gravity direction changes from zones
## @param body The body entering the zone (should be this player)
## @param gravity_direction The new gravity direction vector
func _on_gravity_flipped(body: Node3D, gravity_direction: Vector3) -> void:
	if body == self:
		target_gravity_direction = gravity_direction.normalized()
		# For wall riding (horizontal gravity), make transition instant and add initial pull
		if abs(target_gravity_direction.y) < 0.1:
			current_gravity_direction = target_gravity_direction
			var initial_pull = 5.0  # Initial velocity towards wall
			velocity += target_gravity_direction * initial_pull

## Handles enhanced gravity from zones that modify gravity strength
## @param body The body entering the zone (should be this player)
## @param gravity_direction The gravity direction vector
## @param gravity_multiplier The strength multiplier for gravity
func _on_gravity_enhanced(body: Node3D, gravity_direction: Vector3, gravity_multiplier: float) -> void:
	if body == self:
		# Update gravity direction if specified
		if gravity_direction != Vector3.ZERO:
			target_gravity_direction = gravity_direction.normalized()
			current_gravity_direction = gravity_direction.normalized()
		
		# Update gravity strength multiplier
		current_gravity_multiplier = gravity_multiplier

## Smoothly aligns the player to the surface they're riding on
## @param delta Time delta for smooth interpolation
func _align_player_to_surface(delta: float) -> void:
	var target_transform: Transform3D
	var use_anchor = false
	
	# If we have a wall ride anchor, use its orientation
	if wall_ride_anchor and wall_ride_anchor.has_method("get_target_transform"):
		if wall_ride_anchor.lock_to_transform:
			# Direct transform copy
			target_transform = wall_ride_anchor.get_target_transform()
			use_anchor = true
		else:
			# Just use the up direction from anchor
			var anchor_up = wall_ride_anchor.get_up_direction()
			var new_up = anchor_up
			
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
			target_transform = current_transform
			target_transform.basis = current_transform.basis.rotated(rotation_axis, angle)
			use_anchor = true
	
	# Fallback to gravity-based alignment if no anchor
	if not use_anchor:
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
		target_transform = current_transform
		target_transform.basis = current_transform.basis.rotated(rotation_axis, angle)
	
	# Smooth interpolation
	var lerp_speed = wall_ride_anchor.alignment_speed if wall_ride_anchor and "alignment_speed" in wall_ride_anchor else ROTATION_TRANSITION_SPEED
	var lerp_factor = min(lerp_speed * delta, 1.0)
	
	var current_quat = global_transform.basis.get_rotation_quaternion()
	var target_quat = target_transform.basis.get_rotation_quaternion()
	var interpolated_quat = current_quat.slerp(target_quat, lerp_factor)
	
	# Apply the interpolated rotation while preserving scale and position
	var scale = global_transform.basis.get_scale()
	var new_basis = Basis(interpolated_quat).scaled(scale)
	
	if use_anchor and wall_ride_anchor.lock_to_transform:
		# Also lerp position if locked to transform
		global_position = global_position.lerp(target_transform.origin, lerp_factor)
	
	global_transform.basis = new_basis

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

func _physics_process(delta: float) -> void:
	if not is_touching_ground() and velocity.y == 0 and not is_jumping:  # Updated to use enhanced ground detection
		push_error("Physics error: Not touching ground with zero Y velocity.")
	
	# For multiplayer: only process input if we have authority over this player
	var process_input = true
	if multiplayer.has_multiplayer_peer() and is_multiplayer_authority():
		process_input = true
	elif multiplayer.has_multiplayer_peer() and not is_multiplayer_authority():
		process_input = false
		# TODO: Add interpolation for remote players here
	
	# Decrement bounce pad air resistance timer
	if bounce_pad_air_resistance_timer > 0.0:
		bounce_pad_air_resistance_timer -= delta
	
	# Decrement dodge cooldowns every frame.
	for key in dodge_cooldowns:
		if dodge_cooldowns[key] > 0:
			dodge_cooldowns[key] -= delta
	
	var turn_input := get_turn_input() if process_input else 0.0
	
	apply_acceleration(delta, process_input)
	apply_turning(delta, turn_input)
	
	# Check for dodge inputs (works on ground or in air) - updated to use enhanced detection.
	if process_input:
		if Input.is_action_just_pressed(input_actions["dodge_left"]):
			apply_dodge(-2.0)
		if Input.is_action_just_pressed(input_actions["dodge_right"]):
			apply_dodge(2.0)
	
	apply_gravity_and_jump(delta, process_input)
	
	# Set up_direction based on current gravity for proper floor/wall detection
	up_direction = -current_gravity_direction.normalized()
	
	move_and_slide()  # Apply velocity with collisions.
	
	# Special handling for wall riding collisions
	if abs(current_gravity_direction.x) > 0.01 or abs(current_gravity_direction.z) > 0.01:
		_handle_wall_collisions()
	
	handle_collisions(get_slide_collision_count())  # Check for grinds/bails post-slide.
	
	# Handle multiplayer synchronization
	if multiplayer.has_multiplayer_peer():
		if is_multiplayer_authority():
			# Send our position to other players
			sync_timer += delta
			if sync_timer >= SYNC_RATE:
				sync_timer = 0.0
				_receive_player_state.rpc(global_position, rotation.y, velocity)
		else:
			# Interpolate to received position for remote players
			global_position = global_position.lerp(sync_position, 10.0 * delta)
			rotation.y = lerp_angle(rotation.y, sync_rotation, 10.0 * delta)
			velocity = velocity.lerp(sync_velocity, 10.0 * delta)

func _process(_delta: float) -> void:
	update_trail()
	
	# Visual indicator for enhanced gravity
	if current_gravity_multiplier > 1.1 and trail and trail.material_override:
		# Tint trail red when in enhanced gravity zone
		var tint_strength = (current_gravity_multiplier - 1.0) / 2.5  # 0 to 1 range
		trail.material_override.emission = Color(1, 1 - tint_strength, 1 - tint_strength) * 2.0
	elif trail and trail.material_override:
		# Reset to normal cyan color
		var norm_cadence = cadence_bar.current_cadence / cadence_bar.MAX_CADENCE if cadence_bar else 0.5
		var glow_intensity = lerp(1.0, 3.0, norm_cadence)
		trail.material_override.emission = Color(0, 1, 1) * glow_intensity
	
	# Update UI indicator if available
	if gravity_indicator_label:
		if current_gravity_multiplier > 1.1:
			gravity_indicator_label.text = "GRAVITY x%.1f" % current_gravity_multiplier
			gravity_indicator_label.modulate = Color(1, 0.5, 0.5)
			gravity_indicator_label.visible = true
		else:
			gravity_indicator_label.visible = false

## Returns the current gravity direction for debugging
func get_gravity_direction() -> Vector3:
	return current_gravity_direction

## Sets the wall ride anchor for orientation
func set_wall_ride_anchor(anchor: Area3D) -> void:
	wall_ride_anchor = anchor

## Clears the wall ride anchor
func clear_wall_ride_anchor(anchor: Area3D) -> void:
	if wall_ride_anchor == anchor:
		wall_ride_anchor = null

## Activates additional air resistance for the specified duration (used by bounce pads)
## This adds extra air resistance on top of the global air resistance
func activate_air_resistance() -> void:
	bounce_pad_air_resistance_timer = AIR_RESISTANCE_DURATION

## Instantly snap the player's rotation to match the given gravity direction
## Used by gravity zones with snap alignment enabled
## @param gravity_direction The gravity vector to align against
func snap_to_gravity_alignment(gravity_direction: Vector3) -> void:
	var new_up = -gravity_direction.normalized()
	var current_forward = -global_transform.basis.z
	
	# Calculate new basis aligned with gravity
	var new_basis = Basis()
	
	# Handle different gravity directions
	if abs(new_up.dot(Vector3.UP)) < 0.99:  # Wall or angled surface
		# For wall riding, we want to face "up" the wall (vertical direction)
		var new_forward: Vector3
		
		# Calculate what "up" means relative to the wall
		# Project world up onto the wall plane
		var world_up_on_wall = Vector3.UP - Vector3.UP.dot(new_up) * new_up
		world_up_on_wall = world_up_on_wall.normalized()
		
		# If we can use world up as forward (it's not parallel to new_up)
		if world_up_on_wall.length() > 0.1:
			new_forward = world_up_on_wall
		else:
			# Fallback for ceiling/floor - maintain some forward direction
			new_forward = Vector3.FORWARD if abs(Vector3.FORWARD.dot(new_up)) < 0.9 else Vector3.RIGHT
			new_forward = new_forward - new_forward.dot(new_up) * new_up
			new_forward = new_forward.normalized()
		
		# Calculate right vector
		var new_right = new_forward.cross(new_up).normalized()
		
		# Recalculate forward to ensure orthogonality
		new_forward = new_up.cross(new_right).normalized()
		
		# Set the basis
		new_basis.x = new_right
		new_basis.y = new_up
		new_basis.z = -new_forward
	else:
		# For up/down gravity, maintain current rotation around Y
		new_basis = global_transform.basis
		new_basis.y = new_up
	
	# Preserve the original scale before applying rotation
	var original_scale = global_transform.basis.get_scale()
	
	# Apply the new transform instantly while preserving scale
	global_transform.basis = new_basis.scaled(original_scale)
	
	# Ensure gravity directions are updated immediately
	current_gravity_direction = gravity_direction.normalized()
	target_gravity_direction = gravity_direction.normalized()

## RPC function to receive player state from other players
## @param pos The position of the remote player
## @param rot_y The Y rotation of the remote player
## @param vel The velocity of the remote player
@rpc("any_peer", "call_remote", "unreliable")
func _receive_player_state(pos: Vector3, rot_y: float, vel: Vector3) -> void:
	# Only accept updates from the player who has authority
	var sender_id = multiplayer.get_remote_sender_id()
	if sender_id == get_multiplayer_authority():
		sync_position = pos
		sync_rotation = rot_y
		sync_velocity = vel
