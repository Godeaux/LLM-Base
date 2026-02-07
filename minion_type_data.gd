class_name MinionTypeData
extends Resource
## Data-driven stats for a minion type. Create .tres files per type.


# --- Exports ---
@export var type_name: String = "Basic"
@export var max_health: float = 30.0
@export var move_speed: float = 4.0
@export var attack_damage: float = 8.0
@export var attack_interval: float = 1.2
@export var attack_range: float = 2.5
@export var leash_radius: float = 15.0
@export var color: Color = Color(0.3, 0.5, 1.0)
