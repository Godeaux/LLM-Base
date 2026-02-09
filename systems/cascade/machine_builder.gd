class_name MachineBuilder
extends Node2D
## Builds and manages the marble machine layout.
## Starts with a simple Plinko grid and grows via upgrades.

const PEG_SPACING: float = 60.0
const PEG_RADIUS: float = 8.0
const ROWS: int = 10
const COLS: int = 9
const START_X: float = 280.0
const START_Y: float = 120.0
const BIN_Y: float = 680.0
const BIN_COUNT: int = 8
const BIN_WIDTH: float = 60.0


func _ready() -> void:
	_build_walls()
	_build_plinko_grid()
	_build_collection_bins()


func _build_walls() -> void:
	_add_wall(Vector2(240, 400), Vector2(10, 600))
	_add_wall(Vector2(1040, 400), Vector2(10, 600))


func _build_plinko_grid() -> void:
	for row: int in ROWS:
		var offset_x: float = PEG_SPACING * 0.5 if row % 2 == 1 else 0.0
		var col_count: int = COLS if row % 2 == 0 else COLS - 1
		for col: int in col_count:
			var x: float = START_X + col * PEG_SPACING + offset_x
			var y: float = START_Y + row * PEG_SPACING
			_add_peg(Vector2(x, y))


func _build_collection_bins() -> void:
	for i: int in BIN_COUNT:
		var x: float = START_X + i * BIN_WIDTH + BIN_WIDTH * 0.5
		var multiplier: float = 1.0
		var center_dist: int = absi(i - BIN_COUNT / 2)
		multiplier = 1.0 + center_dist * 0.5
		_add_collection_bin(Vector2(x, BIN_Y), multiplier)
		if i > 0:
			_add_wall(Vector2(START_X + i * BIN_WIDTH, BIN_Y - 15), Vector2(4, 30))


func _add_peg(pos: Vector2) -> void:
	var peg := MachineElement.new()
	peg.element_type = "peg"
	peg.position = pos
	peg.collision_layer = 1
	peg.collision_mask = 0

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = PEG_RADIUS
	shape.shape = circle
	peg.add_child(shape)

	var sprite := Sprite2D.new()
	sprite.texture = _create_circle_texture()
	sprite.scale = Vector2.ONE * (PEG_RADIUS / 16.0)
	sprite.modulate = Color(0.6, 0.6, 0.7)
	peg.add_child(sprite)

	add_child(peg)


func _add_wall(pos: Vector2, size: Vector2) -> void:
	var wall := StaticBody2D.new()
	wall.position = pos
	wall.collision_layer = 1
	wall.collision_mask = 0

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	wall.add_child(shape)

	var visual := ColorRect.new()
	visual.size = size
	visual.position = -size * 0.5
	visual.color = Color(0.3, 0.3, 0.4)
	wall.add_child(visual)

	add_child(wall)


func _add_collection_bin(pos: Vector2, multiplier: float) -> void:
	var bin := CollectionBin.new()
	bin.position = pos
	bin.score_multiplier = multiplier

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(BIN_WIDTH - 8, 20)
	shape.shape = rect
	bin.add_child(shape)

	var visual := ColorRect.new()
	visual.size = Vector2(BIN_WIDTH - 8, 20)
	visual.position = Vector2(-(BIN_WIDTH - 8) * 0.5, -10)
	var brightness: float = clampf(0.2 + multiplier * 0.15, 0.2, 0.8)
	visual.color = Color(brightness, brightness * 0.8, 0.2, 0.5)
	bin.add_child(visual)

	add_child(bin)


func _create_circle_texture() -> Texture2D:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var center := Vector2(16, 16)
	for x: int in 32:
		for y: int in 32:
			var dist := Vector2(x, y).distance_to(center)
			if dist <= 15.0:
				var alpha: float = clampf(16.0 - dist, 0.0, 1.0)
				img.set_pixel(x, y, Color(1, 1, 1, alpha))
	return ImageTexture.create_from_image(img)
