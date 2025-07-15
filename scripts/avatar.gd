# scripts/avatar.gd
# Modular avatar handler for Kenney models. Positions on board; expandable for swaps.
# Attach to AvatarRoot in avatar.tscn.

extends Node3D

@onready var model_instance: Node3D = $characterMedium  # Adjust to your imported node's name.

# Function to set position offset for board riding.
# @param offset: Vector3 - Adjustment for feet-on-board (e.g., Vector3(0, board_height + 0.1, 0)).
func set_position_offset(offset: Vector3) -> void:
	if not model_instance:
		push_error("Model instance not found - check node path.")
		return
	model_instance.position = offset
	print("Applied offset: " + str(offset))  # Debug vibe.

func _ready() -> void:
	# Default offset - tweak based on your hoverboard.glb scale.
	set_position_offset(Vector3(0, 0.1, 0))  # Small y-up for floating hover feel.
