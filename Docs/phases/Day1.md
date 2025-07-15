# Day 1: Setup & Basics

**Goal**: Get productive in Godot 4.3 by setting up the project, learning basics, and creating a simple controllable board on a flat track. This day focuses on foundational skills through tutorials and initial scene building. Remember to vibe code – take it step by step, experiment, and have fun!

## Expanded To-Do List

- [x] **Install Godot**:
   - Download and install Godot 4.3 from the official website (godotengine.org).
   - Verify installation by launching the editor.
   - Educational Note: Godot is free and open-source – perfect for beginners!

- [x] **Set Up the Project**:
   - Create a new project named "Apex Flow Circuit" in a dedicated folder.
   - Familiarize yourself with the editor interface: Scene dock, FileSystem, Inspector, etc.
   - Import any initial assets if needed (e.g., from Kenney.nl for placeholders).

- [x] **Follow Getting Started Documentation**:
   - Read through Godot's "Getting Started" section in the official docs.
   - Focus on key concepts: Nodes, Scenes, Signals.
   - Experiment in a test scene to understand hierarchy.

- [x] **Complete 'Your First 2D Game' Tutorial**:
   - Follow the official tutorial to build a simple 2D game (e.g., Dodge the Creeps).
   - This builds confidence in GDScript and basic mechanics.
   - Pivot: Once done, explore the 3D equivalent by creating a simple 3D scene.

- [x] **Learn 3D Basics**:
   - Watch a short GDQuest YouTube video on Godot 3D fundamentals (e.g., Camera, MeshInstance, Physics).
   - Create a basic 3D scene with a floor (PlaneMesh) and a simple object.

- [x] **Build Simple Track Scene**:
   - Create a new scene in `scenes/` called `basic_track.tscn`.
   - Add a Node3D as root.
   - Add a MeshInstance3D with a PlaneMesh for the flat track (scale it large).
   - Add basic lighting (DirectionalLight3D) and a camera.

- [X] **Create Controllable Board**:
   - Create a new scene for the player board, e.g., `player_board.tscn`.
   - Use a CharacterBody3D node for movement (better for control than RigidBody initially).
   - Attach a simple Mesh (BoxMesh or import a board model if available).

- [X] **Add Avatar to Board**:
   - In the `player_board.tscn` scene, add a child Node3D for the avatar position.
   - Add a MeshInstance3D for the avatar (use a simple CapsuleMesh as a placeholder or import a free character model from Kenney.nl).
   - Position the avatar on top of the board mesh, slightly offset for a riding pose.
   - Educational Note: This makes the player feel more connected – later, we can add animations!
   - Vibe Tip: Experiment with scaling and rotation to get a fun riding stance.

- [X] **Implement Basic Movement Script**:
   - Create a GDScript file in `scripts/` called `player_movement.gd`.
   - Attach it to the player_board root.
   - Implement simple controls: Forward acceleration, turning left/right, jumping.
   - Use `_physics_process` for smooth movement.
   - AI Prompt Suggestion: "Simple GDScript for 3D player movement in Godot, like a hoverboard."

- [X] **Integrate into Main Scene**:
    - Instance the player_board into the basic_track scene.
    - Set up a WorldEnvironment for basic visuals.
    - Add collision to the track if needed.

- [X] **Test and Debug**:
    - Run the scene and test movement.
    - Use print statements for debugging (e.g., current speed).
    - Tweak values like speed and gravity – vibe it out to feel fun!
    - Check FPS in the profiler; aim for 60+.

- [x] **Learning Log**:
    - Create or update a log in Docs/ (e.g., LearningLog.md).
    - Entry: "Learned via Godot docs and AI prompts; clarified Node hierarchy and basic 3D setup."

- [ ] **Commit Changes**:
    - Use Git to commit: "Day 1: Project setup, basic controllable board with avatar."
    - Push to repo if using version control.

**Milestone**: A controllable board moving on a flat track – the foundation for Velocity Cadence!

**Tips**: If stuck, reference /r/godot or Godot forums. Take breaks to avoid burnout. Test iteratively! 