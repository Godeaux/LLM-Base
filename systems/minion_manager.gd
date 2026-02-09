class_name MinionManager
extends Node
## Tracks active minions, enforces max count, handles spawn/despawn.


# --- Constants ---
const MINION_SCENE: PackedScene = preload("res://entities/Minion.tscn")
const MAX_MINIONS: int = 5
const ESCORT_RADIUS: float = 4.0
const DEFAULT_FOLLOW_RADIUS: float = 2.5


# --- Private variables ---
var _active_minions: Array[Minion] = []
var _type_resources: Dictionary = {
	1: preload("res://data/minion_type_basic.tres"),
}


# --- Built-in virtual methods ---
func _ready() -> void:
	EventBus.minion_count_changed.emit(0, MAX_MINIONS)


# --- Public methods ---
func can_summon() -> bool:
	return _active_minions.size() < MAX_MINIONS


func get_minion_count() -> int:
	return _active_minions.size()


func summon_minion(world_position: Vector3, type_id: int = 1) -> Minion:
	if not can_summon():
		push_warning("MinionManager: Cannot summon — max count reached.")
		return null
	var minion: Minion = MINION_SCENE.instantiate() as Minion
	add_child(minion)
	minion.global_position = world_position
	var type_res: MinionTypeData = _type_resources.get(type_id) as MinionTypeData
	if type_res:
		minion.apply_type_stats(type_res)
	_active_minions.append(minion)
	minion.tree_exited.connect(_on_minion_removed.bind(minion))
	assign_escort_position(minion)
	EventBus.minion_summoned.emit(type_id)
	EventBus.minion_count_changed.emit(_active_minions.size(), MAX_MINIONS)
	print("MinionManager: Summoned minion type %d (%d/%d)." % [
		type_id, _active_minions.size(), MAX_MINIONS])
	return minion


func assign_escort_position(minion: Minion) -> void:
	var existing_angles: Array[float] = []
	for m: Minion in _active_minions:
		if m != minion and m.current_mode == Minion.Mode.FOLLOW:
			existing_angles.append(m.get_follow_angle())
	var angle := _find_largest_gap_angle(existing_angles)
	minion.set_escort_position(angle, DEFAULT_FOLLOW_RADIUS)


# --- Private methods ---
func _find_largest_gap_angle(angles: Array[float]) -> float:
	if angles.is_empty():
		return 0.0
	angles.sort()
	var best_gap: float = 0.0
	var best_angle: float = 0.0
	for i in angles.size():
		var current := angles[i]
		var next := angles[(i + 1) % angles.size()]
		var gap: float
		if next > current:
			gap = next - current
		else:
			gap = (TAU - current) + next
		if gap > best_gap:
			best_gap = gap
			best_angle = current + gap / 2.0
			if best_angle >= TAU:
				best_angle -= TAU
	return best_angle


func _on_minion_removed(minion: Minion) -> void:
	_active_minions.erase(minion)
	EventBus.minion_count_changed.emit(_active_minions.size(), MAX_MINIONS)
