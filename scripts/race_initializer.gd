## Race Initializer Script
## Automatically starts the race when the track scene loads
## Handles both single-player and multiplayer race initialization

extends Node

func _ready() -> void:
	# Wait a moment for everything to be ready
	await get_tree().create_timer(1.0).timeout
	
	# Initialize the race based on game mode
	if GameManager.is_multiplayer_game:
		_initialize_multiplayer_race()
	else:
		_initialize_single_player_race()

## Initializes a single-player race
func _initialize_single_player_race() -> void:
	print("Initializing single-player race...")
	
	# Set up local player ID in the lap display
	var lap_display = get_node_or_null("/root/BasicTrackRoot/UI/LapDisplay")
	if lap_display:
		lap_display.set_local_player_id(1)
	
	# Start the race with player ID 1
	if RaceManager:
		RaceManager.initialize_race([1])
	else:
		print("ERROR: RaceManager not found!")

## Initializes a multiplayer race
func _initialize_multiplayer_race() -> void:
	print("Initializing multiplayer race...")
	
	# Only the host should initialize the race
	if not GameManager.is_host:
		print("Not host, waiting for race initialization...")
		return
	
	# Get all player IDs from GameManager
	var player_ids = GameManager.player_data.keys()
	print("Multiplayer race with players: ", player_ids)
	
	# Set up local player ID in lap display
	var lap_display = get_node_or_null("/root/BasicTrackRoot/UI/LapDisplay")
	if lap_display:
		var local_player_id = multiplayer.get_unique_id()
		lap_display.set_local_player_id(local_player_id)
	
	# Initialize race for all players
	if RaceManager:
		RaceManager.initialize_race(player_ids)
		
		# Sync race initialization to all clients
		_sync_race_initialization.rpc(player_ids)
	else:
		print("ERROR: RaceManager not found!")

## RPC to synchronize race initialization across all clients
## @param player_ids Array of player IDs participating in the race
@rpc("authority", "call_local", "reliable")
func _sync_race_initialization(player_ids: Array) -> void:
	if multiplayer.is_server():
		return  # Host already initialized
	
	print("Received race initialization sync for players: ", player_ids)
	
	# Set up local player ID in lap display for clients
	var lap_display = get_node_or_null("/root/BasicTrackRoot/UI/LapDisplay")
	if lap_display:
		var local_player_id = multiplayer.get_unique_id()
		lap_display.set_local_player_id(local_player_id)
	
	# Initialize race manager on client
	if RaceManager:
		RaceManager.initialize_race(player_ids) 