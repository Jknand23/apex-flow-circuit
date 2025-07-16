# scripts/gravity_flip_zone.gd
# This script defines a zone that, when entered by the player,
# changes the direction of gravity.

## The GravityFlipZone class extends Area3D to detect when a body enters or exits its collision shape.
## It is designed to be attached to an Area3D node with a CollisionShape3D.
class_name GravityFlipZone
extends Area3D

## Emitted when a body enters the gravity flip zone.
## @param body The body that entered the zone.
## @param gravity_direction The new direction for gravity.
signal gravity_flipped(body, gravity_direction)

## The direction gravity will point to within this zone.
## This vector is exported so it can be set in the Godot editor,
## allowing for different gravity directions for each zone.
@export var gravity_direction: Vector3 = Vector3.DOWN

func _ready() -> void:
	# Add this zone to a group for easy finding
	add_to_group("gravity_zones")


## Called when a body enters the collision shape of this Area3D.
## It checks if the entering body is the player and, if so,
## emits the gravity_flipped signal with the new gravity direction.
## @param body The body that entered the area.
func _on_body_entered(body):
	if body.is_in_group("player"):
		gravity_flipped.emit(body, gravity_direction)


## Called when a body exits the collision shape of this Area3D.
## It checks if the exiting body is the player and, if so,
## emits the gravity_flipped signal to reset gravity to its default direction (down).
## @param body The body that exited the area.
func _on_body_exited(body):
	if body.is_in_group("player"):
		gravity_flipped.emit(body, Vector3.DOWN) 