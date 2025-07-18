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

# Store player data when starting a multiplayer game
func start_multiplayer_game(players: Dictionary) -> void:
	is_multiplayer_game = true
	player_data = players.duplicate()
	
	# Find our character index
	var my_id = multiplayer.get_unique_id()
	if player_data.has(my_id):
		my_character_index = player_data[my_id].get("character", 0) 