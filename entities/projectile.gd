class_name Projectile
extends Node3D
## A slow-traveling projectile that deals damage on arrival.
## Spawned by ranged minions. Tracks target position, applies damage + knockback on hit.


# --- Constants ---
const ARRIVAL_DISTANCE: float = 0.3


# --- Public variables ---
var target_node: Node3D = null
var damage: float = 25.0
var speed: float = 12.0
var knockback_force: float = 8.0
var shooter: Node3D = null


# --- Private variables ---
var _last_known_pos: Vector3 = Vector3.ZERO
var _target_lost: bool = false


# --- Built-in virtual methods ---
func _ready() -> void:
	if target_node and is_instance_valid(target_node):
		_last_known_pos = target_node.global_position


func _process(delta: float) -> void:
	# Update target position if still alive
	if target_node and is_instance_valid(target_node) and not _target_lost:
		_last_known_pos = target_node.global_position
	else:
		_target_lost = true

	# Move toward target
	var direction := _last_known_pos - global_position
	direction.y = 0.0
	var dist := direction.length()

	if dist < ARRIVAL_DISTANCE:
		_on_arrival()
		return

	direction /= dist
	global_position += direction * speed * delta


func _on_arrival() -> void:
	if not _target_lost and target_node and is_instance_valid(target_node):
		var health := target_node.get_node_or_null("HealthComponent") as HealthComponent
		if health:
			health.take_damage_from(damage, shooter)
		if target_node.has_method("apply_knockback") and shooter:
			var kb_dir := target_node.global_position - global_position
			target_node.apply_knockback(kb_dir, knockback_force)
	queue_free()
