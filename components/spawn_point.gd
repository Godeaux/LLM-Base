@tool
class_name SpawnPoint
extends Marker3D
## Editor-visible enemy spawn marker. Place as a child of a MapTile scene.
## WaveSpawner collects these from tiles ahead of the horse to spawn enemies.


# --- Constants ---
const DEBUG_RADIUS: float = 0.4


# --- Built-in virtual methods ---
func _ready() -> void:
	add_to_group("spawn_points")
	if Engine.is_editor_hint():
		_add_debug_visual()


# --- Private methods ---
func _add_debug_visual() -> void:
	var mesh_instance := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = DEBUG_RADIUS
	sphere.height = DEBUG_RADIUS * 2.0
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(1.0, 0.9, 0.1, 0.6)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.no_depth_test = true
	sphere.material = material
	mesh_instance.mesh = sphere
	add_child(mesh_instance, false, Node.INTERNAL_MODE_BACK)
