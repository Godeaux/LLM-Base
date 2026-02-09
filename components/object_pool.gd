class_name ObjectPool
extends Node
## Generic object pool for frequently spawned/destroyed objects.
## Reduces allocation overhead by reusing inactive instances.

@export var scene: PackedScene
@export var initial_size: int = 10

var _pool: Array[Node] = []
var _active: Array[Node] = []


func _ready() -> void:
	for i: int in initial_size:
		var obj := scene.instantiate()
		obj.set_process(false)
		obj.set_physics_process(false)
		obj.visible = false
		add_child(obj)
		_pool.append(obj)


func acquire() -> Node:
	var obj: Node
	if _pool.is_empty():
		obj = scene.instantiate()
		add_child(obj)
	else:
		obj = _pool.pop_back()

	obj.set_process(true)
	obj.set_physics_process(true)
	obj.visible = true
	_active.append(obj)

	if obj.has_method("reset"):
		obj.reset()
	return obj


func release(obj: Node) -> void:
	if obj in _active:
		_active.erase(obj)
		obj.set_process(false)
		obj.set_physics_process(false)
		obj.visible = false
		_pool.append(obj)


func get_active_count() -> int:
	return _active.size()


func get_active_nodes() -> Array[Node]:
	return _active.duplicate()


func release_all() -> void:
	for obj: Node in _active.duplicate():
		release(obj)
