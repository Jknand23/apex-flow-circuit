# dedicated_server.gd
# This script is responsible for initializing the game in headless server mode.

extends Node

# Server configuration
const SERVER_PORT = 7777
const MAX_PLAYERS = 8 # Set the max number of players for the server

func _ready() -> void:
	# This function is called when the server starts.
	# It only runs if the game is launched with the --headless flag.
	
	print("--- Dedicated Server Initializing ---")
	
	# Godot in headless mode still tries to use audio, so we disable it.
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), -80)
	
	# Start listening for incoming connections.
	_start_server()
	
	# Load the main track scene. The server needs this to manage game state.
	var scene_load_status = get_tree().change_scene_to_file("res://scenes/basic_track.tscn")
	if scene_load_status != OK:
		print_error("Failed to load track scene on server.")
		get_tree().quit(1) # Exit with an error code

## Starts the ENet multiplayer server.
func _start_server() -> void:
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(SERVER_PORT, MAX_PLAYERS)
	
	if error != OK:
		print_error("Failed to start dedicated server!")
		get_tree().quit(1)
	
	multiplayer.multiplayer_peer = peer
	print("Dedicated server listening on port %d for %d players." % [SERVER_PORT, MAX_PLAYERS])
	
	# Connect signals to handle players joining and leaving.
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)

## Called when a new player connects to the server.
## @param id The network ID of the newly connected player.
func _on_player_connected(id: int) -> void:
	print("Player connected: %d" % id)
	# Here you could add logic to send initial state to the player,
	# or wait for them to fully load into the game scene.

## Called when a player disconnects from the server.
## @param id The network ID of the disconnected player.
func _on_player_disconnected(id: int) -> void:
	print("Player disconnected: %d" % id)
	# This is where you would handle removing the player's character
	# from the game world and cleaning up any related data. 