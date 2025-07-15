# Day 3: Environment & Engagement

**Note: We are using Godot 4.3**

**Goal**: Transform your basic track into an engaging single-player racing experience with progression systems and enhanced visuals.  
**Estimated Total Time**: 10-12 hours

## Current State Assessment
- ✅ Basic movement with Velocity Cadence system working
- ✅ Grind rails (`Rail.tscn`) with collision detection
- ✅ Hazards (`Hazard.tscn`) that reset cadence on hit
- ✅ Basic cel-shader implementation
- ✅ Trail system code (needs Trail node in player scene)
- ✅ Functional UI with cadence bar

## Detailed Task Breakdown

### 1. City Scene Import & Track Foundation (2-3 hours)
**Priority**: Import city environment first before track design
**Goal**: Establish urban setting for track layout

**Tasks:**
- **Source City Scene** (30 minutes):
  - Download suitable futuristic city environment from sources like:
    - Kenney.nl (free assets)
    - OpenGameArt.org
    - Sketchfab (free downloads)
  - Import into `assets/models/environments/`

- **Integrate City Scene** (1 hour):
  - Replace or enhance current basic track with city environment
  - Ensure proper collision setup for city geometry
  - Maintain existing rail and hazard functionality

- **Track Layout Design** (1-1.5 hours):
  - Design racing circuit that flows through city environment
  - Plan elevation changes using building rooftops and elevated highways
  - Identify optimal locations for gravity flip zones (building walls/ceilings)
  - Sketch out checkpoint placement for lap system

### 2. Track Expansion & Environment (2.5-3 hours)
**Current State**: You have one rail and one hazard  
**Goal**: Create a proper racing circuit with varied elements

**Tasks:**
- **Expand Rail Network** (1.5 hours):
  - Duplicate existing `Rail.tscn` to create 12-15 rail sections
  - Arrange rails following city architecture (building edges, bridge rails, etc.)
  - Create rail chains for extended grinding opportunities
  - Vary heights to create jumping sequences between buildings
  - Test grind detection works on all rails in city context

- **Strategic Hazard Placement** (1 hour):
  - Create 8-10 hazard instances with city-themed variations
  - Add moving hazards using Tween nodes:
    - Hovering traffic (cars, drones)
    - Sliding building maintenance platforms
    - Rotating energy barriers
  - Place hazards to create risk/reward decisions near rail networks

- **Enhanced Track Geometry** (30 minutes):
  - Utilize city building surfaces for banked turns
  - Create ramps using building rooftops
  - Add wall-ride surfaces on building sides

### 3. Gravity Flip Zones Implementation (2-2.5 hours)
**Preference**: Gradual transitions for smooth feel
**Goal**: Wall/ceiling riding sections integrated with city architecture

**Tasks:**
- **Create Grav-Flip Area Scene** (1 hour):
  - New scene: `scenes/gravity_flip_zone.tscn`
  - Use Area3D with BoxShape3D collision detection
  - Script: `scripts/gravity_flip_zone.gd`
  - Visual indicators using emission materials (bright neon edges)
  - Different zones for walls vs. ceilings

- **Gradual Gravity Transition System** (1-1.5 hours):
  - Modify `player_movement.gd` to accept smooth gravity direction changes
  - Implement gradual gravity rotation using lerp over 0.5-1 second
  - Ensure controls remain relative to board orientation during transition
  - Add visual feedback (board rotation animation)

- **City Integration & Testing** (30 minutes):
  - Place 3-4 gravity zones on building walls and ceilings
  - Test smooth transitions feel natural
  - Verify rail grinding works in flipped gravity

### 4. Complete Trail Effects (1-1.5 hours)
**Current State**: Trail code exists but Trail node is missing  
**Goal**: Working Tron-style trail visual

**Tasks:**
- **Add Trail Node to Player** (45 minutes):
  - Open `player_board.tscn` in editor
  - Add MeshInstance3D child named "Trail"
  - Use QuadMesh (size 0.1 x 3.0) positioned behind board
  - Create glowing material with emission and transparency
  - Test existing trail update code connects properly

- **Enhanced Trail Visual** (45 minutes):
  - Fine-tune material: bright cyan emission with alpha fade
  - Add subtle particle system for trail sparkles
  - Test dramatic scaling (0.1x to 100x) based on Cadence
  - Ensure trail visible in all gravity orientations

### 5. Race Objectives & Win Conditions (1.5-2 hours)
**Current State**: Free-form movement  
**Goal**: Structured racing with objectives

**Tasks:**
- **Lap System Implementation** (1.5 hours):
  - Create `scripts/race_manager.gd` singleton
  - Add checkpoint triggers (Area3D nodes) around city track
  - Implement lap counter (target: 3 laps) and race timer
  - Add UI elements: current lap, best lap time, total time
  - Handle checkpoint sequence validation

- **Win Conditions & Race Flow** (30 minutes):
  - Trigger race completion after 3 laps
  - Create simple race results screen showing:
    - Total time
    - Best lap
    - XP earned
  - Basic restart functionality (R key)

