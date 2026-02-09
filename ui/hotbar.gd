class_name Hotbar
extends CanvasLayer
## Minimal bottom-center hotbar showing minion type slots (1/2/3).
## Listens to EventBus signals for selection and count updates.


# --- Constants ---
const SLOT_SIZE: float = 48.0
const SLOT_GAP: float = 6.0
const BORDER_WIDTH: float = 3.0
const FONT_SIZE: int = 16
const COUNT_FONT_SIZE: int = 14
const COLOR_SELECTED := Color(1.0, 1.0, 1.0, 0.9)
const COLOR_UNSELECTED := Color(0.4, 0.4, 0.4, 0.6)
const BG_COLOR := Color(0.0, 0.0, 0.0, 0.5)

const SLOT_COLORS: Array[Color] = [
	Color(0.3, 0.5, 1.0),   # Warrior (blue)
	Color(0.5, 0.2, 0.8),   # Sniper (purple)
	Color(0.3, 0.9, 0.4),   # Healer (green)
]

const SLOT_LABELS: Array[String] = ["1", "2", "3"]


# --- Private variables ---
var _slots: Array[PanelContainer] = []
var _slot_borders: Array[StyleBoxFlat] = []
var _count_label: Label
var _selected: int = 1


# --- Built-in virtual methods ---
func _ready() -> void:
	layer = 10
	_build_ui()
	EventBus.hotbar_slot_changed.connect(_on_slot_changed)
	EventBus.minion_count_changed.connect(_on_count_changed)
	_update_selection(_selected)


# --- Private methods ---
func _build_ui() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	# Container anchored to bottom-center
	var container := VBoxContainer.new()
	container.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	container.grow_horizontal = Control.GROW_DIRECTION_BOTH
	container.grow_vertical = Control.GROW_DIRECTION_BEGIN
	container.offset_top = -70.0
	container.offset_bottom = -10.0
	container.alignment = BoxContainer.ALIGNMENT_END
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(container)

	# Count label above slots
	_count_label = Label.new()
	_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_count_label.add_theme_font_size_override("font_size", COUNT_FONT_SIZE)
	_count_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 0.8))
	_count_label.text = "0 / 5"
	_count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(_count_label)

	# Horizontal row of slots
	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", int(SLOT_GAP))
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(hbox)

	for i in 3:
		var panel := PanelContainer.new()
		panel.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

		var style := StyleBoxFlat.new()
		style.bg_color = BG_COLOR
		style.border_color = COLOR_UNSELECTED
		style.set_border_width_all(int(BORDER_WIDTH))
		style.set_corner_radius_all(6)
		panel.add_theme_stylebox_override("panel", style)
		_slot_borders.append(style)

		var margin := MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 4)
		margin.add_theme_constant_override("margin_right", 4)
		margin.add_theme_constant_override("margin_top", 2)
		margin.add_theme_constant_override("margin_bottom", 2)
		margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(margin)

		var vbox := VBoxContainer.new()
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		margin.add_child(vbox)

		# Color indicator circle
		var color_rect := ColorRect.new()
		color_rect.custom_minimum_size = Vector2(20.0, 20.0)
		color_rect.color = SLOT_COLORS[i]
		color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(color_rect)

		# Key label
		var label := Label.new()
		label.text = SLOT_LABELS[i]
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", FONT_SIZE)
		label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(label)

		hbox.add_child(panel)
		_slots.append(panel)


func _update_selection(slot: int) -> void:
	for i in _slot_borders.size():
		if i == slot - 1:
			_slot_borders[i].border_color = COLOR_SELECTED
		else:
			_slot_borders[i].border_color = COLOR_UNSELECTED


func _on_slot_changed(slot_index: int) -> void:
	_selected = slot_index
	_update_selection(slot_index)


func _on_count_changed(current: int, maximum: int) -> void:
	_count_label.text = "%d / %d" % [current, maximum]
