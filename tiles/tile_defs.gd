class_name TileDefs
extends RefCounted
## Shared enums, constants, and helpers for the tile system.
## No per-tile data — that lives on MapTile nodes directly.


# --- Enums ---
enum Edge { NORTH, SOUTH, EAST, WEST }

# --- Constants ---
const TILE_SIZE: float = 10.0

## Edge midpoints in tile-local space (tile centered at origin).
const EDGE_POSITIONS: Dictionary = {
	Edge.NORTH: Vector3(0.0, 0.0, -5.0),
	Edge.SOUTH: Vector3(0.0, 0.0, 5.0),
	Edge.EAST: Vector3(5.0, 0.0, 0.0),
	Edge.WEST: Vector3(-5.0, 0.0, 0.0),
}


# --- Static methods ---
static func opposite_edge(edge: Edge) -> Edge:
	match edge:
		Edge.NORTH:
			return Edge.SOUTH
		Edge.SOUTH:
			return Edge.NORTH
		Edge.EAST:
			return Edge.WEST
		Edge.WEST:
			return Edge.EAST
	return Edge.NORTH


static func edge_to_grid_offset(edge: Edge) -> Vector2i:
	match edge:
		Edge.NORTH:
			return Vector2i(0, -1)
		Edge.SOUTH:
			return Vector2i(0, 1)
		Edge.EAST:
			return Vector2i(1, 0)
		Edge.WEST:
			return Vector2i(-1, 0)
	return Vector2i.ZERO


static func perpendicular_edges(primary: Edge) -> Array[Edge]:
	## Returns the two edges perpendicular to the given direction.
	match primary:
		Edge.EAST, Edge.WEST:
			return [Edge.NORTH, Edge.SOUTH]
		Edge.NORTH, Edge.SOUTH:
			return [Edge.EAST, Edge.WEST]
	return []


static func edge_from_initial(initial: String) -> int:
	## Returns Edge value from single-letter initial, or -1 if invalid.
	match initial:
		"N":
			return Edge.NORTH
		"S":
			return Edge.SOUTH
		"E":
			return Edge.EAST
		"W":
			return Edge.WEST
	return -1