### 6. Sound Effects Integration (1.5-2 hours)
**Preference**: Free sounds from online sources
**Goal**: Audio feedback for all major actions

**Tasks:**
- **Audio System Setup** (45 minutes):
  - Create `scripts/audio_manager.gd` autoload singleton
  - Add multiple AudioStreamPlayer nodes for different categories:
    - SFX_Grind, SFX_Jump, SFX_Cadence, SFX_Hazard
  - Set up volume controls and audio bus routing

- **Sound Asset Collection** (45 minutes):
  - Source free sounds from:
    - freesound.org (grind, electronic beeps, whooshes)
    - zapsplat.com (with free account)
    - Kenney.nl audio packs
  - Required sounds: grind start/loop/end, jump, land, cadence gain/loss, hazard hit, race complete
  - Import to `assets/sounds/` folder

- **Audio Integration** (30 minutes):
  - Connect sound triggers to existing game events in player_movement.gd
  - Add audio cues for race milestones (lap complete, race start)
  - Test audio doesn't impact FPS (use audio profiler)

### 7. XP Progression System (1.5-2 hours)
**Preference**: Unlocks for cosmetics and victory animations
**Goal**: Rewarding progression with visible improvements

**Tasks:**
- **XP Framework** (1 hour):
  - Create `scripts/progression_manager.gd` singleton
  - Implement XP gain events:
    - Trick bonuses: +10 XP per successful grind combo
    - Lap completion: +50 XP per lap
    - Speed bonuses: +5 XP for high cadence sustained
    - Perfect race: +100 XP bonus
  - JSON save/load system in user://progression.json

- **Cosmetic Unlock System** (30 minutes):
  - Design unlock tiers:
    - Level 1 (100 XP): New trail colors
    - Level 2 (300 XP): Avatar skin variants
    - Level 3 (600 XP): Victory animation poses
    - Level 4 (1000 XP): Special board effects
  - Create unlock notification system

- **UI Integration** (30 minutes):
  - Add XP bar and level display to main UI
  - Floating XP gain text with animation
  - Unlocks notification popup

### 8. Visual Polish & Material Enhancement (2-2.5 hours)
**Priority**: Improved materials (user preference)
**Goal**: Enhanced visual appeal with focus on materials

**Tasks:**
- **Enhanced Track Materials** (1 hour):
  - City environment material improvements:
    - Building surfaces: reflective windows, neon trim
    - Road surfaces: wet asphalt look with city light reflections
    - Rail materials: bright metal with emission glow
  - Track-specific materials:
    - Cadence boost zones with pulsing emission
    - Speed strips with animated scrolling textures

- **Cel-Shader Enhancement** (45 minutes):
  - Improve existing `cel_shader.gdshader`:
    - Add rim lighting for better object definition
    - Enhance outline thickness and color options
    - Add emission support for glowing elements
  - Apply enhanced shader to all track elements

- **Atmospheric Effects** (45 minutes):
  - Particle systems for environmental immersion:
    - Grind sparks (GPUParticles3D on rails)
    - Landing dust/energy bursts
    - Ambient city particles (floating debris, light motes)
  - Enhanced skybox with city glow and dynamic colors
  - Fog/atmosphere for depth perception

### 9. Performance Testing & Optimization (1 hour)
**Current State**: Untested performance  
**Goal**: Verified 60 FPS with all enhancements

**Tasks:**
- **Performance Analysis** (30 minutes):
  - Use Godot's built-in profiler during complex scenes
  - Monitor during gravity flips, heavy particle usage, city rendering
  - Check draw calls, physics load, and script execution time
  - Test worst-case scenarios (multiple effects + city + audio)

- **Optimization Pass** (30 minutes):
  - Reduce particle counts for budget devices if needed
  - Optimize material complexity (fewer shader features if needed)
  - Use LOD for distant city elements if performance drops
  - Profile audio impact and optimize if necessary

## AI Utilization Prompts
- "Implement gravity flips in Godot with smooth transitions"
- "GDScript for progression system with JSON save/load"
- "Optimize Godot materials for 60 FPS performance"

## Learning Log Focus
- Document: "Pivoted to city environment; learned material optimization techniques"
- Note performance optimization discoveries
- Track time spent on each major system

## Success Milestone
**Target**: Engaging single-player race in city environment with:
- Complete track with gravity zones and varied hazards
- Working lap system with race objectives
- Audio feedback and progression rewards
- Enhanced visuals maintaining 60 FPS
- City setting that supports the futuristic board racing theme

## Vibe Coding Tips
- Import city scene FIRST - let the environment inspire your track design
- Test each gravity flip zone individually before connecting them
- Playtest frequently - does the track flow feel good?
- Don't overthink cosmetic unlocks - simple color swaps work great
- Material improvements have huge visual impact for minimal performance cost

**Day 3 sets up the foundation for all remaining days - nail the fun factor here!** 