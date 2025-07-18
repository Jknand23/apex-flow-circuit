# Player Board Skins Setup Guide

## Overview
Due to Godot's limitations with runtime shader texture updates, we're using pre-configured player board scenes for each character skin. This guide walks through setting up the four player board variants.

## Required Player Board Scenes

You need to create these four scenes in the `scenes/` folder:
1. `player_board_skater_male.tscn` - Skater Male A skin
2. `player_board_skater_female.tscn` - Skater Female A skin  
3. `player_board_cyborg_female.tscn` - Cyborg Female A skin
4. `player_board_criminal_male.tscn` - Criminal Male A skin

## Step-by-Step Setup

### Step 1: Rename the Original Scene
1. Rename `player_board.tscn` to `player_board_skater_male.tscn`
2. This will be your base scene with the default skin

### Step 2: Create the Other Three Scenes
1. Duplicate `player_board_skater_male.tscn` three times
2. Rename the duplicates to:
   - `player_board_skater_female.tscn`
   - `player_board_cyborg_female.tscn`
   - `player_board_criminal_male.tscn`

### Step 3: Configure Each Scene's Avatar Skin

For each player board scene:

1. **Open the scene** in Godot editor
2. **Add an Avatar instance** if not already present:
   - Right-click on PlayerBoard node
   - Add Child Node → Instance Scene
   - Select `avatar.tscn`
   - Position it at (0, 1, 0) to place it above the board

3. **Apply the correct skin texture**:
   - Navigate to Avatar → characterMedium → Skeleton3D
   - Find all MeshInstance3D nodes
   - For each MeshInstance3D:
     - In the Inspector, find Surface Material Override
     - Create a new ShaderMaterial
     - Set Shader to `res://shaders/cel_shader.gdshader`
     - In Shader Parameters:
       - Set `albedo_texture` to the appropriate skin:
         - Skater Male: `res://assets/textures/avatars/skins/skaterMaleA.png`
         - Skater Female: `res://assets/textures/avatars/skins/skaterFemaleA.png`
         - Cyborg Female: `res://assets/textures/avatars/skins/cyborgFemaleA.png`
         - Criminal Male: `res://assets/textures/avatars/skins/criminalMaleA.png`
       - Set `cel_levels` to 2.0
       - Set `base_color` to white

4. **Save the scene** (Ctrl+S)

### Step 4: Verify the Setup

Run this verification in Godot's script editor:

```gdscript
# Test script - paste in a new script and run
extends Node

func _ready():
	var setup_script = preload("res://scripts/setup_player_boards.gd")
	if setup_script.verify_player_board_scenes():
		print("✅ All player board scenes are properly set up!")
	else:
		print("❌ Some player board scenes are missing!")
```

## Testing

1. Run the multiplayer test:
   - Start the game and go to Multiplayer
   - Host a game
   - Select different characters in the lobby
   - Start the game
   - Verify that each player spawns with their selected skin

## Troubleshooting

### Avatar Not Visible
- Ensure the Avatar node is added as a child of PlayerBoard
- Check that the Avatar position is set to (0, 1, 0)
- Verify the Avatar scale is (1, 1, 1)

### Wrong Skin Showing
- Double-check that you saved each scene after applying the skin
- Verify the texture path is correct in the shader parameters
- Make sure you're editing the correct scene file

### Scene Not Loading
- Check the file names match exactly (case-sensitive)
- Ensure all scenes are in the `scenes/` folder
- Run the verification script to check all scenes exist 