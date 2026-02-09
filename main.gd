extends Node2D
## Entry point for Idle Physics. Loads the main menu on startup.


func _ready() -> void:
	# Deferred to avoid remove_child conflict during scene tree init.
	SceneManager.change_scene.call_deferred("res://ui/menus/MainMenu.tscn", false)
