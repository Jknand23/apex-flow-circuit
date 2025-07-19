## Checkpoint Trigger Script
## Detects when players cross the start/finish line and notifies RaceManager
## Attach to an Area3D node positioned at the start/finish line

extends Area3D

## Type of checkpoint (start_finish, intermediate, etc.)
@export var checkpoint_type: String = "start_finish"

## Unique ID for this checkpoint (useful for race validation)
@export var checkpoint_id: int = 0

## Visual feedback for checkpoint crossing (optional)
@onready var visual_effect: Node = get_node_or_null("VisualEffect")

func _ready() -> void:
	# Add to checkpoint group for easy identification
	add_to_group("checkpoints")
	
	# Connect body entered signal
	body_entered.connect(_on_body_entered)
	
	print("Checkpoint '", checkpoint_type, "' (ID: ", checkpoint_id, ") ready at position: ", global_position)

## Called when a body enters the checkpoint area
## @param body The body that entered the checkpoint
func _on_body_entered(body: Node3D) -> void:
	# Check if it's a player
	var is_player = body.is_in_group("player") or body.name.begins_with("Player_")
	
	if not is_player:
		return
	
	# Get player ID for multiplayer support
	var player_id = _get_player_id(body)
	
	print("Player ", player_id, " crossed checkpoint: ", checkpoint_type)
	
	# Handle different checkpoint types
	match checkpoint_type:
		"start_finish":
			_handle_start_finish_crossing(player_id, body)
		"intermediate":
			_handle_intermediate_crossing(player_id, body)
		_:
			print("Unknown checkpoint type: ", checkpoint_type)
	
	# Visual feedback
	_trigger_visual_effect()

## Handles start/finish line crossing
## @param player_id The ID of the player
## @param body The player body node
func _handle_start_finish_crossing(player_id: int, body: Node3D) -> void:
	# Notify RaceManager about finish line crossing
	if RaceManager:
		RaceManager.player_crossed_finish_line(player_id)
	else:
		print("ERROR: RaceManager not found!")

## Handles intermediate checkpoint crossing (for future use)
## @param player_id The ID of the player  
## @param body The player body node
func _handle_intermediate_crossing(player_id: int, body: Node3D) -> void:
	# Future: Could be used for lap validation or section timing
	print("Player ", player_id, " passed intermediate checkpoint ", checkpoint_id)

## Gets the player ID from the player body
## @param body The player body node
## @return Player ID for multiplayer, or 1 for single player
func _get_player_id(body: Node3D) -> int:
	# For multiplayer, extract ID from player name (e.g., "Player_2" -> 2)
	if body.name.begins_with("Player_"):
		var id_string = body.name.substr(7)  # Remove "Player_" prefix
		return int(id_string) if id_string.is_valid_int() else 1
	
	# For single player, return 1
	return 1

## Triggers visual feedback effect
func _trigger_visual_effect() -> void:
	if visual_effect:
		# Animate or activate visual effect
		if visual_effect.has_method("play"):
			visual_effect.play()
		elif visual_effect is AnimationPlayer:
			visual_effect.play("checkpoint_crossed")
	
	# Add screen flash or other feedback
	_screen_flash_effect()

## Creates a brief screen flash when crossing checkpoint
func _screen_flash_effect() -> void:
	# Find UI and create brief visual feedback
	var ui = get_node_or_null("/root/BasicTrackRoot/UI")
	if not ui:
		return
	
	# Create temporary flash overlay
	var flash = ColorRect.new()
	flash.color = Color(1, 1, 1, 0.3)  # Semi-transparent white
	flash.size = get_viewport().get_visible_rect().size
	flash.position = Vector2.ZERO
	ui.add_child(flash)
	
	# Animate fade out
	var tween = create_tween()
	tween.tween_property(flash, "modulate:a", 0.0, 0.2)
	tween.tween_callback(flash.queue_free) 
