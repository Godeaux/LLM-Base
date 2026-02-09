extends Node2D
## Cascade game mode: marble machine with balls, pegs, and collection bins.

@onready var _builder: MachineBuilder = $MachineBuilder
@onready var _spawner: BallSpawner = $BallSpawner
@onready var _manager: CascadeManager = $CascadeManager
@onready var _hud: CascadeHud = $CascadeHud
@onready var _upgrade_panel: UpgradePanel = $UpgradePanelLayer/UpgradePanel


func _ready() -> void:
	_spawner.add_ball_type(BallTypes.standard(), 1.0)
	_spawner.spawn_position = Vector2(640, 50)

	_manager.setup(_builder, _spawner)
	_upgrade_panel.setup(_manager)
	_hud.setup_upgrade_toggle(_upgrade_panel)

	get_tree().paused = false
