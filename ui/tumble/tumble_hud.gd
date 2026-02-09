class_name TumbleHud
extends CanvasLayer
## HUD overlay for the Tumble game mode.

var _tracker: TowerTracker

@onready var _currency_label: Label = %CurrencyLabel
@onready var _height_label: Label = %HeightLabel
@onready var _max_height_label: Label = %MaxHeightLabel
@onready var _block_count_label: Label = %BlockCountLabel
@onready var _collapse_label: Label = %CollapseLabel
@onready var _back_button: Button = %BackButton


func _ready() -> void:
	_back_button.pressed.connect(_on_back_pressed)
	GameState.currency_changed.connect(_on_currency_changed)
	_collapse_label.visible = false
	_update_currency()


func setup(tracker: TowerTracker) -> void:
	_tracker = tracker
	_tracker.height_changed.connect(_on_height_changed)
	_tracker.collapse_started.connect(_on_collapse_started)
	_tracker.collapse_ended.connect(_on_collapse_ended)


func _process(_delta: float) -> void:
	var spawner: Node = get_tree().get_first_node_in_group("block_spawner")
	if spawner and spawner.has_method("get_pool"):
		var pool: ObjectPool = spawner.get_pool() as ObjectPool
		if pool:
			_block_count_label.text = ("Blocks: " + str(pool.get_active_count()))


func _on_height_changed(current: float, maximum: float) -> void:
	_height_label.text = "Height: " + str(int(current))
	_max_height_label.text = "Best: " + str(int(maximum))


func _on_collapse_started() -> void:
	_collapse_label.visible = true


func _on_collapse_ended(_max_height: float, currency: int) -> void:
	_collapse_label.visible = false
	if currency > 0:
		(
			VisualJuice
			. float_text(
				self,
				"+" + str(currency),
				Vector2(580, 300),
				Color.YELLOW,
			)
		)


func _update_currency() -> void:
	_currency_label.text = str(GameState.get_currency("tumble"))


func _on_currency_changed(mode: String, _amount: int) -> void:
	if mode == "tumble":
		_update_currency()


func _on_back_pressed() -> void:
	SceneManager.go_to_menu()
