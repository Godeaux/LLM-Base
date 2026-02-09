class_name Minion
extends CharacterBody3D
## Pikmin-style minion with guard-post STAY mode and combat-capable FOLLOW mode.
## Supports MELEE (warrior), RANGED (sniper), and HEALER behavior types via
## MinionTypeData resource. STAY minions operate within a leash radius from their
## home position. FOLLOW minions escort the Trojan Horse in formation.


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
const HORSE_AVOIDANCE_RADIUS: float = 2.2
const HALO_COLOR_FULL := Color(0.95, 1.0, 0.76)
const HALO_COLOR_DEAD := Color(0.85, 0.05, 0.05)
const KILL_FLOOR_Y: float = -5.0
const PROJECTILE_SCENE: PackedScene = preload("res://entities/Projectile.tscn")
const HEAL_PROJECTILE_SCENE: PackedScene = preload("res://entities/HealProjectile.tscn")


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
var _halo_material: StandardMaterial3D
var _combat_target: Node3D = null
var _heal_target: Node3D = null
var _leash_triggered: bool = false
var _retarget_timer: float = 0.0
var _health_component: HealthComponent
var _attack_component: AttackComponent
var _heal_component: HealComponent = null
var _move_speed: float = 4.0
var _leash_radius: float = 15.0
var _aggro_radius: float = 8.0
var _behavior_type: String = "MELEE"
var _preferred_range: float = 0.0
var _weapon_pivot: Node3D = null


# --- Onready variables ---
@onready var _sphere: MeshInstance3D = $Visual/Sphere
@onready var _halo: MeshInstance3D = $Visual/MeshInstance3D
@onready var _anim_player: AnimationPlayer = $AnimationPlayer
@onready var _sword_pivot: Node3D = $Visual/SwordPivot


# --- Built-in virtual methods ---
func _ready() -> void:
	add_to_group("minions")
	collision_layer = 2
	collision_mask = 15  # Ground (1) + Minions (2) + Enemies (4) + Payload (8)
	_visual_material = _sphere.mesh.surface_get_material(0).duplicate() as StandardMaterial3D
	_sphere.set_surface_override_material(0, _visual_material)
	if _halo:
		_halo_material = _halo.mesh.surface_get_material(0).duplicate() as StandardMaterial3D
		_halo.set_surface_override_material(0, _halo_material)
	_health_component = get_node_or_null("HealthComponent") as HealthComponent
	_attack_component = get_node_or_null("AttackComponent") as AttackComponent
	if _health_component:
		_health_component.died.connect(_on_died)
		_health_component.health_changed.connect(_on_health_changed)
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

	_rotate_toward_active_target(delta)

	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0.0
	move_and_slide()

	if global_position.y < KILL_FLOOR_Y:
		_on_died()
		return


# --- Public methods ---
func set_mode(new_mode: Mode) -> void:
	if current_mode == new_mode:
		return
	current_mode = new_mode
	if new_mode == Mode.STAY:
		_home_position = global_position
	_leash_triggered = false
	_clear_combat_target()
	_clear_heal_target()
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
	_clear_heal_target()
	_update_visual()


func end_drag() -> void:
	_is_being_dragged = false
	_update_visual()


func move_to_drag_position(ground_pos: Vector3) -> void:
	global_position = ground_pos + Vector3(0.0, DRAG_LIFT_HEIGHT, 0.0)


func apply_type_stats(data: MinionTypeData) -> void:
	type_data = data
	_apply_type_data()
	_update_visual()


func get_follow_angle() -> float:
	return _follow_angle


func set_escort_position(angle: float, radius: float) -> void:
	_follow_angle = angle
	_follow_radius = radius


# --- Private methods: Type Setup ---
func _apply_type_data() -> void:
	if not type_data:
		return
	_move_speed = type_data.move_speed
	_leash_radius = type_data.leash_radius
	_aggro_radius = type_data.aggro_radius
	_behavior_type = type_data.behavior_type
	_preferred_range = type_data.preferred_range
	if _health_component:
		_health_component.max_health = type_data.max_health
		_health_component._current_health = type_data.max_health
	if _attack_component:
		_attack_component.damage = type_data.attack_damage
		_attack_component.attack_interval = type_data.attack_interval
		_attack_component.attack_range = type_data.attack_range
	# Healer: create HealComponent dynamically
	if _behavior_type == "HEALER" and not _heal_component:
		_heal_component = HealComponent.new()
		_heal_component.name = "HealComponent"
		_heal_component.heal_amount = type_data.heal_amount
		_heal_component.heal_interval = type_data.heal_interval
		_heal_component.heal_range = type_data.heal_range
		_heal_component.animation_driven = true
		add_child(_heal_component)
		_heal_component.heal_started.connect(_on_heal_started)
		_heal_component.heal_performed.connect(_on_heal_performed)
	_setup_weapon_visual()


