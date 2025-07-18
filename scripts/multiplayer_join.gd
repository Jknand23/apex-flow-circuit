## Multiplayer Join Script
## Handles the interface for joining an existing multiplayer game
## Players enter a 6-digit lobby code to connect to a host's game

extends Control

# Network connection parameters
const DEFAULT_PORT = 7000
const MAX_CLIENTS = 1  # Only 1 client can join (2 player total)

# Reference to UI elements
@onready var code_input = $JoinContainer/CodeInput
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
	
	# Enable join button only when we have 6 digits
	join_button.disabled = filtered_text.length() != 6

# Handle join button press - attempt to connect to host
func _on_join_pressed() -> void:
	var code = code_input.text
	if code.length() != 6:
		_show_status("Invalid lobby code", Color.RED)
		return
	
	# Disable UI while connecting
	join_button.disabled = true
	code_input.editable = false
	_show_status("Connecting...", Color.YELLOW)
	
	# Convert lobby code to IP address (for now using localhost)
	# In a real implementation, you'd use a lobby server or matchmaking
	var host_ip = "127.0.0.1"  # Localhost for testing
	var port = DEFAULT_PORT + (int(code) % 58535)  # Use code to offset port, keep within valid range (7000-65535)
	
	# Create client peer
	var peer = ENetMultiplayerPeer.new()
	var result = peer.create_client(host_ip, port)
	
	if result == OK:
		multiplayer.multiplayer_peer = peer
		print("Attempting to connect to host at %s:%d" % [host_ip, port])
	else:
		_show_status("Failed to create client", Color.RED)
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
	_show_status("Connection failed - check lobby code", Color.RED)
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
	join_button.disabled = code_input.text.length() != 6
	code_input.editable = true
	code_input.grab_focus()

# Handle back button press - return to multiplayer menu
func _on_back_pressed() -> void:
	# Clean up any network connection
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
	
	get_tree().change_scene_to_file("res://scenes/multiplayer_menu.tscn") 