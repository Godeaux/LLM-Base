extends Node
## Manages scene transitions with fade effects. Guards against double-taps.

signal scene_changed(scene_path: String)

var _current_scene_path: String = ""
var _is_transitioning: bool = false


func change_scene(path: String, fade: bool = true) -> void:
	if _is_transitioning:
		return
	_is_transitioning = true

	if fade:
		await _fade_out()

	get_tree().change_scene_to_file(path)
	_current_scene_path = path

	await get_tree().process_frame

	if fade:
		await _fade_in()

	_is_transitioning = false
	scene_changed.emit(path)


func reload_current() -> void:
	if _current_scene_path != "":
		change_scene(_current_scene_path)


func go_to_menu() -> void:
	change_scene("res://ui/menus/MainMenu.tscn")


func _fade_out() -> void:
	var tween := create_tween()
	tween.tween_interval(0.3)
	await tween.finished


func _fade_in() -> void:
	var tween := create_tween()
	tween.tween_interval(0.3)
	await tween.finished
