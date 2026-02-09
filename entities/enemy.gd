class_name Enemy
extends CharacterBody3D
## Enemy that walks toward the Trojan Horse or engages minions, depending on archetype.
## RUNNER: bee-lines for horse, briefly stunned (forced aggro) when hit by a minion.
## FIGHTER: prioritizes engaging nearby minions to death before advancing on horse.


# --- Constants ---
const RETARGET_INTERVAL: float = 0.5
const GRAVITY: float = 9.8
const FLASH_COLOR := Color(1.0, 1.0, 0.3)  ## Bright yellow damage flash
const FLASH_DURATION: float = 0.12
const PATH_RECALC_INTERVAL: float = 1.0
const WAYPOINT_REACHED_THRESHOLD: float = 1.5
const HALO_COLOR_FULL := Color(0.895, 1.0, 0.283, 1.0)
const HALO_COLOR_DEAD := Color(0.373, 0.0, 0.004, 1.0)
const KILL_FLOOR_Y: float = -5.0

# --- Exports ---
@export var knockback_decay: float = 5.0


# --- Private variables ---
var _health_component: HealthComponent
var _attack_component: AttackComponent
var _visual: Node3D
var _body_material: StandardMaterial3D
var _halo_material: StandardMaterial3D
var _base_color: Color
var _current_target: Node3D = null
var _retarget_timer: float = 0.0
var _emerging: bool = false
var _knockback_velocity: Vector3 = Vector3.ZERO
var _knockback_multiplier: float = 1.0
var _map_manager: MapManager = null
var _waypoints: PackedVector3Array = PackedVector3Array()
var _waypoint_index: int = 0
var _path_recalc_timer: float = 0.0

# Type data (populated by initialize(); defaults match original behavior).
var _type_data: EnemyTypeData = null
var _move_speed: float = 3.0
var _detection_range: float = 15.0
var _archetype: String = "RUNNER"

# Stun state (RUNNER only).
var _stunned: bool = false
var _stun_timer: float = 0.0
var _stun_duration: float = 1.5
var _stun_attacker: Node3D = null


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
	var halo_mesh := $Visual/Halo as MeshInstance3D
	if halo_mesh:
		_halo_material = halo_mesh.mesh.surface_get_material(0).duplicate() as StandardMaterial3D
		halo_mesh.set_surface_override_material(0, _halo_material)
	_health_component.died.connect(_on_died)
	_health_component.health_changed.connect(_on_health_changed)
	_health_component.damaged_by.connect(_on_damaged_by)


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

	# Tick stun timer (RUNNER only).
	if _stunned:
		_stun_timer -= delta
		if _stun_timer <= 0.0:
			_stunned = false
			_stun_attacker = null
			_retarget_timer = 0.0  # Force immediate retarget back to normal priorities.

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

	if global_position.y < KILL_FLOOR_Y:
		_on_died()
		return


# --- Public methods ---
func initialize(data: EnemyTypeData) -> void:
	## Apply type data. Must be called after _ready() (i.e. after add_child).
	_type_data = data
	_move_speed = data.move_speed
	_detection_range = data.detection_range
	_archetype = data.archetype
	_stun_duration = data.stun_duration

	# Stats → components.
	_health_component.max_health = data.max_health
	_health_component._current_health = data.max_health
	_attack_component.damage = data.attack_damage
	_attack_component.attack_interval = data.attack_interval
	_attack_component.attack_range = data.attack_range
	knockback_decay = data.knockback_decay
	_knockback_multiplier = data.knockback_multiplier

	# Visuals.
	_base_color = data.body_color
	if _body_material:
		_body_material.albedo_color = data.body_color
	if _halo_material:
		_halo_material.albedo_color = data.halo_color_full
		_halo_material.emission = data.halo_color_full
	if _visual:
		_visual.scale = data.body_scale


func apply_knockback(direction: Vector3, force: float) -> void:
	var flat_dir := direction
	flat_dir.y = 0.0
	if flat_dir.length_squared() > 0.001:
		flat_dir = flat_dir.normalized()
	_knockback_velocity = flat_dir * force * _knockback_multiplier


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


func get_archetype() -> String:
	return _archetype


# --- Private methods ---
func _on_emerge_complete() -> void:
	_emerging = false
	add_to_group("enemies")
	collision_layer = 4


func _retarget() -> void:
	# If RUNNER is stunned and attacker is still alive, stay locked on.
	if _stunned and _stun_attacker and is_instance_valid(_stun_attacker):
		return

	match _archetype:
		"RUNNER":
			_retarget_runner()
		"FIGHTER":
			_retarget_fighter()
		_:
			_retarget_runner()


func _retarget_runner() -> void:
	## RUNNER: Prioritize horse, fall back to nearby STAY minions.
	var horse := get_tree().get_first_node_in_group("trojan_horse") as Node3D
	if horse and global_position.distance_to(horse.global_position) <= _detection_range:
		_set_target(horse)
		return

	var best_minion: Node3D = null
	var best_dist: float = _detection_range
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


func _retarget_fighter() -> void:
	## FIGHTER: Prioritize nearest minion (any mode), fight to death. Fall back to horse.
	# Already fighting a minion — stick with it until it dies.
	if _current_target and is_instance_valid(_current_target) and _current_target.is_in_group("minions"):
		return

	var best_minion: Node3D = null
	var best_dist: float = _detection_range
	for node: Node in get_tree().get_nodes_in_group("minions"):
		var minion := node as Node3D
		if not minion or not is_instance_valid(minion):
			continue
		var dist := global_position.distance_to(minion.global_position)
		if dist < best_dist:
			best_dist = dist
			best_minion = minion
	if best_minion:
		_set_target(best_minion)
		return

	# No minions in range — target horse.
	var horse := get_tree().get_first_node_in_group("trojan_horse") as Node3D
	if horse:
		_set_target(horse)
		return
	_clear_target()


func _on_damaged_by(_amount: float, attacker: Node3D) -> void:
	## Called when this enemy takes damage. Runners get stunned by minion hits.
	if _archetype != "RUNNER":
		return
	if not attacker or not is_instance_valid(attacker):
		return
	if not attacker.is_in_group("minions"):
		return
	_stunned = true
	_stun_timer = _stun_duration
	_stun_attacker = attacker
	# Force retarget to the minion that hit us.
	_set_target(attacker)


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

	_follow_waypoints_to(_current_target.global_position, _move_speed)


func _drift_toward_horse() -> void:
	var horse := get_tree().get_first_node_in_group("trojan_horse") as Node3D
	if not horse:
		velocity.x = 0.0
		velocity.z = 0.0
		return

	_follow_waypoints_to(horse.global_position, _move_speed * 0.5)


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
	_update_halo()
	_flash_damage()


func _update_halo() -> void:
	if not _halo_material or not _health_component:
		return
	var pct: float = _health_component.get_health_percent()
	var full_color: Color = HALO_COLOR_FULL
	var dead_color: Color = HALO_COLOR_DEAD
	if _type_data:
		full_color = _type_data.halo_color_full
		dead_color = _type_data.halo_color_dead
	var color: Color = full_color.lerp(dead_color, 1.0 - pct)
	_halo_material.albedo_color = color
	_halo_material.emission = color


func _flash_damage() -> void:
	if not _body_material:
		return
	_body_material.albedo_color = FLASH_COLOR
	var tween := create_tween()
	tween.tween_property(_body_material, "albedo_color", _base_color, FLASH_DURATION)


func _on_died() -> void:
	EventBus.enemy_killed.emit()
	queue_free()
