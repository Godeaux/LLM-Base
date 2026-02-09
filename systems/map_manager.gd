class_name MapManager
extends Node3D
## Manages the tile grid. Places tiles, validates connections,
## and provides route queries for the Trojan Horse.
## Supports procedural map generation with directional bias.


# --- Constants ---
const TILE_SIZE: float = TileDefs.TILE_SIZE
const STRAIGHT_NS: PackedScene = preload("res://tiles/StraightNS.tscn")
const STRAIGHT_EW: PackedScene = preload("res://tiles/StraightEW.tscn")
const CURVE_SE: PackedScene = preload("res://tiles/CurveSE.tscn")
const CURVE_SW: PackedScene = preload("res://tiles/CurveSW.tscn")
const CURVE_NE: PackedScene = preload("res://tiles/CurveNE.tscn")
const CURVE_NW: PackedScene = preload("res://tiles/CurveNW.tscn")
const FORK_WNE: PackedScene = preload("res://tiles/ForkWNE.tscn")
const FORK_WSE: PackedScene = preload("res://tiles/ForkWSE.tscn")

# --- Private variables ---
var _grid: Dictionary = {}  ## Dictionary[Vector2i, MapTile]
var _start_tile: MapTile
var _start_entry_edge: TileDefs.Edge
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _astar: AStar2D = AStar2D.new()
var _grid_to_astar_id: Dictionary = {}  ## Dictionary[Vector2i, int]
var _next_astar_id: int = 0

## Tile lookup: keyed by entry_edge * 4 + exit_edge → PackedScene.
var _tile_lookup: Dictionary = {}


# --- Built-in virtual methods ---
func _ready() -> void:
	_build_tile_lookup()


# --- Public methods ---
func generate_map(config: Dictionary) -> void:
	## Procedurally generates a map with directional bias.
	## Config keys: columns, primary_dir, wander_budget, wander_chance,
	## fork_interval, fork_merge_offset, seed.
	var columns: int = config.get("columns", 50)
	var primary_dir: TileDefs.Edge = config.get("primary_dir", TileDefs.Edge.EAST)
	var wander_budget: int = config.get("wander_budget", 3)
	var wander_chance: float = config.get("wander_chance", 0.35)
	var fork_interval: int = config.get("fork_interval", 8)
	var fork_merge_offset: int = config.get("fork_merge_offset", 4)
	var map_seed: int = config.get("seed", 0)

	if map_seed != 0:
		_rng.seed = map_seed
	else:
		_rng.randomize()

	var perp_dirs: Array[TileDefs.Edge] = TileDefs.perpendicular_edges(primary_dir)
	var cursor := Vector2i(0, 0)
	var entry_edge := TileDefs.opposite_edge(primary_dir)
	var columns_placed := 0
	var wander_count := 0
	var steps_since_fork := 0

	while columns_placed < columns:
		## --- Fork check ---
		if steps_since_fork >= fork_interval and columns_placed > 0 \
				and columns_placed < columns - fork_merge_offset:
			var perp_dir: TileDefs.Edge = perp_dirs[_rng.randi_range(0, 1)]
			if _try_place_fork_block(cursor, entry_edge, primary_dir, perp_dir, fork_merge_offset):
				cursor += TileDefs.edge_to_grid_offset(primary_dir) * fork_merge_offset
				entry_edge = TileDefs.opposite_edge(primary_dir)
				columns_placed += fork_merge_offset
				wander_count = 0
				steps_since_fork = 0
				continue

		## --- Wander or forward ---
		var exit_edge: TileDefs.Edge
		if wander_count < wander_budget and _rng.randf() < wander_chance:
			var perp: TileDefs.Edge = perp_dirs[_rng.randi_range(0, 1)]
			var target := cursor + TileDefs.edge_to_grid_offset(perp)
			if not _grid.has(target):
				exit_edge = perp
				wander_count += 1
			else:
				exit_edge = primary_dir
				columns_placed += 1
				wander_count = 0
		else:
			exit_edge = primary_dir
			columns_placed += 1
			wander_count = 0

		## --- Collision fallback ---
		var next_pos := cursor + TileDefs.edge_to_grid_offset(exit_edge)
		if _grid.has(next_pos):
			exit_edge = primary_dir
			next_pos = cursor + TileDefs.edge_to_grid_offset(primary_dir)
			columns_placed += 1
			wander_count = 0
			if _grid.has(next_pos):
				push_warning("MapManager: generator stuck at %s — ending early." % str(cursor))
				break

		## --- Place and advance ---
		_place(cursor, _tile_for(entry_edge, exit_edge))
		cursor = next_pos
		entry_edge = TileDefs.opposite_edge(exit_edge)
		if exit_edge == primary_dir:
			steps_since_fork += 1

	## Final tile.
	if not _grid.has(cursor):
		_place(cursor, _tile_for(entry_edge, primary_dir))

	_start_tile = _grid[Vector2i(0, 0)]
	_start_entry_edge = TileDefs.opposite_edge(primary_dir)
	_validate_connections()
	_build_astar()
	print("MapManager: generated map — %d tiles, %d columns." % [_grid.size(), columns])


