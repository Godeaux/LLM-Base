extends Control
## Main menu with three game mode buttons.

@onready var _cascade_btn: Button = %CascadeButton
@onready var _tumble_btn: Button = %TumbleButton
@onready var _orbit_btn: Button = %OrbitButton
@onready var _cascade_currency: Label = %CascadeCurrency
@onready var _tumble_currency: Label = %TumbleCurrency
@onready var _orbit_currency: Label = %OrbitCurrency
@onready var _title_label: Label = %TitleLabel


func _ready() -> void:
	_cascade_btn.pressed.connect(_on_cascade_pressed)
	_tumble_btn.pressed.connect(_on_tumble_pressed)
	_orbit_btn.pressed.connect(_on_orbit_pressed)
	GameState.currency_changed.connect(_on_currency_changed)
	_update_currency_displays()

	_title_label.text = "IDLE PHYSICS"


func _update_currency_displays() -> void:
	_cascade_currency.text = str(GameState.get_currency("cascade"))
	_tumble_currency.text = str(GameState.get_currency("tumble"))
	_orbit_currency.text = str(GameState.get_currency("orbit"))


func _on_currency_changed(_mode: String, _amount: int) -> void:
	_update_currency_displays()


func _on_cascade_pressed() -> void:
	SceneManager.change_scene("res://systems/cascade/CascadeGame.tscn")


func _on_tumble_pressed() -> void:
	SceneManager.change_scene("res://systems/tumble/TumbleGame.tscn")


func _on_orbit_pressed() -> void:
	SceneManager.change_scene("res://systems/orbit/OrbitGame.tscn")
