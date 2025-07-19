## Race Manager Singleton
## Handles lap tracking, race timing, and race state management
## Supports both single-player and multiplayer racing with 3-lap races

extends Node

# Race constants
const LAPS_TO_WIN: int = 3
const LAP_START_DELAY: float = 3.0  # Countdown before race starts

# Race state
var is_race_active: bool = false
var race_start_time: float = 0.0
var race_countdown: float = 0.0
var is_countdown_active: bool = false

# Player lap tracking - Dictionary of player_id -> lap_data
var player_lap_data: Dictionary = {}

# Signals for UI and game events
signal lap_completed(player_id: int, lap_number: int, lap_time: float)
signal race_started()
signal race_finished(player_id: int, total_time: float)
signal countdown_updated(seconds: int)

# Struct-like dictionary for player lap data
func create_player_lap_data() -> Dictionary:
	return {
		"current_lap": 1,
		"lap_start_time": 0.0,
		"lap_times": [],  # Array of completed lap times
		"race_start_time": 0.0,
		"race_finished": false,
		"best_lap_time": 0.0
	}

func _ready() -> void:
	# Ensure this persists across scene changes
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Connect to GameManager signals if needed
	if GameManager:
		# Reset when leaving multiplayer
		pass

func _process(delta: float) -> void:
	# Handle race countdown
	if is_countdown_active:
		race_countdown -= delta
		var countdown_seconds = int(ceil(race_countdown))
		countdown_updated.emit(countdown_seconds)
		
		if race_countdown <= 0:
			_start_race()

## Initializes race for single or multiplayer
## @param player_ids Array of player IDs to track (use [1] for single player)
func initialize_race(player_ids: Array) -> void:
	print("=== Initializing race for players: ", player_ids, " ===")
	
	# Clear previous race data
	player_lap_data.clear()
	is_race_active = false
	
	# Initialize each player's lap data
	for player_id in player_ids:
		player_lap_data[player_id] = create_player_lap_data()
		print("Initialized lap data for player ", player_id)
	
	# Start countdown
	_start_countdown()

## Starts the pre-race countdown
func _start_countdown() -> void:
	print("Starting race countdown...")
	is_countdown_active = true
	race_countdown = LAP_START_DELAY
	countdown_updated.emit(int(ceil(race_countdown)))

## Starts the actual race after countdown
func _start_race() -> void:
	print("Race started!")
	is_countdown_active = false
	is_race_active = true
	race_start_time = Time.get_ticks_msec() / 1000.0
	
	# Set race start time for all players
	for player_id in player_lap_data:
		player_lap_data[player_id]["race_start_time"] = race_start_time
		player_lap_data[player_id]["lap_start_time"] = race_start_time
	
	race_started.emit()

## Called when a player crosses the start/finish line
## @param player_id The ID of the player who crossed the line
func player_crossed_finish_line(player_id: int) -> void:
	if not is_race_active or not player_lap_data.has(player_id):
		print("Race not active or player not found: ", player_id)
		return
	
	var player_data = player_lap_data[player_id]
	if player_data["race_finished"]:
		print("Player ", player_id, " already finished race")
		return
	
	var current_time = Time.get_ticks_msec() / 1000.0
	var lap_time = current_time - player_data["lap_start_time"]
	var current_lap = player_data["current_lap"]
	
	print("Player ", player_id, " completed lap ", current_lap, " in ", lap_time, " seconds")
	
	# Record lap time
	player_data["lap_times"].append(lap_time)
	
	# Update best lap time
	if player_data["best_lap_time"] == 0.0 or lap_time < player_data["best_lap_time"]:
		player_data["best_lap_time"] = lap_time
	
	# Check if race is finished
	if current_lap >= LAPS_TO_WIN:
		# Emit lap completion signal for final lap
		lap_completed.emit(player_id, current_lap, lap_time)
		_finish_race_for_player(player_id, current_time)
	else:
		# Start next lap
		player_data["current_lap"] += 1
		player_data["lap_start_time"] = current_time
		print("Player ", player_id, " starting lap ", player_data["current_lap"])
		
		# Emit lap completion signal AFTER updating to next lap
		lap_completed.emit(player_id, current_lap, lap_time)

