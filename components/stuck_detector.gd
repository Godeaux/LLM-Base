class_name StuckDetector
extends Node
## Monitors a RigidBody2D parent's velocity.
## Emits 'stuck' if velocity stays below threshold for too long.

signal stuck

@export var velocity_threshold: float = 5.0
@export var stuck_time: float = 3.0

var _stuck_timer: float = 0.0
var _body: RigidBody2D


func _ready() -> void:
	_body = get_parent() as RigidBody2D


func _physics_process(delta: float) -> void:
	if not _body:
		return

	if _body.linear_velocity.length() < velocity_threshold:
		_stuck_timer += delta
		if _stuck_timer >= stuck_time:
			_stuck_timer = 0.0
			stuck.emit()
	else:
		_stuck_timer = 0.0


func reset() -> void:
	_stuck_timer = 0.0
