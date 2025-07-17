# scripts/debug_grind_rails.gd
# Debug script to visualize grindable rail collision shapes
# Attach to any Node3D in the scene to see all grindable collision shapes

extends Node3D

## Enable/disable debug visualization
@export var show_debug: bool = true

## Color for grindable collision shapes
@export var grindable_color: Color = Color(0, 1, 0, 0.5)

var debug_meshes: Array = []

func _ready() -> void:
	# Wait for scene to fully load
	await get_tree().process_frame
	
	if show_debug:
		_create_debug_visuals()

## Creates visual representations of all grindable collision shapes
func _create_debug_visuals() -> void:
	# Clear existing debug meshes
	for mesh in debug_meshes:
		mesh.queue_free()
	debug_meshes.clear()
	
	# Find all grindable objects
	var grindables = get_tree().get_nodes_in_group("grindable")
	# print("Found ", grindables.size(), " grindable objects")
	
	for grindable in grindables:
		# print("Grindable: ", grindable.name, " at ", grindable.global_position)
		
		# Find collision shapes in the grindable
		for child in grindable.get_children():
			if child is CollisionShape3D:
				_visualize_collision_shape(child)

## Creates a visual mesh for a collision shape
func _visualize_collision_shape(collision_shape: CollisionShape3D) -> void:
	if not collision_shape.shape:
		return
	
	var mesh_instance = MeshInstance3D.new()
	
	# Create mesh based on shape type
	if collision_shape.shape is BoxShape3D:
		var box_mesh = BoxMesh.new()
		box_mesh.size = collision_shape.shape.size
		mesh_instance.mesh = box_mesh
	# else:
	# 	print("Unsupported shape type for visualization")
	else:
		return
	
	# Create material
	var material = StandardMaterial3D.new()
	material.albedo_color = grindable_color
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh_instance.material_override = material
	
	# Position the mesh
	add_child(mesh_instance)
	mesh_instance.global_transform = collision_shape.global_transform
	
	debug_meshes.append(mesh_instance)
	
	# print("  - Collision shape at: ", collision_shape.global_position, " size: ", collision_shape.shape.size if collision_shape.shape is BoxShape3D else "unknown") 