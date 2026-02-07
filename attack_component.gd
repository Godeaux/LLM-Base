class_name AttackComponent
extends Node
## Reusable attack component. Deals damage to a target at intervals.
## Parent entity owns targeting logic — this component only handles cooldown and damage.


# --- Signals ---
signal attack_performed


# --- Exports ---
@export var damage: float = 10.0
@export var attack_interval: float = 1.5
@export var attack_range: float = 2.0


# --- Private variables ---
var _target_health: HealthComponent = null
var _target_node: Node3D = null
var _owner_node: Node3D = null
var _timer: Timer


# --- Built-in virtual methods ---
func _ready() -> void:
	_owner_node = get_parent() as Node3D
	_timer = Timer.new()
	_timer.wait_time = attack_interval
	_timer.one_shot = false
	_timer.timeout.connect(_on_timer_timeout)
	add_child(_timer)


# --- Public methods ---
func set_target(health: HealthComponent, target_node: Node3D) -> void:
	_target_health = health
	_target_node = target_node
	if _timer.is_stopped():
		_timer.start()


func clear_target() -> void:
	_target_health = null
	_target_node = null
	_timer.stop()


func has_target() -> bool:
	return _target_health != null and _target_node != null


func is_target_in_range() -> bool:
	if not _target_node or not _owner_node:
		return false
	var dist := _owner_node.global_position.distance_to(_target_node.global_position)
	return dist <= attack_range


# --- Private methods ---
func _on_timer_timeout() -> void:
	if not _target_health or not _target_node or not _owner_node:
		clear_target()
		return
	if not is_instance_valid(_target_node):
		clear_target()
		return
	if not is_target_in_range():
		return
	_target_health.take_damage(damage)
	attack_performed.emit()
