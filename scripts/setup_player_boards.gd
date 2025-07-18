## Setup Player Boards Script
## Utility script to help configure player board scenes with pre-applied skins
## This addresses the Godot runtime shader texture update limitation

extends Node

# Character configurations mapping indices to their properties
const CHARACTER_CONFIGS = {
	0: {
		"name": "player_board_skater_male",
		"skin_path": "res://assets/textures/avatars/skins/skaterMaleA.png",
		"display_name": "Skater Male A"
	},
	1: {
		"name": "player_board_skater_female", 
		"skin_path": "res://assets/textures/avatars/skins/skaterFemaleA.png",
		"display_name": "Skater Female A"
	},
	2: {
		"name": "player_board_cyborg_female",
		"skin_path": "res://assets/textures/avatars/skins/cyborgFemaleA.png",
		"display_name": "Cyborg Female A"
	},
	3: {
		"name": "player_board_criminal_male",
		"skin_path": "res://assets/textures/avatars/skins/criminalMaleA.png",
		"display_name": "Criminal Male A"
	}
}

## Instructions for manual setup in Godot Editor:
## 1. Duplicate player_board.tscn three times
## 2. Rename them to:
##    - player_board_skater_male.tscn (this is the original, just rename it)
##    - player_board_skater_female.tscn
##    - player_board_cyborg_female.tscn
##    - player_board_criminal_male.tscn
## 3. Open each scene and manually apply the skin to the Avatar's mesh
## 4. Save each scene

## Helper function to get the correct player board scene path
static func get_player_board_scene_path(character_index: int) -> String:
	var config = CHARACTER_CONFIGS.get(character_index, CHARACTER_CONFIGS[0])
	return "res://scenes/" + config.name + ".tscn"

## Debug function to verify all player board scenes exist
static func verify_player_board_scenes() -> bool:
	var all_exist = true
	for i in CHARACTER_CONFIGS:
		var path = get_player_board_scene_path(i)
		if not ResourceLoader.exists(path):
			push_error("Missing player board scene: " + path)
			all_exist = false
		else:
			print("✓ Found player board scene: " + path)
	return all_exist 