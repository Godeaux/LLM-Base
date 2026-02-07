extends Node3D
## Root scene for Trojan Horse.
## Manages the game level and coordinates top-level systems.


# --- Onready variables ---
@onready var _map_manager: MapManager = $MapManager
@onready var _trojan_horse: TrojanHorse = $TrojanHorse
@onready var _wizard: Wizard = $Wizard
@onready var _wave_spawner: WaveSpawner = $WaveSpawner


# --- Built-in virtual methods ---
func _ready() -> void:
	print("Trojan Horse — procedural map generation.")
	_map_manager.generate_map({
		"columns": 50,
		"primary_dir": TileDefs.Edge.EAST,
		"wander_budget": 3,
		"wander_chance": 0.35,
		"fork_interval": 8,
		"fork_merge_offset": 4,
		"seed": 0,
	})
	var start_tile := _map_manager.get_start_tile()
	_wizard.global_position = start_tile.global_position + Vector3(0.0, 0.68, 0.0)
	_trojan_horse.initialize(_map_manager)
	_trojan_horse.start_route(start_tile, _map_manager.get_start_route())
	_wave_spawner.trojan_horse = _trojan_horse
