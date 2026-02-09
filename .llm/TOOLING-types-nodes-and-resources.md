# Tooling: Types, Nodes & Resources

GDScript type system, choosing the right node base class, custom Resources for data-driven design, and export variable organization.

All standards target **Godot 4.6** with static typing.

---

## Static Typing

### The basics
- Type **all** variables: `var speed: float = 10.0`
- Type **all** function parameters and return values: `func move(dir: Vector2) -> void:`
- Type **all** arrays: `var enemies: Array[Enemy] = []`
- Type **all** dictionaries: `var scores: Dictionary[String, int] = {}`
- Use type inference (`:=`) only when the type is obvious from context: `var name := "Player"`

### Project-level type safety warnings

Enable these in **Project Settings → Debug → GDScript** to enforce typing discipline engine-wide:

| Setting | Value | Purpose |
|---------|-------|---------|
| `UNTYPED_DECLARATION` | Warn or Error | Catches `var x = 5` (should be `var x: int = 5`) |
| `UNSAFE_PROPERTY_ACCESS` | Warn | Catches property access on untyped variables |
| `UNSAFE_METHOD_ACCESS` | Warn | Catches method calls on untyped variables |
| `UNSAFE_CAST` | Warn | Catches casts that could fail at runtime |
| `INFERRED_DECLARATION` | Off (or Warn) | Optional — warns on `:=` if you prefer explicit types |

**Recommendation:** Set `UNTYPED_DECLARATION` to **Error** for new projects. This makes the editor flag any untyped variable immediately.

### Anti-patterns to avoid

**Never combine `@onready` with `@export`:**
```gdscript
# BAD — @onready silently overrides the exported value after scene load
@export @onready var target: Node2D = $Target

# GOOD — use one or the other
@export var target: Node2D           # Set in inspector
@onready var _target: Node2D = $Target  # Set by scene tree
```

**Never use untyped Dictionary for structured data:**
```gdscript
# BAD — no type safety, easy to misspell keys
var player: Dictionary = {"health": 100, "name": "Hero"}

# GOOD — use typed Dictionary
var scores: Dictionary[String, int] = {"Alice": 100, "Bob": 200}

# BETTER for complex structures — use a custom Resource
class_name PlayerData extends Resource
@export var health: int = 100
@export var player_name: String = "Hero"
```

**Avoid `Variant` when a concrete type is known:**
```gdscript
# BAD — bypasses compile-time checks
var thing = get_node("Something")

# GOOD — cast to known type
var sprite: Sprite2D = $Sprite2D as Sprite2D
```

---

## Node Type Selection Guide

Choosing the right base class is a foundational Godot decision.

| Base Class | When to Use | Memory | Example |
|------------|-------------|--------|---------|
| **Node** | Pure logic, no position needed | Lightest | GameManager, StateMachine, EventBus |
| **Node2D** | 2D positioned object | Light | Any 2D game entity |
| **Node3D** | 3D positioned object | Light | Any 3D game entity |
| **CharacterBody2D/3D** | Player/NPC with move_and_slide | Medium | Player, enemies, NPCs |
| **RigidBody2D/3D** | Physics-driven objects | Medium | Crates, balls, ragdolls |
| **StaticBody2D/3D** | Immovable collision | Light | Walls, floors, platforms |
| **Area2D/3D** | Overlap detection, no physics response | Light | Triggers, pickups, hitboxes |
| **Resource** | Data container, no scene tree presence | Lightest | Item stats, config, save data |
| **RefCounted** | Logic object, no scene tree, auto-freed | Lightest | Commands, calculations, DTOs |

**Rules of thumb:**
- If it doesn't need to be in the scene tree → `Resource` or `RefCounted`
- If it needs position but not physics → `Node2D`/`Node3D`
- If it needs physics movement → `CharacterBody` or `RigidBody`
- If it's purely data → `Resource` (serializable, inspector-editable, shareable)

---

## Custom Resources

Resources are one of Godot's most powerful features. Use them for any data that:
- Needs to be editable in the Inspector
- Should be saved as `.tres` files
- Can be shared across multiple nodes
- Represents configuration, stats, or definitions

```gdscript
# item_data.gd
class_name ItemData extends Resource

@export var item_name: String = ""
@export var description: String = ""
@export var icon: Texture2D
@export var stack_size: int = 1
@export var value: int = 0
@export var rarity: Rarity = Rarity.COMMON

enum Rarity { COMMON, UNCOMMON, RARE, EPIC }
```

Then create `.tres` files in the editor for each item. Reference them in code:
```gdscript
@export var weapon_data: ItemData  # Drag-and-drop in inspector
```

**When NOT to use Resources:**
- For state that changes every frame (use variables)
- When you need scene tree access (use Nodes)
- For one-off data (just use variables or constants)

---

## Export Variable Organization

Use `@export_group` and `@export_subgroup` to organize the Inspector for complex nodes:

```gdscript
@export_group("Movement")
@export var speed: float = 200.0
@export var acceleration: float = 1000.0
@export var friction: float = 800.0

@export_group("Combat")
@export var max_health: int = 100
@export var attack_damage: int = 10
@export_subgroup("Resistances")
@export var fire_resistance: float = 0.0
@export var ice_resistance: float = 0.0

@export_group("Audio")
@export var hit_sound: AudioStream
@export var death_sound: AudioStream
```
