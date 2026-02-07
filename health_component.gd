class_name HealthComponent
extends Node
## Reusable health component. Attach as a child of any entity that needs health.


# --- Signals ---
signal health_changed(current: float, maximum: float)
signal died

# --- Exports ---
@export var max_health: float = 100.0

# --- Private variables ---
var _current_health: float


# --- Built-in virtual methods ---
func _ready() -> void:
	_current_health = max_health


# --- Public methods ---
func take_damage(amount: float) -> void:
	_current_health = maxf(_current_health - amount, 0.0)
	health_changed.emit(_current_health, max_health)
	if _current_health <= 0.0:
		died.emit()


func heal(amount: float) -> void:
	_current_health = minf(_current_health + amount, max_health)
	health_changed.emit(_current_health, max_health)


func get_health_percent() -> float:
	if max_health <= 0.0:
		return 0.0
	return _current_health / max_health
