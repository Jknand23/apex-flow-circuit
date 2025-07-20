## Multiplayer Lobby Script
## Manages the lobby where both host and client wait before starting the game
## Handles player slots, character selection, ready states, and game launch

extends Control

# Network constants
const DEFAULT_PORT = 7000
const MAX_CLIENTS = 1

# Player data structure
var players = {}
var player_ready_status = {}
var player_characters = {}
var lobby_code = ""
var is_host = false

# Character options (add more as you create them)
var character_options = [
	"Skater Male A",
	"Skater Female A", 
	"Cyborg Female A",
	"Criminal Male A"
]

# UI References
@onready var code_label = $TitleContainer/LobbyCodeContainer/CodeValue
@onready var ip_label = $TitleContainer/IPAddressContainer/IPValue
@onready var player1_status = $PlayersContainer/Player1Slot/VBoxContainer/StatusLabel
@onready var player2_status = $PlayersContainer/Player2Slot/VBoxContainer/StatusLabel
@onready var player1_char_container = $PlayersContainer/Player1Slot/VBoxContainer/CharacterContainer
@onready var player2_char_container = $PlayersContainer/Player2Slot/VBoxContainer/CharacterContainer
@onready var player1_char_select = $PlayersContainer/Player1Slot/VBoxContainer/CharacterContainer/CharacterSelect
@onready var player2_char_select = $PlayersContainer/Player2Slot/VBoxContainer/CharacterContainer/CharacterSelect
@onready var player1_ready_btn = $PlayersContainer/Player1Slot/VBoxContainer/ReadyButton
@onready var player2_ready_btn = $PlayersContainer/Player2Slot/VBoxContainer/ReadyButton
@onready var start_button = $BottomContainer/StartButton
@onready var player1_label = $PlayersContainer/Player1Slot/VBoxContainer/PlayerLabel
@onready var player2_label = $PlayersContainer/Player2Slot/VBoxContainer/PlayerLabel

# Called when the node enters the scene tree
func _ready() -> void:
	# Setup multiplayer callbacks
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	
	# Setup character options
	_setup_character_options()
	
	# Check if we're coming from main menu (hosting) or join screen (client)
	if not multiplayer.has_multiplayer_peer() or multiplayer.is_server():
		_setup_as_host()
	else:
		_setup_as_client()

# Setup character dropdown options
func _setup_character_options() -> void:
	player1_char_select.clear()
	player2_char_select.clear()
	
	for character in character_options:
		player1_char_select.add_item(character)
		player2_char_select.add_item(character)

# Setup lobby as host
func _setup_as_host() -> void:
	is_host = true
	
	# Generate lobby code
	lobby_code = str(randi() % 900000 + 100000)  # 6-digit code
	code_label.text = lobby_code
	
	# Display host IP address for clients to connect
	var host_ip = _get_local_ip_address()
	if ip_label:
		ip_label.text = host_ip
	
	print("=== HOST LOBBY SETUP DEBUG ===")
	print("Generated lobby code: ", lobby_code)
	print("Host IP address: ", host_ip)
	
	# Create server
	var peer = ENetMultiplayerPeer.new()
	var port = DEFAULT_PORT + (int(lobby_code) % 58535)  # Use code to offset port, keep within valid range (7000-65535)
	var result = peer.create_server(port, MAX_CLIENTS)
	
	if result == OK:
		multiplayer.multiplayer_peer = peer
		print("Server started on port %d with lobby code %s" % [port, lobby_code])
		print("Clients should connect to: %s:%d" % [host_ip, port])
		
		# Register lobby with the lobby service for automatic discovery
		if LobbyService:
			LobbyService.register_lobby(lobby_code, port, func(success: bool, message: String):
				if success:
					print("Lobby registered with discovery service")
				else:
					print("Failed to register lobby: ", message)
					# Still continue - manual IP entry will still work
			)
		
		# Add host to players
		var host_id = multiplayer.get_unique_id()
		players[host_id] = {"name": "Host", "character": 0, "ready": false}
		player_ready_status[host_id] = false
		player_characters[host_id] = 0
		
		print("Host player ID: ", host_id)
		print("Initial players data: ", players)
		print("Initial player_characters: ", player_characters)
		
		# Update UI
		player1_label.text = "PLAYER 1 (HOST)"
		player1_status.text = "Connected"
		player1_status.modulate = Color.GREEN
		
		# Enable host controls
		player1_char_select.disabled = false
		player1_ready_btn.disabled = false
		print("Host controls enabled")
	else:
		print("Failed to create server: %d" % result)
	
	print("=== END HOST LOBBY SETUP DEBUG ===")

