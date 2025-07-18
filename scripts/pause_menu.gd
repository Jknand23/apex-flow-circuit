## Pause Menu Script
## Handles pausing the game and returning to main menu
## Press ESC to toggle pause

extends Control

var is_paused: bool = false

# Called when the node enters the scene tree
func _ready() -> void:
	# Start hidden
	visible = false
	# Process input even when paused
	process_mode = Node.PROCESS_MODE_ALWAYS

# Handle input events
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_toggle_pause()

# Toggle pause state
func _toggle_pause() -> void:
	is_paused = !is_paused
	visible = is_paused
	
	# Pause or unpause the game tree
	get_tree().paused = is_paused
	
	if is_paused:
		# Grab focus on resume button when paused
		if has_node("MenuContainer/ResumeButton"):
			$MenuContainer/ResumeButton.grab_focus()

# Resume the game
func _on_resume_pressed() -> void:
	_toggle_pause()

# Return to main menu
func _on_main_menu_pressed() -> void:
	# Unpause before changing scenes
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

# Quit the game
func _on_quit_pressed() -> void:
	get_tree().quit() 