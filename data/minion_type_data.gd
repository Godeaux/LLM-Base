class_name MinionTypeData
extends Resource
## Data-driven stats for a minion type. Create .tres files per type.


# --- Exports ---
@export_group("General")
@export var type_name: String = "Basic"
@export var color: Color = Color(0.3, 0.5, 1.0)

@export_group("Stats")
@export var max_health: float = 30.0
@export var move_speed: float = 4.0
@export var leash_radius: float = 15.0

@export_group("Combat")
@export var attack_damage: float = 50.0
@export var attack_interval: float = 1.2
@export var attack_range: float = 0.9
@export var aggro_radius: float = 8.0  ## Detection range for acquiring targets (separate from melee range)
@export var knockback_force: float = 5.0
