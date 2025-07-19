## Race Results Screen Script
## Shows race completion results and provides options for restart or menu return
## Attach to a CanvasLayer node that serves as an overlay

extends CanvasLayer

# UI element references
@onready var control: Control = $Control
@onready var results_panel: Panel = $Control/ResultsPanel
@onready var title_label: Label = $Control/ResultsPanel/VBox/TitleLabel
@onready var time_label: Label = $Control/ResultsPanel/VBox/TimeLabel
@onready var lap_times_label: Label = $Control/ResultsPanel/VBox/LapTimesLabel
@onready var best_lap_label: Label = $Control/ResultsPanel/VBox/BestLapLabel
@onready var restart_button: Button = $Control/ResultsPanel/VBox/ButtonContainer/RestartButton
@onready var menu_button: Button = $Control/ResultsPanel/VBox/ButtonContainer/MenuButton

# Results data
var race_results: Dictionary = {}

func _ready() -> void:
	# Initially hidden
	visible = false
	
	# Set process mode to handle paused input
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	
	# Connect to RaceManager signals
	if RaceManager:
		RaceManager.race_finished.connect(_on_race_finished)
		RaceManager.all_players_show_results.connect(_on_all_players_show_results)
		print("Race results screen connected to RaceManager")
	else:
		print("ERROR: RaceManager not found in race results screen!")
	
	# Connect button signals immediately
	_connect_buttons()
	print("Race results screen ready and buttons connected")

## Shows the race results screen for single player or individual player in multiplayer
## @param player_id The player who finished
## @param total_time The total race time
func show_results(player_id: int, total_time: float) -> void:
	if not RaceManager:
		return
	
	# Get complete race data
	race_results = RaceManager.get_race_progress(player_id)
	race_results["total_time"] = total_time
	
	# Update UI elements
	title_label.text = "RACE COMPLETE!"
	time_label.text = "Total Time: %s" % _format_time(total_time)
	best_lap_label.text = "Best Lap: %s" % _format_time(race_results["best_lap"])
	
	# Format lap times
	var lap_times_text = "Lap Times:\n"
	for i in range(RaceManager.LAPS_TO_WIN):
		if i < race_results["lap_times"].size():
			var lap_time = race_results["lap_times"][i]
			lap_times_text += "Lap %d: %s\n" % [i + 1, _format_time(lap_time)]
		else:
			lap_times_text += "Lap %d: N/A\n" % [i + 1]
	lap_times_label.text = lap_times_text
	
	# Show the screen
	visible = true
	
	# Pause the game while showing results
	get_tree().paused = true
	
	# Focus on restart button for keyboard navigation
	if restart_button:
		restart_button.grab_focus()
	
	print("Showing race results for player ", player_id)

## Shows multiplayer race results with all players' data
func show_multiplayer_results() -> void:
	if not RaceManager:
		return
	
	# Get all players' progress
	var all_progress = RaceManager.get_all_player_progress()
	
	# Find the winner (first to finish)
	var winner_id = -1
	var winner_time = 0.0
	
	for player_id in all_progress:
		if all_progress[player_id]["race_finished"]:
			winner_id = player_id
			# Calculate their total time from lap times
			var lap_times = all_progress[player_id]["lap_times"]
			for lap_time in lap_times:
				winner_time += lap_time
			break
	
	# Update title
	if winner_id == multiplayer.get_unique_id():
		title_label.text = "YOU WON!"
		title_label.modulate = Color.GOLD
	else:
		title_label.text = "RACE COMPLETE!"
		title_label.modulate = Color.WHITE
	
	# Format results for all players
	var results_text = ""
	
	# Sort players by completion status and ID
	var sorted_players = all_progress.keys()
	sorted_players.sort_custom(func(a, b): 
		var a_finished = all_progress[a]["race_finished"]
		var b_finished = all_progress[b]["race_finished"]
		if a_finished and not b_finished:
			return true
		elif not a_finished and b_finished:
			return false
		else:
			return a < b
	)
	
	for player_id in sorted_players:
		var player_data = all_progress[player_id]
		var player_name = "Player %d" % player_id
		
		# Add player indicator for local player
		if player_id == multiplayer.get_unique_id():
			player_name += " (You)"
		
		results_text += "\n%s:\n" % player_name
		
		# Calculate total time if finished
		if player_data["race_finished"]:
			var total_time = 0.0
			for lap_time in player_data["lap_times"]:
				total_time += lap_time
			results_text += "  Total Time: %s\n" % _format_time(total_time)
		else:
			results_text += "  Total Time: N/A (Did Not Finish)\n"
		
		# Show lap times
		results_text += "  Lap Times: "
		for i in range(RaceManager.LAPS_TO_WIN):
			if i < player_data["lap_times"].size():
				results_text += "%s" % _format_time(player_data["lap_times"][i])
			else:
				results_text += "N/A"
			
			if i < RaceManager.LAPS_TO_WIN - 1:
				results_text += ", "
		results_text += "\n"
		
		# Show best lap
		if player_data["best_lap"] > 0:
			results_text += "  Best Lap: %s\n" % _format_time(player_data["best_lap"])
		else:
			results_text += "  Best Lap: N/A\n"
	
	# Update UI with multiplayer results
	time_label.visible = false  # Hide single player time display
	best_lap_label.visible = false  # Hide single player best lap
	lap_times_label.text = results_text
	
	# Show the screen
	visible = true
	
	# Pause the game while showing results
	get_tree().paused = true
	
	# Focus on restart button for keyboard navigation
	if restart_button:
		restart_button.grab_focus()
	
	print("Showing multiplayer race results")

