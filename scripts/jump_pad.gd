# scripts/jump_pad.gd
# Interactive zone that launches the player upward when entered.
# Attach to an Area3D node with CollisionShape3D for zone detection.

## The JumpPad class extends Area3D to detect when the player enters its collision area.
## When triggered, it applies an upward velocity boost to launch the player.
class_name JumpPad
extends Area3D

## Emitted when a player launches from this jump pad.
## @param body The body that was launched.
## @param launch_velocity The velocity vector applied to the body.
signal player_launched(body, launch_velocity)

## The upward force applied when the player hits the jump pad.
## Higher values create more dramatic launches.
@export var launch_force: float = 15.0

## Optional horizontal boost for angled jump pads.
## Uses the jump pad's forward direction (-Z axis).
@export var forward_boost: float = 0.0

## Cooldown time in seconds to prevent rapid re-triggering.
@export var cooldown_time: float = 0.2

## Sound effect to play when triggered (optional).
@export var launch_sound: AudioStream

## Visual effect on launch (optional particle system).
@onready var particles: GPUParticles3D = $LaunchParticles if has_node("LaunchParticles") else null
@onready var audio_player: AudioStreamPlayer3D = $AudioStreamPlayer3D if has_node("AudioStreamPlayer3D") else null

# Internal cooldown tracking
var last_trigger_time: float = 0.0

func _ready() -> void:
	# Add to group for easy identification
	add_to_group("jump_pads")
	
	# Setup audio if sound is provided
	if launch_sound and audio_player:
		audio_player.stream = launch_sound

## Called when a body enters the jump pad collision area.
## Applies launch force to the player if cooldown has elapsed.
## @param body The body that entered the area.
func _on_body_entered(body: Node3D) -> void:
	# More robust player detection for multiplayer
	var is_player = body.is_in_group("player") or body.name.begins_with("Player_") or body is CharacterBody3D
	
	# Only print debug info for potential players
	if is_player or body.name.contains("Player"):
		print("Jump pad triggered by: ", body.name, " Groups: ", body.get_groups())
	
	# Check if it's the player and cooldown has elapsed
	if not is_player:
		# Only print for actual player-like objects to reduce spam
		if body.name.contains("Player") or body is CharacterBody3D:
			print("Not a player, ignoring: ", body.name)
		return
		
	var time_since_last = Time.get_ticks_msec() / 1000.0 - last_trigger_time
	
	if time_since_last < cooldown_time:
		print("Still on cooldown, ignoring")
		return
	
	print("Launching player!")
	# Apply the launch force
	_launch_player(body)
	last_trigger_time = Time.get_ticks_msec() / 1000.0

## Applies the launch velocity to the player.
## @param player The player CharacterBody3D to launch.
func _launch_player(player: CharacterBody3D) -> void:
	# Safety check - ensure it's a CharacterBody3D
	if not player is CharacterBody3D:
		push_warning("Jump pad target is not a CharacterBody3D: " + str(player))
		return
	
	# Calculate launch direction
	var launch_direction = Vector3.UP * launch_force
	
	# Add forward boost if specified
	if forward_boost > 0.0:
		var forward = -global_transform.basis.z.normalized()
		launch_direction += forward * forward_boost
	
	# Apply the velocity safely
	player.velocity.y = launch_direction.y
	player.velocity.x += launch_direction.x
	player.velocity.z += launch_direction.z
	
	# Set jumping state to prevent immediate landing
	if "is_jumping" in player:
		player.is_jumping = true
	
	# Activate air resistance timer for realistic post-launch behavior
	if player.has_method("activate_air_resistance"):
		player.activate_air_resistance()
	
	# Trigger effects
	_play_effects()
	
	# Emit signal for external systems
	player_launched.emit(player, launch_direction)
	
	print("Jump pad launched player with velocity: ", player.velocity)

## Plays visual and audio effects when triggered.
func _play_effects() -> void:
	# Play sound effect
	if audio_player and launch_sound:
		audio_player.play()
	
	# Trigger particle effect
	if particles:
		particles.restart()

## Public method to manually trigger the jump pad.
## Useful for scripted sequences or testing.
## @param target_body The body to launch.
func trigger_launch(target_body: CharacterBody3D) -> void:
	_launch_player(target_body) 
