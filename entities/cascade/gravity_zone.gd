class_name CascadeGravityZone
extends Area2D
## An area that overrides gravity for balls passing through it.

@export var zone_strength: float = 400.0
@export var zone_direction: Vector2 = Vector2.UP


func _ready() -> void:
	gravity_space_override = Area2D.SPACE_OVERRIDE_REPLACE
	gravity = zone_strength
	gravity_direction = zone_direction.normalized()
	collision_layer = 0
	collision_mask = 2
