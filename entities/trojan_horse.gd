class_name TrojanHorse
extends Node3D
## The Trojan Horse payload that follows tile-based paths.
## Features a multi-part limb damage system: 4 legs + center body.
## Destroying legs slows the horse; center body death = game over.


# --- Constants ---
const LEG_COLOR_HEALTHY := Color(0.65, 0.5, 0.3)
const LEG_COLOR_DESTROYED := Color(0.15, 0.1, 0.05)
const BODY_COLOR_HEALTHY := Color(0.65, 0.5, 0.3)
const BODY_COLOR_DESTROYED := Color(0.15, 0.1, 0.05)
const FLASH_COLOR := Color(1.0, 1.0, 0.3)
const FLASH_DURATION: float = 0.12

## Leg positions in local space relative to Visual node.
## Body is 1×1.2×2.5 centered at Y=0.6. Legs sit under the body at corners.
## look_at faces -Z, so front = -Z, rear = +Z, left = -X, right = +X.
## NOTE: These are first-attempt approximations — tweak in editor if needed.
const LEG_SIZE := Vector3(0.2, 0.55, 0.2)
const LEG_POSITIONS: Array[Vector3] = [
	Vector3(-0.35, 0.275, -0.9),  # FRONT_LEFT
	Vector3(0.35, 0.275, -0.9),   # FRONT_RIGHT
	Vector3(-0.35, 0.275, 0.9),   # REAR_LEFT
	Vector3(0.35, 0.275, 0.9),    # REAR_RIGHT
]
const LEG_STUB_SCALE := Vector3(0.6, 0.3, 0.6)

## Walk bob animation.
const BOB_AMPLITUDE: float = 0.04
const BOB_FREQUENCY: float = 6.0

## Limp tilt: degrees of tilt per destroyed leg on that side.
const LIMP_TILT_DEGREES: float = 4.0
const TILT_LERP_SPEED: float = 3.0

# --- Exports ---
@export var move_speed: float = 0.5

# --- Private variables ---
var _limb_system: HorseLimbSystem
var _escort_ring: MeshInstance3D
var _map_manager: MapManager
var _current_tile: MapTile
var _current_route: TileRoute
var _curve_offset: float = 0.0
var _active: bool = false
var _visual: Node3D
var _body_node: CSGBox3D
var _body_material: StandardMaterial3D
var _leg_nodes: Array[CSGBox3D] = []
var _leg_materials: Array[StandardMaterial3D] = []
var _neck_node: CSGBox3D
var _head_node: CSGBox3D
var _tail_node: CSGBox3D
var _walk_time: float = 0.0
var _target_tilt: Vector3 = Vector3.ZERO
var _current_tilt: Vector3 = Vector3.ZERO


# --- Built-in virtual methods ---
func _ready() -> void:
	add_to_group("trojan_horse")
	_limb_system = $HealthComponent as HorseLimbSystem
	_limb_system.health_changed.connect(_on_health_changed)
	_limb_system.died.connect(_on_died)
	_limb_system.limb_damaged.connect(_on_limb_damaged)
	_limb_system.limb_destroyed.connect(_on_limb_destroyed)
	_limb_system.center_damaged.connect(_on_center_damaged)
	_visual = $Visual as Node3D
	_body_node = $Visual/Body as CSGBox3D
	_body_material = _body_node.material.duplicate() as StandardMaterial3D
	_body_node.material = _body_material
	_create_horse_parts()
	_create_legs()
	_create_escort_ring()


func _process(delta: float) -> void:
	if not _active or not _current_route:
		return
	var curve: Curve3D = _current_route.curve
	var curve_length := curve.get_baked_length()
	var speed_mult: float = _limb_system.get_speed_multiplier()
	_curve_offset += move_speed * speed_mult * delta
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
	_update_walk_animation(delta, speed_mult)


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


func _create_horse_parts() -> void:
	## Builds the neck, head, and tail CSG pieces under Visual.
	## All positions are approximations — verify in the Godot editor.
	var wood_mat := StandardMaterial3D.new()
	wood_mat.albedo_color = BODY_COLOR_HEALTHY

	## Neck: angled box extending from front of body (-Z) upward.
	_neck_node = CSGBox3D.new()
	_neck_node.name = "Neck"
	_neck_node.size = Vector3(0.4, 0.9, 0.4)
	## Position at the front of the body, raised. Tilted ~25° forward (around X).
	_neck_node.position = Vector3(0.0, 1.3, -1.3)
	_neck_node.rotation_degrees = Vector3(25.0, 0.0, 0.0)
	_neck_node.material = wood_mat
	_visual.add_child(_neck_node)

	## Head: wider box at top of neck.
	_head_node = CSGBox3D.new()
	_head_node.name = "Head"
	_head_node.size = Vector3(0.5, 0.35, 0.6)
	## Sits at the top-front of the neck.
	_head_node.position = Vector3(0.0, 1.75, -1.55)
	_head_node.material = wood_mat
	_visual.add_child(_head_node)

	## Tail: small box extending from rear of body (+Z), angled up slightly.
	_tail_node = CSGBox3D.new()
	_tail_node.name = "Tail"
	_tail_node.size = Vector3(0.15, 0.15, 0.6)
	_tail_node.position = Vector3(0.0, 1.1, 1.5)
	_tail_node.rotation_degrees = Vector3(-20.0, 0.0, 0.0)
	_tail_node.material = wood_mat
	_visual.add_child(_tail_node)


