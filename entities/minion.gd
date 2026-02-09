class_name Minion
extends CharacterBody3D
## Pikmin-style minion with guard-post STAY mode and combat-capable FOLLOW mode.
## Reads stats from MinionTypeData resource. STAY minions chase enemies within
## a leash radius and return home afterward. FOLLOW minions escort the Trojan Horse
## and chase enemies within their aggro radius.


# --- Signals ---
signal mode_changed(new_mode: Mode)


# --- Enums ---
enum Mode { FOLLOW, STAY }


# --- Constants ---
const ARRIVE_DISTANCE: float = 2.0
const DEAD_ZONE: float = 0.05
const GRAVITY: float = 9.8
const DRAG_LIFT_HEIGHT: float = 1.5
const COLOR_DRAGGED := Color(1.0, 1.0, 0.4)
const RETARGET_INTERVAL: float = 0.3
const ROTATION_SPEED: float = 10.0
const SEPARATION_RADIUS: float = 1.5
const SEPARATION_WEIGHT: float = 2.5
const SHIELD_AWARENESS: float = 12.0


# --- Exports ---
@export var type_data: MinionTypeData


# --- Public variables ---
var current_mode: Mode = Mode.FOLLOW


# --- Private variables ---
var _follow_angle: float = 0.0
var _follow_radius: float = 2.5
var _home_position: Vector3 = Vector3.ZERO
var _is_being_dragged: bool = false
var _visual_material: StandardMaterial3D
var _combat_target: Node3D = null
var _leash_triggered: bool = false
var _retarget_timer: float = 0.0
var _health_component: HealthComponent
var _attack_component: AttackComponent
var _move_speed: float = 4.0
var _leash_radius: float = 15.0
var _aggro_radius: float = 8.0


# --- Onready variables ---
@onready var _sphere: MeshInstance3D = $Visual/Sphere
@onready var _anim_player: AnimationPlayer = $AnimationPlayer


# --- Built-in virtual methods ---
func _ready() -> void:
	add_to_group("minions")
	collision_layer = 2
	collision_mask = 15  # Ground (1) + Minions (2) + Enemies (4) + Payload (8)
	_visual_material = _sphere.mesh.surface_get_material(0).duplicate() as StandardMaterial3D
	_sphere.set_surface_override_material(0, _visual_material)
	_health_component = get_node_or_null("HealthComponent") as HealthComponent
	_attack_component = get_node_or_null("AttackComponent") as AttackComponent
	if _health_component:
		_health_component.died.connect(_on_died)
	if _attack_component:
		_attack_component.attack_started.connect(_on_attack_started)
		_attack_component.attack_performed.connect(_on_attack_performed)
	_apply_type_data()
	_update_visual()


func _physics_process(delta: float) -> void:
	if _is_being_dragged:
		velocity = Vector3.ZERO
		return

	_retarget_timer -= delta
	if _retarget_timer <= 0.0:
		_scan_for_target()
		_retarget_timer = RETARGET_INTERVAL

	match current_mode:
		Mode.FOLLOW:
			_process_follow()
		Mode.STAY:
			_process_stay()

	_rotate_toward_target(delta)

	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0.0
	move_and_slide()


# --- Public methods ---
func set_mode(new_mode: Mode) -> void:
	if current_mode == new_mode:
		return
	current_mode = new_mode
	if new_mode == Mode.STAY:
		_home_position = global_position
	_leash_triggered = false
	_clear_combat_target()
	_update_visual()
	mode_changed.emit(new_mode)
	EventBus.minion_mode_changed.emit(Mode.keys()[new_mode])


func set_stay_position(pos: Vector3) -> void:
	_home_position = pos
	global_position = pos
	set_mode(Mode.STAY)


func start_drag() -> void:
	_is_being_dragged = true
	_clear_combat_target()
	_update_visual()


func end_drag() -> void:
	_is_being_dragged = false
	_update_visual()


func move_to_drag_position(ground_pos: Vector3) -> void:
	global_position = ground_pos + Vector3(0.0, DRAG_LIFT_HEIGHT, 0.0)


func apply_type_stats(data: MinionTypeData) -> void:
	type_data = data
	_apply_type_data()


