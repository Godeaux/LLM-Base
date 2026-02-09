class_name Enemy
extends CharacterBody3D
## Basic enemy that walks toward the Trojan Horse and attacks it.
## Retargets to nearby STAY minions only if horse is out of detection range.


# --- Constants ---
const MOVE_SPEED: float = 3.0
const DETECTION_RANGE: float = 15.0
const RETARGET_INTERVAL: float = 0.5
const GRAVITY: float = 9.8


# --- Exports ---
@export var knockback_decay: float = 10.0


# --- Private variables ---
var _health_component: HealthComponent
var _attack_component: AttackComponent
var _visual: Node3D
var _current_target: Node3D = null
var _retarget_timer: float = 0.0
var _emerging: bool = false
var _knockback_velocity: Vector3 = Vector3.ZERO


# --- Built-in virtual methods ---
func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 4  # Layer 3 (bit 2 = value 4)
	collision_mask = 9  # Ground (1) + Payload (8)
	_health_component = $HealthComponent as HealthComponent
	_attack_component = $AttackComponent as AttackComponent
	_visual = $Visual
	_health_component.died.connect(_on_died)


func _physics_process(delta: float) -> void:
	if _emerging:
		velocity.x = 0.0
		velocity.z = 0.0
		if not is_on_floor():
			velocity.y -= GRAVITY * delta
		else:
			velocity.y = 0.0
		move_and_slide()
		return

	_retarget_timer -= delta
	if _retarget_timer <= 0.0:
		_retarget()
		_retarget_timer = RETARGET_INTERVAL

	if _current_target and is_instance_valid(_current_target):
		_move_toward_target()
	else:
		velocity.x = MOVE_SPEED * 0.5
		velocity.z = 0.0

	velocity.x += _knockback_velocity.x
	velocity.z += _knockback_velocity.z
	_knockback_velocity = _knockback_velocity.move_toward(Vector3.ZERO, knockback_decay * delta)

	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0.0
	move_and_slide()


# --- Public methods ---
func apply_knockback(direction: Vector3, force: float) -> void:
	var flat_dir := direction
	flat_dir.y = 0.0
	if flat_dir.length_squared() > 0.001:
		flat_dir = flat_dir.normalized()
	_knockback_velocity = flat_dir * force


func emerge() -> void:
	_emerging = true
	remove_from_group("enemies")
	collision_layer = 0
	_visual.position.y = -1.8
	var tween := create_tween()
	tween.tween_property(_visual, "position:y", 0.0, 1.5) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_callback(_on_emerge_complete)


# --- Private methods ---
func _on_emerge_complete() -> void:
	_emerging = false
	add_to_group("enemies")
	collision_layer = 4


func _retarget() -> void:
	var horse := get_tree().get_first_node_in_group("trojan_horse") as Node3D
	if horse and global_position.distance_to(horse.global_position) <= DETECTION_RANGE:
		_set_target(horse)
		return

	var best_minion: Minion = null
	var best_dist: float = DETECTION_RANGE
	for node: Node in get_tree().get_nodes_in_group("minions"):
		var minion := node as Minion
		if not minion or minion.current_mode != Minion.Mode.STAY:
			continue
		var dist := global_position.distance_to(minion.global_position)
		if dist < best_dist:
			best_dist = dist
			best_minion = minion
	if best_minion:
		_set_target(best_minion)
		return

	_clear_target()


func _set_target(target: Node3D) -> void:
	if _current_target == target:
		return
	_current_target = target
	var target_health := target.get_node_or_null("HealthComponent") as HealthComponent
	if target_health:
		_attack_component.set_target(target_health, target)
	else:
		_attack_component.clear_target()


func _clear_target() -> void:
	_current_target = null
	_attack_component.clear_target()


func _move_toward_target() -> void:
	var diff := _current_target.global_position - global_position
	diff.y = 0.0
	if _attack_component.is_target_in_range():
		velocity.x = 0.0
		velocity.z = 0.0
	else:
		var direction := diff.normalized()
		velocity.x = direction.x * MOVE_SPEED
		velocity.z = direction.z * MOVE_SPEED


func _on_died() -> void:
	EventBus.enemy_killed.emit()
	queue_free()