func _setup_weapon_visual() -> void:
	if not type_data or not _anim_player:
		return
	# Duplicate the animation library so type-specific animations don't leak
	# across instances (all minions share the same scene resource otherwise).
	var lib: AnimationLibrary = _anim_player.get_animation_library("")
	if lib:
		var unique_lib := lib.duplicate()
		_anim_player.remove_animation_library("")
		_anim_player.add_animation_library("", unique_lib)
	match _behavior_type:
		"RANGED":
			if _sword_pivot:
				_sword_pivot.visible = false
			_build_rifle_visual()
			_build_sniper_animation()
		"HEALER":
			if _sword_pivot:
				_sword_pivot.visible = false
			_build_staff_visual()
			_build_heal_animation()


func _build_rifle_visual() -> void:
	var visual: Node3D = $Visual
	var pivot := Node3D.new()
	pivot.name = "RiflePivot"
	pivot.position = Vector3(0.0, 0.301, 0.0)
	visual.add_child(pivot)
	_weapon_pivot = pivot

	var rifle := MeshInstance3D.new()
	rifle.name = "Rifle"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.6, 0.08, 0.08)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.25, 0.25, 0.3)
	mat.metallic = 0.7
	mat.roughness = 0.3
	mesh.material = mat
	rifle.mesh = mesh
	rifle.position = Vector3(0.3, 0.0, 0.0)
	pivot.add_child(rifle)


func _build_staff_visual() -> void:
	var visual: Node3D = $Visual
	var pivot := Node3D.new()
	pivot.name = "StaffPivot"
	pivot.position = Vector3(0.0, 0.0, 0.0)
	visual.add_child(pivot)
	_weapon_pivot = pivot

	var staff := MeshInstance3D.new()
	staff.name = "Staff"
	var staff_mesh := BoxMesh.new()
	staff_mesh.size = Vector3(0.06, 0.7, 0.06)
	var staff_mat := StandardMaterial3D.new()
	staff_mat.albedo_color = Color(0.8, 0.65, 0.2)
	staff_mat.metallic = 0.5
	staff_mat.roughness = 0.4
	staff_mesh.material = staff_mat
	staff.mesh = staff_mesh
	staff.position = Vector3(0.2, 0.35, 0.0)
	pivot.add_child(staff)

	var orb := MeshInstance3D.new()
	orb.name = "Orb"
	var orb_mesh := SphereMesh.new()
	orb_mesh.radius = 0.08
	orb_mesh.height = 0.16
	var orb_mat := StandardMaterial3D.new()
	orb_mat.albedo_color = Color(0.3, 1.0, 0.4)
	orb_mat.emission_enabled = true
	orb_mat.emission = Color(0.3, 1.0, 0.4)
	orb_mat.emission_energy_multiplier = 1.5
	orb_mesh.material = orb_mat
	orb.mesh = orb_mesh
	orb.position = Vector3(0.2, 0.72, 0.0)
	pivot.add_child(orb)


func _build_sniper_animation() -> void:
	## Build "sniper_shot" animation: rifle recoil + fire_projectile call.
	var anim := Animation.new()
	anim.length = 0.5

	# Track 0: RiflePivot position (recoil)
	var pos_track := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(pos_track, "Visual/RiflePivot:position")
	anim.track_insert_key(pos_track, 0.0, Vector3(0.0, 0.301, 0.0))
	anim.track_insert_key(pos_track, 0.1, Vector3(-0.15, 0.35, 0.0))  # Recoil back+up
	anim.track_insert_key(pos_track, 0.3, Vector3(0.0, 0.301, 0.0))   # Return

	# Track 1: RiflePivot rotation (kick up)
	var rot_track := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(rot_track, "Visual/RiflePivot:rotation")
	anim.track_insert_key(rot_track, 0.0, Vector3.ZERO)
	anim.track_insert_key(rot_track, 0.1, Vector3(0.0, 0.0, 0.3))    # Kick up
	anim.track_insert_key(rot_track, 0.3, Vector3.ZERO)

	# Track 2: Call fire_projectile at fire frame
	var call_track := anim.add_track(Animation.TYPE_METHOD)
	anim.track_set_path(call_track, ".")
	anim.track_insert_key(call_track, 0.1, {"method": "fire_projectile", "args": []})

	var lib: AnimationLibrary = _anim_player.get_animation_library("")
	if lib:
		lib.add_animation("sniper_shot", anim)


