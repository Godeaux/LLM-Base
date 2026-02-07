class_name WaveSpawner
extends Node
## Spawns enemies in waves. Next wave starts after current wave is cleared.


# --- Constants ---
const ENEMY_SCENE: PackedScene = preload("res://Enemy.tscn")
const SPAWN_HEIGHT: float = 5.0
const INITIAL_DELAY: float = 3.0
const BETWEEN_WAVE_DELAY: float = 5.0
const EAST_OFFSET_MIN: float = 20.0
const EAST_OFFSET_MAX: float = 40.0
const PERP_OFFSET_MAX: float = 4.0


# --- Exports ---
@export var trojan_horse: TrojanHorse


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

	var positions := _compute_spawn_positions(enemy_count)
	for pos: Vector3 in positions:
		var enemy: Enemy = ENEMY_SCENE.instantiate() as Enemy
		add_child(enemy)
		enemy.global_position = pos


func _compute_spawn_positions(count: int) -> Array[Vector3]:
	var positions: Array[Vector3] = []
	var base_pos := Vector3.ZERO
	if trojan_horse:
		base_pos = trojan_horse.global_position
	for i: int in count:
		var east_offset := randf_range(EAST_OFFSET_MIN, EAST_OFFSET_MAX)
		var perp_offset := randf_range(-PERP_OFFSET_MAX, PERP_OFFSET_MAX)
		positions.append(Vector3(
			base_pos.x + east_offset,
			SPAWN_HEIGHT,
			base_pos.z + perp_offset,
		))
	return positions


func _on_enemy_killed() -> void:
	_active_enemies -= 1
	print("WaveSpawner: Enemy killed. Remaining: %d." % _active_enemies)
	if _active_enemies <= 0 and not _all_waves_done:
		EventBus.wave_completed.emit(_current_wave)
		print("WaveSpawner: Wave %d completed." % _current_wave)
		get_tree().create_timer(BETWEEN_WAVE_DELAY).timeout.connect(_start_next_wave)
