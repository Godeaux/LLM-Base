class_name PlayerInputHandler
extends Node
## Handles mouse interaction for minion summoning, mode toggling, and dragging.
## Also handles hotbar key input (1-4) for minion type selection.


# --- Constants ---
const DRAG_THRESHOLD_PX: float = 20.0
const RAYCAST_LENGTH: float = 100.0


# --- Private variables ---
var _selected_slot: int = 1
var _is_dragging: bool = false
var _drag_start_screen: Vector2 = Vector2.ZERO
var _dragged_minion: Minion = null


# --- Onready variables ---
@onready var _camera: Camera3D = get_node("../Camera3D")
@onready var _wizard: Wizard = get_node("../Wizard")
@onready var _minion_manager: MinionManager = get_node("../MinionManager")
@onready var _horse: TrojanHorse = get_node("../TrojanHorse")


# --- Built-in virtual methods ---
func _ready() -> void:
	EventBus.hotbar_slot_changed.emit(_selected_slot)


func _unhandled_input(event: InputEvent) -> void:
	_handle_hotbar(event)
	_handle_mouse(event)


# --- Private methods ---
func _handle_hotbar(event: InputEvent) -> void:
	for i in range(1, 5):
		if event.is_action_pressed("summon_%d" % i):
			_selected_slot = i
			EventBus.hotbar_slot_changed.emit(i)
			return


func _handle_mouse(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_on_mouse_down(event.position)
		else:
			_on_mouse_up(event.position)
	elif event is InputEventMouseMotion and _dragged_minion:
		_on_mouse_motion(event.position)


func _on_mouse_down(screen_pos: Vector2) -> void:
	_drag_start_screen = screen_pos
	_is_dragging = false
	_dragged_minion = _raycast_minion(screen_pos)


func _on_mouse_motion(screen_pos: Vector2) -> void:
	if not _is_dragging:
		if screen_pos.distance_to(_drag_start_screen) > DRAG_THRESHOLD_PX:
			_is_dragging = true
			_dragged_minion.start_drag()
			if _horse:
				_horse.show_escort_ring()
	if _is_dragging:
		var ground_pos := _raycast_ground(screen_pos)
		if ground_pos != Vector3.INF:
			_dragged_minion.move_to_drag_position(ground_pos)


func _on_mouse_up(screen_pos: Vector2) -> void:
	if _is_dragging and _dragged_minion:
		_finish_drag(screen_pos)
	elif _dragged_minion:
		_toggle_minion_mode(_dragged_minion)
	else:
		_try_summon(screen_pos)
	if _is_dragging and _dragged_minion:
		_dragged_minion.end_drag()
	if _is_dragging and _horse:
		_horse.hide_escort_ring()
	_dragged_minion = null
	_is_dragging = false


func _finish_drag(screen_pos: Vector2) -> void:
	_dragged_minion.end_drag()
	var world_pos := _raycast_ground(screen_pos)
	if world_pos == Vector3.INF:
		return
	if _horse:
		var offset := world_pos - _horse.global_position
		offset.y = 0.0
		var distance := offset.length()
		if distance <= MinionManager.ESCORT_RADIUS:
			var local_dir := _horse.global_transform.basis.inverse() * offset
			var local_angle := atan2(local_dir.z, local_dir.x)
			var radius := clampf(distance, 1.5, MinionManager.ESCORT_RADIUS)
			_dragged_minion.set_escort_position(local_angle, radius)
			_dragged_minion.set_mode(Minion.Mode.FOLLOW)
			return
	_dragged_minion.set_stay_position(world_pos)


func _toggle_minion_mode(minion: Minion) -> void:
	if minion.current_mode == Minion.Mode.FOLLOW:
		minion.set_mode(Minion.Mode.STAY)
	else:
		minion.set_mode(Minion.Mode.FOLLOW)
		_minion_manager.assign_escort_position(minion)
	print("PlayerInputHandler: Toggled minion to %s." % Minion.Mode.keys()[minion.current_mode])


func _try_summon(screen_pos: Vector2) -> void:
	if not _minion_manager.has_type(_selected_slot):
		print("PlayerInputHandler: Slot %d locked." % _selected_slot)
		return
	if not _minion_manager.can_summon():
		print("PlayerInputHandler: Max minion count reached.")
		return
	var world_pos := _raycast_ground(screen_pos)
	if world_pos == Vector3.INF:
		return
	var distance := world_pos.distance_to(_wizard.global_position)
	if distance > _wizard.summon_radius:
		print("PlayerInputHandler: Outside summon radius (%.1f > %.1f)." % [
			distance, _wizard.summon_radius])
		return
	_minion_manager.summon_minion(world_pos, _selected_slot)


func _raycast_ground(screen_pos: Vector2) -> Vector3:
	var space := _camera.get_world_3d().direct_space_state
	var from := _camera.project_ray_origin(screen_pos)
	var to := from + _camera.project_ray_normal(screen_pos) * RAYCAST_LENGTH
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 1
	var result := space.intersect_ray(query)
	if result.is_empty():
		return Vector3.INF
	return result["position"] as Vector3


func _raycast_minion(screen_pos: Vector2) -> Minion:
	var space := _camera.get_world_3d().direct_space_state
	var from := _camera.project_ray_origin(screen_pos)
	var to := from + _camera.project_ray_normal(screen_pos) * RAYCAST_LENGTH
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 2
	var result := space.intersect_ray(query)
	if result.is_empty():
		return null
	var collider: Node = result["collider"]
	while collider:
		if collider is Minion:
			return collider as Minion
		collider = collider.get_parent()
	return null
