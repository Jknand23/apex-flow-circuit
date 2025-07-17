# scripts/debug_wall_riding.gd
# Debug visualization for wall riding - shows up direction, gravity, and forward vectors
# Attach to a Node3D child of the player to visualize orientation

extends Node3D

## Reference to the player node
@onready var player: CharacterBody3D = get_parent()

## Debug draw settings
@export var draw_vectors: bool = true
@export var vector_length: float = 3.0
@export var vector_thickness: float = 0.1

var debug_meshes: Dictionary = {}

func _ready() -> void:
	if not player is CharacterBody3D:
		push_error("Parent must be a CharacterBody3D")
		return
	
	# Create debug meshes for each vector
	_create_debug_mesh("up", Color.GREEN)
	_create_debug_mesh("forward", Color.BLUE)
	_create_debug_mesh("right", Color.RED)
	_create_debug_mesh("gravity", Color.YELLOW)

## Creates a debug mesh for visualizing a vector
func _create_debug_mesh(name: String, color: Color) -> void:
	var mesh_instance = MeshInstance3D.new()
	var cylinder = CylinderMesh.new()
	cylinder.height = vector_length
	cylinder.top_radius = vector_thickness
	cylinder.bottom_radius = vector_thickness
	
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color
	material.emission_intensity = 2.0
	
	mesh_instance.mesh = cylinder
	mesh_instance.material_override = material
	mesh_instance.name = "Debug_" + name
	
	add_child(mesh_instance)
	debug_meshes[name] = mesh_instance

func _physics_process(_delta: float) -> void:
	if not draw_vectors or not player:
		_hide_all_meshes()
		return
	
	# Get player vectors
	var up_vector = player.global_transform.basis.y.normalized()
	var forward_vector = -player.global_transform.basis.z.normalized()
	var right_vector = player.global_transform.basis.x.normalized()
	
	# Get gravity from player script
	var gravity_vector = Vector3.DOWN
	if player.has_method("get_gravity_direction"):
		gravity_vector = player.call("get_gravity_direction")
	elif "current_gravity_direction" in player:
		gravity_vector = player.current_gravity_direction
	
	# Update debug meshes
	_update_debug_mesh("up", up_vector)
	_update_debug_mesh("forward", forward_vector)
	_update_debug_mesh("right", right_vector)
	_update_debug_mesh("gravity", gravity_vector)
	
	# Print debug info every 30 frames
	if Engine.get_process_frames() % 30 == 0:
		print("=== Wall Riding Debug ===")
		print("Player Up: ", up_vector)
		print("Player Forward: ", forward_vector)
		print("Gravity Direction: ", gravity_vector)
		print("Is on floor: ", player.is_on_floor())
		print("Up direction: ", player.up_direction)

## Updates a debug mesh to point in the given direction
func _update_debug_mesh(name: String, direction: Vector3) -> void:
	if not name in debug_meshes:
		return
		
	var mesh = debug_meshes[name]
	mesh.visible = true
	
	# Position at half length along direction
	mesh.position = direction * (vector_length * 0.5)
	
	# Look in the direction
	if direction != Vector3.UP and direction != Vector3.DOWN:
		mesh.look_at(mesh.global_position + direction, Vector3.UP)
		mesh.rotate_object_local(Vector3.RIGHT, PI/2)
	else:
		# Special case for up/down vectors
		mesh.rotation = Vector3.ZERO
		if direction == Vector3.DOWN:
			mesh.rotate_object_local(Vector3.RIGHT, PI)

func _hide_all_meshes() -> void:
	for mesh in debug_meshes.values():
		mesh.visible = false 