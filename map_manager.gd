class_name MapManager
extends Node3D
## Manages the tile grid. Places tiles, validates connections,
## and provides route queries for the Trojan Horse.


# --- Constants ---
const TILE_SIZE: float = TileDefs.TILE_SIZE
const STRAIGHT_NS: PackedScene = preload("res://tiles/StraightNS.tscn")
const STRAIGHT_EW: PackedScene = preload("res://tiles/StraightEW.tscn")
const CURVE_SE: PackedScene = preload("res://tiles/CurveSE.tscn")
const CURVE_SW: PackedScene = preload("res://tiles/CurveSW.tscn")
const FORK_WNE: PackedScene = preload("res://tiles/ForkWNE.tscn")

# --- Private variables ---
var _grid: Dictionary = {}  ## Dictionary[Vector2i, MapTile]
var _start_tile: MapTile
var _start_entry_edge: TileDefs.Edge


# --- Public methods ---
func build_test_map() -> void:
	## Test layout (horse enters from south, goes north, curves east, forks):
	##
	##   (0,2) StraightNS  →  horse enters S, exits N
	##     ↑
	##   (0,1) CurveSE     →  enters S, exits E
	##            →
	##          (1,1) StraightEW  →  enters W, exits E
	##                    →
	##                  (2,1) ForkWNE  →  enters W, exits N or E
	##                    ↑               →
	##                  (2,0) StraightNS  (3,1) CurveSW
	##                  (dead end)            ↓
	##                                    (3,2) StraightNS
	##                                    (dead end)
	_place(Vector2i(0, 2), STRAIGHT_NS)
	_place(Vector2i(0, 1), CURVE_SE)
	_place(Vector2i(1, 1), STRAIGHT_EW)
	_place(Vector2i(2, 1), FORK_WNE)
	_place(Vector2i(2, 0), STRAIGHT_NS)
	_place(Vector2i(3, 1), CURVE_SW)
	_place(Vector2i(3, 2), STRAIGHT_NS)

	_start_tile = _grid[Vector2i(0, 2)]
	_start_entry_edge = TileDefs.Edge.SOUTH
	_validate_connections()
	print("MapManager: test map built — %d tiles." % _grid.size())


func get_start_tile() -> MapTile:
	return _start_tile


func get_start_route() -> TileRoute:
	var routes := _start_tile.get_routes_from_edge(_start_entry_edge)
	if routes.is_empty():
		push_error("MapManager: no route from %s on start tile." %
			TileDefs.Edge.keys()[_start_entry_edge])
		return null
	return routes[0]


func get_next_route(current_tile: MapTile, exit_edge: TileDefs.Edge) -> Dictionary:
	## Returns { "tile": MapTile, "route": TileRoute } or empty dict if no neighbor.
	var neighbor_pos := current_tile.grid_position + TileDefs.edge_to_grid_offset(exit_edge)
	var neighbor: MapTile = _grid.get(neighbor_pos)
	if not neighbor:
		return {}
	var entry_edge := TileDefs.opposite_edge(exit_edge)
	var routes := neighbor.get_routes_from_edge(entry_edge)
	if routes.is_empty():
		return {}
	## Pick randomly if multiple routes (fork). Phase 6 will add player choice.
	var chosen: TileRoute = routes.pick_random()
	if routes.size() > 1:
		print("MapManager: fork at %s — picked %s exit." % [
			neighbor.grid_position,
			TileDefs.Edge.keys()[chosen.exit_edge]
		])
	return { "tile": neighbor, "route": chosen }


# --- Private methods ---
func _place(grid_pos: Vector2i, scene: PackedScene) -> MapTile:
	var tile: MapTile = scene.instantiate() as MapTile
	tile.grid_position = grid_pos
	tile.position = Vector3(grid_pos.x * TILE_SIZE, 0.0, grid_pos.y * TILE_SIZE)
	tile.name = "%s_%d_%d" % [tile.tile_name, grid_pos.x, grid_pos.y]
	add_child(tile)
	_grid[grid_pos] = tile
	return tile


func _validate_connections() -> void:
	for pos: Vector2i in _grid:
		var tile: MapTile = _grid[pos]
		for edge: TileDefs.Edge in tile.open_edges:
			var neighbor_pos := pos + TileDefs.edge_to_grid_offset(edge)
			var neighbor: MapTile = _grid.get(neighbor_pos)
			if not neighbor:
				push_warning("MapManager: tile %s has open %s edge but no neighbor at %s." % [
					pos, TileDefs.Edge.keys()[edge], neighbor_pos
				])
				continue
			var opposite := TileDefs.opposite_edge(edge)
			if opposite not in neighbor.open_edges:
				push_warning("MapManager: edge mismatch — %s %s vs %s %s." % [
					pos, TileDefs.Edge.keys()[edge],
					neighbor_pos, TileDefs.Edge.keys()[opposite]
				])