func get_follow_angle() -> float:
	return _follow_angle


func set_escort_position(angle: float, radius: float) -> void:
	_follow_angle = angle
	_follow_radius = radius


# --- Private methods ---
func _apply_type_data() -> void:
	if not type_data:
		return
	_move_speed = type_data.move_speed
	_leash_radius = type_data.leash_radius
	_aggro_radius = type_data.aggro_radius
	if _health_component:
		_health_component.max_health = type_data.max_health
		_health_component._current_health = type_data.max_health
	if _attack_component:
		_attack_component.damage = type_data.attack_damage
		_attack_component.attack_interval = type_data.attack_interval
		_attack_component.attack_range = type_data.attack_range


func _scan_for_target() -> void:
	if not _attack_component:
		return
	var enemies := get_tree().get_nodes_in_group("enemies")
	var scan_range: float
	if current_mode == Mode.STAY:
		scan_range = _leash_radius
	else:
		scan_range = _aggro_radius

	var scan_origin: Vector3
	if current_mode == Mode.STAY:
		scan_origin = _home_position
	else:
		scan_origin = global_position

	var best_enemy: Node3D = null
	var best_dist: float = scan_range
	for node: Node in enemies:
		var enemy := node as Node3D
		if not enemy or not is_instance_valid(enemy):
			continue
		var dist := scan_origin.distance_to(enemy.global_position)
		if dist < best_dist:
			best_dist = dist
			best_enemy = enemy

	if best_enemy:
		_set_combat_target(best_enemy)
	elif _combat_target and not is_instance_valid(_combat_target):
		_clear_combat_target()


func _set_combat_target(target: Node3D) -> void:
	if _combat_target == target:
		return
	_combat_target = target
	var target_health := target.get_node_or_null("HealthComponent") as HealthComponent
	if target_health and _attack_component:
		_attack_component.set_target(target_health, target)
	else:
		_clear_combat_target()


func _find_nearest_enemy_to(origin: Vector3, max_dist: float) -> Node3D:
	var best: Node3D = null
	var best_dist := max_dist
	for node: Node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Node3D
		if not enemy or not is_instance_valid(enemy):
			continue
		var dist := origin.distance_to(enemy.global_position)
		if dist < best_dist:
			best_dist = dist
			best = enemy
	return best


func _clear_combat_target() -> void:
	_combat_target = null
	_leash_triggered = false
	if _attack_component:
		_attack_component.clear_target()


func _process_follow() -> void:
	# Chase combat target if we have one
	if _combat_target and is_instance_valid(_combat_target):
		_pursue_combat_target()
		return

	# Otherwise escort the Trojan Horse in formation
	var horse := get_tree().get_first_node_in_group("trojan_horse") as Node3D
	if not horse:
		velocity.x = 0.0
		velocity.z = 0.0
		return

	# Normal formation position
	var angle := horse.rotation.y + _follow_angle
	var formation_pos := horse.global_position + Vector3(
		cos(angle) * _follow_radius, 0.0, sin(angle) * _follow_radius)

	# Bias toward nearest threat to shield the horse
	var target_pos := formation_pos
	var nearest := _find_nearest_enemy_to(horse.global_position, SHIELD_AWARENESS)
	if nearest:
		var dir_to_enemy := nearest.global_position - horse.global_position
		dir_to_enemy.y = 0.0
		var enemy_dist := dir_to_enemy.length()
		if enemy_dist > 0.1:
			dir_to_enemy /= enemy_dist
			var intercept_pos := horse.global_position + dir_to_enemy * _follow_radius
			var blend := 1.0 - enemy_dist / SHIELD_AWARENESS
			target_pos = formation_pos.lerp(intercept_pos, blend)

	_move_toward(target_pos)


func _process_stay() -> void:
	if _leash_triggered:
		_move_toward(_home_position)
		return

	if _combat_target and is_instance_valid(_combat_target):
		var dist_from_home := _home_position.distance_to(global_position)
		if dist_from_home > _leash_radius:
			_leash_triggered = true
			_move_toward(_home_position)
			return
		_pursue_combat_target()
	else:
		var dist_to_home := global_position.distance_to(_home_position)
		if dist_to_home > DEAD_ZONE:
			_move_toward(_home_position)
		else:
			velocity.x = 0.0
			velocity.z = 0.0


