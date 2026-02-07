extends Node3D
## Root scene for Trojan Horse.
## Manages the game level and coordinates top-level systems.


# --- Onready variables ---
@onready var _map_manager: MapManager = $MapManager
@onready var _trojan_horse: TrojanHorse = $TrojanHorse
@onready var _wizard: Wizard = $Wizard


# --- Built-in virtual methods ---
func _ready() -> void:
	print("Trojan Horse — tile-based map system.")
	_map_manager.build_test_map()
	var start_tile := _map_manager.get_start_tile()
	_wizard.global_position = start_tile.global_position + Vector3(0.0, 0.68, 0.0)
	_trojan_horse.initialize(_map_manager)
	_trojan_horse.start_route(start_tile, _map_manager.get_start_route())