# Setup lobby as client
func _setup_as_client() -> void:
	is_host = false
	
	# The client is already connected from the join screen
	# Request lobby info from host
	_request_lobby_info.rpc_id(1)
	
	# Update UI for client
	player1_label.text = "PLAYER 1 (HOST)"
	player2_label.text = "PLAYER 2 (YOU)"
	
	# Disable host controls for client
	player1_char_select.disabled = true
	player1_ready_btn.disabled = true
	player1_ready_btn.visible = false
	
	# Enable client controls
	player2_char_container.visible = true
	player2_char_select.disabled = false
	player2_ready_btn.visible = true
	player2_ready_btn.disabled = false
	player2_status.text = "Connected"
	player2_status.modulate = Color.GREEN

# Called when a peer connects (server only)
func _on_peer_connected(id: int) -> void:
	print("Player connected: %d" % id)
	
	if is_host:
		# Add new player
		players[id] = {"name": "Player 2", "character": 0, "ready": false}
		player_ready_status[id] = false
		player_characters[id] = 0
		
		# Update UI
		player2_status.text = "Connected"
		player2_status.modulate = Color.GREEN
		
		# Send current lobby state to new player
		_receive_lobby_info.rpc_id(id, lobby_code, players, player_ready_status, player_characters)

# Called when a peer disconnects
func _on_peer_disconnected(id: int) -> void:
	print("Player disconnected: %d" % id)
	
	if is_host:
		# Remove player
		players.erase(id)
		player_ready_status.erase(id)
		player_characters.erase(id)
		
		# Update UI
		player2_status.text = "Waiting for player..."
		player2_status.modulate = Color.GRAY
		
		# Disable start button
		start_button.disabled = true

# RPC functions
@rpc("any_peer", "call_local")
func _request_lobby_info() -> void:
	pass  # Server will respond with _receive_lobby_info

@rpc("authority", "call_remote")
func _receive_lobby_info(code: String, lobby_players: Dictionary, ready_status: Dictionary, characters: Dictionary) -> void:
	lobby_code = code
	players = lobby_players
	player_ready_status = ready_status
	player_characters = characters
	code_label.text = lobby_code
	_update_ui()

@rpc("any_peer", "call_local", "reliable")
func _update_player_character(player_id: int, character_index: int) -> void:
	print("=== UPDATE PLAYER CHARACTER RPC DEBUG ===")
	print("Received character update RPC")
	print("Player ID: ", player_id)
	print("Character index: ", character_index)
	print("Before update - player_characters: ", player_characters)
	print("Before update - players: ", players)
	
	player_characters[player_id] = character_index
	if players.has(player_id):
		players[player_id]["character"] = character_index
		print("Updated players[", player_id, "][character] = ", character_index)
	else:
		print("ERROR: Player ID ", player_id, " not found in players dictionary!")
	
	print("After update - player_characters: ", player_characters)
	print("After update - players: ", players)
	
	_update_ui()
	print("=== END UPDATE PLAYER CHARACTER RPC DEBUG ===")

@rpc("any_peer", "call_local", "reliable")
func _update_player_ready(player_id: int, ready: bool) -> void:
	print("=== UPDATE PLAYER READY RPC DEBUG ===")
	print("Player ID: ", player_id, " ready: ", ready)
	
	player_ready_status[player_id] = ready
	if players.has(player_id):
		players[player_id]["ready"] = ready
	_update_ui()
	print("=== END UPDATE PLAYER READY RPC DEBUG ===")

@rpc("authority", "call_local", "reliable")
func _start_game() -> void:
	print("=== START GAME RPC DEBUG ===")
	print("Starting multiplayer game...")
	print("About to call GameManager.start_multiplayer_game with players: ", players)
	
	# Store game data in GameManager
	GameManager.start_multiplayer_game(players)
	GameManager.is_host = is_host
	GameManager.lobby_code = lobby_code
	
	print("GameManager.player_data after start_multiplayer_game: ", GameManager.player_data)
	print("GameManager.is_multiplayer_game: ", GameManager.is_multiplayer_game)
	
	print("Changing scene to basic_track.tscn...")
	get_tree().change_scene_to_file("res://scenes/basic_track.tscn")
	print("=== END START GAME RPC DEBUG ===")

