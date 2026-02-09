class_name TrojanHorse
extends Node3D
## The Trojan Horse payload that follows tile-based paths.
## Manually samples Curve3D per tile and transitions between tiles.
## Protect it from enemies — if its health reaches zero, you lose.


# --- Exports ---
@export var move_speed: float = 1.0

# --- Private variables ---
var _health_component: HealthComponent
var _escort_ring: MeshInstance3D
var _map_manager: MapManager
var _current_tile: MapTile
var _current_route: TileRoute
var _curve_offset: float = 0.0
var _active: bool = false


# --- Built-in virtual methods ---
func _ready() -> void:
	add_to_group("trojan_horse")
	_health_component = $HealthComponent as HealthComponent
	_health_component.health_changed.connect(_on_health_changed)
	_health_component.died.connect(_on_died)
	_create_escort_ring()


func _process(delta: float) -> void:
	if not _active or not _current_route:
		return
	var curve: Curve3D = _current_route.curve
	var curve_length := curve.get_baked_length()
	_curve_offset += move_speed * delta
	if _curve_offset >= curve_length:
		_on_route_end()
		return
	## Sample position — reversed routes read the curve backwards.
	var sample_offset := _curve_offset
	if _current_route.reversed:
		sample_offset = curve_length - _curve_offset
	var path_xform: Transform3D = _current_route.path_transform
	var local_pos: Vector3 = path_xform * curve.sample_baked(sample_offset)
	global_position = _current_tile.to_global(local_pos)
	## Face direction of travel using a look-ahead sample.
	var look_ahead := 0.5
	var look_sample: float
	if _current_route.reversed:
		look_sample = maxf(sample_offset - look_ahead, 0.0)
	else:
		look_sample = minf(sample_offset + look_ahead, curve_length)
	var look_pos: Vector3 = _current_tile.to_global(path_xform * curve.sample_baked(look_sample))
	if global_position.distance_to(look_pos) > 0.01:
		look_at(look_pos, Vector3.UP)


# --- Public methods ---
func get_current_tile() -> MapTile:
	return _current_tile


func get_exit_edge() -> TileDefs.Edge:
	if _current_route:
		return _current_route.exit_edge
	return TileDefs.Edge.EAST


func show_escort_ring() -> void:
	if _escort_ring:
		_escort_ring.visible = true


func hide_escort_ring() -> void:
	if _escort_ring:
		_escort_ring.visible = false


func initialize(manager: MapManager) -> void:
	_map_manager = manager


func start_route(tile: MapTile, route: TileRoute) -> void:
	_current_tile = tile
	_current_route = route
	_curve_offset = 0.0
	_active = true
	## Snap to route start position.
	var start_sample := 0.0
	if route.reversed:
		start_sample = route.curve.get_baked_length()
	global_position = _current_tile.to_global(route.path_transform * route.curve.sample_baked(start_sample))
	EventBus.horse_entered_tile.emit(tile.tile_name)
	print("Horse: entered tile %s at %s." % [tile.tile_name, tile.grid_position])


# --- Private methods ---
func _on_route_end() -> void:
	var next := _map_manager.get_next_route(_current_tile, _current_route.exit_edge)
	if next.is_empty():
		_active = false
		EventBus.horse_reached_map_end.emit()
		print("Horse: reached end of map!")
		return
	start_route(next["tile"] as MapTile, next["route"] as TileRoute)


func _create_escort_ring() -> void:
	_escort_ring = MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = MinionManager.ESCORT_RADIUS - 0.05
	torus.outer_radius = MinionManager.ESCORT_RADIUS + 0.05
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.8, 0.8, 0.0, 0.4)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	torus.material = material
	_escort_ring.mesh = torus
	_escort_ring.visible = false
	add_child(_escort_ring)


# --- Signal callbacks ---
func _on_health_changed(current: float, maximum: float) -> void:
	EventBus.horse_health_changed.emit(current, maximum)
	print("Horse health: %s / %s" % [current, maximum])


func _on_died() -> void:
	EventBus.horse_died.emit()
	print("The Trojan Horse has been destroyed!")