func _input(event: InputEvent) -> void:
	# Only handle input when results screen is visible
	if not visible:
		return
		
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("player_jump"):
		# Space or Enter to restart
		_on_restart_pressed()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
		# Escape to menu
		_on_menu_pressed()
		get_viewport().set_input_as_handled()

## Hides the race results screen
func hide_results() -> void:
	visible = false
	get_tree().paused = false

## Connects button signals immediately when nodes are available
func _connect_buttons() -> void:
	# Ensure we have the button references
	if not restart_button:
		restart_button = get_node_or_null("Control/ResultsPanel/VBox/ButtonContainer/RestartButton")
	if not menu_button:
		menu_button = get_node_or_null("Control/ResultsPanel/VBox/ButtonContainer/MenuButton")
	
	# Connect restart button
	if restart_button and not restart_button.pressed.is_connected(_on_restart_pressed):
		restart_button.pressed.connect(_on_restart_pressed)
		print("Connected restart button")
	else:
		print("ERROR: Restart button not found or already connected!")
	
	# Connect menu button
	if menu_button and not menu_button.pressed.is_connected(_on_menu_pressed):
		menu_button.pressed.connect(_on_menu_pressed)
		print("Connected menu button")
	else:
		print("ERROR: Menu button not found or already connected!")

## Formats time in MM:SS.sss format
## @param time_seconds Time in seconds to format
## @return Formatted time string
func _format_time(time_seconds: float) -> String:
	var minutes = int(time_seconds) / 60
	var seconds = int(time_seconds) % 60
	var milliseconds = int((time_seconds - int(time_seconds)) * 1000)
	return "%02d:%02d.%03d" % [minutes, seconds, milliseconds]

# Signal handlers

## Called when a player finishes the race
## @param player_id The player who finished
## @param total_time The total race time
func _on_race_finished(player_id: int, total_time: float) -> void:
	# In single player, show results immediately
	if not GameManager.is_multiplayer_game:
		show_results(player_id, total_time)
		return
	
	# In multiplayer, only show if all players should see results now
	# The all_players_show_results signal will handle showing for everyone

## Called when all players should see the race results (multiplayer)
func _on_all_players_show_results() -> void:
	if GameManager.is_multiplayer_game:
		show_multiplayer_results()

## Called when restart button is pressed
func _on_restart_pressed() -> void:
	print("=== RESTART BUTTON PRESSED ===")
	hide_results()
	
	# Reset the race
	if RaceManager:
		RaceManager.reset_race()
		print("Race manager reset")
	
	# Small delay to ensure cleanup
	await get_tree().create_timer(0.1).timeout
	
	# Restart the scene
	print("Reloading current scene...")
	get_tree().reload_current_scene()

## Called when menu button is pressed
func _on_menu_pressed() -> void:
	print("=== MENU BUTTON PRESSED ===")
	hide_results()
	
	# Reset game state
	if RaceManager:
		RaceManager.reset_race()
		print("Race manager reset")
	
	if GameManager:
		GameManager.reset_multiplayer_state()
		print("Game manager reset")
	
	# Small delay to ensure cleanup
	await get_tree().create_timer(0.1).timeout
	
	# Return to main menu
	print("Changing scene to main menu...")
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn") 