func get_start_tile() -> MapTile:
	return _start_tile


func get_start_route() -> TileRoute:
	var routes := _start_tile.get_routes_from_edge(_start_entry_edge)
	if routes.is_empty():
		push_error("MapManager: no route from %s on start tile." %
			TileDefs.Edge.keys()[_start_entry_edge])
		return null
	return routes[0]


func get_tiles_ahead(from_tile: MapTile, exit_edge: TileDefs.Edge, count: int) -> Array[MapTile]:
	## BFS walk forward from the given tile's exit edge. Returns up to count tiles,
	## following all branches at forks.
	var result: Array[MapTile] = []
	var visited: Dictionary = {}
	visited[from_tile.grid_position] = true
	var queue: Array[Array] = [[from_tile, exit_edge]]
	while not queue.is_empty() and result.size() < count:
		var item: Array = queue.pop_front()
		var tile: MapTile = item[0]
		var edge: TileDefs.Edge = item[1] as TileDefs.Edge
		var neighbor_pos := tile.grid_position + TileDefs.edge_to_grid_offset(edge)
		if visited.has(neighbor_pos):
			continue
		visited[neighbor_pos] = true
		var neighbor: MapTile = _grid.get(neighbor_pos)
		if not neighbor:
			continue
		result.append(neighbor)
		var entry := TileDefs.opposite_edge(edge)
		for route: TileRoute in neighbor.get_routes_from_edge(entry):
			queue.append([neighbor, route.exit_edge])
	return result


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


func world_to_grid(world_pos: Vector3) -> Vector2i:
	## Converts a world position to the nearest grid coordinate.
	return Vector2i(roundi(world_pos.x / TILE_SIZE), roundi(world_pos.z / TILE_SIZE))


func get_tile_at(grid_pos: Vector2i) -> MapTile:
	## Returns the MapTile at the given grid position, or null if none exists.
	return _grid.get(grid_pos) as MapTile


func find_path_waypoints(from_world: Vector3, to_world: Vector3) -> PackedVector3Array:
	## Returns world-space waypoints (tile edge midpoints) from from_world to to_world.
	## Returns empty array if no path exists or both positions are on the same tile.
	var from_grid: Vector2i = world_to_grid(from_world)
	var to_grid: Vector2i = world_to_grid(to_world)

	if from_grid == to_grid:
		return PackedVector3Array()

	if not _grid_to_astar_id.has(from_grid):
		from_grid = _find_nearest_grid(from_world)
		if from_grid == Vector2i(-9999, -9999):
			return PackedVector3Array()
	if not _grid_to_astar_id.has(to_grid):
		to_grid = _find_nearest_grid(to_world)
		if to_grid == Vector2i(-9999, -9999):
			return PackedVector3Array()

	var from_id: int = _grid_to_astar_id[from_grid]
	var to_id: int = _grid_to_astar_id[to_grid]
	var id_path: PackedInt64Array = _astar.get_id_path(from_id, to_id)

	if id_path.is_empty():
		return PackedVector3Array()

	var waypoints: PackedVector3Array = PackedVector3Array()
	for i: int in range(id_path.size() - 1):
		var current_grid: Vector2 = _astar.get_point_position(id_path[i])
		var next_grid: Vector2 = _astar.get_point_position(id_path[i + 1])
		var diff := Vector2i(roundi(next_grid.x - current_grid.x), roundi(next_grid.y - current_grid.y))
		var edge: TileDefs.Edge = _grid_offset_to_edge(diff)
		var tile_center := Vector3(current_grid.x * TILE_SIZE, 0.0, current_grid.y * TILE_SIZE)
		waypoints.append(tile_center + TileDefs.EDGE_POSITIONS[edge])
	return waypoints


