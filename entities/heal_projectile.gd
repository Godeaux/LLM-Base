class_name HealProjectile
extends Node3D
## A traveling green heal bolt that restores health on arrival.
## Spawned by healer minions. Tracks target, heals on hit, bursts on arrival.


# --- Constants ---
const ARRIVAL_DISTANCE: float = 0.5


# --- Public variables ---
var target_node: Node3D = null
var heal_amount: float = 5.0
var speed: float = 10.0


# --- Private variables ---
var _last_known_pos: Vector3 = Vector3.ZERO
var _target_lost: bool = false


# --- Built-in virtual methods ---
func _ready() -> void:
	if target_node and is_instance_valid(target_node):
		_last_known_pos = target_node.global_position


func _process(delta: float) -> void:
	if target_node and is_instance_valid(target_node) and not _target_lost:
		_last_known_pos = target_node.global_position
	else:
		_target_lost = true

	var direction := _last_known_pos - global_position
	direction.y = 0.0
	var dist := direction.length()

	if dist < ARRIVAL_DISTANCE:
		_on_arrival()
		return

	direction /= dist
	global_position += direction * speed * delta


# --- Private methods ---
func _on_arrival() -> void:
	if not _target_lost and target_node and is_instance_valid(target_node):
		var health := target_node.get_node_or_null("HealthComponent") as HealthComponent
		if health:
			health.heal(heal_amount)
	_spawn_arrival_effect()
	queue_free()


func _spawn_arrival_effect() -> void:
	var glow := MeshInstance3D.new()
	var glow_mesh := SphereMesh.new()
	glow_mesh.radius = 0.08
	glow_mesh.height = 0.16
	var glow_mat := StandardMaterial3D.new()
	glow_mat.albedo_color = Color(0.3, 1.0, 0.4, 0.8)
	glow_mat.emission_enabled = true
	glow_mat.emission = Color(0.3, 1.0, 0.4)
	glow_mat.emission_energy_multiplier = 2.5
	glow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glow_mesh.material = glow_mat
	glow.mesh = glow_mesh
	get_tree().current_scene.add_child(glow)
	glow.global_position = _last_known_pos + Vector3(0.0, 0.5, 0.0)

	var tween := get_tree().create_tween()
	tween.tween_property(glow, "scale", Vector3(5.0, 5.0, 5.0), 0.3)
	tween.parallel().tween_property(glow_mat, "albedo_color:a", 0.0, 0.3)
	tween.tween_callback(glow.queue_free)
