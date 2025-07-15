# Apex Flow Circuit Development Plan

## Overview
This is a realistic 80-hour plan (spread over 1 week, ~11-12 hours/day) to build a functional prototype of *Apex Flow Circuit* in Godot. As a beginner, focus on "vibe coding"—iterative, fun development. The prototype will include core mechanics, basic multiplayer, performance optimizations, progression, and engagement to meet the project requirements. Track learning in a log for evaluation (e.g., resources used, AI prompts, pivots).

Tech Stack: Godot 4.x (GDScript), desktop primary (export to web later). Keep files modular (<500 lines), with descriptive names and comments.

## Realistic Scope for 80 Hours
- **Core**: Single track with Velocity Cadence, tricks/grinds, collisions, hazards.
- **Multiplayer**: Basic online racing (2-4 players, real-time sync).
- **Performance**: 60 FPS target; optimize physics/assets.
- **Progression**: XP unlocks for track variations and cosmetics.
- **Engagement**: Race objectives, sound/VFX, light storyline.
- **Platform**: Desktop prototype.

This hits requirements: Real-time interaction (bumps/racing), low-latency gameplay, progression (XP/levels), fun objectives.

## Daily Breakdown

### Day 1: Setup & Basics (10-12 hours)
**Goal**: Get productive in Godot.  
- Install Godot; set up project.  
- Follow "Getting Started" docs and "Your First 2D Game" tutorial. Pivot to 3D basics.  
- Build simple scene: Track primitives, controllable board (movement).  
- AI Utilization: Prompt for "Simple GDScript for player movement."  
- Learning Log: "Learned via Godot docs; AI clarified Node hierarchy."  
- Milestone: Controllable board on flat track.

### Day 2: Core Mechanics (Velocity Cadence & Tricks) (10-12 hours)
**Goal**: Nail the fun factor.  
- Implement Cadence bar (UI, decay, speed tie-in).  
- Add jumps, grinds, bails (physics detection).  
- Visuals: Basic cel-shading, trail effects.  
- Test FPS with debugger.  
- AI Prompt: "GDScript for decaying speed bar."  
- Learning Log: "YouTube for physics; AI debugged collisions."  
- Milestone: Solo loop with tricks and speed building.

### Day 3: Environment & Engagement (10-12 hours)
**Goal**: Add track elements for progression feel.  
- Build track: Rails, hazards, Grav-Flip zones.  
- Objectives: Laps, win conditions; add sound effects.  
- Progression: XP counter, unlock hard mode.  
- Polish: Animations, VFX.  
- AI Prompt: "Implement gravity flips in Godot."  
- Learning Log: "Pivoted to primitives for speed; AI optimizations."  
- Milestone: Engaging single-player race.

### Day 4: Multiplayer Foundations (10-12 hours)
**Goal**: Hit technical achievement.  
- Set up ENet networking; lobby for host/join.  
- Sync positions, Cadence, tricks (@rpc).  
- Add player collisions (jostles).  
- Local testing.  
- AI Prompt: "GDScript for syncing movement in multiplayer."  
- Learning Log: "Godot docs + YouTube; AI refined RPCs."  
- Milestone: 2-player local race.

### Day 5: Multiplayer Polish & Performance (10-12 hours)
**Goal**: Ensure no-lag multiplayer.  
- Online support with prediction/interpolation.  
- Optimize: Reduce draw calls, profile usage.  
- Sync hazards/bails.  
- Test with 4 players.  
- AI Prompt: "Optimize Godot for low-latency racing."  
- Learning Log: "Learned interpolation; AI tweaks."  
- Milestone: Smooth online demo.

### Day 6: Progression & Full Loop (10-12 hours)
**Goal**: Implement complexity/advancement.  
- XP system (save to JSON); unlock cosmetics/levels.  
- Menus: Main, results.  
- Boost: Badges, storyline text.  
- AI Prompt: "GDScript for persistent XP unlocks."  
- Learning Log: "Docs for saves; AI integration."  
- Milestone: Complete demo with advancement.

### Day 7: Polish, Testing, & Documentation (8-10 hours)
**Goal**: Maximize quality/evaluation.  
- Art/sound tweaks.  
- Testing: Performance, bugs, stress tests.  
- Export to desktop/web.  
- Compile log: Highlight AI use, velocity, innovations.  
- AI Prompt: "Summarize learning pathway."  
- Milestone: Polished prototype.

## Tips for Success & AI Assistance
- **Routine**: 1-2 hours learning, then code/test. Take breaks.  
- **Resources**: Godot docs, YouTube (GDQuest), /r/godot, Kenney.nl assets.  
- **Code Style**: Functional GDScript, comments, modular scenes.  
- **Pivots**: Fallback to splitscreen if needed.  
- **Evaluation Tie-In**: Document learning velocity (e.g., "Productive by Day 2"), AI prompts (15+ for code/debug), innovations (AI-assisted physics pivots).  
- **Next Steps**: Use AI for specific code/explanations.

This plan ensures a quality prototype while learning efficiently.