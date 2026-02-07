class_name TileRoute
extends RefCounted
## A single traversable path through a tile, from one edge to another.
## Built at runtime from Path3D children in the tile scene.


# --- Public variables ---
var entry_edge: TileDefs.Edge
var exit_edge: TileDefs.Edge
var curve: Curve3D
var reversed: bool = false  ## If true, sample curve from end to start.
var path_transform: Transform3D = Transform3D.IDENTITY  ## Path3D's local transform within the tile.
