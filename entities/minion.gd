class_name Minion
extends CharacterBody3D
## Pikmin-style minion with guard-post STAY mode and combat-capable FOLLOW mode.
## Reads stats from MinionTypeData resource. STAY minions chase enemies within
## a leash radius and return home afterward. FOLLOW minions attack nearby enemies
## while continuing to trail the wizard.


# --- Signals ---
signal mode_changed(new_mode: Mode)


# --- Enums ---
enum Mode { FOLLOW, STAY }


# --- Constants ---
const POSITION_THRESHOLD: float = 0.3
const GRAVITY: float = 9.8
const DRAG_LIFT_HEIGHT: float = 1.5
const COLOR_DRAGGED := Color(1.0, 1.0, 0.4)
const RETARGET_INTERVAL: float = 0.3


# --- Exports ---
@export var type_data: MinionTypeData


# --- Public variables ---
var current_mode: Mode = Mode.FOLLOW


# --- Private variables ---
var _follow_offset: Vector3 = Vector3.ZERO
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


# --- Onready variables ---
@onready var _sphere: MeshInstance3D = $Visual/Sphere
@onready var _anim_player: AnimationPlayer = $AnimationPlayer


# --- Built-in virtual methods ---
func _ready() -> void:
	add_to_group("minions")
	collision_layer = 2
	collision_mask = 9  # Ground (1) + Payload (8)
	_follow_offset = Vector3(randf_range(-0.8, 0.8), 0.0, randf_range(-0.8, 0.8))
	_visual_material = _sphere.mesh.surface_get_material(0).duplicate() as StandardMaterial3D
	_sphere.set_surface_override_material(0, _visual_material)
	_health_component = get_node_or_null("HealthComponent") as HealthComponent
	_attack_component = get_node_or_null("AttackComponent") as AttackComponent
	if _health_component:
		_health_component.died.connect(_on_died)
	if _attack_component:
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


# --- Private methods ---
func _apply_type_data() -> void:
	if not type_data:
		return
	_move_speed = type_data.move_speed
	_leash_radius = type_data.leash_radius
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
		scan_range = _attack_component.attack_range

	var best_enemy: Node3D = null
	var best_dist: float = scan_range
	for node: Node in enemies:
		var enemy := node as Node3D
		if not enemy or not is_instance_valid(enemy):
			continue
		var dist := global_position.distance_to(enemy.global_position)
		if current_mode == Mode.STAY:
			dist = _home_position.distance_to(enemy.global_position)
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


func _clear_combat_target() -> void:
	_combat_target = null
	_leash_triggered = false
	if _attack_component:
		_attack_component.clear_target()


func _process_follow() -> void:
	var wizard := get_tree().get_first_node_in_group("wizard") as Wizard
	if not wizard:
		velocity.x = 0.0
		velocity.z = 0.0
		return
	var target := wizard.global_position + _follow_offset
	var diff := target - global_position
	diff.y = 0.0
	var distance := diff.length()
	if distance > POSITION_THRESHOLD:
		var direction := diff.normalized()
		velocity.x = direction.x * _move_speed
		velocity.z = direction.z * _move_speed
	else:
		velocity.x = 0.0
		velocity.z = 0.0


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
		if not _attack_component.is_target_in_range():
			_move_toward(_combat_target.global_position)
		else:
			velocity.x = 0.0
			velocity.z = 0.0
	else:
		var dist_to_home := global_position.distance_to(_home_position)
		if dist_to_home > POSITION_THRESHOLD:
			_move_toward(_home_position)
		else:
			velocity.x = 0.0
			velocity.z = 0.0


func _move_toward(target_pos: Vector3) -> void:
	var diff := target_pos - global_position
	diff.y = 0.0
	var distance := diff.length()
	if distance > POSITION_THRESHOLD:
		var direction := diff.normalized()
		velocity.x = direction.x * _move_speed
		velocity.z = direction.z * _move_speed
	else:
		velocity.x = 0.0
		velocity.z = 0.0


func _on_attack_performed() -> void:
	_play_sword_swing()
	_apply_knockback_to_target()
	if _leash_triggered:
		_clear_combat_target()


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
