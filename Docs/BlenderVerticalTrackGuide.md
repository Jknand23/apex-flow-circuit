# Blender Vertical Track Creation Guide

**Purpose:** Complete step-by-step instructions for creating a vertical racing track around the Low Poly City using Blender, then importing back into Godot.

---

## Prerequisites
- Blender 3.0+ installed
- Your `Low poly City-FBX.fbx` file ready
- Basic understanding of 3D navigation

---

## Phase 1: Setup and City Import

### 1.1 Start New Project
1. Open Blender
2. **File** → **New** → **General**
3. Delete default cube (`X` → **Delete**)
4. Save project as `CityTrack.blend`

### 1.2 Import City Model
1. **File** → **Import** → **FBX (.fbx)**
2. Navigate to your `assets/models/environments/`
3. Select `Low poly City-FBX.fbx`
4. **Import FBX**

### 1.3 Setup Scene
1. **Frame city in view:**
   - Select city object (click on it)
   - Press **Home** key or **Numpad .** (period) to frame it
2. **Switch to top view:**
   - Press **`** (backtick) → **Top** (or **View** menu → **Viewpoint** → **Top**)
3. **Switch to Orthographic:**
   - Press **`** → **Orthographic** (or **5** if numpad enabled)

---

## Phase 2: Creating the Track Path

### 2.1 Add Base Curve
1. **Add Bezier Curve:**
   - `Shift + A` → **Curve** → **Bezier**
2. **Position starting point:**
   - Tab into **Edit Mode**
   - Select curve points and move them (`G` to grab/move)
   - Start at ground level on city edge

### 2.2 Build Vertical Path
1. **Add more curve points:**
   - `E` to **extrude** new points
   - `G` then `Z` to move along Z-axis (vertical)
   - `G` then `X` or `Y` to move horizontally

2. **Create vertical sections:**
   - **Ground to Building:** Start low, curve up building sides
   - **Building Traversal:** Run along rooftops and walls
   - **Aerial Sections:** Bridge between buildings with curves
   - **Spiral Sections:** Use `R` (rotate) to create corkscrews

### 2.3 Design Track Layout
**Suggested vertical track sections:**
- **Launch Ramp:** Steep incline from street level
- **Building Wall Ride:** Track along skyscraper sides
- **Rooftop Sprint:** Flat sections across building tops
- **Aerial Loops:** Curved bridges between buildings
- **Spiral Descent:** Corkscrew down around cylindrical buildings
- **Ground Return:** Banking curves back to street level

### 2.4 Curve Editing Tips
- **Select points:** Right-click on curve handles
- **Adjust curve smoothness:** Select point, press `V` for handle type
- **Copy sections:** `Shift + D` to duplicate curve segments
- **Join curves:** Select multiple curves, `Ctrl + J`

---

## Phase 3: Converting to Track Geometry

### 3.1 Set Curve Properties
1. **Select your curve**
2. **Properties Panel** → **Curve Properties** (curve icon)
3. **Bevel section:**
   - **Depth:** `0.5` (track width)
   - **Resolution:** `4` (smoothness)
4. **Fill:** **Both** (creates solid track)

### 3.2 Alternative: Manual Mesh Creation
If curve method doesn't work:
1. **Convert curve to mesh:**
   - Select curve
   - `Ctrl + C` → **Mesh**
2. **Add thickness:**
   - Tab into **Edit Mode**
   - Select all (`A`)
   - `Alt + E` → **Faces Along Normals**
   - Move mouse to set thickness

### 3.3 Create Track Barriers
1. **Duplicate track:**
   - Select track, `Shift + D`
2. **Scale up slightly:**
   - `S` → `1.1` (10% larger)
3. **Move barriers up:**
   - `G` → `Z` → `0.2`

---

## Phase 4: Track Refinement

### 4.1 Add Banking to Curves
1. **Enter Edit Mode** (`Tab`)
2. **Select curve sections**
3. **Rotate for banking:**
   - `R` → `Z` → angle value (e.g., `15` for 15 degrees)

### 4.2 Create Checkpoints/Sections
1. **Add planes** for checkpoint triggers:
   - `Shift + A` → **Mesh** → **Plane**
2. **Scale and position** across track
3. **Name them** systematically: `Checkpoint_01`, `Checkpoint_02`, etc.

### 4.3 Add Details
- **Support pillars** under aerial sections
- **Track connectors** between building sections
- **Launch ramps** with proper angles
- **Landing platforms** for jumps

---

## Phase 5: Organization and Materials

### 5.1 Organize Objects
1. **Create Collections:**
   - **Outliner** → Right-click → **New Collection**
   - Collections: `City`, `Track_Main`, `Track_Barriers`, `Checkpoints`
2. **Move objects to collections:**
   - Drag objects in Outliner

### 5.2 Basic Materials (Optional)
1. **Select track geometry**
2. **Material Properties** tab
3. **New Material**
4. **Base Color:** Set to track color (gray/black)

---

## Phase 6: Export for Godot

### 6.1 Prepare for Export
1. **Select track objects only** (not city)
2. **Apply all modifiers:**
   - Select object → **Modifier Properties**
   - Click **Apply** on each modifier

### 6.2 Export Options

**Option A: Separate Track File**
1. **Select track objects**
2. **File** → **Export** → **FBX (.fbx)**
3. **Selection Only:** ✓ (checked)
4. **Scale:** `1.00`
5. **Export as:** `vertical_track.fbx`

**Option B: Combined Scene**
1. **Select all** (`A`)
2. **File** → **Export** → **FBX (.fbx)**
3. **Export as:** `city_with_track.fbx`

### 6.3 Godot Import Settings
When importing in Godot:
- **Import tab:** Set to **Scene**
- **Meshes:** Create **Trimesh Collision** for track
- **Materials:** Import or replace with Godot materials

---

## Phase 7: Godot Integration

### 7.1 Scene Setup
1. **Import track** into Godot scene
2. **Add StaticBody3D** to track mesh
3. **Add CollisionShape3D** with track collision
4. **Test with player movement**

### 7.2 Track Features in Godot
- **Checkpoint triggers:** Area3D nodes
- **Speed boosts:** Special track sections
- **Gravity zones:** For wall-riding sections
- **Respawn points:** At safe locations

---

## Troubleshooting

### Common Issues:
- **Track too narrow/wide:** Adjust curve bevel depth
- **Jagged curves:** Increase curve resolution
- **Track not solid:** Check curve fill settings
- **Intersections with buildings:** Use snap to face
- **Godot import issues:** Check FBX export scale

### Performance Tips:
- **Keep geometry simple** for better game performance
- **Use separate materials** for track sections
- **Optimize curve resolution** (don't over-smooth)
- **Create modular sections** for easier editing

---

## Keyboard Reference Card

| Action | Shortcut |
|--------|----------|
| Add Object | `Shift + A` |
| Delete | `X` |
| Edit Mode | `Tab` |
| Grab/Move | `G` |
| Rotate | `R` |
| Scale | `S` |
| Extrude | `E` |
| Select All | `A` |
| Duplicate | `Shift + D` |
| View Menu | ` (backtick) |
| Frame Selected | `Numpad .` or `Home` |

---

**Tips for Success:**
- Start simple with basic curves, add complexity gradually
- Test frequently by switching to camera view
- Save versions of your work (`File` → **Save As**)
- Keep track sections modular for easier iteration
- Reference real racing games for inspiration

**End Goal:** A thrilling vertical racing track that uses your city's architecture as an integrated part of the racing experience! 