func _build_heal_animation() -> void:
	## Build "staff_heal" animation: staff bob + orb pulse + apply_heal call.
	var anim := Animation.new()
	anim.length = 0.6

	# Track 0: StaffPivot position (gentle bob)
	var pos_track := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(pos_track, "Visual/StaffPivot:position")
	anim.track_insert_key(pos_track, 0.0, Vector3.ZERO)
	anim.track_insert_key(pos_track, 0.3, Vector3(0.0, 0.15, 0.0))  # Bob up
	anim.track_insert_key(pos_track, 0.6, Vector3.ZERO)

	# Track 1: Call fire_heal_projectile at peak
	var call_track := anim.add_track(Animation.TYPE_METHOD)
	anim.track_set_path(call_track, ".")
	anim.track_insert_key(call_track, 0.3, {"method": "fire_heal_projectile", "args": []})

	var lib: AnimationLibrary = _anim_player.get_animation_library("")
	if lib:
		lib.add_animation("staff_heal", anim)


# --- Private methods: Target Scanning ---
func _scan_for_target() -> void:
	match _behavior_type:
		"HEALER":
			_scan_for_heal_target()
		_:
			_scan_for_combat_target()


func _scan_for_combat_target() -> void:
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


func _scan_for_heal_target() -> void:
	if not _heal_component:
		return
	var scan_origin: Vector3
	if current_mode == Mode.STAY:
		scan_origin = _home_position
	else:
		scan_origin = global_position
	var scan_range: float = type_data.heal_range if type_data else 6.0

	# Priority 1: Horse if damaged
	var horse := get_tree().get_first_node_in_group("trojan_horse") as Node3D
	if horse and is_instance_valid(horse):
		var horse_health := horse.get_node_or_null("HealthComponent") as HealthComponent
		if horse_health and horse_health.get_health_percent() < 1.0:
			var dist := scan_origin.distance_to(horse.global_position)
			if dist <= scan_range:
				_set_heal_target(horse)
				return

	# Priority 2: Lowest-HP minion in range
	var best_target: Node3D = null
	var best_pct: float = 1.0
	for node: Node in get_tree().get_nodes_in_group("minions"):
		var ally := node as Node3D
		if ally == self or not ally or not is_instance_valid(ally):
			continue
		var ally_health := ally.get_node_or_null("HealthComponent") as HealthComponent
		if not ally_health or ally_health.get_health_percent() >= 1.0:
			continue
		var dist := scan_origin.distance_to(ally.global_position)
		if dist <= scan_range and ally_health.get_health_percent() < best_pct:
			best_pct = ally_health.get_health_percent()
			best_target = ally

	if best_target:
		_set_heal_target(best_target)
	elif _heal_target and (not is_instance_valid(_heal_target) or _get_target_health_pct(_heal_target) >= 1.0):
		_clear_heal_target()


func _get_target_health_pct(target: Node3D) -> float:
	var health := target.get_node_or_null("HealthComponent") as HealthComponent
	if health:
		return health.get_health_percent()
	return 1.0


func _set_combat_target(target: Node3D) -> void:
	if _combat_target == target:
		return
	_combat_target = target
	var target_health := target.get_node_or_null("HealthComponent") as HealthComponent
	if target_health and _attack_component:
		_attack_component.set_target(target_health, target)
	else:
		_clear_combat_target()


func _set_heal_target(target: Node3D) -> void:
	if _heal_target == target:
		return
	_heal_target = target
	var target_health := target.get_node_or_null("HealthComponent") as HealthComponent
	if target_health and _heal_component:
		_heal_component.set_target(target_health, target)
	else:
		_clear_heal_target()


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


func _clear_heal_target() -> void:
	_heal_target = null
	if _heal_component:
		_heal_component.clear_target()


# --- Private methods: Behavior Processing ---
func _process_follow() -> void:
	if _behavior_type == "HEALER":
		_process_follow_healer()
		return

	# Chase combat target if we have one
	if _combat_target and is_instance_valid(_combat_target):
		_pursue_combat_target()
		return

	# Otherwise escort the Trojan Horse in formation
	_move_to_formation()


func _process_follow_healer() -> void:
	# Pursue heal target if someone needs healing
	if _heal_target and is_instance_valid(_heal_target):
		_pursue_heal_target()
		return
	# Otherwise escort the Trojan Horse in formation
	_move_to_formation()


