extends Camera3D

## Main Camera Script for Gameplay
## Follows the player without any debug controls
## This camera maintains its relative position to the parent (PlayerBoard)

# The camera maintains its transform relative to the parent
# No mouse capture or WASD movement in gameplay mode

func _ready() -> void:
	# Camera is already positioned correctly in the scene
	# No debug controls are enabled for gameplay
	pass

func _process(_delta: float) -> void:
	# The camera maintains its position relative to the parent automatically
	# No additional processing needed since it's a child of PlayerBoard
	pass 
