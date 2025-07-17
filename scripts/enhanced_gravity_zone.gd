# scripts/enhanced_gravity_zone.gd
# Zone that modifies gravity strength and/or direction to control player physics.
# Useful for reducing bouncing on downhill areas or creating special physics zones.

## The EnhancedGravityZone class extends Area3D to modify gravity strength and direction.
## Unlike basic gravity zones, this can amplify gravity without changing direction.
class_name EnhancedGravityZone
extends Area3D

## Emitted when a body enters or exits the gravity zone.
## @param body The body that entered/exited the zone.
## @param gravity_direction The gravity direction vector.
## @param gravity_multiplier The strength multiplier for gravity.
signal gravity_enhanced(body, gravity_direction, gravity_multiplier)

## The direction gravity will point within this zone.
## Set to Vector3.DOWN to keep normal downward gravity.
@export var zone_gravity_direction: Vector3 = Vector3.DOWN

## Multiplier for gravity strength within this zone.
## Values > 1.0 increase gravity, < 1.0 decrease it.
## Useful values: 1.5-3.0 for reducing bounce on downhill areas.
@export var gravity_strength_multiplier: float = 3.5

## Whether this zone only affects downward gravity.
## When true, only applies when current gravity is already downward.
## Perfect for downhill areas without affecting wall riding.
@export var downhill_only: bool = true

## Visual indicator for the zone boundaries (editor only).
@export var show_zone_preview: bool = true

## Zone entry/exit tracking
var bodies_in_zone: Array[Node3D] = []

func _ready() -> void:
	# Add to appropriate groups
	add_to_group("gravity_zones")
	add_to_group("enhanced_gravity_zones")
	
	# Connect signals
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Create visual preview for editor
	if Engine.is_editor_hint() and show_zone_preview:
		_create_zone_preview()
	
	# print("Enhanced gravity zone ready - Direction: ", zone_gravity_direction, " Multiplier: ", gravity_strength_multiplier)

## Creates a visual preview of the zone in the editor
func _create_zone_preview() -> void:
	var preview = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(1, 1, 1)  # Will be scaled by CollisionShape3D
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(1, 0.5, 0, 0.3)  # Orange tint
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.flags_transparent = true
	
	preview.mesh = box
	preview.material_override = material
	add_child(preview)

## Called when a body enters the enhanced gravity zone.
## Applies gravity modifications based on zone settings.
## @param body The body that entered the area.
func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return
	
	# Check if this zone should only affect downward gravity
	if downhill_only:
		var current_gravity = _get_player_gravity_direction(body)
		if not _is_downward_gravity(current_gravity):
			print("Enhanced gravity zone: Ignoring non-downward gravity")
			return
	
	# Track body in zone
	if not body in bodies_in_zone:
		bodies_in_zone.append(body)
	
	# Apply enhanced gravity
	gravity_enhanced.emit(body, zone_gravity_direction, gravity_strength_multiplier)
	# print("Enhanced gravity applied - Direction: ", zone_gravity_direction, " Multiplier: ", gravity_strength_multiplier)

## Called when a body exits the enhanced gravity zone.
## Resets gravity to normal values.
## @param body The body that exited the area.
func _on_body_exited(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return
	
	# Remove from tracking
	bodies_in_zone.erase(body)
	
	# Reset to normal gravity
	gravity_enhanced.emit(body, Vector3.DOWN, 1.0)
	# print("Enhanced gravity reset to normal")

## Gets the current gravity direction from the player
## @param player The player node to check
## @return Vector3 The current gravity direction
func _get_player_gravity_direction(player: Node3D) -> Vector3:
	if player.has_method("get_gravity_direction"):
		return player.call("get_gravity_direction")
	elif "current_gravity_direction" in player:
		return player.current_gravity_direction
	else:
		return Vector3.DOWN

## Checks if the given gravity direction is considered "downward"
## @param gravity_dir The gravity direction to check
## @return bool True if gravity is primarily downward
func _is_downward_gravity(gravity_dir: Vector3) -> bool:
	# Consider gravity downward if Y component is dominant and positive
	return gravity_dir.y > 0.7 and abs(gravity_dir.x) < 0.3 and abs(gravity_dir.z) < 0.3

## Sets the zone to target specific areas
## @param multiplier The gravity strength multiplier
## @param downhill_only_mode Whether to only affect downward gravity
func configure_for_downhill(multiplier: float, downhill_only_mode: bool = true) -> void:
	gravity_strength_multiplier = multiplier
	downhill_only = downhill_only_mode
	zone_gravity_direction = Vector3.DOWN
	print("Configured enhanced gravity zone for downhill - Multiplier: ", multiplier) 