# Update UI based on current state
func _update_ui() -> void:
	# Update character selections
	for player_id in players:
		if player_id == 1:  # Host
			player1_char_select.selected = player_characters.get(player_id, 0)
		else:  # Client
			player2_char_select.selected = player_characters.get(player_id, 0)
	
	# Update ready buttons
	var my_id = multiplayer.get_unique_id()
	if my_id == 1:  # Host
		player1_ready_btn.text = "READY" if not player_ready_status.get(my_id, false) else "NOT READY"
		player1_ready_btn.modulate = Color.WHITE if not player_ready_status.get(my_id, false) else Color.GREEN
	else:  # Client
		player2_ready_btn.text = "READY" if not player_ready_status.get(my_id, false) else "NOT READY"
		player2_ready_btn.modulate = Color.WHITE if not player_ready_status.get(my_id, false) else Color.GREEN
	
	# Update other player's ready status
	for player_id in players:
		if player_id != my_id:
			if player_id == 1:  # Host (from client's perspective)
				player1_ready_btn.text = "READY" if player_ready_status.get(player_id, false) else "NOT READY"
				player1_ready_btn.modulate = Color.GREEN if player_ready_status.get(player_id, false) else Color.WHITE
			else:  # Client (from host's perspective)
				# Just show visual indication since client can't see other's button
				if player_ready_status.get(player_id, false):
					player2_status.text = "Ready!"
					player2_status.modulate = Color.GREEN
				else:
					player2_status.text = "Connected"
					player2_status.modulate = Color.GREEN
	
	# Enable start button if host and all players are ready
	if is_host:
		var all_ready = true
		for player_id in players:
			if not player_ready_status.get(player_id, false):
				all_ready = false
				break
		start_button.disabled = not (all_ready and players.size() == 2)

# Button handlers
func _on_player1_character_selected(index: int) -> void:
	print("=== PLAYER 1 CHARACTER SELECTION DEBUG ===")
	print("Character selected - index: ", index)
	print("Is host: ", is_host)
	print("Current player_characters before update: ", player_characters)
	
	if is_host:
		var my_id = multiplayer.get_unique_id()
		print("Host ID: ", my_id)
		print("Sending character update RPC...")
		_update_player_character.rpc(my_id, index)
		print("Host selected character index: ", index)
	else:
		print("ERROR: Player 1 selection called but not host!")
	
	print("=== END PLAYER 1 CHARACTER SELECTION DEBUG ===")

func _on_player2_character_selected(index: int) -> void:
	print("=== PLAYER 2 CHARACTER SELECTION DEBUG ===")
	print("Character selected - index: ", index)
	print("Is host: ", is_host)
	print("Current player_characters before update: ", player_characters)
	
	if not is_host:
		var my_id = multiplayer.get_unique_id()
		print("Client ID: ", my_id)
		print("Sending character update RPC...")
		_update_player_character.rpc(my_id, index)
		print("Client selected character index: ", index)
	else:
		print("ERROR: Player 2 selection called but is host!")
	
	print("=== END PLAYER 2 CHARACTER SELECTION DEBUG ===")

func _on_player1_ready_pressed() -> void:
	print("=== PLAYER 1 READY DEBUG ===")
	if is_host:
		var my_id = multiplayer.get_unique_id()
		var new_ready = not player_ready_status.get(my_id, false)
		print("Host ready state changing to: ", new_ready)
		_update_player_ready.rpc(my_id, new_ready)

func _on_player2_ready_pressed() -> void:
	print("=== PLAYER 2 READY DEBUG ===")
	if not is_host:
		var my_id = multiplayer.get_unique_id()
		var new_ready = not player_ready_status.get(my_id, false)
		print("Client ready state changing to: ", new_ready)
		_update_player_ready.rpc(my_id, new_ready)

func _on_start_pressed() -> void:
	if is_host:
		print("=== STARTING GAME DEBUG ===")
		print("Host starting game...")
		print("Final players data: ", players)
		print("Final player_characters: ", player_characters)
		print("Final player_ready_status: ", player_ready_status)
		
		# Verify all players have character selections
		for player_id in players:
			var character_index = players[player_id].get("character", -1)
			print("Player ", player_id, " character index: ", character_index)
		
		print("Calling _start_game.rpc()")
		_start_game.rpc()
		print("=== END STARTING GAME DEBUG ===")

func _on_leave_pressed() -> void:
	# Unregister lobby if we're the host
	if is_host and LobbyService:
		LobbyService.unregister_lobby(lobby_code)
		print("Unregistered lobby from discovery service")
	
	# Clean up network connection and reset state
	GameManager.reset_multiplayer_state()
	
	# Return to multiplayer menu
	get_tree().change_scene_to_file("res://scenes/multiplayer_menu.tscn") 

# Get the local IP address of this machine
func _get_local_ip_address() -> String:
	var ip_addresses = IP.get_local_addresses()
	
	# Look for a non-loopback IPv4 address
	for ip in ip_addresses:
		# Skip localhost
		if ip == "127.0.0.1":
			continue
		# Look for typical local network IPs
		if ip.begins_with("192.168.") or ip.begins_with("10.") or ip.begins_with("172."):
			return ip
		# Also accept other IPv4 addresses
		if "." in ip and not ":" in ip:
			return ip
	
	# Fallback to localhost if no local network IP found
	return "127.0.0.1" 