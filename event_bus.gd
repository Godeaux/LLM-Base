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

signal minion_summoned(minion_type: int)
signal minion_mode_changed(mode_name: String)
signal minion_count_changed(current: int, maximum: int)
signal hotbar_slot_changed(slot_index: int)

signal enemy_killed
signal wave_started(wave_number: int, enemy_count: int)
signal wave_completed(wave_number: int)


func _ready() -> void:
	_register_input_actions()


func _register_input_actions() -> void:
	_add_key_action("move_up", KEY_W)
	_add_key_action("move_down", KEY_S)
	_add_key_action("move_left", KEY_A)
	_add_key_action("move_right", KEY_D)
	_add_key_action("summon_1", KEY_1)
	_add_key_action("summon_2", KEY_2)
	_add_key_action("summon_3", KEY_3)
	_add_key_action("summon_4", KEY_4)
	_add_mouse_button_action("click", MOUSE_BUTTON_LEFT)


func _add_key_action(action_name: String, keycode: Key) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
		var event := InputEventKey.new()
		event.physical_keycode = keycode
		InputMap.action_add_event(action_name, event)


func _add_mouse_button_action(action_name: String, button: MouseButton) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
		var event := InputEventMouseButton.new()
		event.button_index = button
		InputMap.action_add_event(action_name, event)
