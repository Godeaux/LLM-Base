# Patterns: Events, Persistence & Command/Undo

How systems communicate, how game state is saved/loaded, and how to implement undo/redo.

All examples target **Godot 4.6** with static typing.

---

## Event Bus / Signals

**When to use:** Decoupled communication between systems. UI reacting to game events. Achievements, analytics, audio triggers. Anywhere you'd otherwise pass callbacks through multiple layers.

```gdscript
# Autoload: EventBus.gd
extends Node

signal player_damaged(amount: int, source: String)
signal enemy_killed(enemy_id: String, position: Vector2)
signal item_collected(item_data: Resource)
signal game_paused
signal game_resumed
```

```gdscript
# In any script that needs to listen:
func _ready() -> void:
    EventBus.player_damaged.connect(_on_player_damaged)

func _on_player_damaged(amount: int, source: String) -> void:
    print("Took %d damage from %s" % [amount, source])
```

**Common mistakes:**
- Forgetting to disconnect persistent autoload signals when changing scenes (Godot auto-disconnects when the listener node is freed, but only with default connect flags)
- Emitting events during iteration (use `call_deferred("emit_signal", ...)` if needed)
- Overusing events for everything (direct calls are fine for tightly coupled systems)
- Making the EventBus a dumping ground (keep signals focused and well-named)

---

## Save/Load Serialization

**When to use:** Every game that needs to persist state. Start simple, add versioning when you ship.

```gdscript
class_name SaveManager extends Node

const SAVE_PATH := "user://save.json"
const CURRENT_VERSION: int = 1

static func save_game(data: Dictionary[String, Variant]) -> void:
    data["version"] = CURRENT_VERSION
    data["timestamp"] = Time.get_unix_time_from_system()

    var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if file:
        file.store_string(JSON.stringify(data, "\t"))

static func load_game() -> Dictionary:
    if not FileAccess.file_exists(SAVE_PATH):
        return {}

    var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
    if not file:
        return {}

    var content := file.get_as_text()
    var data: Variant = JSON.parse_string(content)
    if data is Dictionary:
        return _migrate(data)
    return {}

static func _migrate(data: Dictionary) -> Dictionary:
    # Handle version migrations:
    # if data.get("version", 0) < 2: data["new_field"] = default_value
    return data

static func delete_save() -> void:
    if FileAccess.file_exists(SAVE_PATH):
        DirAccess.remove_absolute(SAVE_PATH)
```

**Common mistakes:**
- Not versioning saves from day one (makes migration painful later)
- Saving non-serializable data (functions, circular references, Node references)
- Using `load()` or `save()` as method names (shadows GDScript globals — use `load_game()`/`save_game()`)
- Not handling corrupted save files gracefully

---

## Command Pattern (Undo/Redo)

**When to use:** Undo/redo, replays, AI action queues, networked actions.

**Important:** Each `class_name` must be in its own `.gd` file. The examples below show three separate files.

```gdscript
# command.gd — Base class
class_name Command extends RefCounted

func execute() -> void:
    pass

func undo() -> void:
    pass
```

```gdscript
# move_command.gd — A concrete command (one per file)
class_name MoveCommand extends Command

var _entity: Node2D
var _movement: Vector2

func _init(entity: Node2D, movement: Vector2) -> void:
    _entity = entity
    _movement = movement

func execute() -> void:
    _entity.position += _movement

func undo() -> void:
    _entity.position -= _movement
```

```gdscript
# command_history.gd — Manages the undo/redo stack
class_name CommandHistory extends RefCounted

var _history: Array[Command] = []
var _index: int = -1

func execute(command: Command) -> void:
    # Discard any future history (after undo)
    _history.resize(_index + 1)
    command.execute()
    _history.append(command)
    _index += 1

func undo() -> void:
    if _index >= 0:
        _history[_index].undo()
        _index -= 1

func redo() -> void:
    if _index < _history.size() - 1:
        _index += 1
        _history[_index].execute()

func can_undo() -> bool:
    return _index >= 0

func can_redo() -> bool:
    return _index < _history.size() - 1
```

**Common mistakes:**
- Putting multiple `class_name` declarations in one file (GDScript requires one per file)
- Commands that capture mutable state by reference (capture values, not references)
- Storing too much history (cap it or clear periodically)
