class_name TowerTracker
extends Node
## Monitors the block tower: tracks height, detects collapse,
## awards currency. Core Tumble-specific system.

signal collapse_started
signal collapse_ended(max_height: float, currency: int)
signal height_changed(current: float, maximum: float)

const COLLAPSE_VELOCITY_THRESHOLD: float = 80.0
const COLLAPSE_CONFIRM_TIME: float = 0.5
const SETTLE_VELOCITY_THRESHOLD: float = 20.0
const SETTLE_CONFIRM_TIME: float = 1.0
const CURRENCY_PER_HEIGHT_UNIT: float = 10.0
const MIN_BLOCKS_FOR_COLLAPSE: int = 5

@export var floor_y: float = 650.0

var max_height_ever: float = 0.0
var current_height: float = 0.0
var is_collapsing: bool = false

var _spawner: BlockSpawner
var _pool: ObjectPool
var _camera: Camera2D
var _collapse_timer: float = 0.0
var _settle_timer: float = 0.0


func setup(
	spawner: BlockSpawner,
	pool: ObjectPool,
	camera: Camera2D,
) -> void:
	_spawner = spawner
	_pool = pool
	_camera = camera


func _physics_process(delta: float) -> void:
	if not _pool:
		return
	_update_height()
	if is_collapsing:
		_check_settle(delta)
	else:
		_check_collapse(delta)
	_recycle_fallen()


func _update_height() -> void:
	var highest_y: float = floor_y
	for node: Node in _pool.get_active_nodes():
		if node.visible and node is TumbleBlock:
			var tb := node as TumbleBlock
			if tb.global_position.y < highest_y:
				highest_y = tb.global_position.y
	current_height = maxf(floor_y - highest_y, 0.0)
	if current_height > max_height_ever:
		max_height_ever = current_height
	height_changed.emit(current_height, max_height_ever)
	if _spawner:
		_spawner.update_highest_y(highest_y)


func _check_collapse(delta: float) -> void:
	if _pool.get_active_count() < MIN_BLOCKS_FOR_COLLAPSE:
		_collapse_timer = 0.0
		return
	var avg_vel: float = _get_average_velocity()
	if avg_vel > COLLAPSE_VELOCITY_THRESHOLD:
		_collapse_timer += delta
		if _collapse_timer >= COLLAPSE_CONFIRM_TIME:
			_start_collapse()
	else:
		_collapse_timer = 0.0


func _check_settle(delta: float) -> void:
	var avg_vel: float = _get_average_velocity()
	if avg_vel < SETTLE_VELOCITY_THRESHOLD:
		_settle_timer += delta
		if _settle_timer >= SETTLE_CONFIRM_TIME:
			_end_collapse()
	else:
		_settle_timer = 0.0


func _start_collapse() -> void:
	is_collapsing = true
	_collapse_timer = 0.0
	_settle_timer = 0.0
	if _spawner:
		_spawner.set_paused(true)
	if _camera:
		VisualJuice.shake(_camera, 8.0, 0.5)
	collapse_started.emit()
	EventBus.tower_collapsed.emit(max_height_ever)


func _end_collapse() -> void:
	var currency: int = int(max_height_ever / CURRENCY_PER_HEIGHT_UNIT)
	if currency > 0:
		EventBus.currency_earned.emit(currency, "tumble")
	var prev_max: float = max_height_ever
	collapse_ended.emit(prev_max, currency)
	_pool.release_all()
	max_height_ever = 0.0
	current_height = 0.0
	_collapse_timer = 0.0
	_settle_timer = 0.0
	is_collapsing = false
	if _spawner:
		_spawner.set_paused(false)
	if _camera:
		_camera.position.y = 360.0


func _recycle_fallen() -> void:
	for node: Node in _pool.get_active_nodes():
		if node is TumbleBlock:
			var tb := node as TumbleBlock
			if tb.global_position.y > floor_y + 150.0:
				_pool.release(tb)


func _get_average_velocity() -> float:
	var total: float = 0.0
	var count: int = 0
	for node: Node in _pool.get_active_nodes():
		if node.visible and node is TumbleBlock:
			var tb := node as TumbleBlock
			total += tb.linear_velocity.length()
			count += 1
	if count == 0:
		return 0.0
	return total / count
