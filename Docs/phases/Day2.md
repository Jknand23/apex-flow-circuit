# Day 2: Core Mechanics (Velocity Cadence & Tricks)

**Note: We are using Godot 4.3**

**Goal**: Nail the fun factor.  
**Estimated Time**: 10-12 hours

## Step-by-Step Checklist

### Implement Cadence Bar
- [X] Create a UI node (e.g., ProgressBar) for the Cadence bar in the scene.
- [X] Write GDScript to handle decay mechanism (e.g., timer-based reduction).
- [X] Link the Cadence bar value to the player's speed variable in the movement script.

### Add Jumps, Grinds, and Bails
- [ ] Set up input detection for jump action and apply physics impulse to the player board.
- [ ] Implement grind detection using raycasts or collision areas on grindable surfaces.
- [ ] Add bail logic: Detect collisions with hazards or failed landings, reset Cadence bar.

### Add Basic Visuals
- [ ] Apply cel-shading materials to player models and track elements.
- [ ] Create trail effects using ParticleProcessMaterial or Line2D nodes.

### Test FPS
- [ ] Open the Godot debugger and monitor FPS during gameplay.
- [ ] Identify and note any performance drops related to new mechanics.

## AI Utilization Prompts
- Prompt for "GDScript for decaying speed bar."

## Learning Log
- Note resources used, e.g., "YouTube for physics; AI debugged collisions."

## Milestone
- Achieve a solo loop with tricks and speed building. 