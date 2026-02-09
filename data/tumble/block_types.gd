class_name BlockTypes
extends RefCounted
## Factory for creating BlockData instances for each block type.


static func wood_rect() -> BlockData:
	var d := BlockData.new()
	d.block_name = "Wood Rectangle"
	d.shape_type = "rectangle"
	d.size = Vector2(40, 20)
	d.mass = 1.0
	d.friction = 0.6
	d.bounce = 0.0
	d.linear_damp = 1.0
	d.angular_damp = 2.0
	d.color = Color(0.72, 0.53, 0.3)
	d.material_name = "wood"
	return d


static func wood_square() -> BlockData:
	var d := BlockData.new()
	d.block_name = "Wood Square"
	d.shape_type = "square"
	d.size = Vector2(25, 25)
	d.mass = 0.8
	d.friction = 0.6
	d.bounce = 0.0
	d.linear_damp = 1.0
	d.angular_damp = 2.0
	d.color = Color(0.65, 0.48, 0.28)
	d.material_name = "wood"
	return d