func get_graph_edges() -> Array[PackedVector3Array]:
	## Returns all A* graph edges as pairs of world-space positions (for debug drawing).
	var edges: Array[PackedVector3Array] = []
	var visited: Dictionary = {}
	for grid_pos: Vector2i in _grid:
		var tile: MapTile = _grid[grid_pos]
		var from_world := Vector3(grid_pos.x * TILE_SIZE, 0.2, grid_pos.y * TILE_SIZE)
		for edge: TileDefs.Edge in tile.open_edges:
			var neighbor_pos: Vector2i = grid_pos + TileDefs.edge_to_grid_offset(edge)
			var pair_key: int = mini(grid_pos.x * 10000 + grid_pos.y, neighbor_pos.x * 10000 + neighbor_pos.y) * 100000 + maxi(grid_pos.x * 10000 + grid_pos.y, neighbor_pos.x * 10000 + neighbor_pos.y)
			if visited.has(pair_key):
				continue
			visited[pair_key] = true
			if _grid.has(neighbor_pos):
				var to_world := Vector3(neighbor_pos.x * TILE_SIZE, 0.2, neighbor_pos.y * TILE_SIZE)
				var pair: PackedVector3Array = PackedVector3Array([from_world, to_world])
				edges.append(pair)
	return edges


func get_tile_centers() -> PackedVector3Array:
	## Returns world-space centers of all tiles (for debug drawing).
	var centers: PackedVector3Array = PackedVector3Array()
	for grid_pos: Vector2i in _grid:
		centers.append(Vector3(grid_pos.x * TILE_SIZE, 0.2, grid_pos.y * TILE_SIZE))
	return centers


# --- Private methods ---
func _build_tile_lookup() -> void:
	## Maps (entry_edge * 4 + exit_edge) → PackedScene for 2-edge tiles.
	var E := TileDefs.Edge
	_tile_lookup[E.SOUTH * 4 + E.NORTH] = STRAIGHT_NS
	_tile_lookup[E.NORTH * 4 + E.SOUTH] = STRAIGHT_NS
	_tile_lookup[E.WEST * 4 + E.EAST] = STRAIGHT_EW
	_tile_lookup[E.EAST * 4 + E.WEST] = STRAIGHT_EW
	_tile_lookup[E.SOUTH * 4 + E.EAST] = CURVE_SE
	_tile_lookup[E.EAST * 4 + E.SOUTH] = CURVE_SE
	_tile_lookup[E.SOUTH * 4 + E.WEST] = CURVE_SW
	_tile_lookup[E.WEST * 4 + E.SOUTH] = CURVE_SW
	_tile_lookup[E.NORTH * 4 + E.EAST] = CURVE_NE
	_tile_lookup[E.EAST * 4 + E.NORTH] = CURVE_NE
	_tile_lookup[E.NORTH * 4 + E.WEST] = CURVE_NW
	_tile_lookup[E.WEST * 4 + E.NORTH] = CURVE_NW


func _tile_for(entry_edge: TileDefs.Edge, exit_edge: TileDefs.Edge) -> PackedScene:
	var key := int(entry_edge) * 4 + int(exit_edge)
	var scene: PackedScene = _tile_lookup.get(key)
	if not scene:
		push_error("MapManager: no tile for entry=%s exit=%s." % [
			TileDefs.Edge.keys()[entry_edge], TileDefs.Edge.keys()[exit_edge]])
	return scene


