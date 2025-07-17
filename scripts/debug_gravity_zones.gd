# scripts/debug_gravity_zones.gd
# Debug helper for testing enhanced gravity zones
# Attach to a Node3D in your scene to spawn test zones with keyboard

extends Node3D

## Key to spawn a gravity zone at player position
@export var spawn_key: String = "g"

## Reference to the player
@export var player_path: NodePath = "/root/BasicTrackRoot/PlayerBoard"

## Enhanced gravity zone scene
@export var zone_scene: PackedScene = preload("res://scenes/enhanced_gravity_zone.tscn")

## Current zone for testing
var test_zone: Area3D

func _ready() -> void:
	print("Gravity Zone Debug Helper Active - Press '", spawn_key, "' to spawn test zone at player")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed(spawn_key):
		_spawn_test_zone()
	
	# Additional debug keys
	if event.is_action_pressed("ui_page_up"):
		_adjust_zone_multiplier(0.5)
	elif event.is_action_pressed("ui_page_down"):
		_adjust_zone_multiplier(-0.5)

## Spawns a test zone at the player's position
func _spawn_test_zone() -> void:
	var player = get_node_or_null(player_path)
	if not player:
		print("Player not found at path: ", player_path)
		return
	
	# Remove old test zone if exists
	if test_zone:
		test_zone.queue_free()
	
	# Create new zone
	test_zone = zone_scene.instantiate()
	get_parent().add_child(test_zone)
	
	# Position at player with offset
	test_zone.global_position = player.global_position + Vector3(0, -2, 0)
	
	# Make it large and noticeable
	if test_zone.has_node("CollisionShape3D"):
		var shape = test_zone.get_node("CollisionShape3D")
		if shape.shape is BoxShape3D:
			shape.shape.size = Vector3(20, 10, 20)
	
	# Set strong effect
	test_zone.gravity_strength_multiplier = 4.0
	test_zone.downhill_only = false  # Test everywhere
	
	print("Test gravity zone spawned at player position")
	print("Multiplier: ", test_zone.gravity_strength_multiplier)
	print("Position: ", test_zone.global_position)

## Adjusts the multiplier of the test zone
func _adjust_zone_multiplier(delta: float) -> void:
	if not test_zone:
		print("No test zone to adjust")
		return
	
	test_zone.gravity_strength_multiplier = max(0.5, test_zone.gravity_strength_multiplier + delta)
	print("Zone multiplier adjusted to: ", test_zone.gravity_strength_multiplier) 