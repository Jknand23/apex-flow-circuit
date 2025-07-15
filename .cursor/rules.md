# Cursor Rules for Apex Flow Circuit

## Project Overview
- This is a Godot 4.3 project using GDScript, building a high-octane board-racing game prototype.
- Focus on core mechanics like Velocity Cadence (decaying speed bar tied to tricks), multiplayer racing, performance (60 FPS target), progression (XP unlocks), and engagement (objectives, sound/VFX).
- Development style: "Vibe coding" – iterative, fun, educational process. Explain concepts step-by-step like teaching a beginner. Avoid portraying untested code or features as guaranteed real-world successes; suggest testing and iteration instead.
- Scope: Realistic 80-hour prototype with one track, basic online multiplayer (2-4 players), desktop primary (web export later).

## Coding Style and Best Practices
- **Language and Tools**: Use GDScript exclusively. Stick to Godot's built-in features (e.g., Nodes, Scenes, Signals, RPC for multiplayer). Recommend free assets from Kenney.nl if needed.
- **File Structure**: Keep files modular and under 500 lines. Use descriptive names (e.g., `velocity_cadence.gd` instead of `speed.gd`). Organize into folders like `scripts/`, `scenes/`, `assets/` (models, sounds, textures).
- **Code Organization**:
  - Add comments to every function and major block, explaining "why" (purpose) and "how" (mechanics).
  - Use functional programming where possible: Favor pure functions, avoid global state.
  - Modular scenes: Break down into reusable scenes (e.g., separate scenes for player board, track hazards, UI elements).
- **Error Handling and Debugging**: Always include basic error checks (e.g., null checks). Suggest using Godot's debugger and profiler for FPS optimization. If suggesting code, include print statements for quick testing.
- **Performance**: Target 60 FPS. Optimize by reducing draw calls, using occlusion culling, and profiling physics. For multiplayer, use prediction/interpolation for low-latency sync.
- **Multiplayer**: Use ENet for networking. Sync essentials like positions, Cadence, and tricks via @rpc. Start with local testing, then online.
- **Progression and Saves**: Use JSON for simple XP/persistence (e.g., unlocks for cosmetics). No complex databases.
- **Art and Audio**: Cel-shaded 3D style inspired by Bomb Rush Cyberfunk. Suggest simple VFX (particles, trails) and sound effects for feedback.

## AI Assistance Guidelines
- **Educational Approach**: When generating or explaining code, break it down educationally in responses: 1) Concept overview, 2) Step-by-step implementation, 3) Why it fits the project, 4) Testing tips. Reference Godot docs, GDQuest YouTube, or /r/godot for learning. Keep code clean without embedded educational notes—deliver learning through prompts and conversations.
- **Vibe Coding**: Encourage fun, iterative changes. Suggest small experiments (e.g., "Try tweaking this gravity value and playtest the feel"). If something might not work perfectly, say "This is a starting point – test and vibe it out!"
- **Prompt Responses**: Be concise but thorough. If editing code, use Godot's conventions (e.g., `_ready()`, signals). Always suggest committing changes with descriptive messages.
- **Avoidances**: Don't generate untested features as "production-ready." No in-game purchases or unrelated monetization. Pivot to simpler alternatives if complexity arises (e.g., splitscreen fallback for multiplayer issues).
- **Learning Log Integration**: Remind to log learnings (e.g., "Add to your log: Learned RPCs via this prompt – helped with sync!").

## Example Prompt Response Style
User: "Help me implement Velocity Cadence."
AI: "Sure! Velocity Cadence is your core speed mechanic. Let's break it down educationally:

1. **Concept**: A UI bar that decays over time but fills with tricks.
2. **Implementation**: Attach this GDScript to a Node...
   [Code snippet with comments]
3. **Why it fits**: Ties into risk/reward without overpowering multiplayer.
4. **Test it**: Run the scene and tweak decay rate – vibe the feel!"

Follow these rules to keep development fun and on-track! 