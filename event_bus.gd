extends Node
## Global event bus for cross-system communication.
## Signals are added incrementally as systems need them.
## Also handles input action registration (code-based for reliability).


# --- Signals ---
signal horse_health_changed(current: float, maximum: float)
signal horse_died
signal horse_entered_tile(tile_name: String)
signal horse_reached_fork(route_count: int)
signal horse_reached_map_end


func _ready() -> void:
	_register_input_actions()


func _register_input_actions() -> void:
	_add_key_action("move_up", KEY_W)
	_add_key_action("move_down", KEY_S)
	_add_key_action("move_left", KEY_A)
	_add_key_action("move_right", KEY_D)


func _add_key_action(action_name: String, keycode: Key) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
		var event := InputEventKey.new()
		event.physical_keycode = keycode
		InputMap.action_add_event(action_name, event)
