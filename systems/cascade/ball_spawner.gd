class_name BallSpawner
extends Node
## Spawns balls from an ObjectPool at timed intervals.
## Supports multiple ball types with weighted random selection.

@export var spawn_interval: float = 1.0
@export var spawn_position: Vector2 = Vector2(640, 50)
@export var ball_data: BallData

var _timer: float = 0.0
var _ball_types: Array[BallData] = []
var _ball_weights: Array[float] = []
var _total_weight: float = 0.0

@onready var _pool: ObjectPool = $BallPool


func _ready() -> void:
	add_to_group("ball_spawner")
	EventBus.ball_stuck.connect(_on_ball_stuck)


func _process(delta: float) -> void:
	_timer += delta
	if _timer >= spawn_interval:
		_timer -= spawn_interval
		_spawn_ball()


func _spawn_ball() -> void:
	var ball: Node = _pool.acquire()
	if ball is CascadeBall:
		var cb := ball as CascadeBall
		cb.data = _pick_ball_type()
		cb.global_position = spawn_position
		cb.global_position.x += randf_range(-20.0, 20.0)
		cb.reset()


func add_ball_type(data: BallData, weight: float) -> void:
	_ball_types.append(data)
	_ball_weights.append(weight)
	_total_weight += weight


func upgrade_spawn_rate(multiplier: float) -> void:
	spawn_interval *= multiplier


func get_pool() -> ObjectPool:
	return _pool


func _pick_ball_type() -> BallData:
	if _ball_types.is_empty():
		return ball_data
	if _total_weight <= 0.0:
		return _ball_types[0]
	var roll: float = randf() * _total_weight
	var cumulative: float = 0.0
	for i: int in _ball_types.size():
		cumulative += _ball_weights[i]
		if roll <= cumulative:
			return _ball_types[i]
	return _ball_types[_ball_types.size() - 1]


func _on_ball_stuck(ball: Node) -> void:
	if ball is CascadeBall:
		_pool.release(ball)
