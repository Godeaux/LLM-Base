class_name DebugPathOverlay
extends MeshInstance3D
## Debug visualization for A* pathfinding. Toggle with F3.
## Draws: tile graph edges (green), enemy waypoint paths (red),
## current waypoint markers (yellow), and tile center dots (cyan).


# --- Constants ---
const GRAPH_COLOR := Color(0.2, 0.8, 0.2, 0.6)
const PATH_COLOR := Color(1.0, 0.2, 0.2, 0.9)
const WAYPOINT_COLOR := Color(1.0, 1.0, 0.0, 0.9)
const CENTER_COLOR := Color(0.0, 0.8, 0.8, 0.5)
const DRAW_HEIGHT: float = 0.3  ## Y offset above ground for visibility
const CROSS_SIZE: float = 0.4


# --- Exports ---
@export var map_manager: MapManager


# --- Private variables ---
var _immediate_mesh: ImmediateMesh
var _active: bool = false
var _graph_edges: Array[PackedVector3Array] = []
var _tile_centers: PackedVector3Array = PackedVector3Array()
var _graph_cached: bool = false


# --- Built-in virtual methods ---
func _ready() -> void:
	_immediate_mesh = ImmediateMesh.new()
	mesh = _immediate_mesh
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.no_depth_test = true
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	material_override = mat
	visible = false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_debug_paths"):
		_active = not _active
		visible = _active
		if _active and not _graph_cached:
			_cache_graph()
		get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	if not _active:
		return
	_immediate_mesh.clear_surfaces()
	_draw_graph()
	_draw_tile_centers()
	_draw_enemy_paths()


# --- Private methods ---
func _cache_graph() -> void:
	if not map_manager:
		return
	_graph_edges = map_manager.get_graph_edges()
	_tile_centers = map_manager.get_tile_centers()
	_graph_cached = true


func _draw_graph() -> void:
	if _graph_edges.is_empty():
		return
	_immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	for edge: PackedVector3Array in _graph_edges:
		if edge.size() < 2:
			continue
		_immediate_mesh.surface_set_color(GRAPH_COLOR)
		_immediate_mesh.surface_add_vertex(edge[0])
		_immediate_mesh.surface_set_color(GRAPH_COLOR)
		_immediate_mesh.surface_add_vertex(edge[1])
	_immediate_mesh.surface_end()


func _draw_tile_centers() -> void:
	if _tile_centers.is_empty():
		return
	_immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	for center: Vector3 in _tile_centers:
		# Draw a small cross at each tile center.
		_immediate_mesh.surface_set_color(CENTER_COLOR)
		_immediate_mesh.surface_add_vertex(center + Vector3(-CROSS_SIZE, 0.0, 0.0))
		_immediate_mesh.surface_set_color(CENTER_COLOR)
		_immediate_mesh.surface_add_vertex(center + Vector3(CROSS_SIZE, 0.0, 0.0))
		_immediate_mesh.surface_set_color(CENTER_COLOR)
		_immediate_mesh.surface_add_vertex(center + Vector3(0.0, 0.0, -CROSS_SIZE))
		_immediate_mesh.surface_set_color(CENTER_COLOR)
		_immediate_mesh.surface_add_vertex(center + Vector3(0.0, 0.0, CROSS_SIZE))
	_immediate_mesh.surface_end()


func _draw_enemy_paths() -> void:
	var enemies := get_tree().get_nodes_in_group("enemies")
	if enemies.is_empty():
		return

	# Draw path lines.
	_immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	for node: Node in enemies:
		var enemy := node as Enemy
		if not enemy:
			continue
		var waypoints: PackedVector3Array = enemy.get_current_waypoints()
		var wp_index: int = enemy.get_waypoint_index()
		if waypoints.is_empty():
			continue

		# Line from enemy to current waypoint.
		var enemy_pos: Vector3 = enemy.global_position
		enemy_pos.y = DRAW_HEIGHT
		if wp_index < waypoints.size():
			var wp: Vector3 = waypoints[wp_index]
			wp.y = DRAW_HEIGHT
			_immediate_mesh.surface_set_color(PATH_COLOR)
			_immediate_mesh.surface_add_vertex(enemy_pos)
			_immediate_mesh.surface_set_color(PATH_COLOR)
			_immediate_mesh.surface_add_vertex(wp)

		# Lines between remaining waypoints.
		for i: int in range(wp_index, waypoints.size() - 1):
			var from: Vector3 = waypoints[i]
			var to: Vector3 = waypoints[i + 1]
			from.y = DRAW_HEIGHT
			to.y = DRAW_HEIGHT
			_immediate_mesh.surface_set_color(PATH_COLOR)
			_immediate_mesh.surface_add_vertex(from)
			_immediate_mesh.surface_set_color(PATH_COLOR)
			_immediate_mesh.surface_add_vertex(to)
	_immediate_mesh.surface_end()

	# Draw waypoint markers.
	_immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	for node: Node in enemies:
		var enemy := node as Enemy
		if not enemy:
			continue
		var waypoints: PackedVector3Array = enemy.get_current_waypoints()
		var wp_index: int = enemy.get_waypoint_index()
		for i: int in range(wp_index, waypoints.size()):
			var wp: Vector3 = waypoints[i]
			wp.y = DRAW_HEIGHT
			# Small cross at each waypoint.
			_immediate_mesh.surface_set_color(WAYPOINT_COLOR)
			_immediate_mesh.surface_add_vertex(wp + Vector3(-CROSS_SIZE, 0.0, 0.0))
			_immediate_mesh.surface_set_color(WAYPOINT_COLOR)
			_immediate_mesh.surface_add_vertex(wp + Vector3(CROSS_SIZE, 0.0, 0.0))
			_immediate_mesh.surface_set_color(WAYPOINT_COLOR)
			_immediate_mesh.surface_add_vertex(wp + Vector3(0.0, 0.0, -CROSS_SIZE))
			_immediate_mesh.surface_set_color(WAYPOINT_COLOR)
			_immediate_mesh.surface_add_vertex(wp + Vector3(0.0, 0.0, CROSS_SIZE))
	_immediate_mesh.surface_end()
