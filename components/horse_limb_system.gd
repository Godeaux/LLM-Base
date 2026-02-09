class_name HorseLimbSystem
extends HealthComponent
## Multi-part damage system for the Trojan Horse.
## Manages 4 limbs with independent HP pools plus a center body HP pool.
## Incoming damage is routed to the nearest alive limb based on attacker
## direction. Dead limbs let damage pass through to the center body.
## Extends HealthComponent so enemies need no code changes.


# --- Signals ---
signal limb_damaged(limb_index: int, current_hp: float, max_hp: float)
signal limb_destroyed(limb_index: int)
signal limb_revived(limb_index: int)
signal center_damaged(current_hp: float, max_hp: float)

# --- Enums ---
enum Limb { FRONT_LEFT, FRONT_RIGHT, REAR_LEFT, REAR_RIGHT }

# --- Constants ---
## Local-space direction vectors for each limb (look_at faces -Z).
const LIMB_DIRECTIONS: Array[Vector3] = [
	Vector3(-1.0, 0.0, -1.0),  # FRONT_LEFT:  -X, -Z
	Vector3(1.0, 0.0, -1.0),   # FRONT_RIGHT: +X, -Z
	Vector3(-1.0, 0.0, 1.0),   # REAR_LEFT:   -X, +Z
	Vector3(1.0, 0.0, 1.0),    # REAR_RIGHT:  +X, +Z
]

# --- Exports ---
@export_group("Limb Stats")
@export var limb_max_health: float = 20.0
@export var center_max_health: float = 40.0

# --- Private variables ---
var _limb_health: PackedFloat32Array
var _limb_alive: Array[bool] = [true, true, true, true]
var _center_health: float
var _owner_3d: Node3D


# --- Built-in virtual methods ---
func _ready() -> void:
	_owner_3d = get_parent() as Node3D
	_limb_health = PackedFloat32Array([
		limb_max_health, limb_max_health, limb_max_health, limb_max_health
	])
	_center_health = center_max_health
	max_health = limb_max_health * 4.0 + center_max_health
	_current_health = max_health


# --- Public methods ---
func take_damage(amount: float) -> void:
	## Fallback when no attacker direction is available.
	## Distributes damage evenly across alive limbs, remainder to center.
	var alive_indices: Array[int] = _get_alive_limb_indices()
	if alive_indices.is_empty():
		_damage_center(amount)
	else:
		var per_limb: float = amount / float(alive_indices.size())
		for i: int in alive_indices:
			_route_damage_to_limb(i, per_limb)
	_recalculate_total_health()


func take_damage_from(amount: float, attacker: Node3D) -> void:
	## Routes damage to the nearest alive limb based on attacker direction.
	## If that limb is dead, damage passes through to center body.
	if not _owner_3d or not is_instance_valid(attacker):
		take_damage(amount)
		return
	var local_pos: Vector3 = _owner_3d.to_local(attacker.global_position)
	var target_limb: int = _direction_to_limb(local_pos)
	if _limb_alive[target_limb]:
		_route_damage_to_limb(target_limb, amount)
	else:
		## Limb is dead — damage passes through to center.
		_damage_center(amount)
	_recalculate_total_health()
	damaged_by.emit(amount, attacker)


func heal(amount: float) -> void:
	## Distributes healing evenly to center + alive limbs.
	var targets: int = 1  # center always receives healing
	var alive_indices: Array[int] = _get_alive_limb_indices()
	targets += alive_indices.size()
	var per_target: float = amount / float(targets)
	_center_health = minf(_center_health + per_target, center_max_health)
	for i: int in alive_indices:
		_limb_health[i] = minf(_limb_health[i] + per_target, limb_max_health)
	_recalculate_total_health()


func get_speed_multiplier() -> float:
	var alive_count: int = 0
	for alive: bool in _limb_alive:
		if alive:
			alive_count += 1
	return float(alive_count) / 4.0


func get_limb_health_percent(limb_index: int) -> float:
	if limb_max_health <= 0.0:
		return 0.0
	return _limb_health[limb_index] / limb_max_health


func is_limb_alive(limb_index: int) -> bool:
	return _limb_alive[limb_index]


func get_center_health_percent() -> float:
	if center_max_health <= 0.0:
		return 0.0
	return _center_health / center_max_health


func revive_limb(limb_index: int, hp: float) -> void:
	## Restores a dead limb with the specified HP. For future Healer minion.
	if _limb_alive[limb_index]:
		return
	_limb_alive[limb_index] = true
	_limb_health[limb_index] = clampf(hp, 0.0, limb_max_health)
	limb_revived.emit(limb_index)
	_recalculate_total_health()


func get_damaged_limb_index(attacker: Node3D) -> int:
	## Returns which limb index an attacker would hit. Used by visuals.
	if not _owner_3d or not is_instance_valid(attacker):
		return -1
	var local_pos: Vector3 = _owner_3d.to_local(attacker.global_position)
	var target: int = _direction_to_limb(local_pos)
	if _limb_alive[target]:
		return target
	return -1  # Limb dead — damage goes to center


# --- Private methods ---
func _direction_to_limb(local_pos: Vector3) -> int:
	## Maps a horse-local position to the nearest limb quadrant.
	## look_at() faces -Z: Front = -Z, Rear = +Z, Left = -X, Right = +X.
	if local_pos.z < 0.0:
		return Limb.FRONT_LEFT if local_pos.x < 0.0 else Limb.FRONT_RIGHT
	else:
		return Limb.REAR_LEFT if local_pos.x < 0.0 else Limb.REAR_RIGHT


func _route_damage_to_limb(limb_index: int, amount: float) -> void:
	_limb_health[limb_index] = maxf(_limb_health[limb_index] - amount, 0.0)
	limb_damaged.emit(limb_index, _limb_health[limb_index], limb_max_health)
	if _limb_health[limb_index] <= 0.0 and _limb_alive[limb_index]:
		_limb_alive[limb_index] = false
		limb_destroyed.emit(limb_index)


func _damage_center(amount: float) -> void:
	_center_health = maxf(_center_health - amount, 0.0)
	center_damaged.emit(_center_health, center_max_health)
	if _center_health <= 0.0:
		_recalculate_total_health()
		died.emit()


func _recalculate_total_health() -> void:
	var total: float = _center_health
	for hp: float in _limb_health:
		total += hp
	_current_health = total
	health_changed.emit(_current_health, max_health)


func _get_alive_limb_indices() -> Array[int]:
	var indices: Array[int] = []
	for i: int in range(4):
		if _limb_alive[i]:
			indices.append(i)
	return indices
