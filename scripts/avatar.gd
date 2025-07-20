# scripts/avatar.gd
# Modular avatar handler for Kenney models. Positions on board; expandable for swaps.
# Attach to AvatarRoot in avatar.tscn.

extends Node3D

var model_instance: Node3D  # Will be found in _ready()
var skin_meshes = {}  # Dictionary to store mesh instances for each skin

# Called when the node enters the scene tree
func _ready():
	# Find the character model (should be a direct child)
	_find_character_model()
	
	# Pre-create mesh instances for each skin if this becomes necessary
	# _create_skin_mesh_instances()
	apply_squat_pose(0.8)  # Adjust intensity (0.0-1.0) for subtlety
	
	# Adjust character position to be better centered on board
	if model_instance:
		model_instance.position.z -= 0.01  # Move character back on board

# Function to set position offset for board riding.
# @param offset: Vector3 - Adjustment for feet-on-board (e.g., Vector3(0, board_height + 0.1, 0)).
func set_position_offset(offset: Vector3) -> void:
	if not model_instance:
		_find_character_model()  # Try to find it again
	
	if not model_instance:
		# Not critical for multiplayer - just skip positioning
		print("Model instance not found - character will use default position")
		return
	
	print("=== CHARACTER POSITIONING DEBUG ===")
	print("Model instance found: ", model_instance.name)
	print("Original position: ", model_instance.position)
	print("Original global position: ", model_instance.global_position)
	print("Applying offset: ", offset)
		
	model_instance.position = offset
	
	print("New position: ", model_instance.position)
	print("New global position: ", model_instance.global_position)
	print("AvatarRoot position: ", global_position)
	print("AvatarRoot global position: ", global_position)
	print("=== END DEBUG ===")

## Recursively finds all MeshInstance3D nodes with materials
## @param node The node to search from
## @param results Array to collect results
func _find_all_meshes_recursive(node: Node, results: Array) -> void:
	if node is MeshInstance3D:
		results.append(node)
		print("  Found MeshInstance3D: ", node.name, " at path: ", node.get_path())
		
		# Check mesh details
		if node.mesh:
			print("    - Mesh type: ", node.mesh.get_class())
			print("    - Surface count: ", node.get_surface_override_material_count())
			
			# Check all surface materials
			for i in range(node.get_surface_override_material_count()):
				var mat = node.get_surface_override_material(i)
				if mat:
					print("    - Surface ", i, " material: ", mat, " type: ", mat.get_class())
					if mat is ShaderMaterial:
						print("      - Shader: ", mat.shader)
						print("      - albedo_texture param: ", mat.get_shader_parameter("albedo_texture"))
		
		# Also check mesh resource materials
		if node.mesh and node.mesh.get_surface_count() > 0:
			print("    - Mesh resource surface count: ", node.mesh.get_surface_count())
			for i in range(node.mesh.get_surface_count()):
				var mat = node.mesh.surface_get_material(i)
				if mat:
					print("    - Mesh surface ", i, " material: ", mat, " type: ", mat.get_class())
	
	# Recursively check children
	for child in node.get_children():
		_find_all_meshes_recursive(child, results)

