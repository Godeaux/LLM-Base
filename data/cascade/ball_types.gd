class_name BallTypes
extends RefCounted
## Factory for creating BallData instances for each ball type.


static func standard() -> BallData:
	var d := BallData.new()
	d.ball_name = "Standard"
	d.mass = 1.0
	d.bounce = 0.4
	d.color = Color(0.4, 0.8, 1.0)
	d.trail_color = Color(0.4, 0.8, 1.0, 0.4)
	d.score_multiplier = 1.0
	d.radius = 8.0
	return d


static func heavy() -> BallData:
	var d := BallData.new()
	d.ball_name = "Heavy"
	d.mass = 3.0
	d.bounce = 0.2
	d.color = Color(0.5, 0.5, 0.6)
	d.trail_color = Color(0.5, 0.5, 0.6, 0.4)
	d.score_multiplier = 2.0
	d.radius = 12.0
	return d


static func bouncy() -> BallData:
	var d := BallData.new()
	d.ball_name = "Bouncy"
	d.mass = 0.5
	d.bounce = 0.85
	d.color = Color(0.3, 0.9, 0.3)
	d.trail_color = Color(0.3, 0.9, 0.3, 0.4)
	d.score_multiplier = 0.8
	d.radius = 7.0
	return d


static func golden() -> BallData:
	var d := BallData.new()
	d.ball_name = "Golden"
	d.mass = 1.0
	d.bounce = 0.5
	d.color = Color(1.0, 0.85, 0.2)
	d.trail_color = Color(1.0, 0.85, 0.2, 0.5)
	d.score_multiplier = 3.0
	d.radius = 8.0
	return d


static func explosive() -> BallData:
	var d := BallData.new()
	d.ball_name = "Explosive"
	d.mass = 1.5
	d.bounce = 0.3
	d.color = Color(1.0, 0.3, 0.2)
	d.trail_color = Color(1.0, 0.3, 0.2, 0.5)
	d.score_multiplier = 1.5
	d.special_behavior = "explosive"
	d.radius = 9.0
	return d


static func magnetic() -> BallData:
	var d := BallData.new()
	d.ball_name = "Magnetic"
	d.mass = 1.0
	d.bounce = 0.5
	d.color = Color(0.6, 0.3, 0.9)
	d.trail_color = Color(0.6, 0.3, 0.9, 0.5)
	d.score_multiplier = 1.2
	d.special_behavior = "magnetic"
	d.radius = 8.0
	return d
