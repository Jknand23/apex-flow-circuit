## Multiplayer Join Script
## Handles the interface for joining an existing multiplayer game.
## Players enter a host IP address and a 6-digit lobby code to connect.

extends Control

# Network connection parameters
const DEFAULT_PORT = 7000

# Reference to UI elements
@onready var code_input = $JoinContainer/CodeInput
@onready var ip_input = $JoinContainer/IPInput
@onready var join_button = $JoinContainer/ButtonContainer/JoinButton
@onready var status_label = $JoinContainer/StatusLabel

func _ready() -> void:
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	ip_input.grab_focus()

func _on_code_input_text_changed(new_text: String) -> void:
	var filtered_text = ""
	for char in new_text:
		if char.is_valid_int():
			filtered_text += char
	if filtered_text != new_text:
		code_input.text = filtered_text
		code_input.caret_column = filtered_text.length()
	_update_join_button_state()

func _on_ip_input_text_changed(new_text: String) -> void:
	_update_join_button_state()

func _update_join_button_state() -> void:
	var code_valid = code_input.text.length() == 6
	var ip_valid = _is_valid_ip(ip_input.text) or ip_input.text == "localhost"
	join_button.disabled = not (code_valid and ip_valid)

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

func _on_join_pressed() -> void:
	var code = code_input.text
	var host_ip = ip_input.text
	
	if not _is_valid_ip(host_ip) and host_ip != "localhost":
		_show_status("Invalid IP address", Color.RED)
		return
		
	if host_ip == "localhost":
		host_ip = "127.0.0.1"

	join_button.disabled = true
	code_input.editable = false
	ip_input.editable = false
	_show_status("Connecting to " + host_ip + "...", Color.YELLOW)
	
	var port = DEFAULT_PORT + (int(code) % 58535)
	
	var peer = ENetMultiplayerPeer.new()
	var result = peer.create_client(host_ip, port)
	
	if result == OK:
		multiplayer.multiplayer_peer = peer
		print("Attempting to connect to host at %s:%d" % [host_ip, port])
	else:
		_show_status("Failed to create client connection.", Color.RED)
		_reset_ui()

func _on_connected_to_server() -> void:
	print("Connected to server successfully!")
	GameManager.is_host = false
	get_tree().change_scene_to_file("res://scenes/multiplayer_lobby.tscn")

func _on_connection_failed() -> void:
	print("Failed to connect to server")
	_show_status("Connection failed. Check IP and lobby code.", Color.RED)
	_reset_ui()

func _on_server_disconnected() -> void:
	print("Server disconnected")
	_show_status("Lost connection to host.", Color.RED)
	_reset_ui()

func _show_status(message: String, color: Color = Color.WHITE) -> void:
	status_label.text = message
	status_label.modulate = color
	status_label.visible = true

func _reset_ui() -> void:
	_update_join_button_state()
	code_input.editable = true
	ip_input.editable = true
	ip_input.grab_focus()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/multiplayer_menu.tscn") 