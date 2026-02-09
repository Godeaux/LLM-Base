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
const BUMPER_RADIUS: float = 16.0

const BUMPER_SLOTS: Array = [
	"370,330",
	"550,330",
	"460,420",
	"640,420",
	"370,510",
	"550,510",
]
const RAMP_SLOTS: Array = [
	"260,300,-0.3",
	"780,300,0.3",
	"260,500,-0.3",
	"780,500,0.3",
]
const TRAMPOLINE_SLOTS: Array = [
	"370,650",
	"520,650",
	"670,650",
]


func _ready() -> void:
	_build_walls()
	_build_plinko_grid()
	_build_collection_bins()


func add_bumpers(count: int) -> void:
	var placed: int = 0
	for slot: String in BUMPER_SLOTS:
		if placed >= count:
			break
		var parts: PackedStringArray = slot.split(",")
		var pos := Vector2(float(parts[0]), float(parts[1]))
		_add_bumper(pos)
		placed += 1


func add_ramps(count: int) -> void:
	var placed: int = 0
	for slot: String in RAMP_SLOTS:
		if placed >= count:
			break
		var parts: PackedStringArray = slot.split(",")
		var pos := Vector2(float(parts[0]), float(parts[1]))
		var angle: float = float(parts[2])
		_add_ramp(pos, angle)
		placed += 1


func add_trampolines(count: int) -> void:
	var placed: int = 0
	for slot: String in TRAMPOLINE_SLOTS:
		if placed >= count:
			break
		var parts: PackedStringArray = slot.split(",")
		var pos := Vector2(float(parts[0]), float(parts[1]))
		_add_trampoline(pos)
		placed += 1


func add_spinner(pos: Vector2) -> void:
	var wheel := SpinningWheel.new()
	wheel.position = pos
	wheel.collision_layer = 1
	wheel.collision_mask = 0

	for i: int in wheel.paddle_count:
		var angle: float = TAU * i / wheel.paddle_count
		var paddle_shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(60, 8)
		paddle_shape.shape = rect
		paddle_shape.position = Vector2(30, 0).rotated(angle)
		paddle_shape.rotation = angle
		wheel.add_child(paddle_shape)

		var visual := ColorRect.new()
		visual.size = Vector2(60, 8)
		visual.position = Vector2(0, -4).rotated(angle)
		visual.rotation = angle
		visual.color = Color(0.8, 0.5, 0.2)
		wheel.add_child(visual)

	var center_sprite := Sprite2D.new()
	center_sprite.texture = _create_circle_texture()
	center_sprite.scale = Vector2.ONE * 0.5
	center_sprite.modulate = Color(0.9, 0.6, 0.2)
	wheel.add_child(center_sprite)

	add_child(wheel)


func add_gravity_zone(pos: Vector2, size: Vector2, dir: Vector2) -> void:
	var zone := CascadeGravityZone.new()
	zone.position = pos
	zone.zone_direction = dir
	zone.zone_strength = 400.0

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	zone.add_child(shape)

	var visual := ColorRect.new()
	visual.size = size
	visual.position = -size * 0.5
	visual.color = Color(0.2, 0.5, 0.9, 0.15)
	zone.add_child(visual)

	add_child(zone)


func add_magnetic_field(pos: Vector2, radius: float) -> void:
	var field := MagneticField.new()
	field.position = pos
	field.strength = 200.0

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = radius
	shape.shape = circle
	field.add_child(shape)

	var sprite := Sprite2D.new()
	sprite.texture = _create_circle_texture()
	sprite.scale = Vector2.ONE * (radius / 16.0)
	sprite.modulate = Color(0.6, 0.3, 0.9, 0.3)
	field.add_child(sprite)

	add_child(field)


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
			_add_wall(
				Vector2(START_X + i * BIN_WIDTH, BIN_Y - 15),
				Vector2(4, 30),
			)


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


func _add_bumper(pos: Vector2) -> void:
	var bumper := MachineElement.new()
	bumper.element_type = "bumper"
	bumper.position = pos
	bumper.collision_layer = 1
	bumper.collision_mask = 0

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = BUMPER_RADIUS
	shape.shape = circle
	bumper.add_child(shape)

	var sprite := Sprite2D.new()
	sprite.texture = _create_circle_texture()
	sprite.scale = Vector2.ONE * (BUMPER_RADIUS / 16.0)
	sprite.modulate = Color(1.0, 0.4, 0.3)
	bumper.add_child(sprite)

	add_child(bumper)


func _add_ramp(pos: Vector2, angle: float) -> void:
	var ramp := MachineElement.new()
	ramp.element_type = "ramp"
	ramp.position = pos
	ramp.rotation = angle
	ramp.collision_layer = 1
	ramp.collision_mask = 0

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(80, 6)
	shape.shape = rect
	ramp.add_child(shape)

	var visual := ColorRect.new()
	visual.size = Vector2(80, 6)
	visual.position = Vector2(-40, -3)
	visual.color = Color(0.4, 0.7, 0.4)
	ramp.add_child(visual)

	add_child(ramp)


func _add_trampoline(pos: Vector2) -> void:
	var tramp := MachineElement.new()
	tramp.element_type = "trampoline"
	tramp.position = pos
	tramp.collision_layer = 1
	tramp.collision_mask = 0

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(50, 6)
	shape.shape = rect
	tramp.add_child(shape)

	var visual := ColorRect.new()
	visual.size = Vector2(50, 6)
	visual.position = Vector2(-25, -3)
	visual.color = Color(0.3, 0.8, 0.9)
	tramp.add_child(visual)

	add_child(tramp)


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
