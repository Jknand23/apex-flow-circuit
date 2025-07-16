# Fixing Collision Alignment for Road Pieces

When road collision shapes don't match the visual mesh, here are the proper methods to fix them.

## Problem: Collision Shape Misalignment

### Symptoms
- Players fall through roads
- Collision debug shows shapes floating above/below the road
- Physics interactions feel wrong on slants

## Solution Methods

### Method 1: Auto-Generate from Mesh (Recommended for Slants)

1. **Open the problematic road prefab** (e.g., `road_slant_high_ready.tscn`)
2. **Expand the RoadModel** in the Scene dock to find the MeshInstance3D
3. **Right-click the MeshInstance3D** → "Create Single Convex Collision Sibling"
4. **Delete the old CollisionShape3D** with wrong alignment
5. **Move the new collision** from under MeshInstance3D to under the StaticBody3D root
6. **Rename** the new CollisionShape3D to match your naming convention

### Method 2: Manual Box Alignment

1. **Enable collision debug**: Project Settings → Debug → Shapes → Visible Collision Shapes = ON
2. **Run the scene** to see the collision shape position
3. **Open the prefab** and select the CollisionShape3D
4. **Adjust Transform** in Inspector:
   - **Position**: Move Y until it sits on the road surface
   - **Rotation**: Rotate X to match the road angle
   - **Scale**: Adjust if the box is too big/small

### Method 3: Multiple Simple Shapes

For complex road pieces, use several BoxShape3D:

1. **Duplicate CollisionShape3D** nodes
2. **Position each box** to cover different sections of the road
3. **Better performance** than convex shapes for long roads

## Specific Fixes for Slant Roads

### Road-Slant-High Proper Setup

**Step 1**: Open `road_slant_high_ready.tscn`

**Step 2**: In the Scene dock, expand:
```
RoadSlantHigh (StaticBody3D)
├── RoadModel (instance)
│   └── road-slant-high (MeshInstance3D)  ← Right-click this
└── SlantCollision (CollisionShape3D)     ← Delete this
```

**Step 3**: Right-click `road-slant-high` → "Create Single Convex Collision Sibling"

**Step 4**: A new CollisionShape3D appears under road-slant-high. **Drag it up** to be directly under RoadSlantHigh (same level as RoadModel)

**Step 5**: **Rename** the new CollisionShape3D to "SlantCollision"

**Step 6**: **Save the scene**

### Road-Slant Quick Fix Angles

If you prefer BoxShape3D, here are working transform values:

```gdscript
# For road-slant (gentle slope):
transform = Transform3D(1, 0, 0, 0, 0.966, 0.259, 0, -0.259, 0.966, 0, 0.3, 0)

# For road-slant-high (steep slope):  
transform = Transform3D(1, 0, 0, 0, 0.844, 0.537, 0, -0.537, 0.844, 0, 0.8, 0)

# For road-slant-flat (gentle decline):
transform = Transform3D(1, 0, 0, 0, 0.985, 0.174, 0, -0.174, 0.985, 0, 0.2, 0)
```

## Testing Your Fixes

### Visual Debug
1. **Enable collision shapes**: Project Settings → Debug → Shapes → Visible Collision Shapes
2. **Run the test scene** to see collision outlines
3. **Green/colored shapes** should align perfectly with road surface

### Physics Test
1. **Place a RigidBody3D** (like a ball) above the road
2. **Run the scene** - the ball should roll along the road surface
3. **No falling through** = collision is properly aligned

### Player Test
1. **Use your player controller** on the road piece
2. **Walk/ride along the surface** - should feel smooth
3. **No teleporting or floating** = good collision

## Performance Considerations

### ConvexPolygonShape3D
- ✅ **Perfect accuracy** - matches mesh exactly
- ⚠️ **Higher performance cost** for complex meshes
- 👍 **Best for slants and curves**

### BoxShape3D  
- ✅ **Very fast performance**
- ✅ **Good enough** for simple roads
- 👍 **Best for straight roads**

### Multiple BoxShape3D
- ✅ **Good performance**
- ✅ **High accuracy** when positioned well
- 👍 **Best for complex pieces**

## Common Transform Values

### Rotation Matrix Quick Reference
```
15° slope = 0.966, 0.259, -0.259, 0.966
30° slope = 0.866, 0.500, -0.500, 0.866  
45° slope = 0.707, 0.707, -0.707, 0.707
```

### Y Position Guidelines
- **Gentle slopes**: Y = 0.2 to 0.5
- **Steep slopes**: Y = 0.5 to 1.0  
- **Extreme slopes**: Y = 1.0+

## Troubleshooting

### "Create Collision Sibling" Missing
- **Problem**: Menu option not available
- **Solution**: Make sure you're right-clicking the MeshInstance3D, not the parent

### Collision Still Wrong
- **Problem**: Auto-generated collision doesn't fit
- **Solution**: Manually adjust the CollisionShape3D position/rotation after generation

### Performance Issues
- **Problem**: Too many ConvexPolygonShape3D shapes
- **Solution**: Use BoxShape3D for straight sections, ConvexPolygonShape3D only for curves/slants

---

**Follow these steps and your road collision will be perfect!** 🎯 