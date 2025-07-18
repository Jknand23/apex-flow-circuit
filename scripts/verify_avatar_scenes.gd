## Verify Avatar Scenes Script
## Checks that all avatar scene files exist and can be loaded

extends Node

func _ready() -> void:
	print("=== VERIFYING AVATAR SCENES ===")
	
	var all_good = true
	
	for i in range(4):
		var avatar_path = GameManager.get_avatar_scene(i)
		print("\nCharacter ", i, ":")
		print("  Avatar scene: ", avatar_path)
		
		if ResourceLoader.exists(avatar_path):
			print("  ✅ File exists")
			var scene = load(avatar_path)
			if scene:
				print("  ✅ Can load scene")
			else:
				print("  ❌ Cannot load scene")
				all_good = false
		else:
			print("  ❌ File does not exist")
			all_good = false
	
	print("\n=== VERIFICATION ", "PASSED" if all_good else "FAILED", " ===")
	
	if not all_good:
		print("\nTo fix:")
		print("1. Create/rename these avatar files in the scenes folder:")
		print("   - skaler_male.tscn (note the typo)")
		print("   - skater_female.tscn")
		print("   - cybord_female.tscn (note the typo)")
		print("   - criminal_male.tscn") 