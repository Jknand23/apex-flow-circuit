# scripts/wall_ride_anchor.gd
# Invisible anchor point that orients the player for wall riding
# Place these along walls with the desired player orientation

extends Area3D

## How quickly the player aligns to this anchor's orientation
@export var alignment_speed: float = 10.0

## Whether to lock the player to this exact transform while in range
@export var lock_to_transform: bool = false

## Optional: Override gravity direction instead of using orientation
@export var override_gravity: bool = true
@export var gravity_direction: Vector3 = Vector3.LEFT

## Visual helper in editor
@export var show_preview: bool = true

## Reference to preview mesh
var preview_mesh: MeshInstance3D

func _ready() -> void:
	# Set up as wall riding anchor
	add_to_group("wall_ride_anchors")
	
	# Connect signals
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Create preview mesh for editor
	if Engine.is_editor_hint() and show_preview:
		_create_preview_mesh()

## Creates a preview mesh to show orientation in editor
func _create_preview_mesh() -> void:
	preview_mesh = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(2, 0.1, 1)  # Flat box to show "board" orientation
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0, 1, 1, 0.5)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	
	preview_mesh.mesh = box
	preview_mesh.material_override = material
	add_child(preview_mesh)

## When player enters, start orienting them
func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return
		
	# Store reference to this anchor on the player
	if body.has_method("set_wall_ride_anchor"):
		body.call("set_wall_ride_anchor", self)
	else:
		# Fallback: directly set gravity if player doesn't have the method
		if override_gravity and body.has_signal("wall_riding_changed"):
			body.emit_signal("wall_riding_changed", body, gravity_direction)

## When player exits, clear the anchor reference
func _on_body_exited(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return
		
	if body.has_method("clear_wall_ride_anchor"):
		body.call("clear_wall_ride_anchor", self)
	else:
		# Fallback: reset gravity
		if override_gravity and body.has_signal("wall_riding_changed"):
			body.emit_signal("wall_riding_changed", body, Vector3.DOWN)

## Gets the target transform for the player
func get_target_transform() -> Transform3D:
	return global_transform

## Gets the up direction based on this anchor's orientation
func get_up_direction() -> Vector3:
	return global_transform.basis.y.normalized()

## Editor functionality
func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	
	var collision_shape = get_child_count() > 0
	var has_collision = false
	for child in get_children():
		if child is CollisionShape3D:
			has_collision = true
			break
	
	if not has_collision:
		warnings.append("Add a CollisionShape3D to define the trigger area")
	
	return warnings 