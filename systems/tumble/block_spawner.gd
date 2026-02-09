class_name BlockSpawner
extends Node
## Spawns blocks from an ObjectPool at timed intervals.
## Positions blocks above the current tower peak.

@export var spawn_interval: float = 2.5
@export var platform_center_x: float = 640.0
@export var platform_width: float = 300.0
@export var floor_y: float = 650.0
@export var spawn_height_offset: float = 100.0

var _timer: float = 0.0
var _paused: bool = false
var _highest_block_y: float = 650.0
var _block_types: Array[BlockData] = []
var _block_weights: Array[float] = []
var _total_weight: float = 0.0

@onready var _pool: ObjectPool = $BlockPool


func _ready() -> void:
	add_to_group("block_spawner")


func _process(delta: float) -> void:
	if _paused:
		return
	_timer += delta
	if _timer >= spawn_interval:
		_timer -= spawn_interval
		_spawn_block()


func set_paused(paused: bool) -> void:
	_paused = paused
	_timer = 0.0


func update_highest_y(y: float) -> void:
	_highest_block_y = y


func get_pool() -> ObjectPool:
	return _pool


func add_block_type(bdata: BlockData, weight: float) -> void:
	_block_types.append(bdata)
	_block_weights.append(weight)
	_total_weight += weight


func upgrade_spawn_rate(multiplier: float) -> void:
	spawn_interval *= multiplier


func _spawn_block() -> void:
	var block: Node = _pool.acquire()
	if block is TumbleBlock:
		var tb := block as TumbleBlock
		tb.data = _pick_block_type()
		var half_w: float = platform_width * 0.4
		var x: float = platform_center_x + randf_range(-half_w, half_w)
		var y: float = _highest_block_y - spawn_height_offset
		y = minf(y, floor_y - 200.0)
		tb.global_position = Vector2(x, y)
		tb.reset()
		tb.rotation = randf_range(-0.15, 0.15)
		tb.activate()


func _pick_block_type() -> BlockData:
	if _block_types.is_empty():
		return BlockTypes.wood_rect()
	if _total_weight <= 0.0:
		return _block_types[0]
	var roll: float = randf() * _total_weight
	var cumulative: float = 0.0
	for i: int in _block_types.size():
		cumulative += _block_weights[i]
		if roll <= cumulative:
			return _block_types[i]
	return _block_types[_block_types.size() - 1]