func _move_to_formation() -> void:
	var horse := get_tree().get_first_node_in_group("trojan_horse") as Node3D
	if not horse:
		velocity.x = 0.0
		velocity.z = 0.0
		return

	# Normal formation position (in horse-local space via its basis)
	var local_offset := Vector3(
		cos(_follow_angle) * _follow_radius, 0.0, sin(_follow_angle) * _follow_radius)
	var formation_pos := horse.global_position + horse.global_transform.basis * local_offset

	# Bias toward nearest threat to shield the horse (not for healers)
	var target_pos := formation_pos
	if _behavior_type != "HEALER":
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
	if _behavior_type == "HEALER":
		_process_stay_healer()
		return

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


func _process_stay_healer() -> void:
	if _heal_target and is_instance_valid(_heal_target):
		_pursue_heal_target()
	else:
		var dist_to_home := global_position.distance_to(_home_position)
		if dist_to_home > DEAD_ZONE:
			_move_toward(_home_position)
		else:
			velocity.x = 0.0
			velocity.z = 0.0


func _pursue_heal_target() -> void:
	if not _heal_component or not _heal_target or not is_instance_valid(_heal_target):
		_clear_heal_target()
		return
	if _heal_component.is_target_in_range():
		# In range — stay put, let HealComponent timer handle healing
		velocity.x = 0.0
		velocity.z = 0.0
	else:
		_move_toward(_heal_target.global_position)


func _rotate_toward_active_target(delta: float) -> void:
	var look_target: Node3D = null
	if _behavior_type == "HEALER":
		look_target = _heal_target
	else:
		look_target = _combat_target
	if not look_target or not is_instance_valid(look_target):
		return
	var dir := look_target.global_position - global_position
	dir.y = 0.0
	if dir.length_squared() < 0.01:
		return
	var target_angle := atan2(-dir.z, dir.x)  # Model faces +X at rest
	rotation.y = lerp_angle(rotation.y, target_angle, ROTATION_SPEED * delta)


func _pursue_combat_target() -> void:
	var separation := _get_separation_force()
	var diff := _combat_target.global_position - global_position
	diff.y = 0.0
	var distance := diff.length()

	# Ranged: maintain preferred distance (kite)
	if _behavior_type == "RANGED" and _preferred_range > 0.0:
		if distance < _preferred_range * 0.7 and distance > DEAD_ZONE:
			# Too close — back away
			var retreat_dir := -diff.normalized()
			velocity.x = retreat_dir.x * _move_speed
			velocity.z = retreat_dir.z * _move_speed
			return
		elif distance > type_data.attack_range:
			# Too far — approach to attack range
			var approach_dir := diff.normalized()
			var speed := _move_speed
			var target_dist := _preferred_range
			var gap := distance - target_dist
			if gap < ARRIVE_DISTANCE:
				speed *= gap / ARRIVE_DISTANCE
			var desired := approach_dir * speed + separation * SEPARATION_WEIGHT
			velocity.x = desired.x
			velocity.z = desired.z
			return
		else:
			# In sweet spot — hold position
			if separation.length_squared() > 0.01:
				var sep_dir := separation.normalized()
				velocity.x = sep_dir.x * _move_speed * 0.3
				velocity.z = sep_dir.z * _move_speed * 0.3
			else:
				velocity.x = 0.0
				velocity.z = 0.0
			return

	# Melee: close to attack range
	if not _attack_component.is_target_in_range():
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
	var effective_target := _apply_horse_avoidance(target_pos)
	var diff := effective_target - global_position
	diff.y = 0.0
	var distance := diff.length()
	if distance < DEAD_ZONE:
		velocity.x = 0.0
		velocity.z = 0.0
		return
	var direction := diff.normalized()
	var speed := _move_speed
	# Use distance to original target for arrival slowdown
	var orig_dist := (target_pos - global_position)
	orig_dist.y = 0.0
	if orig_dist.length() < ARRIVE_DISTANCE:
		speed *= orig_dist.length() / ARRIVE_DISTANCE
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed


