class_name BallData
extends Resource
## Data definition for ball types in the Cascade game mode.

@export var ball_name: String = "Standard"
@export var mass: float = 1.0
@export var bounce: float = 0.5
@export var color: Color = Color.WHITE
@export var trail_color: Color = Color(1.0, 1.0, 1.0, 0.5)
@export var score_multiplier: float = 1.0
@export var special_behavior: String = ""
@export var radius: float = 8.0
