class_name IsometricCamera
extends Camera3D
## Fixed isometric camera that smoothly follows between wizard and Trojan Horse.
## When both targets exist, follows the midpoint. Biases toward horse if wizard is far.


# --- Exports ---
@export var target_path: NodePath
@export var secondary_target_path: NodePath
@export var follow_speed: float = 5.0
@export var offset: Vector3 = Vector3(10.0, 10.0, 10.0)
@export var max_wizard_distance: float = 15.0

# --- Private variables ---
var _target: Node3D
var _secondary_target: Node3D


# --- Built-in virtual methods ---
func _ready() -> void:
	if target_path:
		_target = get_node(target_path) as Node3D
	if secondary_target_path:
		_secondary_target = get_node(secondary_target_path) as Node3D


func _process(delta: float) -> void:
	if not _target:
		return
	var focus_point := _target.global_position
	if _secondary_target:
		var midpoint := (_target.global_position + _secondary_target.global_position) * 0.5
		var distance := _target.global_position.distance_to(_secondary_target.global_position)
		var bias := clampf(distance / max_wizard_distance, 0.0, 1.0)
		focus_point = midpoint.lerp(_secondary_target.global_position, bias * 0.5)
	var target_pos := focus_point + offset
	global_position = global_position.lerp(target_pos, follow_speed * delta)
