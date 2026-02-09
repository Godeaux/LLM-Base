extends Node2D
## Orbit game mode entry point. Placeholder until Increment 6.


func _ready() -> void:
	var back_btn: Button = $CanvasLayer/BackButton
	back_btn.pressed.connect(_on_back_pressed)


func _on_back_pressed() -> void:
	SceneManager.go_to_menu()
