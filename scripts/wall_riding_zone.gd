# scripts/wall_riding_zone.gd
# This script defines a zone that enables wall riding by directing gravity toward the wall surface.
# When the player enters this zone, gravity pulls them toward the wall, allowing 90-degree traversal.

## The WallRidingZone class extends Area3D to detect player entry and apply wall-specific gravity.
## It automatically calculates gravity direction based on the wall's surface normal.
class_name WallRidingZone
extends Area3D

## Emitted when a body enters or exits the wall riding zone.
## @param body The body that entered/exited the zone.
## @param gravity_direction The new direction for gravity.
signal wall_riding_changed(body, gravity_direction)

## The direction gravity will point within this zone (toward the wall).
## This can be set manually or calculated automatically from wall geometry.
@export var wall_surface_gravity: Vector3 = Vector3.LEFT
@export var auto_detect_wall_normal: bool = true
@export var wall_riding_strength: float = 1.0  # Multiplier for gravity strength on walls
@export var enable_surface_alignment: bool = true  # Whether player rotates to match wall surface

## Enable snap-to-position for instant alignment
@export var enable_snap_alignment: bool = true

## How far to push the player towards the surface when snapping (helps ensure contact)
@export var snap_push_distance: float = 2.0

## Reference to any wall mesh for normal detection
@export var wall_mesh: StaticBody3D

func _ready() -> void:
	# Add this zone to a group for easy identification
	add_to_group("wall_riding_zones")
	add_to_group("gravity_zones")  # Also part of gravity system
	
	# Force enable snap alignment if not set
	if enable_snap_alignment:
		# print("Snap alignment is ENABLED for ", name)
		pass
	else:
		# print("WARNING: Snap alignment was DISABLED, enabling it now")
		enable_snap_alignment = true
	
	# Ensure Area3D is properly configured for detection
	monitoring = true
	monitorable = true
	
	# print("Wall riding zone initialized: ", name)
	# print("Groups: ", get_groups())
	# print("Wall surface gravity: ", wall_surface_gravity)
	# print("Monitoring enabled: ", monitoring)
	# print("Signal connections: ", get_signal_list())
	
	# Auto-detect wall normal if enabled and wall mesh is assigned
	if auto_detect_wall_normal and wall_mesh:
		_calculate_wall_gravity()

## Calculates gravity direction based on the wall's surface normal
func _calculate_wall_gravity() -> void:
	if not wall_mesh:
		return
		
	# Get the wall's transform to determine its facing direction
	var wall_transform = wall_mesh.global_transform
	var wall_normal = wall_transform.basis.z.normalized()  # Assuming Z is the wall face normal
	
	# Gravity should point toward the wall (opposite of normal)
	wall_surface_gravity = -wall_normal
	# print("Auto-detected wall gravity direction: ", wall_surface_gravity)

## Called when a body enters the wall riding zone.
## Applies wall-specific gravity to enable riding up the surface.
## @param body The body that entered the area.
func _on_body_entered(body):
	# print("Body entered wall riding zone: ", body.name, " - Groups: ", body.get_groups())
	# print("Body class: ", body.get_class(), " Is CharacterBody3D: ", body is CharacterBody3D)
	
	# More flexible player detection
	var is_player = body.is_in_group("player") or body.name == "PlayerBoard" or body is CharacterBody3D
	
	if is_player:
		# print("Player entered wall riding zone - gravity: ", wall_surface_gravity)
		wall_riding_changed.emit(body, wall_surface_gravity)
		
		# Apply snap alignment if enabled
		if enable_snap_alignment:
			# print("Snap alignment is enabled, calling _snap_player_alignment")
			_snap_player_alignment(body)
		# else:
		# 	print("WARNING: Snap alignment is disabled!")
	# else:
	# 	print("Non-player body entered zone: ", body.name)

## Called when a body exits the wall riding zone.
## Resets gravity to normal downward direction.
## @param body The body that exited the area.
func _on_body_exited(body):
	if body.is_in_group("player"):
		# print("Player exited wall riding zone - resetting gravity")
		wall_riding_changed.emit(body, Vector3.DOWN)

## Instantly snaps the player to the proper alignment for the gravity direction
## @param player The player body to snap
func _snap_player_alignment(player: Node3D) -> void:
	if not player is CharacterBody3D:
		return
	
	# print("SNAP ALIGNMENT TRIGGERED - Player: ", player.name)
	
	# First try to use the player's built-in snap method if available
	if player.has_method("snap_to_gravity_alignment"):
		# print("Using player's snap_to_gravity_alignment method")
		player.call("snap_to_gravity_alignment", wall_surface_gravity)
		
		# Push the player slightly towards the surface to ensure contact
		if snap_push_distance > 0:
			player.global_position += wall_surface_gravity.normalized() * snap_push_distance
			# print("Pushed player towards wall by: ", snap_push_distance)
		
		# Add velocity towards the surface
		if "velocity" in player:
			player.velocity += wall_surface_gravity.normalized() * 10.0
			# print("Added velocity towards wall: ", wall_surface_gravity.normalized() * 10.0)
		
		return
	
	# print("Player doesn't have snap method, using fallback")
	
	# Fallback: Manual alignment if player doesn't have the method
	# Calculate the new up direction (opposite of gravity)
	var new_up = -wall_surface_gravity.normalized()
	
	# Get player's current forward direction
	var current_forward = -player.global_transform.basis.z
	
	# Calculate the new basis aligned with the gravity
	var new_basis = Basis()
	
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
	
	# Preserve the original scale before applying rotation
	var original_scale = player.global_transform.basis.get_scale()
	
	# Apply the new transform while preserving scale
	player.global_transform.basis = new_basis.scaled(original_scale)
	
	# Push the player slightly towards the surface to ensure contact
	if snap_push_distance > 0:
		player.global_position += wall_surface_gravity.normalized() * snap_push_distance
	
	# Set player velocity to move towards the surface
	if "velocity" in player:
		# Add velocity component towards the surface
		player.velocity += wall_surface_gravity.normalized() * 10.0
	
	# print("Snapped player alignment - New up: ", new_up, " Scale preserved: ", original_scale)

## Sets a custom wall direction for manual configuration
## @param direction The direction the wall faces (gravity will be opposite)
func set_wall_direction(direction: Vector3) -> void:
	wall_surface_gravity = -direction.normalized()
	auto_detect_wall_normal = false

## Convenience functions for common wall orientations
func set_left_wall() -> void:
	set_wall_direction(Vector3.RIGHT)

func set_right_wall() -> void:
	set_wall_direction(Vector3.LEFT)

func set_front_wall() -> void:
	set_wall_direction(Vector3.BACK)

func set_back_wall() -> void:
	set_wall_direction(Vector3.FORWARD) 