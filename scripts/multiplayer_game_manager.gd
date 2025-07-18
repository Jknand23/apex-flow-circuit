## Multiplayer Game Manager Script
## Handles spawning and synchronization of players in the game scene
## Attach to a Node in basic_track.tscn to enable multiplayer functionality

extends Node

# Player scene to spawn
const PLAYER_SCENE = preload("res://scenes/player_board.tscn")

# Spawn positions for each player (based on single player spawn)
const SPAWN_POSITIONS = [
	Vector3(113, 0.25, 1.5),      # Player 1 spawn (same as single player)
	Vector3(113, 0.25, -0.5)      # Player 2 spawn (-2 on Z axis, side by side)
]

# Scale that single player uses
const PLAYER_SCALE = 0.1

# Dictionary to track spawned players
var spawned_players = {}

func _ready() -> void:
	# Only spawn players if this is a multiplayer game
	if not GameManager.is_multiplayer_game:
		print("Not a multiplayer game, skipping multiplayer spawning")
		return
		
	print("Multiplayer Game Manager starting...")
	print("Player data: ", GameManager.player_data)
	print("Is host: ", GameManager.is_host)
	
	# Debug: Check for existing cameras in the scene
	var existing_cameras = get_tree().get_nodes_in_group("@all_nodes")
	for node in existing_cameras:
		if node is Camera3D:
			print("Found existing camera: ", node.name, " at path: ", node.get_path(), " current: ", node.current)
	
	# Save world environment before removing player
	var world_environment = _extract_world_environment()
	
	# Remove the existing single-player PlayerBoard
	await _remove_existing_player()
	
	# Restore world environment if needed
	if world_environment:
		get_node("/root/BasicTrackRoot").add_child(world_environment)
		print("Restored WorldEnvironment to scene")
	
	# Wait a moment for scene to settle
	await get_tree().create_timer(0.1).timeout
	
	# Spawn players based on who's in the game
	_spawn_all_players()
	
	# Add a debug camera if no camera is active
	await get_tree().process_frame
	# Temporarily disable debug camera to avoid conflicts
	# _ensure_active_camera()
	
	# Connect to peer disconnection to handle player leaving
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

## Extracts the WorldEnvironment from the player before removal
func _extract_world_environment() -> WorldEnvironment:
	var existing_player = get_node_or_null("/root/BasicTrackRoot/PlayerBoard")
	if existing_player and existing_player.has_node("WorldEnvironment"):
		var world_env = existing_player.get_node("WorldEnvironment")
		existing_player.remove_child(world_env)
		print("Extracted WorldEnvironment from PlayerBoard")
		return world_env
	return null

## Adds a camera to the spawned player matching single player setup
func _add_camera_to_player(player: Node3D) -> void:
	# Create camera matching single player configuration
	var camera = Camera3D.new()
	camera.name = "MainCamera"
	
	# Apply the EXACT transform from single player (from basic_track.tscn)
	# Transform3D(10, 0, 0, 0, 9.65926, 2.58819, 0, -2.58819, 9.65926, 0, 17.4024, 25.4062)
	var basis = Basis()
	# Set basis vectors exactly as in single player
	basis.x = Vector3(10, 0, 0).normalized()
	basis.y = Vector3(0, 9.65926, -2.58819).normalized()  
	basis.z = Vector3(0, 2.58819, 9.65926).normalized()
	camera.transform = Transform3D(basis, Vector3(0, 17.4024, 25.4062))
	
	# Use the same camera script as single player
	var camera_script = load("res://scripts/main_camera.gd")
	if camera_script:
		camera.script = camera_script
	else:
		push_warning("Could not load camera script")
	
	# Add to player
	player.add_child(camera)
	camera.owner = player  # Ensure proper scene ownership
	
	# Force the camera to be a proper child
	camera.set_notify_transform(true)
	
	# Don't set current yet - that's handled by setup functions
	camera.current = false
	
	print("Added MainCamera to player: ", player.name)
	print("Camera parent: ", camera.get_parent().name)
	print("Camera local position: ", camera.position)
	print("Player position: ", player.global_position)
	
	# Wait a frame and check again
	await player.get_tree().process_frame
	print("After frame - Camera global position: ", camera.global_position)
	print("After frame - Is camera child of player?: ", camera.get_parent() == player)

## Removes the pre-existing PlayerBoard from the scene
func _remove_existing_player() -> void:
	var existing_player = get_node_or_null("/root/BasicTrackRoot/PlayerBoard")
	if existing_player:
		print("Removing existing single-player board")
		# Graceful removal to avoid navigation errors
		existing_player.set_physics_process(false)
		existing_player.set_process(false)
		await get_tree().process_frame
		existing_player.queue_free()
		await get_tree().process_frame

## Spawns all players based on GameManager data
func _spawn_all_players() -> void:
	var spawn_index = 0
	
	for player_id in GameManager.player_data:
		print("Spawning player ID: ", player_id)
		_spawn_player(player_id, spawn_index)
		spawn_index += 1

