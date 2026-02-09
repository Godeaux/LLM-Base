class_name BallSpawner
extends Node
## Spawns balls from an ObjectPool at timed intervals.

@export var spawn_interval: float = 1.0
@export var spawn_position: Vector2 = Vector2(640, 50)
@export var ball_data: BallData

var _timer: float = 0.0

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
		cb.data = ball_data
		cb.global_position = spawn_position
		cb.global_position.x += randf_range(-20.0, 20.0)
		cb.reset()


func get_pool() -> ObjectPool:
	return _pool


func _on_ball_stuck(ball: Node) -> void:
	if ball is CascadeBall:
		_pool.release(ball)