func _apply_horse_avoidance(target_pos: Vector3) -> Vector3:
	## If the horse is between us and our target, return a detour waypoint to one
	## side.  Otherwise return the original target unchanged.
	var horse := get_tree().get_first_node_in_group("trojan_horse") as Node3D
	if not horse:
		return target_pos

	var to_target := target_pos - global_position
	to_target.y = 0.0
	var to_horse := horse.global_position - global_position
	to_horse.y = 0.0

	var dist_to_target := to_target.length()
	var dist_to_horse := to_horse.length()

	# Skip if horse is far away or distances are trivially small
	if dist_to_horse > HORSE_AVOIDANCE_RADIUS + dist_to_target:
		return target_pos
	if dist_to_horse < 0.1 or dist_to_target < 0.1:
		return target_pos

	# Project horse center onto the line from minion -> target
	var dir_to_target := to_target / dist_to_target
	var projection := to_horse.dot(dir_to_target)

	# Horse must be ahead of us and before our target to matter
	if projection < 0.0 or projection > dist_to_target:
		return target_pos

	# Perpendicular distance from horse center to our path line
	var closest_on_line := global_position + dir_to_target * projection
	var perp := horse.global_position - closest_on_line
	perp.y = 0.0
	var perp_dist := perp.length()

	if perp_dist > HORSE_AVOIDANCE_RADIUS:
		return target_pos

	# Pick the side we're already offset toward (less jarring)
	var lateral: Vector3
	if perp_dist > 0.1:
		lateral = -perp.normalized()
	else:
		# Headed straight at center — use a consistent perpendicular
		lateral = Vector3(-dir_to_target.z, 0.0, dir_to_target.x)

	var waypoint := horse.global_position + lateral * HORSE_AVOIDANCE_RADIUS
	waypoint.y = target_pos.y
	return waypoint


# --- Private methods: Attack & Heal Callbacks ---
func _on_attack_started() -> void:
	## Animation-driven mode: cooldown fired, play the attack animation.
	match _behavior_type:
		"RANGED":
			_play_sniper_shot()
		_:
			_play_sword_swing()


func _on_attack_performed() -> void:
	## Fires after damage is actually applied (from deal_damage).
	if _leash_triggered:
		_clear_combat_target()


func _on_heal_started() -> void:
	## HealComponent timer fired. Play heal animation.
	_play_staff_heal()


func _on_heal_performed() -> void:
	## Heal was applied. Check if target is now full.
	if _heal_target and is_instance_valid(_heal_target):
		if _get_target_health_pct(_heal_target) >= 1.0:
			_clear_heal_target()


func deal_damage() -> void:
	## Called by the sword_swing animation's Call Method track at the hit keyframe.
	if _attack_component:
		_attack_component.deal_damage()
	_apply_knockback_to_target()


func fire_projectile() -> void:
	## Called by the sniper_shot animation's Call Method track at the fire keyframe.
	if not _combat_target or not is_instance_valid(_combat_target):
		return
	var proj: Projectile = PROJECTILE_SCENE.instantiate() as Projectile
	proj.target_node = _combat_target
	proj.damage = type_data.attack_damage if type_data else 25.0
	proj.speed = type_data.projectile_speed if type_data else 12.0
	proj.knockback_force = type_data.knockback_force if type_data else 8.0
	proj.shooter = self
	get_tree().current_scene.add_child(proj)
	proj.global_position = global_position + Vector3(0.0, 0.3, 0.0)
	# Mark attack as performed for leash logic
	if _attack_component:
		_attack_component.attack_performed.emit()


func apply_heal() -> void:
	## Called by the staff_heal animation's Call Method track.
	if _heal_component:
		_heal_component.apply_heal()


func fire_heal_projectile() -> void:
	## Called by the staff_heal animation's Call Method track. Spawns a green heal bolt.
	if not _heal_target or not is_instance_valid(_heal_target):
		return
	var proj: HealProjectile = HEAL_PROJECTILE_SCENE.instantiate() as HealProjectile
	proj.target_node = _heal_target
	proj.heal_amount = type_data.heal_amount if type_data else 5.0
	proj.speed = 10.0
	get_tree().current_scene.add_child(proj)
	proj.global_position = global_position + Vector3(0.0, 0.3, 0.0)


func _on_health_changed(_current: float, _maximum: float) -> void:
	_update_halo()


func _on_died() -> void:
	queue_free()


# --- Private methods: Animation ---
func _play_sword_swing() -> void:
	if not _anim_player:
		return
	_anim_player.stop()
	_anim_player.play("sword_swing")


func _play_sniper_shot() -> void:
	if not _anim_player:
		return
	_anim_player.stop()
	_anim_player.play("sniper_shot")


func _play_staff_heal() -> void:
	if not _anim_player:
		return
	_anim_player.stop()
	_anim_player.play("staff_heal")


func _apply_knockback_to_target() -> void:
	if not _combat_target or not is_instance_valid(_combat_target):
		return
	if _combat_target.has_method("apply_knockback"):
		var direction := _combat_target.global_position - global_position
		var force: float = 3.0
		if type_data:
			force = type_data.knockback_force
		_combat_target.apply_knockback(direction, force)


# --- Private methods: Visual ---
func _update_halo() -> void:
	if not _halo_material or not _health_component:
		return
	var pct: float = _health_component.get_health_percent()
	_halo_material.emission = HALO_COLOR_FULL.lerp(HALO_COLOR_DEAD, 1.0 - pct)


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
