extends Node
## JSON save/load with version migration. Persists game state across sessions.

const SAVE_PATH := "user://idle_physics_save.json"
const CURRENT_VERSION: int = 1


func save_game(data: Dictionary) -> void:
	data["version"] = CURRENT_VERSION
	data["timestamp"] = Time.get_unix_time_from_system()

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))


func load_game() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return {}

	var content := file.get_as_text()
	var data: Variant = JSON.parse_string(content)
	if data is Dictionary:
		return _migrate(data as Dictionary)
	return {}


func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)


func _migrate(data: Dictionary) -> Dictionary:
	# Handle version migrations as save format evolves:
	# if data.get("version", 0) < 2: data["new_field"] = default_value
	return data
