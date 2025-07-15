# Learning Log for Apex Flow Circuit Project

This log captures key learnings, insights, and experiments throughout the development process. Entries are dated and tied to specific phases or days.

## Day 1: Setup & Basics ( [Insert Date] )

- **Key Learnings**:
  - Explored Godot's "Getting Started" documentation, focusing on Nodes, Scenes, and Signals. Understood how Nodes form the building blocks of scenes, with Scenes being reusable compositions.
  - Completed the 'Your First 2D Game' tutorial, which introduced GDScript basics like variables, functions, and signal connections. Pivoted to 3D by experimenting with Node3D and MeshInstance3D.
  - Watched GDQuest videos on 3D fundamentals, learning about Camera3D, lighting with DirectionalLight3D, and basic physics with CharacterBody3D.
  - Built a simple track scene and a controllable board with an avatar, implementing movement in _physics_process for smooth, frame-independent updates.
  - Clarified Node hierarchy: Root nodes manage children, and attaching scripts to nodes allows for behavior customization.

- **Challenges & Solutions**:
  - Initial confusion with 3D coordinates; resolved by testing transformations in the editor.
  - Movement felt clunky; tweaked speed and gravity values iteratively for a fun 'vibe'.

- **Experiments**:
  - Tried different meshes for the board and avatar; imported free assets from Kenney.nl for placeholders.
  - Added print statements for debugging velocity – great for understanding physics in real-time.

- **Next Steps**: Dive deeper into physics for ramps and jumps in Day 2.

Educational Note: Logging learnings helps reinforce concepts and track progress – a great habit for any developer! 