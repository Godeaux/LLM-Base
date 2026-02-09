class_name WaveSpawner
extends Node
## Spawns enemies in waves at SpawnPoint markers placed on tiles ahead of the
## Trojan Horse. Next wave starts after current wave is cleared.


# --- Constants ---
const ENEMY_SCENE: PackedScene = preload("res://entities/Enemy.tscn")
const INITIAL_DELAY: float = 3.0
const BETWEEN_WAVE_DELAY: float = 5.0
const LOOKAHEAD_TILES: int = 6
const SPAWN_JITTER: float = 1.0


# --- Exports ---
@export var trojan_horse: TrojanHorse
@export var map_manager: MapManager


# --- Private variables ---
var _wave_definitions: Array[int] = [3, 5, 8]
var _current_wave: int = 0
var _active_enemies: int = 0
var _all_waves_done: bool = false


# --- Built-in virtual methods ---
func _ready() -> void:
	EventBus.enemy_killed.connect(_on_enemy_killed)
	get_tree().create_timer(INITIAL_DELAY).timeout.connect(_start_next_wave)


# --- Private methods ---
func _start_next_wave() -> void:
	if _current_wave >= _wave_definitions.size():
		_all_waves_done = true
		print("WaveSpawner: All waves completed!")
		return
	var enemy_count: int = _wave_definitions[_current_wave]
	_current_wave += 1
	_active_enemies = enemy_count
	EventBus.wave_started.emit(_current_wave, enemy_count)
	print("WaveSpawner: Wave %d — spawning %d enemies." % [_current_wave, enemy_count])

	var spawn_points := _collect_forward_spawn_points()
	if spawn_points.is_empty():
		push_warning("WaveSpawner: no spawn points found ahead of horse.")
		return
	for i: int in enemy_count:
		var sp: SpawnPoint = spawn_points.pick_random()
		var pos := sp.global_position
		pos.x += randf_range(-SPAWN_JITTER, SPAWN_JITTER)
		pos.z += randf_range(-SPAWN_JITTER, SPAWN_JITTER)
		pos.y = 0.0
		var enemy: Enemy = ENEMY_SCENE.instantiate() as Enemy
		add_child(enemy)
		enemy.global_position = pos
		enemy.set_map_manager(map_manager)
		enemy.emerge()


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


func _on_enemy_killed() -> void:
	_active_enemies -= 1
	print("WaveSpawner: Enemy killed. Remaining: %d." % _active_enemies)
	if _active_enemies <= 0 and not _all_waves_done:
		EventBus.wave_completed.emit(_current_wave)
		print("WaveSpawner: Wave %d completed." % _current_wave)
		get_tree().create_timer(BETWEEN_WAVE_DELAY).timeout.connect(_start_next_wave)
