## Simple Follow Camera Script
## Attach this to a Camera3D to make it follow its parent
## This ensures the camera stays with the player even if parenting fails

extends Camera3D

# Offset from the parent (behind and above the player)
# Original was (0, 17.4, 25.4) - we'll use a middle ground
@export var offset: Vector3 = Vector3(0, 10, 15)  # Higher and further back
@export var look_ahead_distance: float = 5.0  # Look closer ahead for racing
@export var look_down_angle: float = 15.0  # Angle to look down at player

# The node to follow (defaults to parent)
var target: Node3D

func _ready() -> void:
	# Default to following parent
	target = get_parent()
	
	# Set initial position
	if target:
		position = offset
		rotation_degrees = Vector3(-20, 0, 0)  # Look down slightly

func _process(_delta: float) -> void:
	if not target:
		target = get_parent()
		return
		
	# Follow the player from behind
	if target:
		# Get the player's forward direction (they face -Z in Godot)
		var player_forward = -target.global_transform.basis.z
		var player_right = target.global_transform.basis.x
		var player_up = target.global_transform.basis.y
		
		# Calculate camera position behind the player
		var camera_offset = (
			player_forward * -offset.z +  # Behind the player
			player_up * offset.y +         # Above the player
			player_right * offset.x        # Side offset (0 by default)
		)
		
		# Set camera position
		global_position = target.global_position + camera_offset
		
		# Look slightly ahead and down at the player
		var look_target = target.global_position + player_forward * look_ahead_distance + Vector3(0, 1, 0)
		look_at(look_target, Vector3.UP)
		
		# Apply additional downward tilt
		rotation.x = deg_to_rad(-look_down_angle) 