func _try_place_fork_block(cursor: Vector2i, entry_edge: TileDefs.Edge,
		primary_dir: TileDefs.Edge, perp_dir: TileDefs.Edge,
		merge_offset: int) -> bool:
	## Attempts to place a fork block with a loop-back branch.
	## Returns true if placed, false if not enough space.
	var fwd_offset := TileDefs.edge_to_grid_offset(primary_dir)
	var perp_offset := TileDefs.edge_to_grid_offset(perp_dir)

	## Collect all positions the fork block needs.
	var positions: Array[Vector2i] = []
	for i: int in range(merge_offset):
		var main_pos := cursor + fwd_offset * i
		var branch_pos := cursor + perp_offset + fwd_offset * i
		positions.append(main_pos)
		positions.append(branch_pos)

	## Check all positions are free.
	for pos: Vector2i in positions:
		if _grid.has(pos):
			return false

	## Determine fork and merge tile types based on perpendicular direction.
	var fork_scene: PackedScene
	var merge_scene: PackedScene
	var branch_entry_curve: PackedScene  ## Curve at branch start (perp → primary).
	var branch_exit_curve: PackedScene   ## Curve at branch end (primary → back to main).
	var opposite_perp := TileDefs.opposite_edge(perp_dir)

	if perp_dir == TileDefs.Edge.NORTH:
		fork_scene = FORK_WNE
		merge_scene = FORK_WNE
		## Branch start: enters from SOUTH (opposite of NORTH), exits EAST.
		branch_entry_curve = _tile_for(opposite_perp, primary_dir)
		## Branch end: enters from WEST, exits SOUTH (back toward main row).
		branch_exit_curve = _tile_for(TileDefs.opposite_edge(primary_dir), opposite_perp)
	else:
		## perp_dir == SOUTH
		fork_scene = FORK_WSE
		merge_scene = FORK_WSE
		branch_entry_curve = _tile_for(opposite_perp, primary_dir)
		branch_exit_curve = _tile_for(TileDefs.opposite_edge(primary_dir), opposite_perp)

	var straight_scene: PackedScene = _tile_for(
		TileDefs.opposite_edge(primary_dir), primary_dir)

	## Place fork tile.
	_place(cursor, fork_scene)

	## Place main row straights (between fork and merge).
	for i: int in range(1, merge_offset - 1):
		_place(cursor + fwd_offset * i, straight_scene)

	## Place merge tile.
	_place(cursor + fwd_offset * (merge_offset - 1), merge_scene)

	## Place branch row.
	var branch_start := cursor + perp_offset
	_place(branch_start, branch_entry_curve)
	for i: int in range(1, merge_offset - 1):
		_place(branch_start + fwd_offset * i, straight_scene)
	_place(branch_start + fwd_offset * (merge_offset - 1), branch_exit_curve)

	return true


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


func _build_astar() -> void:
	## Builds the AStar2D graph from the tile grid.
	_astar.clear()
	_grid_to_astar_id.clear()
	_next_astar_id = 0

	for grid_pos: Vector2i in _grid:
		var id: int = _next_astar_id
		_next_astar_id += 1
		_grid_to_astar_id[grid_pos] = id
		_astar.add_point(id, Vector2(grid_pos.x, grid_pos.y))

	for grid_pos: Vector2i in _grid:
		var tile: MapTile = _grid[grid_pos]
		var from_id: int = _grid_to_astar_id[grid_pos]
		for edge: TileDefs.Edge in tile.open_edges:
			var neighbor_pos: Vector2i = grid_pos + TileDefs.edge_to_grid_offset(edge)
			if _grid_to_astar_id.has(neighbor_pos):
				var to_id: int = _grid_to_astar_id[neighbor_pos]
				if not _astar.are_points_connected(from_id, to_id):
					_astar.connect_points(from_id, to_id)


func _find_nearest_grid(world_pos: Vector3) -> Vector2i:
	## Finds the nearest grid position that exists in the A* graph.
	var best_grid := Vector2i(-9999, -9999)
	var best_dist: float = INF
	var test_grid: Vector2i = world_to_grid(world_pos)
	for dx: int in range(-3, 4):
		for dy: int in range(-3, 4):
			var candidate := test_grid + Vector2i(dx, dy)
			if _grid_to_astar_id.has(candidate):
				var candidate_world := Vector3(candidate.x * TILE_SIZE, 0.0, candidate.y * TILE_SIZE)
				var dist: float = world_pos.distance_squared_to(candidate_world)
				if dist < best_dist:
					best_dist = dist
					best_grid = candidate
	return best_grid


func _grid_offset_to_edge(offset: Vector2i) -> TileDefs.Edge:
	## Converts a grid offset to the corresponding Edge.
	if offset == Vector2i(0, -1):
		return TileDefs.Edge.NORTH
	elif offset == Vector2i(0, 1):
		return TileDefs.Edge.SOUTH
	elif offset == Vector2i(1, 0):
		return TileDefs.Edge.EAST
	return TileDefs.Edge.WEST
