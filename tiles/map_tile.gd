@tool
class_name MapTile
extends Node3D
## Runtime tile placed in the map grid. Routes are auto-discovered
## from Path3D children named "Route_X_Y" (e.g., Route_S_N, Route_W_E).
## Reverse routes are generated automatically for bidirectional traversal.
## In-editor: shows N/E/S/W labels at tile edges for orientation.


# --- Constants ---
const _EDGE_WARN_TOLERANCE: float = 1.0

# --- Exports ---
@export var tile_name: String = ""

# --- Public variables ---
var grid_position: Vector2i = Vector2i.ZERO
var open_edges: Array[TileDefs.Edge] = []
var routes: Array[TileRoute] = []


# --- Built-in virtual methods ---
func _ready() -> void:
	_build_routes_from_paths()
	if Engine.is_editor_hint():
		_add_edge_labels()


# --- Public methods ---
func get_routes_from_edge(entry: TileDefs.Edge) -> Array[TileRoute]:
	var result: Array[TileRoute] = []
	for route: TileRoute in routes:
		if route.entry_edge == entry:
			result.append(route)
	return result


# --- Private methods ---
func _build_routes_from_paths() -> void:
	var edge_set: Dictionary = {}
	for child: Node in get_children():
		if not (child is Path3D):
			continue
		var child_name := String(child.name)
		if not child_name.begins_with("Route_"):
			continue
		var parts := child_name.split("_")
		if parts.size() < 3:
			push_warning("MapTile: invalid route name '%s' — expected Route_X_Y." % child_name)
			continue
		var entry_val := TileDefs.edge_from_initial(parts[1])
		var exit_val := TileDefs.edge_from_initial(parts[2])
		if entry_val < 0 or exit_val < 0:
			push_warning("MapTile: unknown edge in '%s'." % child_name)
			continue
		var path_curve: Curve3D = (child as Path3D).curve
		if not path_curve or path_curve.point_count < 2:
			push_warning("MapTile: route '%s' has no valid curve." % child_name)
			continue
		## Forward route.
		var forward := TileRoute.new()
		forward.entry_edge = entry_val as TileDefs.Edge
		forward.exit_edge = exit_val as TileDefs.Edge
		forward.curve = path_curve
		forward.path_transform = (child as Path3D).transform
		forward.reversed = false
		routes.append(forward)
		_validate_route_endpoints(child_name, forward.path_transform, path_curve, entry_val, exit_val)
		edge_set[entry_val] = true
		edge_set[exit_val] = true
		## Auto-generated reverse route.
		var reverse := TileRoute.new()
		reverse.entry_edge = exit_val as TileDefs.Edge
		reverse.exit_edge = entry_val as TileDefs.Edge
		reverse.curve = path_curve
		reverse.path_transform = (child as Path3D).transform
		reverse.reversed = true
		routes.append(reverse)
	for edge_key: int in edge_set:
		open_edges.append(edge_key as TileDefs.Edge)


func _validate_route_endpoints(route_name: String, path_xform: Transform3D,
		curve: Curve3D, entry_edge: int, exit_edge: int) -> void:
	var curve_start: Vector3 = path_xform * curve.sample_baked(0.0)
	var curve_end: Vector3 = path_xform * curve.sample_baked(curve.get_baked_length())
	var expected_entry: Vector3 = TileDefs.EDGE_POSITIONS[entry_edge]
	var expected_exit: Vector3 = TileDefs.EDGE_POSITIONS[exit_edge]
	## Compare XZ only — Y is intentionally raised for visibility.
	var start_xz := Vector2(curve_start.x, curve_start.z)
	var entry_xz := Vector2(expected_entry.x, expected_entry.z)
	var end_xz := Vector2(curve_end.x, curve_end.z)
	var exit_xz := Vector2(expected_exit.x, expected_exit.z)
	var start_dist := start_xz.distance_to(entry_xz)
	var end_dist := end_xz.distance_to(exit_xz)
	if start_dist > _EDGE_WARN_TOLERANCE:
		push_warning("MapTile '%s': %s start at (%.1f, %.1f) is %.1f units from %s edge (%.1f, %.1f)." % [
			tile_name, route_name, curve_start.x, curve_start.z,
			start_dist, TileDefs.Edge.keys()[entry_edge],
			expected_entry.x, expected_entry.z])
	if end_dist > _EDGE_WARN_TOLERANCE:
		push_warning("MapTile '%s': %s end at (%.1f, %.1f) is %.1f units from %s edge (%.1f, %.1f)." % [
			tile_name, route_name, curve_end.x, curve_end.z,
			end_dist, TileDefs.Edge.keys()[exit_edge],
			expected_exit.x, expected_exit.z])


func _add_edge_labels() -> void:
	for edge: int in TileDefs.EDGE_POSITIONS:
		var label := Label3D.new()
		label.text = TileDefs.Edge.keys()[edge].substr(0, 1)
		label.position = TileDefs.EDGE_POSITIONS[edge] + Vector3(0.0, 1.0, 0.0)
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.font_size = 48
		label.modulate = Color.YELLOW
		label.no_depth_test = true
		add_child(label, false, Node.INTERNAL_MODE_BACK)
