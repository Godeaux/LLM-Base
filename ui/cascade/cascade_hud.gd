class_name CascadeHud
extends CanvasLayer
## HUD overlay for the Cascade game mode.

var _upgrade_panel: UpgradePanel

@onready var _currency_label: Label = %CurrencyLabel
@onready var _ball_count_label: Label = %BallCountLabel
@onready var _back_button: Button = %BackButton
@onready var _upgrade_button: Button = %UpgradeButton


func _ready() -> void:
	_back_button.pressed.connect(_on_back_pressed)
	_upgrade_button.pressed.connect(_on_upgrade_pressed)
	GameState.currency_changed.connect(_on_currency_changed)
	_update_currency()


func setup_upgrade_toggle(panel: UpgradePanel) -> void:
	_upgrade_panel = panel


func _process(_delta: float) -> void:
	var spawner: Node = get_tree().get_first_node_in_group("ball_spawner")
	if spawner and spawner.has_method("get_pool"):
		var pool: ObjectPool = spawner.get_pool() as ObjectPool
		if pool:
			_ball_count_label.text = "Balls: " + str(pool.get_active_count())


func _update_currency() -> void:
	_currency_label.text = str(GameState.get_currency("cascade"))


func _on_currency_changed(mode: String, _amount: int) -> void:
	if mode == "cascade":
		_update_currency()


func _on_upgrade_pressed() -> void:
	if _upgrade_panel:
		_upgrade_panel.toggle()


func _on_back_pressed() -> void:
	SceneManager.go_to_menu()
