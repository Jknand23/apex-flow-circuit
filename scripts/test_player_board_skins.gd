## Test Player Board Skins Script
## Verifies that the player board skin system is properly implemented
## Run this in the editor or attach to a test scene

extends Node

func _ready() -> void:
	print("=== PLAYER BOARD SKINS TEST ===")
	test_game_manager_functions()
	test_scene_existence()
	test_scene_loading()
	print("=== TEST COMPLETE ===")

## Test GameManager helper functions
func test_game_manager_functions() -> void:
	print("\n1. Testing GameManager functions:")
	
	for i in range(4):
		var scene_path = GameManager.get_player_board_scene(i)
		var skin_path = GameManager.get_character_skin(i)
		print("  Character ", i, ":")
		print("    Scene: ", scene_path)
		print("    Skin: ", skin_path)
	
	# Test out of bounds
	print("  Out of bounds test (index 10):")
	print("    Scene: ", GameManager.get_player_board_scene(10))
	print("    Skin: ", GameManager.get_character_skin(10))

## Test if all required scenes exist
func test_scene_existence() -> void:
	print("\n2. Testing scene existence:")
	
	var setup_script = preload("res://scripts/setup_player_boards.gd")
	var all_exist = setup_script.verify_player_board_scenes()
	
	if all_exist:
		print("  ✅ All player board scenes exist!")
	else:
		print("  ❌ Some scenes are missing - check error messages above")

## Test loading each scene
func test_scene_loading() -> void:
	print("\n3. Testing scene loading:")
	
	for i in range(4):
		var scene_path = GameManager.get_player_board_scene(i)
		var scene = load(scene_path)
		
		if scene:
			print("  ✅ Successfully loaded: ", scene_path)
			
			# Try to instantiate it
			var instance = scene.instantiate()
			if instance:
				print("    - Can instantiate scene")
				
				# Check for avatar
				var avatar = instance.get_node_or_null("Avatar")
				if avatar:
					print("    - Has Avatar node")
				else:
					print("    - ⚠️  No Avatar node found")
				
				instance.queue_free()
		else:
			print("  ❌ Failed to load: ", scene_path) 