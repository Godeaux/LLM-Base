extends Node2D
## Tumble game mode: blocks stack into a tower, collapse, earn currency.

const FLOOR_Y: float = 650.0
const PLATFORM_CENTER_X: float = 640.0
const PLATFORM_WIDTH: float = 300.0
const CAMERA_DEFAULT_Y: float = 360.0
const CAMERA_LERP_SPEED: float = 2.0
const CAMERA_LEAD_PIXELS: float = 200.0

@onready var _camera: Camera2D = $Camera2D
@onready var _spawner: BlockSpawner = $BlockSpawner
@onready var _tracker: TowerTracker = $TowerTracker
@onready var _hud: TumbleHud = $TumbleHud


func _ready() -> void:
	_spawner.add_block_type(BlockTypes.wood_rect(), 1.0)
	_spawner.add_block_type(BlockTypes.wood_square(), 0.5)
	_spawner.platform_center_x = PLATFORM_CENTER_X
	_spawner.platform_width = PLATFORM_WIDTH
	_spawner.floor_y = FLOOR_Y

	var pool: ObjectPool = _spawner.get_pool()
	_tracker.floor_y = FLOOR_Y
	_tracker.setup(_spawner, pool, _camera)
	_hud.setup(_tracker)

	get_tree().paused = false


func _process(delta: float) -> void:
	_update_camera(delta)


func _update_camera(delta: float) -> void:
	if _tracker.is_collapsing:
		return
	var target_y: float = CAMERA_DEFAULT_Y
	if _tracker.current_height > 200.0:
		var tower_top_y: float = FLOOR_Y - _tracker.current_height
		target_y = tower_top_y - CAMERA_LEAD_PIXELS
		target_y = minf(target_y, CAMERA_DEFAULT_Y)
	_camera.position.y = lerpf(_camera.position.y, target_y, delta * CAMERA_LERP_SPEED)
