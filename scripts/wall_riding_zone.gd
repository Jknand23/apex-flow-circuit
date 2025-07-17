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

## Reference to any wall mesh for normal detection
@export var wall_mesh: StaticBody3D

func _ready() -> void:
	# Add this zone to a group for easy identification
	add_to_group("wall_riding_zones")
	add_to_group("gravity_zones")  # Also part of gravity system
	
	# Ensure Area3D is properly configured for detection
	monitoring = true
	monitorable = true
	
	print("Wall riding zone initialized: ", name)
	print("Groups: ", get_groups())
	print("Wall surface gravity: ", wall_surface_gravity)
	print("Monitoring enabled: ", monitoring)
	print("Signal connections: ", get_signal_list())
	
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
	print("Auto-detected wall gravity direction: ", wall_surface_gravity)

## Called when a body enters the wall riding zone.
## Applies wall-specific gravity to enable riding up the surface.
## @param body The body that entered the area.
func _on_body_entered(body):
	print("Body entered wall riding zone: ", body.name, " - Groups: ", body.get_groups())
	if body.is_in_group("player"):
		print("Player entered wall riding zone - gravity: ", wall_surface_gravity)
		wall_riding_changed.emit(body, wall_surface_gravity)
	else:
		print("Non-player body entered zone: ", body.name)

## Called when a body exits the wall riding zone.
## Resets gravity to normal downward direction.
## @param body The body that exited the area.
func _on_body_exited(body):
	if body.is_in_group("player"):
		print("Player exited wall riding zone - resetting gravity")
		wall_riding_changed.emit(body, Vector3.DOWN)

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