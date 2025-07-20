## Lobby Service
## Handles communication with the lobby server for automatic IP discovery
## This allows players to connect across networks using only lobby codes

extends Node

# Lobby server configuration
# You'll need to set up a simple HTTP server that can store/retrieve lobby data
# For testing, you can use a local server or a free service like Replit
const ENABLE_LOBBY_SERVICE = true  # Set to false to require manual IP entry
const LOBBY_SERVER_URLS = [
	"https://apex-flow-lobby-server.YOUR-USERNAME.repl.co",  # Replace YOUR-USERNAME!
	"http://localhost:3000"                                  # Local testing fallback
]
const LOBBY_ENDPOINT = "/api/lobbies"
var current_server_index = 0

# HTTP request node
var http_request: HTTPRequest

# Cached external IP
var cached_external_ip: String = ""

func _ready() -> void:
	# Create HTTP request node
	http_request = HTTPRequest.new()
	add_child(http_request)

## Registers a lobby with the server
## @param lobby_code The 6-digit lobby code
## @param port The port number the host is listening on
## @param callback Function to call with result (success: bool, message: String)
func register_lobby(lobby_code: String, port: int, callback: Callable) -> void:
	# First, get our external IP
	_get_external_ip(func(ip: String):
		if ip.is_empty():
			callback.call(false, "Failed to get external IP")
			return
		
		# Register the lobby with our external IP
		var data = {
			"code": lobby_code,
			"host_ip": ip,
			"port": port,
			"timestamp": Time.get_unix_time_from_system()
		}
		
		var json = JSON.stringify(data)
		var headers = ["Content-Type: application/json"]
		
		# Make request to register lobby
		http_request.request_completed.connect(_on_register_completed.bind(callback), CONNECT_ONE_SHOT)
		var error = http_request.request(LOBBY_SERVER_URLS[current_server_index] + LOBBY_ENDPOINT, headers, HTTPClient.METHOD_POST, json)
		
		if error != OK:
			callback.call(false, "Failed to send registration request")
	)

## Looks up a lobby by code to get the host's IP and port
## @param lobby_code The 6-digit lobby code to look up
## @param callback Function to call with result (success: bool, host_ip: String, port: int, message: String)
func lookup_lobby(lobby_code: String, callback: Callable) -> void:
	var url = LOBBY_SERVER_URLS[current_server_index] + LOBBY_ENDPOINT + "/" + lobby_code
	
	http_request.request_completed.connect(_on_lookup_completed.bind(callback), CONNECT_ONE_SHOT)
	var error = http_request.request(url)
	
	if error != OK:
		callback.call(false, "", 0, "Failed to send lookup request")

## Removes a lobby from the server (called when host leaves)
## @param lobby_code The lobby code to remove
func unregister_lobby(lobby_code: String) -> void:
	var url = LOBBY_SERVER_URLS[current_server_index] + LOBBY_ENDPOINT + "/" + lobby_code
	
	http_request.request_completed.connect(_on_unregister_completed, CONNECT_ONE_SHOT)
	http_request.request(url, [], HTTPClient.METHOD_DELETE)

## Gets the external IP address of this machine
## @param callback Function to call with the IP address
func _get_external_ip(callback: Callable) -> void:
	# Return cached IP if we have it
	if not cached_external_ip.is_empty():
		callback.call(cached_external_ip)
		return
	
	# Use a public IP service
	var ip_service_url = "https://api.ipify.org?format=text"
	
	var temp_http = HTTPRequest.new()
	add_child(temp_http)
	
	temp_http.request_completed.connect(func(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray):
		if response_code == 200:
			cached_external_ip = body.get_string_from_utf8().strip_edges()
			callback.call(cached_external_ip)
		else:
			# Fallback to local IP detection
			cached_external_ip = _get_local_ip_fallback()
			callback.call(cached_external_ip)
		temp_http.queue_free()
	, CONNECT_ONE_SHOT)
	
	var error = temp_http.request(ip_service_url)
	if error != OK:
		# Fallback to local IP
		cached_external_ip = _get_local_ip_fallback()
		callback.call(cached_external_ip)
		temp_http.queue_free()

## Fallback method to get local IP if external IP service fails
func _get_local_ip_fallback() -> String:
	var ip_addresses = IP.get_local_addresses()
	
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
	
	return "127.0.0.1"

# Callback handlers

func _on_register_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray, callback: Callable) -> void:
	if response_code == 200 or response_code == 201:
		callback.call(true, "Lobby registered successfully")
		current_server_index = 0  # Reset to primary on success
	else:
		# Try next server if available
		if current_server_index < LOBBY_SERVER_URLS.size() - 1:
			current_server_index += 1
			print("Primary server failed, trying backup server %d" % current_server_index)
			# Retry with next server (would need to re-call register_lobby)
		
		var error_msg = "Failed to register lobby (HTTP %d)" % response_code
		if body.size() > 0:
			var response = JSON.parse_string(body.get_string_from_utf8())
			if response and response.has("error"):
				error_msg = response["error"]
		callback.call(false, error_msg)

func _on_lookup_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray, callback: Callable) -> void:
	if response_code == 200:
		var response = JSON.parse_string(body.get_string_from_utf8())
		if response and response.has("host_ip") and response.has("port"):
			callback.call(true, response["host_ip"], response["port"], "Lobby found")
		else:
			callback.call(false, "", 0, "Invalid lobby data")
	elif response_code == 404:
		callback.call(false, "", 0, "Lobby code not found")
	else:
		callback.call(false, "", 0, "Failed to lookup lobby (HTTP %d)" % response_code)

func _on_unregister_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	if response_code == 200:
		print("Lobby unregistered successfully")
	else:
		print("Failed to unregister lobby") 