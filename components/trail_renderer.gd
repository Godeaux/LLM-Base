class_name TrailRenderer
extends Line2D
## Line2D-based trail that follows its parent node.
## Configurable length, width, and color gradient.

@export var max_points: int = 20
@export var trail_width: float = 4.0
@export var fade_trail: bool = true

var _parent_node: Node2D


func _ready() -> void:
	_parent_node = get_parent() as Node2D
	top_level = true
	width = trail_width
	if fade_trail and gradient == null:
		var grad := Gradient.new()
		grad.set_color(0, Color.WHITE)
		grad.set_color(1, Color(1.0, 1.0, 1.0, 0.0))
		gradient = grad


func _process(_delta: float) -> void:
	if not _parent_node or not _parent_node.visible:
		clear_points()
		return

	add_point(_parent_node.global_position)

	while get_point_count() > max_points:
		remove_point(0)


func reset() -> void:
	clear_points()
