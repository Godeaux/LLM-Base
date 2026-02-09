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

@export_group("Behavior")
@export_enum("MELEE", "RANGED", "HEALER") var behavior_type: String = "MELEE"
@export var preferred_follow_angle: float = -1.0  ## -1 = auto gap algorithm. PI = behind horse.

@export_group("Combat")
@export var attack_damage: float = 10.0
@export var attack_interval: float = 1.2
@export var attack_range: float = 0.9
@export var aggro_radius: float = 8.0  ## Detection range for acquiring targets (separate from melee range)
@export var knockback_force: float = 1.0

@export_group("Ranged")
@export var projectile_speed: float = 12.0
@export var preferred_range: float = 8.0  ## Distance ranged minion tries to maintain from target

@export_group("Healing")
@export var heal_amount: float = 5.0
@export var heal_interval: float = 2.0
@export var heal_range: float = 6.0