func _create_legs() -> void:
	for i: int in range(4):
		var leg := CSGBox3D.new()
		leg.size = LEG_SIZE
		leg.position = LEG_POSITIONS[i]
		var mat := StandardMaterial3D.new()
		mat.albedo_color = LEG_COLOR_HEALTHY
		leg.material = mat
		_visual.add_child(leg)
		_leg_nodes.append(leg)
		_leg_materials.append(mat)


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


func _update_walk_animation(delta: float, speed_mult: float) -> void:
	## Walking bob: Y oscillation scaled by speed. Stops when not moving.
	_walk_time += delta * BOB_FREQUENCY * speed_mult
	var bob_offset: float = sin(_walk_time) * BOB_AMPLITUDE * speed_mult
	## Limp tilt: smoothly interpolate toward target tilt.
	_current_tilt = _current_tilt.lerp(_target_tilt, TILT_LERP_SPEED * delta)
	## Apply to Visual node so it doesn't affect collision or position.
	_visual.position.y = bob_offset
	_visual.rotation_degrees = _current_tilt


func _recalculate_limp_tilt() -> void:
	## Compute tilt based on which legs are destroyed.
	## Tilt toward the side with more dead legs.
	var tilt_x: float = 0.0  # Pitch: front/rear
	var tilt_z: float = 0.0  # Roll: left/right
	## FRONT_LEFT (0): tilt forward (-X rot) and right (+Z rot)
	if not _limb_system.is_limb_alive(HorseLimbSystem.Limb.FRONT_LEFT):
		tilt_x -= LIMP_TILT_DEGREES
		tilt_z += LIMP_TILT_DEGREES
	## FRONT_RIGHT (1): tilt forward (-X rot) and left (-Z rot)
	if not _limb_system.is_limb_alive(HorseLimbSystem.Limb.FRONT_RIGHT):
		tilt_x -= LIMP_TILT_DEGREES
		tilt_z -= LIMP_TILT_DEGREES
	## REAR_LEFT (2): tilt backward (+X rot) and right (+Z rot)
	if not _limb_system.is_limb_alive(HorseLimbSystem.Limb.REAR_LEFT):
		tilt_x += LIMP_TILT_DEGREES
		tilt_z += LIMP_TILT_DEGREES
	## REAR_RIGHT (3): tilt backward (+X rot) and left (-Z rot)
	if not _limb_system.is_limb_alive(HorseLimbSystem.Limb.REAR_RIGHT):
		tilt_x += LIMP_TILT_DEGREES
		tilt_z -= LIMP_TILT_DEGREES
	_target_tilt = Vector3(tilt_x, 0.0, tilt_z)


func _update_limb_visual(limb_index: int) -> void:
	var hp_percent: float = _limb_system.get_limb_health_percent(limb_index)
	var target_color: Color = LEG_COLOR_HEALTHY.lerp(LEG_COLOR_DESTROYED, 1.0 - hp_percent)
	_leg_materials[limb_index].albedo_color = target_color
	if not _limb_system.is_limb_alive(limb_index):
		_leg_nodes[limb_index].scale = LEG_STUB_SCALE


func _update_body_visual() -> void:
	var hp_percent: float = _limb_system.get_center_health_percent()
	_body_material.albedo_color = BODY_COLOR_HEALTHY.lerp(BODY_COLOR_DESTROYED, 1.0 - hp_percent)


func _flash_limb(limb_index: int) -> void:
	var mat: StandardMaterial3D = _leg_materials[limb_index]
	var target_color: Color = LEG_COLOR_HEALTHY.lerp(
		LEG_COLOR_DESTROYED, 1.0 - _limb_system.get_limb_health_percent(limb_index)
	)
	mat.albedo_color = FLASH_COLOR
	var tween := create_tween()
	tween.tween_property(mat, "albedo_color", target_color, FLASH_DURATION)


func _flash_body() -> void:
	var target_color: Color = BODY_COLOR_HEALTHY.lerp(
		BODY_COLOR_DESTROYED, 1.0 - _limb_system.get_center_health_percent()
	)
	_body_material.albedo_color = FLASH_COLOR
	var tween := create_tween()
	tween.tween_property(_body_material, "albedo_color", target_color, FLASH_DURATION)


# --- Signal callbacks ---
func _on_health_changed(current: float, maximum: float) -> void:
	EventBus.horse_health_changed.emit(current, maximum)


func _on_died() -> void:
	_active = false
	EventBus.horse_died.emit()
	print("The Trojan Horse has been destroyed!")


func _on_limb_damaged(limb_index: int, current_hp: float, max_hp: float) -> void:
	_flash_limb(limb_index)
	_update_limb_visual(limb_index)
	EventBus.horse_limb_damaged.emit(limb_index, current_hp, max_hp)
	var limb_name: String = HorseLimbSystem.Limb.keys()[limb_index]
	print("Horse limb %s hit: %.0f / %.0f" % [limb_name, current_hp, max_hp])


func _on_limb_destroyed(limb_index: int) -> void:
	_update_limb_visual(limb_index)
	_recalculate_limp_tilt()
	var mult: float = _limb_system.get_speed_multiplier()
	EventBus.horse_limb_destroyed.emit(limb_index)
	EventBus.horse_speed_changed.emit(mult)
	var limb_name: String = HorseLimbSystem.Limb.keys()[limb_index]
	print("Horse limb %s DESTROYED! Speed: %.0f%%" % [limb_name, mult * 100.0])


func _on_center_damaged(current_hp: float, max_hp: float) -> void:
	_flash_body()
	_update_body_visual()
	print("Horse CENTER hit: %.0f / %.0f" % [current_hp, max_hp])
