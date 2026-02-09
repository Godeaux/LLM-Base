class_name BlockData
extends Resource
## Data definition for block types in the Tumble game mode.

@export var block_name: String = "Wood Rect"
@export var shape_type: String = "rectangle"
@export var size: Vector2 = Vector2(40, 20)
@export var mass: float = 1.0
@export var friction: float = 0.6
@export var bounce: float = 0.0
@export var linear_damp: float = 1.0
@export var angular_damp: float = 2.0
@export var color: Color = Color(0.72, 0.53, 0.3)
@export var material_name: String = "wood"
@export var break_velocity: float = 0.0
