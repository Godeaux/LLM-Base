extends Node2D
## Cascade game mode: marble machine with balls, pegs, and collection bins.

var _default_ball_data: BallData


func _ready() -> void:
	_default_ball_data = BallData.new()
	_default_ball_data.ball_name = "Standard"
	_default_ball_data.mass = 1.0
	_default_ball_data.bounce = 0.4
	_default_ball_data.color = Color(0.4, 0.8, 1.0)
	_default_ball_data.trail_color = Color(0.4, 0.8, 1.0, 0.4)
	_default_ball_data.score_multiplier = 1.0
	_default_ball_data.radius = 8.0

	var spawner: BallSpawner = $BallSpawner
	spawner.ball_data = _default_ball_data
	spawner.spawn_position = Vector2(640, 50)

	get_tree().paused = false