## Finishes the race for a player
## @param player_id The player who finished
## @param finish_time The time when they finished
func _finish_race_for_player(player_id: int, finish_time: float) -> void:
	var player_data = player_lap_data[player_id]
	player_data["race_finished"] = true
	
	var total_race_time = finish_time - player_data["race_start_time"]
	print("Player ", player_id, " finished race in ", total_race_time, " seconds!")
	
	race_finished.emit(player_id, total_race_time)
	
	# In multiplayer, sync race finish to all clients
	if multiplayer.has_multiplayer_peer() and multiplayer.is_server():
		sync_race_finish.rpc(player_id, total_race_time)
	
	# Check if this is the first player to finish in multiplayer
	if GameManager.is_multiplayer_game:
		var finished_count = 0
		for pid in player_lap_data:
			if player_lap_data[pid]["race_finished"]:
				finished_count += 1
		
		# If this is the first player to finish, show results for all players
		if finished_count == 1:
			print("First player finished! Triggering race results for all players.")
			# Wait a brief moment then show results for all
			await get_tree().create_timer(2.0).timeout
			_trigger_all_player_results.rpc()
	
	# Check if all players finished (for multiplayer)
	var all_finished = true
	for pid in player_lap_data:
		if not player_lap_data[pid]["race_finished"]:
			all_finished = false
			break
	
	if all_finished:
		print("All players finished! Race complete.")
		is_race_active = false

## Gets current lap for a player
## @param player_id The player ID to check
## @return Current lap number (1-3)
func get_current_lap(player_id: int) -> int:
	if player_lap_data.has(player_id):
		return player_lap_data[player_id]["current_lap"]
	return 1

## Gets race progress for a player (for UI display)
## @param player_id The player ID to check
## @return Dictionary with current lap, total laps, times, etc.
func get_race_progress(player_id: int) -> Dictionary:
	if not player_lap_data.has(player_id):
		return {"current_lap": 1, "total_laps": LAPS_TO_WIN, "lap_times": [], "best_lap": 0.0, "race_finished": false}
	
	var player_data = player_lap_data[player_id]
	return {
		"current_lap": player_data["current_lap"],
		"total_laps": LAPS_TO_WIN,
		"lap_times": player_data["lap_times"].duplicate(),
		"best_lap": player_data["best_lap_time"],
		"race_finished": player_data["race_finished"]
	}

## Gets race progress for all players (for multiplayer results)
## @return Dictionary of player_id -> race progress
func get_all_player_progress() -> Dictionary:
	var all_progress = {}
	for player_id in player_lap_data:
		all_progress[player_id] = get_race_progress(player_id)
	return all_progress

## Resets race state (for restart or new race)
func reset_race() -> void:
	print("Resetting race state")
	player_lap_data.clear()
	is_race_active = false
	is_countdown_active = false
	race_countdown = 0.0

## RPC functions for multiplayer synchronization
@rpc("any_peer", "call_local", "reliable")
func sync_lap_completion(player_id: int, lap_number: int, lap_time: float) -> void:
	# This ensures all clients see lap completions
	if not multiplayer.is_server():
		lap_completed.emit(player_id, lap_number, lap_time)

@rpc("authority", "call_local", "reliable") 
func sync_race_start() -> void:
	# Broadcast race start to all clients
	if not multiplayer.is_server():
		race_started.emit()

@rpc("authority", "call_local", "reliable")
func sync_race_finish(player_id: int, total_time: float) -> void:
	# Broadcast race finish to all clients
	if not multiplayer.is_server():
		race_finished.emit(player_id, total_time)

## RPC to trigger race results display for all players
@rpc("authority", "call_local", "reliable")
func _trigger_all_player_results() -> void:
	# Signal that triggers results screen for all players
	print("Triggering race results for all players")
	# Get the first finisher's data
	var first_finisher_id = -1
	var first_finisher_time = 0.0
	
	for player_id in player_lap_data:
		if player_lap_data[player_id]["race_finished"]:
			first_finisher_id = player_id
			var finish_time = Time.get_ticks_msec() / 1000.0
			first_finisher_time = finish_time - player_lap_data[player_id]["race_start_time"]
			break
	
	if first_finisher_id != -1:
		# Emit a special signal to show results for all players
		all_players_show_results.emit()

# Add new signal for showing results to all players
signal all_players_show_results() 