## Spawns a single player
## @param player_id The network ID of the player
## @param spawn_index The index for spawn position (0 or 1)
func _spawn_player(player_id: int, spawn_index: int) -> void:
	# Instantiate player scene
	var player_instance = PLAYER_SCENE.instantiate()
	
	# Set unique name for network identification
	player_instance.name = "Player_" + str(player_id)
	
	# Set spawn position
	if spawn_index < SPAWN_POSITIONS.size():
		player_instance.position = SPAWN_POSITIONS[spawn_index]
	else:
		# Fallback position if we have more players than spawn points
		player_instance.position = SPAWN_POSITIONS[0] + Vector3(0, 0, spawn_index * 2)
	
	# Apply the correct scale (matching single player)
	player_instance.scale = Vector3(PLAYER_SCALE, PLAYER_SCALE, PLAYER_SCALE)
	
	# Apply rotation to match single player orientation
	player_instance.rotation_degrees = Vector3(0, 90, 0)  # Face forward
	
	# Add to scene
	get_node("/root/BasicTrackRoot").add_child(player_instance)
	
	# Add camera to the player (since it's not in player_board.tscn)
	_add_camera_to_player(player_instance)
	
	# Configure authority (who controls this player)
	player_instance.set_multiplayer_authority(player_id)
	
	# Ensure player is in the player group (important for interactions)
	if not player_instance.is_in_group("player"):
		player_instance.add_to_group("player")
	
	# Set physics properties to match single player
	if "floor_stop_on_slope" in player_instance:
		player_instance.floor_stop_on_slope = false
	
	# Store reference
	spawned_players[player_id] = player_instance
	
	# If this is our player, setup camera and controls
	if player_id == multiplayer.get_unique_id():
		_setup_local_player(player_instance, spawn_index)
	else:
		# For remote players, disable local input
		_setup_remote_player(player_instance)
	
	# Ensure camera state is correct after setup
	_verify_camera_state(player_instance, player_id)
	
	print("Spawned player ", player_id, " at ", player_instance.position)

## Configures the local player (the one we control)
## @param player The player instance to configure
## @param spawn_index The spawn index (0 or 1) to determine player number
func _setup_local_player(player: Node3D, spawn_index: int) -> void:
	print("Setting up local player controls")
	
	# Wait for camera to be added
	await get_tree().process_frame
	
	# Camera should already be attached to the player
	# Just ensure it's active
	if player.has_node("MainCamera"):
		var camera = player.get_node("MainCamera")
		camera.current = true
		print("Camera activated for local player")
		
		# Ensure camera uses exact single player transform
		var basis = Basis()
		basis.x = Vector3(10, 0, 0).normalized()
		basis.y = Vector3(0, 9.65926, -2.58819).normalized()  
		basis.z = Vector3(0, 2.58819, 9.65926).normalized()
		camera.transform = Transform3D(basis, Vector3(0, 17.4024, 25.4062))
		
		# Debug camera position
		await get_tree().process_frame
		print("Local player position: ", player.global_position)
		print("Camera global position: ", camera.global_position)
		print("Camera is child of player: ", camera.get_parent() == player)
		
		# Double-check the camera is following
		player.global_position += Vector3(1, 0, 0)  # Move player slightly
		await get_tree().process_frame
		print("After player move - Camera moved?: ", camera.global_position)
		player.global_position -= Vector3(1, 0, 0)  # Move back
		
	else:
		push_error("MainCamera not found on local player!")
		# List all children for debugging
		print("Player children: ")
		for child in player.get_children():
			print("  - ", child.name, " (", child.get_class(), ")")
	
	# Setup UI for local player
	var ui = get_node_or_null("/root/BasicTrackRoot/UI")
	if ui:
		ui.visible = true  # Make sure UI is visible for local player
		
		# Update cadence bar reference in player movement script
		if player.has_method("set_cadence_bar"):
			player.call("set_cadence_bar", ui.get_node("CadenceBar"))

## Configures a remote player (controlled by another client)
func _setup_remote_player(player: Node3D) -> void:
	print("Setting up remote player")
	
	# Keep camera but disable it for remote players
	if player.has_node("MainCamera"):
		var camera = player.get_node("MainCamera")
		camera.current = false
		# Don't remove the camera - the remote player needs it on their instance
		print("Disabled camera for remote player (but kept for their client)")
	
	# Disable WorldEnvironment on remote players
	if player.has_node("WorldEnvironment"):
		var world_env = player.get_node("WorldEnvironment")
		world_env.queue_free()
		print("Removed WorldEnvironment from remote player")
	
	# The movement script should check multiplayer authority
	# before processing input

## Ensures there's an active camera in the scene
func _ensure_active_camera() -> void:
	# Check if any camera is current
	var cameras = get_tree().get_nodes_in_group("camera")
	var has_active_camera = false
	
	for node in get_tree().get_nodes_in_group("@all_nodes"):
		if node is Camera3D and node.current:
			has_active_camera = true
			print("Found active camera: ", node.name, " at ", node.global_position)
			break
	
	if not has_active_camera:
		push_error("No active camera found in multiplayer scene!")
		# Create a debug camera
		var debug_cam = Camera3D.new()
		debug_cam.name = "DebugCamera"
		debug_cam.position = Vector3(0, 10, 20)
		debug_cam.look_at(Vector3.ZERO, Vector3.UP)
		debug_cam.current = true
		get_node("/root/BasicTrackRoot").add_child(debug_cam)
		print("Created debug camera at ", debug_cam.global_position)

## Verifies camera state is correct for the player
func _verify_camera_state(player: Node3D, player_id: int) -> void:
	if not player.has_node("MainCamera"):
		push_error("Player ", player_id, " is missing MainCamera!")
		return
		
	var camera = player.get_node("MainCamera")
	var should_be_active = (player_id == multiplayer.get_unique_id())
	
	if camera.current != should_be_active:
		print("Correcting camera state for player ", player_id, " - should be active: ", should_be_active)
		camera.current = should_be_active
	
	# Ensure only one camera is active
	if should_be_active:
		for other_player_id in spawned_players:
			if other_player_id != player_id:
				var other_player = spawned_players[other_player_id]
				if other_player.has_node("MainCamera"):
					other_player.get_node("MainCamera").current = false

## Handles when a player disconnects
func _on_peer_disconnected(id: int) -> void:
	print("Player disconnected: ", id)
	
	# Remove their player instance
	if spawned_players.has(id):
		spawned_players[id].queue_free()
		spawned_players.erase(id) 
