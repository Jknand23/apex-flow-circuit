## GameManager Singleton
## Manages global game state, particularly for multiplayer functionality
## Persists across scene changes to maintain network connections and player data

extends Node

# Multiplayer state
var is_multiplayer_game = false
var is_host = false
var lobby_code = ""
var player_data = {}  # Dictionary of player ID -> {name, character, ready}
var my_character_index = 0

# Character model paths (add more as you create them)
var character_models = [
	"res://assets/models/avatars/characterMedium.fbx",  # Skater Male A
	"res://assets/models/avatars/characterMedium.fbx",  # Skater Female A (using same for now)
	"res://assets/models/avatars/characterMedium.fbx",  # Cyborg Female A (using same for now)
	"res://assets/models/avatars/characterMedium.fbx"   # Criminal Male A (using same for now)
]

# Character skins/textures
var character_skins = [
	"res://assets/textures/avatars/skins/skaterMaleA.png",
	"res://assets/textures/avatars/skins/skaterFemaleA.png",
	"res://assets/textures/avatars/skins/cyborgFemaleA.png",
	"res://assets/textures/avatars/skins/criminalMaleA.png"
]

# Player board scene paths for each character
var player_board_scenes = [
	"res://scenes/player_board_skater_male.tscn",
	"res://scenes/player_board_skater_female.tscn",
	"res://scenes/player_board_cyborg_female.tscn",
	"res://scenes/player_board_criminal_male.tscn"
]

# Avatar scene paths for each character (if using separate avatar scenes)
var avatar_scenes = [
	"res://scenes/skater_male.tscn",
	"res://scenes/skater_female.tscn",
	"res://scenes/cyborg_female.tscn",
	"res://scenes/criminal_male.tscn"
]

# Called when the node enters the scene tree
func _ready() -> void:
	# Make sure this node persists across scene changes
	process_mode = Node.PROCESS_MODE_ALWAYS

# Reset multiplayer state (call when leaving multiplayer)
func reset_multiplayer_state() -> void:
	is_multiplayer_game = false
	is_host = false
	lobby_code = ""
	player_data.clear()
	my_character_index = 0
	
	# Clean up network connection
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()

# Get character model path for a given index
func get_character_model(index: int) -> String:
	if index >= 0 and index < character_models.size():
		return character_models[index]
	return character_models[0]  # Default to first

# Get character skin path for a given index
func get_character_skin(index: int) -> String:
	if index >= 0 and index < character_skins.size():
		return character_skins[index]
	return character_skins[0]  # Default to first

# Get player board scene path for a given index
func get_player_board_scene(index: int) -> String:
	if index >= 0 and index < player_board_scenes.size():
		return player_board_scenes[index]
	return player_board_scenes[0]  # Default to first

# Get avatar scene path for a given index
func get_avatar_scene(index: int) -> String:
	if index >= 0 and index < avatar_scenes.size():
		return avatar_scenes[index]
	return avatar_scenes[0]  # Default to first

## Applies a character skin to an avatar node
## @param avatar_node The avatar node to apply the skin to
## @param character_index The index of the character skin to apply
func apply_character_skin(avatar_node: Node3D, character_index: int) -> void:
	if avatar_node and avatar_node.has_method("change_skin"):
		var skin_path = get_character_skin(character_index)
		avatar_node.change_skin(skin_path)
		print("GameManager applied skin: ", skin_path, " (index: ", character_index, ")")
	else:
		push_warning("Cannot apply skin - avatar node invalid or missing change_skin method")

# Store player data when starting a multiplayer game
func start_multiplayer_game(players: Dictionary) -> void:
	is_multiplayer_game = true
	player_data = players.duplicate()
	
	# Find our character index
	var my_id = multiplayer.get_unique_id()
	if player_data.has(my_id):
		my_character_index = player_data[my_id].get("character", 0) 