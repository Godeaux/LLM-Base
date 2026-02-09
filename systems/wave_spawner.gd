class_name WaveSpawner
extends Node
## Spawns enemies in waves at SpawnPoint markers placed on tiles ahead of the
## Trojan Horse. Enemies stagger in one-by-one. Next wave triggers after a prep
## delay, then either N tiles of horse progress OR a max timer — whichever first.


# --- Constants ---
const ENEMY_SCENE: PackedScene = preload("res://entities/Enemy.tscn")
const RUNNER_DATA: EnemyTypeData = preload("res://data/enemy_type_runner.tres")
const FIGHTER_DATA: EnemyTypeData = preload("res://data/enemy_type_fighter.tres")
const INITIAL_DELAY: float = 3.0
const BETWEEN_WAVE_DELAY: float = 7.0
const LOOKAHEAD_TILES: int = 6
const SPAWN_JITTER: float = 1.0
const SPAWN_STAGGER_INTERVAL: float = 1.2
const TILES_PER_WAVE: int = 6
const MAX_WAVE_WAIT: float = 2.0


# --- Exports ---
@export var trojan_horse: TrojanHorse
@export var map_manager: MapManager


# --- Private variables ---
var _wave_definitions: Array[int] = [3, 4, 5, 5, 6, 7, 7, 8, 9, 10]
var _current_wave: int = 0
var _active_enemies: int = 0
var _all_waves_done: bool = false
var _map_ended: bool = false

var _spawning_in_progress: bool = false
var _spawn_queue_remaining: int = 0
var _spawn_timer: SceneTreeTimer

var _waiting_for_trigger: bool = false
var _tiles_since_last_wave: int = 0
var _initial_timer: SceneTreeTimer
var _prep_timer: SceneTreeTimer
var _max_wait_timer: SceneTreeTimer
var _spawn_type_queue: Array[EnemyTypeData] = []


# --- Built-in virtual methods ---
func _ready() -> void:
	EventBus.enemy_killed.connect(_on_enemy_killed)
	EventBus.horse_entered_tile.connect(_on_horse_entered_tile)
	EventBus.horse_reached_map_end.connect(_on_horse_reached_map_end)
	_initial_timer = get_tree().create_timer(INITIAL_DELAY)
	_initial_timer.timeout.connect(_start_next_wave)


# --- Private methods ---
func _start_next_wave() -> void:
	if _all_waves_done or _map_ended:
		return
	if _current_wave >= _wave_definitions.size():
		_all_waves_done = true
		print("WaveSpawner: All waves completed!")
		return

	var enemy_count: int = _wave_definitions[_current_wave]
	var fighter_ratio: float = _get_fighter_ratio(_current_wave)
	var fighter_count: int = roundi(enemy_count * fighter_ratio)
	var runner_count: int = enemy_count - fighter_count

	# Build shuffled type queue.
	_spawn_type_queue.clear()
	for i: int in fighter_count:
		_spawn_type_queue.append(FIGHTER_DATA)
	for i: int in runner_count:
		_spawn_type_queue.append(RUNNER_DATA)
	_spawn_type_queue.shuffle()

	_current_wave += 1
	_active_enemies = enemy_count
	_spawning_in_progress = true
	_spawn_queue_remaining = enemy_count
	_waiting_for_trigger = false

	EventBus.wave_started.emit(_current_wave, enemy_count)
	print("WaveSpawner: Wave %d — spawning %d enemies (%d runners, %d fighters)." % [
		_current_wave, enemy_count, runner_count, fighter_count])
	_spawn_one_enemy()


func _spawn_one_enemy() -> void:
	if _spawn_queue_remaining <= 0 or _map_ended:
		_spawning_in_progress = false
		return

	var spawn_points := _collect_forward_spawn_points()
	if spawn_points.is_empty():
		push_warning("WaveSpawner: No spawn points found — cancelling remaining %d spawns." % _spawn_queue_remaining)
		_active_enemies -= _spawn_queue_remaining
		_spawn_queue_remaining = 0
		_spawning_in_progress = false
		return

	var sp: SpawnPoint = spawn_points.pick_random()
	var pos := sp.global_position
	pos.x += randf_range(-SPAWN_JITTER, SPAWN_JITTER)
	pos.z += randf_range(-SPAWN_JITTER, SPAWN_JITTER)
	pos.y = 0.0

	var enemy: Enemy = ENEMY_SCENE.instantiate() as Enemy
	add_child(enemy)
	enemy.global_position = pos
	enemy.set_map_manager(map_manager)

	# Apply type data from the queue.
	if not _spawn_type_queue.is_empty():
		var type_data: EnemyTypeData = _spawn_type_queue.pop_front()
		enemy.initialize(type_data)

	enemy.emerge()

	_spawn_queue_remaining -= 1
	if _spawn_queue_remaining > 0 and not _map_ended:
		_spawn_timer = get_tree().create_timer(SPAWN_STAGGER_INTERVAL)
		_spawn_timer.timeout.connect(_spawn_one_enemy)
	else:
		_spawning_in_progress = false


