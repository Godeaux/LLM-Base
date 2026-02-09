class_name Enemy
extends CharacterBody3D
## Basic enemy that walks toward the Trojan Horse and attacks it.
## Uses tile-grid A* pathfinding to follow the map layout.
## Retargets to nearby STAY minions only if horse is out of detection range.


# --- Constants ---
const MOVE_SPEED: float = 3.0
const DETECTION_RANGE: float = 15.0
const RETARGET_INTERVAL: float = 0.5
const GRAVITY: float = 9.8
const FLASH_COLOR := Color(1.0, 1.0, 0.3)  ## Bright yellow damage flash
const FLASH_DURATION: float = 0.12
const PATH_RECALC_INTERVAL: float = 1.0
const WAYPOINT_REACHED_THRESHOLD: float = 1.5


# --- Exports ---
@export var knockback_decay: float = 5.0


# --- Private variables ---
var _health_component: HealthComponent
var _attack_component: AttackComponent
var _visual: Node3D
var _body_material: StandardMaterial3D
var _base_color: Color
var _current_target: Node3D = null
var _retarget_timer: float = 0.0
var _emerging: bool = false
var _knockback_velocity: Vector3 = Vector3.ZERO
var _map_manager: MapManager = null
var _waypoints: PackedVector3Array = PackedVector3Array()
var _waypoint_index: int = 0
var _path_recalc_timer: float = 0.0


# --- Built-in virtual methods ---
func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 4  # Layer 3 (bit 2 = value 4)
	collision_mask = 11  # Ground (1) + Minions (2) + Payload (8)
	_health_component = $HealthComponent as HealthComponent
	_attack_component = $AttackComponent as AttackComponent
	_visual = $Visual
	var body_mesh := $Visual/Body as MeshInstance3D
	if body_mesh:
		_body_material = body_mesh.mesh.surface_get_material(0).duplicate() as StandardMaterial3D
		body_mesh.set_surface_override_material(0, _body_material)
		_base_color = _body_material.albedo_color
	_health_component.died.connect(_on_died)
	_health_component.health_changed.connect(_on_health_changed)


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
	_path_recalc_timer -= delta
	if _retarget_timer <= 0.0:
		_retarget()
		_retarget_timer = RETARGET_INTERVAL

	if _current_target and is_instance_valid(_current_target):
		_move_toward_target()
	else:
		_drift_toward_horse()

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


func set_map_manager(manager: MapManager) -> void:
	_map_manager = manager


func get_current_waypoints() -> PackedVector3Array:
	## Returns current waypoints for debug visualization.
	return _waypoints


func get_waypoint_index() -> int:
	return _waypoint_index


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
	_waypoints = PackedVector3Array()
	_waypoint_index = 0
	_path_recalc_timer = 0.0
	var target_health := target.get_node_or_null("HealthComponent") as HealthComponent
	if target_health:
		_attack_component.set_target(target_health, target)
	else:
		_attack_component.clear_target()


func _clear_target() -> void:
	_current_target = null
	_waypoints = PackedVector3Array()
	_waypoint_index = 0
	_attack_component.clear_target()


func _move_toward_target() -> void:
	if _attack_component.is_target_in_range():
		velocity.x = 0.0
		velocity.z = 0.0
		return

	_follow_waypoints_to(_current_target.global_position, MOVE_SPEED)


func _drift_toward_horse() -> void:
	var horse := get_tree().get_first_node_in_group("trojan_horse") as Node3D
	if not horse:
		velocity.x = 0.0
		velocity.z = 0.0
		return

	_follow_waypoints_to(horse.global_position, MOVE_SPEED * 0.5)


func _follow_waypoints_to(target_pos: Vector3, speed: float) -> void:
	## Core movement: follows A* waypoints toward target_pos, falls back to direct if needed.
	if not _map_manager:
		_move_direct(target_pos, speed)
		return

	# Recalculate path when timer expires or waypoints consumed.
	if _waypoints.is_empty() or _path_recalc_timer <= 0.0:
		_recalculate_path(target_pos)
		_path_recalc_timer = PATH_RECALC_INTERVAL

	# Follow waypoints if we have them.
	if _waypoint_index < _waypoints.size():
		var wp: Vector3 = _waypoints[_waypoint_index]
		var wp_diff: Vector3 = wp - global_position
		wp_diff.y = 0.0
		if wp_diff.length() < WAYPOINT_REACHED_THRESHOLD:
			_waypoint_index += 1
			if _waypoint_index >= _waypoints.size():
				_move_direct(target_pos, speed)
				return
			wp = _waypoints[_waypoint_index]
			wp_diff = wp - global_position
			wp_diff.y = 0.0
		var direction: Vector3 = wp_diff.normalized()
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		# No waypoints (same tile or path failed) — go direct.
		_move_direct(target_pos, speed)


func _move_direct(target_pos: Vector3, speed: float) -> void:
	var diff: Vector3 = target_pos - global_position
	diff.y = 0.0
	if diff.length_squared() > 0.01:
		var direction: Vector3 = diff.normalized()
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = 0.0
		velocity.z = 0.0


func _recalculate_path(target_pos: Vector3) -> void:
	_waypoints = _map_manager.find_path_waypoints(global_position, target_pos)
	_waypoint_index = 0


func _on_health_changed(_current: float, _maximum: float) -> void:
	_flash_damage()


func _flash_damage() -> void:
	if not _body_material:
		return
	_body_material.albedo_color = FLASH_COLOR
	var tween := create_tween()
	tween.tween_property(_body_material, "albedo_color", _base_color, FLASH_DURATION)


func _on_died() -> void:
	EventBus.enemy_killed.emit()
	queue_free()