func _rotate_toward_target(delta: float) -> void:
	if not _combat_target or not is_instance_valid(_combat_target):
		return
	var dir := _combat_target.global_position - global_position
	dir.y = 0.0
	if dir.length_squared() < 0.01:
		return
	var target_angle := atan2(-dir.z, dir.x)  # Model faces +X at rest
	rotation.y = lerp_angle(rotation.y, target_angle, ROTATION_SPEED * delta)


func _pursue_combat_target() -> void:
	var separation := _get_separation_force()
	if not _attack_component.is_target_in_range():
		var diff := _combat_target.global_position - global_position
		diff.y = 0.0
		var distance := diff.length()
		if distance > DEAD_ZONE:
			var approach_dir := diff.normalized()
			var speed := _move_speed
			if distance < ARRIVE_DISTANCE:
				speed *= distance / ARRIVE_DISTANCE
			var desired := approach_dir * speed + separation * SEPARATION_WEIGHT
			velocity.x = desired.x
			velocity.z = desired.z
		else:
			velocity.x = 0.0
			velocity.z = 0.0
	else:
		# In attack range — gently spread out from nearby allies
		if separation.length_squared() > 0.01:
			var sep_dir := separation.normalized()
			velocity.x = sep_dir.x * _move_speed * 0.4
			velocity.z = sep_dir.z * _move_speed * 0.4
		else:
			velocity.x = 0.0
			velocity.z = 0.0


func _get_separation_force() -> Vector3:
	var force := Vector3.ZERO
	for node: Node in get_tree().get_nodes_in_group("minions"):
		var other := node as Minion
		if other == self or not is_instance_valid(other):
			continue
		var diff := global_position - other.global_position
		diff.y = 0.0
		var dist := diff.length()
		if dist < SEPARATION_RADIUS and dist > 0.01:
			force += diff.normalized() * (1.0 - dist / SEPARATION_RADIUS)
	return force


func _move_toward(target_pos: Vector3) -> void:
	var diff := target_pos - global_position
	diff.y = 0.0
	var distance := diff.length()
	if distance < DEAD_ZONE:
		velocity.x = 0.0
		velocity.z = 0.0
		return
	var direction := diff.normalized()
	var speed := _move_speed
	if distance < ARRIVE_DISTANCE:
		speed *= distance / ARRIVE_DISTANCE
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed


func _on_attack_started() -> void:
	## Animation-driven mode: cooldown fired, play the swing. Damage happens when
	## the animation calls deal_damage() via a Call Method track keyframe.
	_play_sword_swing()


func _on_attack_performed() -> void:
	## Fires after damage is actually applied (from deal_damage).
	if _leash_triggered:
		_clear_combat_target()


func deal_damage() -> void:
	## Called by the sword_swing animation's Call Method track at the hit keyframe.
	if _attack_component:
		_attack_component.deal_damage()
	_apply_knockback_to_target()


func _on_died() -> void:
	queue_free()


func _play_sword_swing() -> void:
	if not _anim_player:
		return
	_anim_player.stop()
	_anim_player.play("sword_swing")


func _apply_knockback_to_target() -> void:
	if not _combat_target or not is_instance_valid(_combat_target):
		return
	if _combat_target.has_method("apply_knockback"):
		var direction := _combat_target.global_position - global_position
		var force: float = 3.0
		if type_data:
			force = type_data.knockback_force
		_combat_target.apply_knockback(direction, force)


func _update_visual() -> void:
	if not _visual_material:
		return
	if _is_being_dragged:
		_visual_material.albedo_color = COLOR_DRAGGED
		return
	if type_data:
		match current_mode:
			Mode.FOLLOW:
				_visual_material.albedo_color = type_data.color
			Mode.STAY:
				_visual_material.albedo_color = type_data.color.darkened(0.3)
	else:
		match current_mode:
			Mode.FOLLOW:
				_visual_material.albedo_color = Color(0.3, 0.5, 1.0)
			Mode.STAY:
				_visual_material.albedo_color = Color(1.0, 0.3, 0.3)
