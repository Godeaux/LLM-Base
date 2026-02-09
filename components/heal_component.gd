class_name HealComponent
extends Node
## Reusable heal component. Heals a target at intervals.
## Parent entity owns targeting logic — this component only handles cooldown and healing.


# --- Signals ---
signal heal_started  ## Emitted when cooldown fires (animation_driven mode). Parent plays animation, then calls apply_heal().
signal heal_performed  ## Emitted after heal is actually applied.


# --- Exports ---
@export var heal_amount: float = 5.0
@export var heal_interval: float = 2.0
@export var heal_range: float = 6.0
@export var animation_driven: bool = false  ## When true, timer emits heal_started instead of healing directly.


# --- Private variables ---
var _target_health: HealthComponent = null
var _target_node: Node3D = null
var _owner_node: Node3D = null
var _timer: Timer


# --- Built-in virtual methods ---
func _ready() -> void:
	_owner_node = get_parent() as Node3D
	_timer = Timer.new()
	_timer.wait_time = heal_interval
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
	return dist <= heal_range


func apply_heal() -> void:
	## Apply heal to current target. Call this from animation Call Method tracks.
	if not _target_health or not _target_node:
		return
	if not is_instance_valid(_target_node):
		return
	_target_health.heal(heal_amount)
	heal_performed.emit()


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
	if animation_driven:
		heal_started.emit()
	else:
		apply_heal()
