# scripts/avatar.gd
# Modular avatar handler for Kenney models. Positions on board; expandable for swaps.
# Attach to AvatarRoot in avatar.tscn.

extends Node3D

var model_instance: Node3D  # Will be found in _ready()

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

func _ready() -> void:
	# Wait a frame for scene to be fully ready
	await get_tree().process_frame
	_find_character_model()
	
	if model_instance:
		# Let's see the original positioning without any offset first
		# Based on debug data, the gap might be in X direction, not Y or Z
		set_position_offset(Vector3(0, 0, 0))
	else:
		print("Info: Character model will be positioned when available")

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
