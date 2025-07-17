# scripts/gravity_flip_zone.gd
# This script defines a zone that, when entered by the player,
# changes the direction of gravity and optionally snaps the player into position.

## The GravityFlipZone class extends Area3D to detect when a body enters or exits its collision shape.
## It is designed to be attached to an Area3D node with a CollisionShape3D.
class_name GravityFlipZone
extends Area3D

## Emitted when a body enters the gravity flip zone.
## @param body The body that entered the zone.
## @param gravity_direction The new direction for gravity.
signal gravity_flipped(body, gravity_direction)

## The direction gravity will point to within this zone.
## This vector is exported so it can be set in the Godot editor,
## allowing for different gravity directions for each zone.
@export var zone_gravity_direction: Vector3 = Vector3.DOWN

## Enable snap-to-position for instant alignment
@export var enable_snap_alignment: bool = true

## How far to push the player towards the surface when snapping (helps ensure contact)
@export var snap_push_distance: float = 2.0

## Optional: Set a specific rotation for the player (in degrees)
@export var snap_rotation_degrees: Vector3 = Vector3.ZERO

## Whether to use the snap rotation or calculate it based on gravity
@export var use_custom_rotation: bool = false

func _ready() -> void:
	# Add this zone to a group for easy finding
	add_to_group("gravity_zones")


## Called when a body enters the collision shape of this Area3D.
## It checks if the entering body is the player and, if so,
## emits the gravity_flipped signal with the new gravity direction.
## @param body The body that entered the area.
func _on_body_entered(body):
	if body.is_in_group("player"):
		gravity_flipped.emit(body, zone_gravity_direction)
		
		# Apply snap alignment if enabled
		if enable_snap_alignment:
			_snap_player_alignment(body)


## Called when a body exits the collision shape of this Area3D.
## It checks if the exiting body is the player and, if so,
## emits the gravity_flipped signal to reset gravity to its default direction (down).
## @param body The body that exited the area.
func _on_body_exited(body):
	if body.is_in_group("player"):
		gravity_flipped.emit(body, Vector3.DOWN)


## Instantly snaps the player to the proper alignment for the gravity direction
## @param player The player body to snap
func _snap_player_alignment(player: Node3D) -> void:
	if not player is CharacterBody3D:
		return
	
	# First try to use the player's built-in snap method if available
	if player.has_method("snap_to_gravity_alignment"):
		player.call("snap_to_gravity_alignment", zone_gravity_direction)
		
		# Push the player slightly towards the surface to ensure contact
		if snap_push_distance > 0:
			player.global_position += zone_gravity_direction.normalized() * snap_push_distance
		
		# Add velocity towards the surface
		if "velocity" in player:
			player.velocity += zone_gravity_direction.normalized() * 10.0
		
		return
	
	# Fallback: Manual alignment if player doesn't have the method
	# Calculate the new up direction (opposite of gravity)
	var new_up = -zone_gravity_direction.normalized()
	
	# Get player's current forward direction
	var current_forward = -player.global_transform.basis.z
	
	# If using custom rotation, apply it directly
	if use_custom_rotation:
		player.rotation_degrees = snap_rotation_degrees
	else:
		# Calculate the new basis aligned with the gravity
		var new_basis = Basis()
		
		# Handle different gravity directions
		if abs(new_up.dot(Vector3.UP)) < 0.99:  # Not pointing straight up or down
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
			new_basis = player.global_transform.basis
			new_basis.y = new_up
	
		# Preserve the original scale before applying rotation
		var original_scale = player.global_transform.basis.get_scale()
		
		# Apply the new transform while preserving scale
		player.global_transform.basis = new_basis.scaled(original_scale)
	
	# Push the player slightly towards the surface to ensure contact
	if snap_push_distance > 0:
		player.global_position += zone_gravity_direction.normalized() * snap_push_distance
	
	# Set player velocity to move towards the surface
	if "velocity" in player:
		# Add velocity component towards the surface
		player.velocity += zone_gravity_direction.normalized() * 10.0
	
	print("Snapped player alignment - New up: ", new_up, " Gravity: ", zone_gravity_direction) 
