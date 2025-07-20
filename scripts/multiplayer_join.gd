## Multiplayer Join Script
## Handles the interface for joining an existing multiplayer game
## Players enter a 6-digit lobby code and host IP address to connect across networks

extends Control

# Network connection parameters
const DEFAULT_PORT = 7000
const MAX_CLIENTS = 1  # Only 1 client can join (2 player total)

# --- DEDICATED SERVER CONFIG ---
# Set to your server's static IP address from the Google Cloud console.
const OFFICIAL_SERVER_IP = "YOUR_GOOGLE_CLOUD_IP"
const OFFICIAL_SERVER_PORT = 7777
# ---

# Reference to UI elements
@onready var official_server_button = $JoinContainer/OfficialServerContainer/OfficialServerButton
@onready var code_input = $JoinContainer/CodeInput
@onready var ip_input = $JoinContainer/IPInput
@onready var join_button = $JoinContainer/ButtonContainer/JoinButton
@onready var status_label = $JoinContainer/StatusLabel

# Called when the node enters the scene tree
func _ready() -> void:
	# Setup multiplayer callbacks
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	
	# Focus on the code input
	code_input.grab_focus()
	
	# Set default IP to localhost for local testing
	ip_input.text = "127.0.0.1"
	
	# Set placeholder text to indicate automatic discovery
	ip_input.placeholder_text = "Leave empty for automatic (or enter host IP)"

# Handle code input changes - validate and enable/disable join button
func _on_code_input_text_changed(new_text: String) -> void:
	# Only allow numeric input
	var filtered_text = ""
	for char in new_text:
		if char.is_valid_int():
			filtered_text += char
	
	if filtered_text != new_text:
		code_input.text = filtered_text
		code_input.caret_column = filtered_text.length()
	
	# Update join button state
	_update_join_button_state()

# Handle IP input changes - validate format
func _on_ip_input_text_changed(new_text: String) -> void:
	# Update join button state
	_update_join_button_state()

# Update join button state based on inputs
func _update_join_button_state() -> void:
	var code_valid = code_input.text.length() == 6
	var ip_valid = ip_input.text.is_empty() or ip_input.text == "localhost" or _is_valid_ip(ip_input.text)
	join_button.disabled = not (code_valid and ip_valid)

# Validate IP address format
func _is_valid_ip(ip: String) -> bool:
	var parts = ip.split(".")
	if parts.size() != 4:
		return false
	
	for part in parts:
		if not part.is_valid_int():
			return false
		var num = int(part)
		if num < 0 or num > 255:
			return false
	
	return true

## Connects to the official dedicated server.
func _on_official_server_pressed() -> void:
	if OFFICIAL_SERVER_IP == "YOUR_GOOGLE_CLOUD_IP":
		_show_status("Official server not configured by developer.", Color.RED)
		return
		
	# Disable UI while connecting
	join_button.disabled = true
	official_server_button.disabled = true
	code_input.editable = false
	ip_input.editable = false
	
	_connect_to_host(OFFICIAL_SERVER_IP, OFFICIAL_SERVER_PORT)

# Handle join button press - attempt to connect to host
func _on_join_pressed() -> void:
	var code = code_input.text
	var manual_ip = ip_input.text
	
	if code.length() != 6:
		_show_status("Invalid lobby code", Color.RED)
		return
	
	# Disable UI while connecting
	join_button.disabled = true
	code_input.editable = false
	ip_input.editable = false
	
	# Try automatic IP discovery first
	if LobbyService and (manual_ip.is_empty() or manual_ip == "127.0.0.1"):
		_show_status("Looking up lobby...", Color.YELLOW)
		LobbyService.lookup_lobby(code, func(success: bool, host_ip: String, port: int, message: String):
			if success:
				print("Found lobby at %s:%d" % [host_ip, port])
				_connect_to_host(host_ip, port)
			else:
				print("Lobby lookup failed: ", message)
				# If automatic discovery fails and no manual IP, ask user to enter one
				if manual_ip.is_empty() or manual_ip == "127.0.0.1":
					_show_status("Enter host IP address (shown in host's lobby)", Color.YELLOW)
					_reset_ui()
					ip_input.text = ""  # Clear the default localhost
					ip_input.grab_focus()
				else:
					# Use the manual IP they provided
					_show_status("Using manual IP...", Color.YELLOW)
					var port = DEFAULT_PORT + (int(code) % 58535)
					_connect_to_host(manual_ip, port)
		)
	else:
		# Use manual IP
		if not _is_valid_ip(manual_ip) and manual_ip != "localhost":
			_show_status("Invalid IP address", Color.RED)
			_reset_ui()
			return
		
		# Convert localhost to IP
		if manual_ip == "localhost":
			manual_ip = "127.0.0.1"
		
		var port = DEFAULT_PORT + (int(code) % 58535)
		_connect_to_host(manual_ip, port)

# Connect to host with given IP and port
func _connect_to_host(host_ip: String, port: int) -> void:
	_show_status("Connecting to " + host_ip + "...", Color.YELLOW)
	
	# Create client peer
	var peer = ENetMultiplayerPeer.new()
	var result = peer.create_client(host_ip, port)
	
	if result == OK:
		multiplayer.multiplayer_peer = peer
		print("Attempting to connect to host at %s:%d" % [host_ip, port])
	else:
		_show_status("Failed to create client connection", Color.RED)
		_reset_ui()

# Called when successfully connected to server
func _on_connected_to_server() -> void:
	print("Connected to server successfully!")
	# Store the lobby code in GameManager
	GameManager.lobby_code = code_input.text
	GameManager.is_host = false
	get_tree().change_scene_to_file("res://scenes/multiplayer_lobby.tscn")

# Called when connection to server fails
func _on_connection_failed() -> void:
	print("Failed to connect to server")
	_show_status("Connection failed - check IP and lobby code", Color.RED)
	_reset_ui()

# Called when server disconnects
func _on_server_disconnected() -> void:
	print("Server disconnected")
	_show_status("Lost connection to host", Color.RED)
	_reset_ui()

# Show status message to user
func _show_status(message: String, color: Color = Color.WHITE) -> void:
	status_label.text = message
	status_label.modulate = color
	status_label.visible = true

# Reset UI to allow retry
func _reset_ui() -> void:
	_update_join_button_state()
	official_server_button.disabled = false
	code_input.editable = true
	ip_input.editable = true
	code_input.grab_focus()

# Handle back button press - return to multiplayer menu
func _on_back_pressed() -> void:
	print("Returning to multiplayer menu...")
	get_tree().change_scene_to_file("res://scenes/multiplayer_menu.tscn") 