## Changes the avatar skin texture dynamically
## @param skin_texture_path: String - Path to the new skin texture
func change_skin(skin_texture_path: String) -> void:
	if not model_instance:
		_find_character_model()
	
	if not model_instance:
		push_error("Cannot change skin - character model not found")
		return
	
	print("=== CHANGING SKIN DEBUG ===")
	print("Attempting to change skin to: ", skin_texture_path)
	print("Model instance: ", model_instance, " at path: ", model_instance.get_path())
	
	# Load the new skin texture
	var new_skin = load(skin_texture_path)
	if not new_skin:
		push_error("Failed to load skin texture: " + skin_texture_path)
		return
	
	print("Successfully loaded texture: ", new_skin)
	
	# Find ALL character meshes recursively
	var all_meshes = []
	_find_all_meshes_recursive(model_instance, all_meshes)
	
	print("Found ", all_meshes.size(), " total MeshInstance3D nodes")
	
	var updated_materials = 0
	
	# Process each mesh
	for i in range(all_meshes.size()):
		var character_mesh = all_meshes[i]
		print("\nProcessing mesh ", i, ": ", character_mesh.name)
		
		# CRITICAL: Clear ALL existing materials first
		print("  - Clearing all existing materials...")
		
		# Clear all surface override materials
		for surface_idx in range(character_mesh.get_surface_override_material_count()):
			character_mesh.set_surface_override_material(surface_idx, null)
			print("    - Cleared surface override ", surface_idx)
		
		# Now apply our new shader material with the skin
		if character_mesh.mesh and character_mesh.mesh.get_surface_count() > 0:
			print("  - Mesh has ", character_mesh.mesh.get_surface_count(), " surfaces")
			
			# Get the shader from the original material or create new one
			var shader_to_use = preload("res://shaders/cel_shader.gdshader")
			
			for surface_idx in range(character_mesh.mesh.get_surface_count()):
				print("  - Creating new ShaderMaterial for surface ", surface_idx)
				
				# Create brand new ShaderMaterial
				var new_material = ShaderMaterial.new()
				new_material.shader = shader_to_use
				
				# Set shader parameters
				new_material.set_shader_parameter("cel_levels", 2.0)
				new_material.set_shader_parameter("base_color", Color.WHITE)
				new_material.set_shader_parameter("albedo_texture", new_skin)
				
				# Ensure material is unique to this instance
				new_material.resource_local_to_scene = true
				
				# Do NOT set next_pass - this might be causing issues
				new_material.next_pass = null
				
				# Apply as surface override
				character_mesh.set_surface_override_material(surface_idx, new_material)
				updated_materials += 1
				
				print("    - Applied new ShaderMaterial with skin texture")
				print("    - Shader: ", new_material.shader)
				print("    - Texture: ", new_material.get_shader_parameter("albedo_texture"))
				
				# Double-check it was applied
				var check_mat = character_mesh.get_surface_override_material(surface_idx)
				if check_mat:
					print("    - Verified material was applied: ", check_mat)
					print("    - Verified texture: ", check_mat.get_shader_parameter("albedo_texture"))
	
	print("\nSuccessfully updated ", updated_materials, " materials across ", all_meshes.size(), " meshes")
	print("=== END SKIN CHANGE DEBUG ===")
	
	# Force visual update - sometimes Godot needs this to refresh materials
	if model_instance:
		# Try multiple refresh techniques
		print("Attempting aggressive refresh techniques...")
		
		# 1. Toggle visibility
		model_instance.visible = false
		await get_tree().process_frame
		model_instance.visible = true
		
		# 2. Force material refresh on all meshes
		for mesh in all_meshes:
			if mesh.material_override:
				mesh.material_override = mesh.material_override
			
			# Force update the mesh instance
			mesh.notify_property_list_changed()
			
		# 3. Mark the entire scene tree as needing redraw
		if get_viewport() and get_viewport() is SubViewport:
			get_viewport().render_target_update_mode = SubViewport.UPDATE_ALWAYS
			
		print("Completed aggressive refresh")

