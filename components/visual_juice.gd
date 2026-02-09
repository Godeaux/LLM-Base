class_name VisualJuice
extends Node
## Static utility for screen shake, hit flash, bounce, and floating text.


static func shake(camera: Camera2D, intensity: float = 5.0, duration: float = 0.3) -> void:
	var original_offset := camera.offset
	var tween := camera.create_tween()
	for i: int in 6:
		var rand_offset := Vector2(
			randf_range(-intensity, intensity), randf_range(-intensity, intensity)
		)
		tween.tween_property(camera, "offset", original_offset + rand_offset, duration / 6.0)
	tween.tween_property(camera, "offset", original_offset, duration / 6.0)


static func flash_white(sprite: CanvasItem, duration: float = 0.1) -> void:
	sprite.modulate = Color(10, 10, 10)
	var tween := sprite.create_tween()
	tween.tween_property(sprite, "modulate", Color.WHITE, duration)


static func bounce(node: Node2D, amount: float = 1.3, duration: float = 0.2) -> void:
	var tween := node.create_tween()
	(
		tween
		. tween_property(node, "scale", Vector2.ONE * amount, duration * 0.4)
		. set_ease(Tween.EASE_OUT)
		. set_trans(Tween.TRANS_BACK)
	)
	(
		tween
		. tween_property(node, "scale", Vector2.ONE, duration * 0.6)
		. set_ease(Tween.EASE_OUT)
		. set_trans(Tween.TRANS_ELASTIC)
	)


static func float_text(
	parent: Node, text: String, pos: Vector2, color: Color = Color.YELLOW, duration: float = 0.8
) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", color)
	label.position = pos
	label.z_index = 100
	parent.add_child(label)

	var tween := label.create_tween().set_parallel(true)
	tween.tween_property(label, "position:y", pos.y - 40.0, duration).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, duration).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(label.queue_free)
