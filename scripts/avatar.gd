# scripts/avatar.gd
# Modular avatar handler for Kenney models. Positions on board; expandable for swaps.
# Attach to AvatarRoot in avatar.tscn.

extends Node3D

@onready var model_instance: Node3D = get_node_or_null("characterMedium")  # Use get_node_or_null instead

# Function to set position offset for board riding.
# @param offset: Vector3 - Adjustment for feet-on-board (e.g., Vector3(0, board_height + 0.1, 0)).
func set_position_offset(offset: Vector3) -> void:
	if not model_instance:
		push_error("Model instance not found - check node path.")
		return
	model_instance.position = offset
	print("Applied offset: " + str(offset))  # Debug vibe.

func _ready() -> void:
	if model_instance:
		set_position_offset(Vector3(0, 0.1, 0))
	else:
		print("Warning: characterMedium node not found in avatar")