## Recursively finds a MeshInstance3D node in the character model
## @param node: Node - Starting node to search from
func _find_character_mesh_recursive(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D:
		# Check if it has a material override set
		if node.get_surface_override_material(0) != null:
			return node
		# Also check if it has a mesh with materials
		if node.mesh and node.mesh.get_surface_count() > 0:
			return node
	
	# Recursively check children
	for child in node.get_children():
		var result = _find_character_mesh_recursive(child)
		if result:
			return result
	
	return null

## Finds ALL MeshInstance3D nodes in the character model (not just the first one)
## @param node: Node - Starting node to search from
func _find_all_character_meshes_recursive(node: Node) -> Array[MeshInstance3D]:
	var meshes: Array[MeshInstance3D] = []
	
	if node is MeshInstance3D:
		var mesh_instance = node as MeshInstance3D
		# Include all meshes, not just ones with material overrides
		meshes.append(mesh_instance)
		print("Found mesh: ", mesh_instance.name, " has override: ", mesh_instance.get_surface_override_material(0) != null)
	
	for child in node.get_children():
		meshes.append_array(_find_all_character_meshes_recursive(child))
	
	return meshes

## Attempts to find the character model node
func _find_character_model() -> void:
	# Try direct child first
	model_instance = get_node_or_null("characterMedium")
	
	if not model_instance:
		# Search recursively for any character model
		model_instance = _find_character_recursive(self)

## Recursively searches for character model nodes
func _find_character_recursive(node: Node) -> Node3D:
	if node.name.contains("character") and node is Node3D:
		return node
	
	for child in node.get_children():
		var result = _find_character_recursive(child)
		if result:
			return result
	
	return null

# Preload all skin materials
# TODO: Create these material files first
# const SKIN_MATERIALS = {
# 	0: preload("res://materials/skater_male_material.tres"),
# 	1: preload("res://materials/skater_female_material.tres"),
# 	2: preload("res://materials/cyborg_female_material.tres"),
# 	3: preload("res://materials/criminal_male_material.tres")
# }

## Simple material swap approach - use pre-created materials
## @param character_index The index of the character skin to apply (0-3)
func change_skin_simple(character_index: int) -> void:
	if not model_instance:
		_find_character_model()
		
	if not model_instance:
		push_error("Cannot change skin - character model not found")
		return
		
	# Find the mesh
	var character_mesh = _find_character_mesh_recursive(model_instance)
	if not character_mesh:
		push_error("Cannot find character mesh")
		return
		
	# Material paths
	var material_paths = {
		0: "res://materials/skater_male_material.tres",
		1: "res://materials/skater_female_material.tres",
		2: "res://materials/cyborg_female_material.tres",
		3: "res://materials/criminal_male_material.tres"
	}
	
	# Get the material path
	var material_path = material_paths.get(character_index)
	if not material_path:
		push_error("No material path found for character index: " + str(character_index))
		return
		
	# Try to load the material
	if ResourceLoader.exists(material_path):
		var new_material = load(material_path)
		character_mesh.set_surface_override_material(0, new_material)
		print("Applied pre-made material for character ", character_index)
	else:
		push_warning("Material file doesn't exist: " + material_path + " - falling back to dynamic approach")
		# Fall back to the dynamic skin changing
		var skin_path = GameManager.get_character_skin(character_index)
		change_skin(skin_path)

## Creates mesh instances for each skin as a workaround
func _create_skin_mesh_instances():
	if not model_instance:
		return
		
	var original_mesh = _find_character_mesh_recursive(model_instance)
	if not original_mesh:
		return
		
	# Hide the original mesh
	original_mesh.visible = false
	
	# Create a mesh instance for each skin
	for i in range(4):
		var new_mesh = original_mesh.duplicate()
		new_mesh.name = "SkinMesh_" + str(i)
		original_mesh.get_parent().add_child(new_mesh)
		
		# Apply the skin
		var skin_path = GameManager.get_character_skin(i)
		_apply_skin_to_mesh(new_mesh, skin_path)
		
		# Hide by default
		new_mesh.visible = false
		skin_meshes[i] = new_mesh
		
	print("Created ", skin_meshes.size(), " skin mesh instances")

## Switches between pre-created mesh instances
func switch_skin_mesh(character_index: int) -> void:
	# Hide all meshes
	for mesh in skin_meshes.values():
		mesh.visible = false
		
	# Show the selected one
	if skin_meshes.has(character_index):
		skin_meshes[character_index].visible = true
		print("Switched to skin mesh ", character_index)

## Helper to apply skin to a specific mesh
func _apply_skin_to_mesh(mesh: MeshInstance3D, skin_path: String) -> void:
	var new_skin = load(skin_path)
	if not new_skin:
		return
		
	var shader_to_use = preload("res://shaders/cel_shader.gdshader")
	var new_material = ShaderMaterial.new()
	new_material.shader = shader_to_use
	new_material.set_shader_parameter("cel_levels", 2.0)
	new_material.set_shader_parameter("base_color", Color.WHITE)
	new_material.set_shader_parameter("albedo_texture", new_skin)
	new_material.resource_local_to_scene = true
	
	mesh.set_surface_override_material(0, new_material)

## Applies a static squat pose to the character model
## This runs once in _ready() to set a fixed riding position on the board
## @param squat_intensity: float - Strength of the squat (0.0 = no squat, 1.0 = full bend)
func apply_squat_pose(squat_intensity: float = 1.0) -> void:
	if not model_instance:
		_find_character_model()
		if not model_instance:
			push_error("Cannot apply pose - character model not found")
			return
	
	# Find the Skeleton3D (recursive search in case of nesting)
	var skeleton: Skeleton3D = _find_skeleton_recursive(model_instance)
	if not skeleton:
		push_error("Skeleton3D not found in character model")
		return
	
	# Debug: List all bone names
	print("=== LISTING ALL BONES IN SKELETON ===")
	for i in range(skeleton.get_bone_count()):
		var bone_name = skeleton.get_bone_name(i)
		print("Bone ", i, ": ", bone_name)
	print("=== END BONE LIST ===")
	
	# Map of bones to their rotation adjustments (use your model's exact bone names)
	# Trying common bone name patterns for Kenney models
	var bone_adjustments = {
		# The key is to maintain hip height while bending knees
		# For a proper skateboard stance:
		# - Slight knee bend (not too deep)
		# - Lean forward slightly at spine
		# - Arms relaxed at sides
		# - Feet flat on board
		
		# Try without mixamorig prefix first
		"Hips": Vector3(0, 0, 0),  # Hip rotation for wider stance
		"Spine": Vector3(deg_to_rad(10) * squat_intensity, 0, 0),  # Slight forward lean
		"Spine1": Vector3(deg_to_rad(5) * squat_intensity, 0, 0),  # Additional spine bend
		"LeftUpLeg": Vector3(deg_to_rad(-15) * squat_intensity, deg_to_rad(-10) * squat_intensity, deg_to_rad(-7) * squat_intensity),  # Reduced Y rotation
		"RightUpLeg": Vector3(deg_to_rad(-15) * squat_intensity, deg_to_rad(10) * squat_intensity, deg_to_rad(7) * squat_intensity),  # Reduced Y rotation
		"LeftLeg": Vector3(deg_to_rad(20) * squat_intensity, 0, 0),  # Just bend forward
		"RightLeg": Vector3(deg_to_rad(20) * squat_intensity, 0, 0),  # Just bend forward
		"LeftFoot": Vector3(deg_to_rad(-5) * squat_intensity, deg_to_rad(5) * squat_intensity, 0),  # Slight inward rotation
		"RightFoot": Vector3(deg_to_rad(-5) * squat_intensity, deg_to_rad(-5) * squat_intensity, 0),  # Slight inward rotation
		"LeftArm": Vector3(0, 0, deg_to_rad(-20) * squat_intensity),  # Arms straight down at sides
		"RightArm": Vector3(0, 0, deg_to_rad(20) * squat_intensity),  # Arms straight down at sides
		"LeftForeArm": Vector3(0, 0, 0),  # Keep forearms straight
		"RightForeArm": Vector3(0, 0, 0),  # Keep forearms straight
		
		# Alternative names with mixamorig prefix
		"mixamorig:Hips": Vector3(0, 0, 0),
		"mixamorig:Spine": Vector3(deg_to_rad(10) * squat_intensity, 0, 0),
		"mixamorig:Spine1": Vector3(deg_to_rad(5) * squat_intensity, 0, 0),
		"mixamorig:LeftUpLeg": Vector3(deg_to_rad(-15) * squat_intensity, deg_to_rad(-10) * squat_intensity, deg_to_rad(-7) * squat_intensity),
		"mixamorig:RightUpLeg": Vector3(deg_to_rad(-15) * squat_intensity, deg_to_rad(10) * squat_intensity, deg_to_rad(7) * squat_intensity),
		"mixamorig:LeftLeg": Vector3(deg_to_rad(20) * squat_intensity, 0, 0),
		"mixamorig:RightLeg": Vector3(deg_to_rad(20) * squat_intensity, 0, 0),
		"mixamorig:LeftFoot": Vector3(deg_to_rad(-5) * squat_intensity, deg_to_rad(5) * squat_intensity, 0),
		"mixamorig:RightFoot": Vector3(deg_to_rad(-5) * squat_intensity, deg_to_rad(-5) * squat_intensity, 0),
		"mixamorig:LeftArm": Vector3(0, 0, deg_to_rad(-20) * squat_intensity),
		"mixamorig:RightArm": Vector3(0, 0, deg_to_rad(20) * squat_intensity),
		"mixamorig:LeftForeArm": Vector3(0, 0, 0),
		"mixamorig:RightForeArm": Vector3(0, 0, 0),
		
		# Try more variations
		"Pelvis": Vector3(0, 0, 0),  # Alternative hip name
		"UpperLeg_L": Vector3(deg_to_rad(-15) * squat_intensity, deg_to_rad(-10) * squat_intensity, deg_to_rad(-7) * squat_intensity),
		"UpperLeg_R": Vector3(deg_to_rad(-15) * squat_intensity, deg_to_rad(10) * squat_intensity, deg_to_rad(7) * squat_intensity),
		"LowerLeg_L": Vector3(deg_to_rad(20) * squat_intensity, 0, 0),
		"LowerLeg_R": Vector3(deg_to_rad(20) * squat_intensity, 0, 0),
		"Foot_L": Vector3(deg_to_rad(-5) * squat_intensity, deg_to_rad(5) * squat_intensity, 0),
		"Foot_R": Vector3(deg_to_rad(-5) * squat_intensity, deg_to_rad(-5) * squat_intensity, 0),
		"UpperArm_L": Vector3(0, 0, deg_to_rad(-20) * squat_intensity),
		"UpperArm_R": Vector3(0, 0, deg_to_rad(20) * squat_intensity),
		"LowerArm_L": Vector3(0, 0, 0),
		"LowerArm_R": Vector3(0, 0, 0)
	}
	
	# Don't modify the character's position - just adjust the bones
	# The board position should remain unchanged
	
	var bones_found = 0
	for bone_name in bone_adjustments:
		var bone_id = skeleton.find_bone(bone_name)
		if bone_id == -1:
			continue  # Skip if not found
		
		bones_found += 1
		print("Found bone: ", bone_name, " (ID: ", bone_id, ")")
		
		# Get current pose and apply adjustment
		var current_pose = skeleton.get_bone_pose_rotation(bone_id)
		var adjustment = bone_adjustments[bone_name]
		skeleton.set_bone_pose_rotation(bone_id, current_pose * Quaternion.from_euler(adjustment))
		
	if bones_found > 0:
		print("Squat pose applied with intensity: ", squat_intensity, " (", bones_found, " bones adjusted)")
	else:
		push_warning("No matching bones found for squat pose")

## Helper to find Skeleton3D recursively
## @param node: Node - Starting node to search from
## @return Skeleton3D or null
func _find_skeleton_recursive(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node
	for child in node.get_children():
		var result = _find_skeleton_recursive(child)
		if result:
			return result
	return null
