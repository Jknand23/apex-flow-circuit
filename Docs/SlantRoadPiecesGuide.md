# Slant Road Pieces Guide

Complete guide for building ramps, elevation changes, and vertical track sections using the slant road pieces.

## Available Slant Pieces

### 🔸 road_slant_ready.tscn
- **Type**: Gentle upward slope  
- **Use**: Smooth transitions from flat to elevated
- **Angle**: ~15° incline
- **Groups**: `["road", "track_surface", "ramp"]`

### 🔹 road_slant_high_ready.tscn  
- **Type**: Steep ramp
- **Use**: Dramatic elevation changes, jump launches
- **Angle**: ~30° incline  
- **Groups**: `["road", "track_surface", "ramp"]`

### 🔺 road_slant_flat_ready.tscn
- **Type**: Transition piece
- **Use**: Smoothly connect elevated roads back to ground level
- **Angle**: ~10° decline
- **Groups**: `["road", "track_surface", "transition"]`

## Building Ramps - Step by Step

### Simple Upward Ramp
```
Ground → road_slant_ready.tscn → Elevated Roads
```

### Steep Jump Ramp  
```
Ground → road_slant_high_ready.tscn → Air Gap
```

### Complete Elevation Change
```
Ground → road_slant_ready.tscn → road_slant_high_ready.tscn → Elevated → road_slant_flat_ready.tscn (rotated) → Ground
```

### Multi-Level Track
```
Level 1 → Slant Up → Level 2 → Slant Up → Level 3 → Slant Down → Level 1
```

## Rotation Guide

### For Downward Ramps
- **Rotate Y**: 180° to reverse direction
- **Alternative**: Use road_slant_flat_ready.tscn rotated 90° or 180°

### For Side Ramps  
- **Rotate Y**: 90° or 270° for left/right ramps
- **Banking**: Rotate Z for banked turns on ramps

## Practical Examples

### Launch Pad Setup
1. Place `road_straight_ready.tscn` as approach
2. Add `road_slant_high_ready.tscn` for launch
3. Position landing area with `road_straight_ready.tscn` 
4. Add `road_slant_flat_ready.tscn` for landing transition

### Elevated Highway
1. Ground roads: `road_straight_ready.tscn`
2. On-ramp: `road_slant_ready.tscn`  
3. High section: Multiple `road_straight_ready.tscn` at elevated Y position
4. Off-ramp: `road_slant_flat_ready.tscn` (rotated 180°)

### Spiral Track
1. Combine slant pieces with `road_curve_ready.tscn`
2. Gradually increase Y position each level
3. Use different slant angles for variety

## Collision Setup

### Slant Collision Features
- **Angled collision shapes** match the road surface exactly
- **Debug colors**:
  - 🟠 Orange: road_slant_high_ready.tscn  
  - 🟡 Yellow: road_slant_ready.tscn
  - 🟨 Light Yellow: road_slant_flat_ready.tscn
- **Grouped for scripting**: Easy to detect ramp sections

### Player Physics Considerations
- **Momentum**: Players gain/lose speed on slopes
- **Gravity**: Adjust player gravity for better ramp feel
- **Landing**: Use Area3D triggers for landing detection

## Performance Tips

### For Large Ramp Sections
- **Group similar pieces** under single Node3D
- **Use StaticBody3D merging** for very long ramps  
- **LOD**: Switch to simple collision for distant ramps

### Memory Optimization
- **Instance reuse**: Same prefab can be rotated/positioned differently
- **Texture sharing**: All pieces use the same road_material.tres
- **Collision caching**: Godot caches collision shapes automatically

## Testing Your Ramps

### Test Scene
Open `scenes/test_ramp_building.tscn` to see working examples of:
- ✅ Upward ramp progression
- ✅ Elevated highway section  
- ✅ Downward transition
- ✅ Platform support structures

### Debugging
1. **Enable collision debug** in Project Settings → Debug → Shapes
2. **Check ramp angles** by running and observing player movement
3. **Adjust collision transforms** if physics feel wrong
4. **Test with your player controller** for proper momentum

## Advanced Techniques

### Custom Slant Angles
1. Open a template: `scenes/prefabs/road_*_template.tscn`
2. Replace GLB with different slant model
3. Adjust collision transform rotation to match
4. Save as new prefab

### Procedural Ramp Generation
```gdscript
# Example script for automatic ramp placement
func create_ramp_section(start_pos: Vector3, end_pos: Vector3):
    var height_diff = end_pos.y - start_pos.y
    var distance = start_pos.distance_to(end_pos)
    
    if height_diff > 2.0:
        # Use steep ramp for big elevation changes
        var ramp = preload("res://scenes/prefabs/roads/road_slant_high_ready.tscn").instantiate()
    else:
        # Use gentle ramp for small changes  
        var ramp = preload("res://scenes/prefabs/roads/road_slant_ready.tscn").instantiate()
    
    add_child(ramp)
    ramp.global_position = start_pos
```

## Troubleshooting

### Player Falls Through Ramps
- **Problem**: Collision shape doesn't match visual mesh
- **Solution**: Adjust collision transform rotation in the prefab

### Ramps Don't Connect Smoothly  
- **Problem**: Misaligned pivot points or positioning
- **Solution**: Use grid snapping and consistent Y-level calculations

### Performance Issues
- **Problem**: Too many collision shapes
- **Solution**: Merge adjacent ramp pieces or use simpler collision shapes

---

**Happy ramp building! 🏁** 