func _get_fighter_ratio(wave_index: int) -> float:
	## Returns fraction of enemies that should be Fighters for this wave.
	## Waves 0-1: all runners. Then linearly increases, capping at 50%.
	if wave_index < 2:
		return 0.0
	return clampf((wave_index - 1) * 0.1, 0.0, 0.5)


func _cancel_spawn_queue() -> void:
	if _spawning_in_progress and _spawn_queue_remaining > 0:
		_active_enemies -= _spawn_queue_remaining
		_spawn_queue_remaining = 0
		_spawning_in_progress = false
		if _spawn_timer and _spawn_timer.timeout.is_connected(_spawn_one_enemy):
			_spawn_timer.timeout.disconnect(_spawn_one_enemy)


func _begin_prep_phase() -> void:
	if _all_waves_done or _map_ended:
		return
	if _current_wave >= _wave_definitions.size():
		_all_waves_done = true
		print("WaveSpawner: All waves completed!")
		return
	_prep_timer = get_tree().create_timer(BETWEEN_WAVE_DELAY)
	_prep_timer.timeout.connect(_arm_dual_triggers)


func _arm_dual_triggers() -> void:
	if _all_waves_done or _map_ended:
		return
	_waiting_for_trigger = true
	_tiles_since_last_wave = 0
	_max_wait_timer = get_tree().create_timer(MAX_WAVE_WAIT)
	_max_wait_timer.timeout.connect(_trigger_next_wave)
	print("WaveSpawner: Triggers armed — %d tiles or %.0fs." % [TILES_PER_WAVE, MAX_WAVE_WAIT])


func _trigger_next_wave() -> void:
	if not _waiting_for_trigger:
		return
	_waiting_for_trigger = false
	if _max_wait_timer and _max_wait_timer.timeout.is_connected(_trigger_next_wave):
		_max_wait_timer.timeout.disconnect(_trigger_next_wave)
	_start_next_wave()


func _collect_forward_spawn_points() -> Array[SpawnPoint]:
	var result: Array[SpawnPoint] = []
	if not trojan_horse or not map_manager:
		return result
	var current_tile := trojan_horse.get_current_tile()
	if not current_tile:
		return result
	var exit_edge := trojan_horse.get_exit_edge()
	var ahead_tiles := map_manager.get_tiles_ahead(current_tile, exit_edge, LOOKAHEAD_TILES)
	var ahead_set: Dictionary = {}
	for tile: MapTile in ahead_tiles:
		ahead_set[tile] = true
	for node: Node in get_tree().get_nodes_in_group("spawn_points"):
		var sp := node as SpawnPoint
		if not sp:
			continue
		var parent_tile := sp.get_parent() as MapTile
		if parent_tile and ahead_set.has(parent_tile):
			result.append(sp)
	return result


# --- Public methods ---
func get_debug_info() -> Dictionary:
	## Returns wave state for the debug HUD.
	var state: String = "IDLE"
	var detail: String = ""

	if _map_ended:
		state = "MAP ENDED"
	elif _all_waves_done:
		state = "COMPLETE"
	elif _initial_timer and _initial_timer.time_left > 0.0:
		state = "INITIAL"
		detail = "%.1fs" % _initial_timer.time_left
	elif _spawning_in_progress:
		state = "SPAWNING"
		var total: int = _wave_definitions[_current_wave - 1] if _current_wave > 0 else 0
		detail = "%d/%d" % [total - _spawn_queue_remaining, total]
	elif _prep_timer and _prep_timer.time_left > 0.0:
		state = "PREP"
		detail = "%.1fs" % _prep_timer.time_left
	elif _waiting_for_trigger:
		state = "ARMED"
		detail = "%d/%d tiles" % [_tiles_since_last_wave, TILES_PER_WAVE]
	elif _active_enemies > 0:
		state = "ACTIVE"

	var trigger_time: float = 0.0
	if _max_wait_timer and _max_wait_timer.time_left > 0.0:
		trigger_time = _max_wait_timer.time_left

	return {
		"wave": _current_wave,
		"total_waves": _wave_definitions.size(),
		"state": state,
		"detail": detail,
		"active_enemies": _active_enemies,
		"spawn_queue": _spawn_queue_remaining,
		"tiles_since_wave": _tiles_since_last_wave,
		"tiles_needed": TILES_PER_WAVE,
		"trigger_time_left": trigger_time,
	}


# --- Signal callbacks ---
func _on_enemy_killed() -> void:
	_active_enemies -= 1
	print("WaveSpawner: Enemy killed. Remaining: %d." % _active_enemies)
	if _active_enemies <= 0 and not _spawning_in_progress and not _all_waves_done:
		EventBus.wave_completed.emit(_current_wave)
		print("WaveSpawner: Wave %d completed." % _current_wave)
		_begin_prep_phase()


func _on_horse_entered_tile(_tile_name: String) -> void:
	if _waiting_for_trigger:
		_tiles_since_last_wave += 1
		if _tiles_since_last_wave >= TILES_PER_WAVE:
			_trigger_next_wave()


func _on_horse_reached_map_end() -> void:
	_map_ended = true
	_cancel_spawn_queue()
