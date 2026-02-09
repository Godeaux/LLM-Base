class_name CascadeManager
extends Node
## Manages the Cascade economy: upgrade catalog, purchases, and effects.

signal upgrades_changed

var _upgrades: Array[Dictionary] = []
var _builder: MachineBuilder
var _spawner: BallSpawner


func setup(builder: MachineBuilder, spawner: BallSpawner) -> void:
	_builder = builder
	_spawner = spawner
	_define_upgrades()
	_restore_purchases()


func get_upgrades() -> Array[Dictionary]:
	return _upgrades


func purchase_upgrade(upgrade_id: String) -> bool:
	for upgrade: Dictionary in _upgrades:
		if upgrade["id"] != upgrade_id:
			continue
		if upgrade["purchased"]:
			return false
		if not GameState.spend_currency("cascade", upgrade["cost"] as int):
			return false
		upgrade["purchased"] = true
		GameState.unlock("cascade", upgrade_id)
		_apply_upgrade(upgrade_id)
		EventBus.upgrade_purchased.emit(upgrade_id, "cascade")
		upgrades_changed.emit()
		return true
	return false


func _apply_upgrade(upgrade_id: String) -> void:
	match upgrade_id:
		"spawn_rate_1":
			_spawner.upgrade_spawn_rate(0.75)
		"pool_size_1":
			_add_pool_balls(5)
		"bumpers":
			_builder.add_bumpers(4)
		"ball_heavy":
			_spawner.add_ball_type(BallTypes.heavy(), 0.6)
		"ball_bouncy":
			_spawner.add_ball_type(BallTypes.bouncy(), 0.6)
		"ramps":
			_builder.add_ramps(4)
		"spinner":
			_builder.add_spinner(Vector2(520, 390))
		"trampolines":
			_builder.add_trampolines(3)
		"ball_golden":
			_spawner.add_ball_type(BallTypes.golden(), 0.3)
		"gravity_zone":
			_builder.add_gravity_zone(Vector2(350, 450), Vector2(100, 150), Vector2.UP)
		"magnetic_field":
			_builder.add_magnetic_field(Vector2(520, 550), 60.0)
		"spawn_rate_2":
			_spawner.upgrade_spawn_rate(0.8)


func _add_pool_balls(count: int) -> void:
	var pool: ObjectPool = _spawner.get_pool()
	for i: int in count:
		var obj: Node = pool.scene.instantiate()
		obj.set_process(false)
		obj.set_physics_process(false)
		obj.visible = false
		pool.add_child(obj)


func _restore_purchases() -> void:
	for upgrade: Dictionary in _upgrades:
		var uid: String = upgrade["id"] as String
		if GameState.is_unlocked("cascade", uid):
			upgrade["purchased"] = true
			_apply_upgrade(uid)


func _define_upgrades() -> void:
	_upgrades = [
		{
			"id": "spawn_rate_1",
			"name": "Faster Drops",
			"cost": 20,
			"description": "Balls spawn 25% faster",
			"purchased": false,
		},
		{
			"id": "pool_size_1",
			"name": "More Balls",
			"cost": 35,
			"description": "Add 5 more balls to the pool",
			"purchased": false,
		},
		{
			"id": "bumpers",
			"name": "Add Bumpers",
			"cost": 50,
			"description": "Add bouncy bumpers to the machine",
			"purchased": false,
		},
		{
			"id": "ball_heavy",
			"name": "Heavy Balls",
			"cost": 75,
			"description": "Unlock heavy balls (2x score)",
			"purchased": false,
		},
		{
			"id": "ball_bouncy",
			"name": "Bouncy Balls",
			"cost": 75,
			"description": "Unlock bouncy balls (extra bounce)",
			"purchased": false,
		},
		{
			"id": "ramps",
			"name": "Add Ramps",
			"cost": 100,
			"description": "Add angled ramps to the sides",
			"purchased": false,
		},
		{
			"id": "spinner",
			"name": "Spinning Wheel",
			"cost": 150,
			"description": "Add a spinning wheel to the center",
			"purchased": false,
		},
		{
			"id": "trampolines",
			"name": "Trampolines",
			"cost": 200,
			"description": "Add trampolines above the bins",
			"purchased": false,
		},
		{
			"id": "ball_golden",
			"name": "Golden Balls",
			"cost": 250,
			"description": "Unlock golden balls (3x score)",
			"purchased": false,
		},
		{
			"id": "gravity_zone",
			"name": "Gravity Zone",
			"cost": 350,
			"description": "Add an upward gravity zone",
			"purchased": false,
		},
		{
			"id": "magnetic_field",
			"name": "Magnetic Field",
			"cost": 500,
			"description": "Add a magnetic attractor",
			"purchased": false,
		},
		{
			"id": "spawn_rate_2",
			"name": "Even Faster",
			"cost": 750,
			"description": "Balls spawn 20% faster again",
			"purchased": false,
		},
	]
