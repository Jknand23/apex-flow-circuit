## Main Menu Script
## Handles navigation from the main menu to different game modes and features
## Single player is currently implemented, others show placeholder messages

extends Control

# Called when the node enters the scene tree
func _ready() -> void:
	# Make sure the menu is visible and grab focus
	visible = true
	$MenuContainer/SinglePlayerButton.grab_focus()

# Handle single player button press - launches the game
func _on_single_player_pressed() -> void:
	print("Starting single player mode...")
	# Change to the basic track scene which is the single player mode
	get_tree().change_scene_to_file("res://scenes/basic_track.tscn")

# Handle multiplayer button press - opens multiplayer menu
func _on_multiplayer_pressed() -> void:
	print("Opening multiplayer menu...")
	get_tree().change_scene_to_file("res://scenes/multiplayer_menu.tscn")

# Handle achievements button press - not yet implemented  
func _on_achievements_pressed() -> void:
	print("Achievements selected - Not yet implemented")
	_show_placeholder_message("Achievements system coming soon!")

# Handle victory animation button press - not yet implemented
func _on_victory_animation_pressed() -> void:
	print("Victory animation selected - Not yet implemented")
	_show_placeholder_message("Victory animations coming soon!")

# Handle quit button press - exits the game
func _on_quit_pressed() -> void:
	print("Quitting game...")
	get_tree().quit()

# Show a placeholder message for unimplemented features
func _show_placeholder_message(message: String) -> void:
	# Create a simple popup dialog
	var dialog = AcceptDialog.new()
	dialog.dialog_text = message
	dialog.title = "Coming Soon"
	dialog.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_MAIN_WINDOW_SCREEN
	add_child(dialog)
	dialog.popup_centered()
	
	# Clean up the dialog when closed
	dialog.confirmed.connect(func(): dialog.queue_free())
	dialog.canceled.connect(func(): dialog.queue_free()) 