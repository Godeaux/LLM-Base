class_name EnemyTypeData
extends Resource
## Data-driven stats for an enemy type. Create .tres files per archetype.


# --- Exports ---
@export_group("General")
@export var type_name: String = "Runner"
@export var body_color: Color = Color(0.9, 0.2, 0.2)
@export var halo_color_full: Color = Color(0.895, 1.0, 0.283, 1.0)
@export var halo_color_dead: Color = Color(0.373, 0.0, 0.004, 1.0)

@export_group("Stats")
@export var max_health: float = 50.0
@export var move_speed: float = 3.0
@export var detection_range: float = 15.0

@export_group("Combat")
@export var attack_damage: float = 5.0
@export var attack_interval: float = 1.5
@export var attack_range: float = 2.0
@export var knockback_decay: float = 5.0
@export_range(0.0, 1.0) var knockback_multiplier: float = 1.0  ## Fraction of incoming knockback force applied. Lower = more resistant.

@export_group("Visual")
@export var body_scale: Vector3 = Vector3(1.0, 1.0, 1.0)

@export_group("Behavior")
@export_enum("RUNNER", "FIGHTER") var archetype: String = "RUNNER"
@export var stun_duration: float = 1.5  ## RUNNER only: forced aggro time after being hit by a minion.
