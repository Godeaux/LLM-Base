class_name UpgradePanel
extends PanelContainer
## Slide-in panel displaying available upgrades for purchase.

var _manager: CascadeManager
var _item_container: VBoxContainer


func setup(manager: CascadeManager) -> void:
	_manager = manager
	_manager.upgrades_changed.connect(refresh)
	GameState.currency_changed.connect(_on_currency_changed)
	refresh()


func refresh() -> void:
	if not _item_container:
		return
	for child: Node in _item_container.get_children():
		child.queue_free()

	var currency: int = GameState.get_currency("cascade")
	for upgrade: Dictionary in _manager.get_upgrades():
		var item := _create_upgrade_item(upgrade, currency)
		_item_container.add_child(item)


func show_panel() -> void:
	visible = true
	var tween := create_tween()
	tween.tween_property(self, "position:x", 980.0, 0.2).set_ease(Tween.EASE_OUT)


func hide_panel() -> void:
	var tween := create_tween()
	tween.tween_property(self, "position:x", 1280.0, 0.2).set_ease(Tween.EASE_IN)
	await tween.finished
	visible = false


func toggle() -> void:
	if visible:
		hide_panel()
	else:
		show_panel()


func _ready() -> void:
	_item_container = $ScrollContainer/VBoxContainer
	visible = false
	position.x = 1280.0


func _create_upgrade_item(upgrade: Dictionary, currency: int) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var name_label := Label.new()
	name_label.text = upgrade["name"] as String
	info.add_child(name_label)

	var desc_label := Label.new()
	desc_label.text = upgrade["description"] as String
	desc_label.add_theme_font_size_override("font_size", 12)
	desc_label.modulate = Color(0.7, 0.7, 0.7)
	info.add_child(desc_label)

	row.add_child(info)

	var purchased: bool = upgrade["purchased"] as bool
	var cost: int = upgrade["cost"] as int
	var btn := Button.new()

	if purchased:
		btn.text = "Owned"
		btn.disabled = true
	else:
		btn.text = str(cost) + " coins"
		btn.disabled = currency < cost
		var uid: String = upgrade["id"] as String
		btn.pressed.connect(_on_buy_pressed.bind(uid))

	btn.custom_minimum_size = Vector2(100, 0)
	row.add_child(btn)

	return row


func _on_buy_pressed(upgrade_id: String) -> void:
	if _manager:
		_manager.purchase_upgrade(upgrade_id)


func _on_currency_changed(mode: String, _amount: int) -> void:
	if mode == "cascade":
		refresh()
