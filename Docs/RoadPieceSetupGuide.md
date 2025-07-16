# Road Piece Setup Guide

This guide shows how to convert the imported Kenney road GLB files into usable game assets with proper collision and materials.

## Quick Setup Workflow

### Method 1: Using Templates (Recommended)
1. **Open a template scene** (`scenes/prefabs/road_*_template.tscn`)
2. **Replace the road model** with your desired GLB file
3. **Adjust collision shape** to match the road dimensions
4. **Apply material** to the MeshInstance3D inside the road model
5. **Save as new scene** in `scenes/prefabs/roads/`

### Method 2: From Scratch
1. **Create new scene** with `StaticBody3D` root
2. **Instance road GLB** as child (`Add Child Node` → `Instance`)
3. **Add CollisionShape3D** as child of StaticBody3D
4. **Create appropriate collision shape** (BoxShape3D, CapsuleShape3D, etc.)
5. **Apply road material** to mesh inside the instanced GLB

## Material Setup

### Road Material
- **Location**: `assets/materials/road_material.tres`
- **Texture**: Uses `colormap.png` from Kenney assets
- **Properties**: Configured for realistic road surface (low metallic, medium roughness)

### Applying Materials
1. Expand the instanced GLB in the scene dock
2. Find the `MeshInstance3D` node (usually nested inside)
3. In Inspector → **Material Override** → Add `road_material.tres`

## Collision Shapes Guide

### Straight Roads
- **Shape**: `BoxShape3D`
- **Size**: `Vector3(2, 0.1, 10)` (adjust to match road)
- **Position**: Center at road surface level

### Curved Roads  
- **Shape**: `CapsuleShape3D` or multiple `BoxShape3D`
- **Size**: Match the curve radius and road width
- **Alternative**: Use `ConvexPolygonShape3D` generated from mesh

### Intersections
- **Shape**: Multiple `BoxShape3D` or single large `BoxShape3D`
- **Size**: Cover all road surface areas
- **Position**: Ensure full intersection coverage

### Complex Pieces (Bridges, Ramps)
- **Shape**: `ConvexPolygonShape3D` (auto-generated from mesh)
- **Alternative**: Multiple primitive shapes for better performance

## File Organization

```
scenes/prefabs/roads/
├── straight/
│   ├── road_straight.tscn
│   ├── road_straight_barrier.tscn
│   └── road_straight_half.tscn
├── curves/
│   ├── road_curve.tscn
│   ├── road_curve_barrier.tscn
│   └── road_bend_square.tscn
├── intersections/
│   ├── road_intersection.tscn
│   ├── road_crossroad.tscn
│   └── road_roundabout.tscn
└── special/
    ├── road_bridge.tscn
    ├── road_slant.tscn
    └── road_end.tscn
```

## Tips for Manual Placement

### In Scene Editor
1. **Drag prefab scenes** directly into your main scene
2. **Use snap to grid** for alignment (Scene → Snap → Grid)
3. **Group road pieces** for easy organization
4. **Use duplicate** (Ctrl+D) for quick placement

### Transform Controls
- **Position**: Place at exact world coordinates
- **Rotation**: Use 90° increments for road alignment
- **Scale**: Generally keep at 1,1,1 (scale is built into the models)

### Performance Considerations
- **Group static roads** under single Node3D for better performance
- **Use LOD** for distant road pieces if scene becomes complex
- **Consider merging** similar road pieces into single meshes for large areas

## Common Issues

### No Collision
- **Problem**: Player/objects fall through roads
- **Solution**: Ensure CollisionShape3D is child of StaticBody3D, not Area3D

### No Texture
- **Problem**: Roads appear white/untextured
- **Solution**: Apply road material to MeshInstance3D inside the instanced GLB

### Wrong Scale
- **Problem**: Roads are too big/small compared to player
- **Solution**: Adjust StaticBody3D scale, or use Transform → Scale in prefab

### Misaligned Pieces
- **Problem**: Road pieces don't connect properly
- **Solution**: Use grid snapping and ensure pivot points are consistent

## Next Steps

1. **Create prefabs** for your most-used road pieces
2. **Test collision** by running the scene with your player
3. **Organize scenes** by road type for easy access
4. **Consider scripting** automatic road generation for complex tracks 