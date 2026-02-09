class_name DebugHUD
extends CanvasLayer
## Screen-space debug text overlay. Toggles with F3 alongside DebugPathOverlay.
## Shows wave timers, enemy counts, horse state, minion breakdown, and FPS.


# --- Private variables ---
var _panel: PanelContainer
var _label: Label
var _active: bool = false
var _game_time: float = 0.0

# Set by main.gd after instantiation.
var wave_spawner: WaveSpawner
var trojan_horse: TrojanHorse


# --- Built-in virtual methods ---
func _ready() -> void:
	layer = 100
	_build_ui()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_debug_paths"):
		_active = not _active
		_panel.visible = _active


func _process(delta: float) -> void:
	_game_time += delta
	if not _active:
		return
	_label.text = _build_debug_text()


# --- Private methods ---
func _build_ui() -> void:
	_panel = PanelContainer.new()
	_panel.anchor_left = 0.0
	_panel.anchor_top = 0.0
	_panel.offset_left = 10.0
	_panel.offset_top = 10.0

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.0, 0.0, 0.0, 0.7)
	style.set_content_margin_all(8.0)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	_panel.add_theme_stylebox_override("panel", style)

	_label = Label.new()
	_label.add_theme_font_size_override("font_size", 14)
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Consolas", "Courier New", "monospace"])
	_label.add_theme_font_override("font", font)
	_label.add_theme_color_override("font_color", Color(0.8, 1.0, 0.8))

	_panel.add_child(_label)
	add_child(_panel)
	_panel.visible = false


func _build_debug_text() -> String:
	var lines: PackedStringArray = PackedStringArray()

	# Header + FPS + game time.
	lines.append("FPS %d | %.1fs" % [Engine.get_frames_per_second(), _game_time])

	# Wave spawner state.
	if wave_spawner:
		var info: Dictionary = wave_spawner.get_debug_info()
		var wave_line: String = "WAVE %d/%d  %s" % [info["wave"], info["total_waves"], info["state"]]
		if info["detail"] != "":
			wave_line += " " + str(info["detail"])
		lines.append(wave_line)

		var enemies_line: String = "Enemies: %d alive" % info["active_enemies"]
		if info["spawn_queue"] > 0:
			enemies_line += "  Queue: %d" % info["spawn_queue"]
		lines.append(enemies_line)

		# Trigger info (only when armed or has a running timer).
		if info["state"] == "ARMED":
			var trigger_line: String = "Next: %d/%d tiles" % [
				info["tiles_since_wave"], info["tiles_needed"]]
			if info["trigger_time_left"] > 0.0:
				trigger_line += " | %.1fs timer" % info["trigger_time_left"]
			lines.append(trigger_line)

	# Horse state.
	if trojan_horse:
		var tile: MapTile = trojan_horse.get_current_tile()
		var tile_str: String = "none"
		if tile:
			tile_str = "%s %s" % [tile.tile_name, tile.grid_position]
		var hp_str: String = ""
		var hc: HealthComponent = trojan_horse.get_node_or_null("HealthComponent") as HealthComponent
		if hc:
			hp_str = "  HP %.0f/%.0f" % [hc.get_current_health(), hc.max_health]
		lines.append("HORSE %s%s" % [tile_str, hp_str])

	# Minion breakdown.
	var minions := get_tree().get_nodes_in_group("minions")
	var follow_count: int = 0
	var stay_count: int = 0
	for node: Node in minions:
		var m := node as Minion
		if not m:
			continue
		if m.current_mode == Minion.Mode.FOLLOW:
			follow_count += 1
		else:
			stay_count += 1
	lines.append("MINIONS %d/%d  %dF %dS" % [
		minions.size(), MinionManager.MAX_MINIONS, follow_count, stay_count])

	return "\n".join(lines)
