## Multiplayer Menu Script
## Handles navigation between host and join options for multiplayer games
## This is the entry point for all multiplayer functionality

extends Control

# Called when the node enters the scene tree
func _ready() -> void:
	# Make sure the menu is visible and grab focus
	visible = true
	$MenuContainer/HostButton.grab_focus()

# Handle host button press - opens the host lobby
func _on_host_pressed() -> void:
	print("Opening host lobby...")
	get_tree().change_scene_to_file("res://scenes/multiplayer_lobby.tscn")

# Handle join button press - opens the join screen
func _on_join_pressed() -> void:
	print("Opening join screen...")
	get_tree().change_scene_to_file("res://scenes/multiplayer_join.tscn")

# Handle back button press - returns to main menu
func _on_back_pressed() -> void:
	print("Returning to main menu...")
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn") 