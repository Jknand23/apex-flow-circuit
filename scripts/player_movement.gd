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
const GRAVITY_TRANSITION_SPEED: float = 2.0  # How fast gravity transitions (higher = faster)
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
		# Smooth gravity transition
		if current_gravity_direction != target_gravity_direction:
			current_gravity_direction = current_gravity_direction.lerp(target_gravity_direction, GRAVITY_TRANSITION_SPEED * delta)
			current_gravity_direction = current_gravity_direction.normalized()
			
			# Update character rotation to match gravity
			var new_up = -current_gravity_direction
			var forward = global_transform.basis.z
			var right = forward.cross(new_up).normalized()
			forward = new_up.cross(right).normalized()
			
			global_transform.basis = Basis(right, new_up, forward).orthonormalized()
		
		# Apply gravity in current direction
		velocity += current_gravity_direction * abs(GRAVITY) * delta
	else:
		is_jumping = false  # Reset on land.
	
	if Input.is_action_just_pressed(input_actions["jump"]):
		if is_grinding:
			is_grinding = false  # Exit grind on jump.
		if is_on_floor() or is_grinding:  # Allow jump from ground or grind.
			velocity.y = JUMP_VELOCITY
			is_jumping = true
			print("REGULAR JUMP: Applied velocity.y = ", JUMP_VELOCITY)

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

## Connects to all gravity flip zones in the scene
func _connect_gravity_zones() -> void:
	# Wait for scene to be ready
	await get_tree().process_frame
	
	# Find all gravity zones in the scene
	var zones = get_tree().get_nodes_in_group("gravity_zones")
	for zone in zones:
		if zone.has_signal("gravity_flipped"):
			zone.gravity_flipped.connect(_on_gravity_flipped)
			print("Connected to gravity zone: ", zone.name)

## Handles gravity direction changes from zones
## @param body The body entering the zone (should be this player)
## @param gravity_direction The new gravity direction vector
func _on_gravity_flipped(body: Node3D, gravity_direction: Vector3) -> void:
	if body == self:
		target_gravity_direction = gravity_direction.normalized()
		print("Gravity flipping to: ", target_gravity_direction)

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

func _process(_delta: float) -> void:
	update_trail()
