extends Node
## Cross-mode persistent state: currency, unlocks, prestige levels.

signal currency_changed(mode: String, new_amount: int)

var _currency: Dictionary = {
	"cascade": 0,
	"tumble": 0,
	"orbit": 0,
}

var _unlocked_upgrades: Dictionary = {
	"cascade": [] as Array[String],
	"tumble": [] as Array[String],
	"orbit": [] as Array[String],
}

var _prestige_levels: Dictionary = {
	"cascade": 0,
	"tumble": 0,
	"orbit": 0,
}


func _ready() -> void:
	_load_state()
	EventBus.currency_earned.connect(_on_currency_earned)


func get_currency(mode: String) -> int:
	return _currency.get(mode, 0) as int


func add_currency(mode: String, amount: int) -> void:
	var current: int = _currency.get(mode, 0) as int
	_currency[mode] = current + amount
	currency_changed.emit(mode, _currency[mode] as int)
	_save_state()


func spend_currency(mode: String, amount: int) -> bool:
	var current: int = _currency.get(mode, 0) as int
	if current < amount:
		return false
	_currency[mode] = current - amount
	currency_changed.emit(mode, _currency[mode] as int)
	_save_state()
	return true


func is_unlocked(mode: String, upgrade_id: String) -> bool:
	var upgrades: Array = _unlocked_upgrades.get(mode, []) as Array
	return upgrade_id in upgrades


func unlock(mode: String, upgrade_id: String) -> void:
	if not is_unlocked(mode, upgrade_id):
		var upgrades: Array = _unlocked_upgrades.get(mode, []) as Array
		upgrades.append(upgrade_id)
		_unlocked_upgrades[mode] = upgrades
		_save_state()


func get_prestige_level(mode: String) -> int:
	return _prestige_levels.get(mode, 0) as int


func prestige(mode: String) -> void:
	var level: int = _prestige_levels.get(mode, 0) as int
	_prestige_levels[mode] = level + 1
	_currency[mode] = 0
	_unlocked_upgrades[mode] = [] as Array[String]
	currency_changed.emit(mode, 0)
	_save_state()


func get_prestige_multiplier(mode: String) -> float:
	var level: int = get_prestige_level(mode)
	return 1.0 + level * 0.5


func _on_currency_earned(amount: int, mode: String) -> void:
	var multiplied: int = roundi(amount * get_prestige_multiplier(mode))
	add_currency(mode, multiplied)


func _save_state() -> void:
	var data: Dictionary = {
		"currency": _currency,
		"unlocked_upgrades": _unlocked_upgrades,
		"prestige_levels": _prestige_levels,
	}
	SaveManager.save_game(data)


func _load_state() -> void:
	var data: Dictionary = SaveManager.load_game()
	if data.is_empty():
		return
	if data.has("currency"):
		_currency = data["currency"] as Dictionary
	if data.has("unlocked_upgrades"):
		_unlocked_upgrades = data["unlocked_upgrades"] as Dictionary
	if data.has("prestige_levels"):
		_prestige_levels = data["prestige_levels"] as Dictionary
