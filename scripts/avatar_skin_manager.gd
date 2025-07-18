# scripts/avatar_skin_manager.gd
# Alternative approach to skin changing using texture atlasing
# This manager handles skin changes by modifying UV coordinates or using texture arrays

extends Node

# Dictionary mapping character indices to their UV offsets
const SKIN_UV_OFFSETS = {
	0: Vector2(0.0, 0.0),    # skaterMaleA
	1: Vector2(0.5, 0.0),    # skaterFemaleA  
	2: Vector2(0.0, 0.5),    # cyborgFemaleA
	3: Vector2(0.5, 0.5)     # criminalMaleA
}

## Creates a texture atlas from individual skin textures
## @return ImageTexture containing all skins
static func create_skin_atlas() -> ImageTexture:
	var atlas_size = Vector2i(2048, 2048)  # 2x2 grid of 1024x1024 textures
	var atlas_image = Image.create(atlas_size.x, atlas_size.y, false, Image.FORMAT_RGBA8)
	
	# Load all skin textures
	var skins = [
		"res://assets/textures/avatars/skins/skaterMaleA.png",
		"res://assets/textures/avatars/skins/skaterFemaleA.png",
		"res://assets/textures/avatars/skins/cyborgFemaleA.png", 
		"res://assets/textures/avatars/skins/criminalMaleA.png"
	]
	
	# Place each skin in the atlas
	for i in range(skins.size()):
		var skin_texture = load(skins[i]) as Texture2D
		if skin_texture:
			var skin_image = skin_texture.get_image()
			var x = (i % 2) * 1024
			var y = (i / 2) * 1024
			atlas_image.blit_rect(skin_image, Rect2i(0, 0, 1024, 1024), Vector2i(x, y))
	
	return ImageTexture.create_from_image(atlas_image)

## Alternative method: Change skin by modifying shader parameters for UV offset
## @param mesh_instance The mesh to modify
## @param character_index The character skin index
static func change_skin_via_uv_offset(mesh_instance: MeshInstance3D, character_index: int) -> void:
	var material = mesh_instance.get_surface_override_material(0)
	if material and material is ShaderMaterial:
		var uv_offset = SKIN_UV_OFFSETS.get(character_index, Vector2.ZERO)
		material.set_shader_parameter("uv_offset", uv_offset)
		material.set_shader_parameter("uv_scale", Vector2(0.5, 0.5))
		print("Set UV offset to: ", uv_offset, " for character ", character_index) 