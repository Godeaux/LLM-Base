# Patterns: Entities, Components & Object Pooling

How to structure game entities with composable behaviors, define data-driven content, and efficiently manage frequently spawned objects.

All examples target **Godot 4.6** with static typing.

---

## Component Pattern

**When to use:** When entities need flexible, composable behaviors. Alternative to deep inheritance. Works identically in 2D and 3D — swap the base types.

### 2D Example
```gdscript
# Scene tree:
# Player (CharacterBody2D)
#   ├── HealthComponent
#   ├── MovementComponent
#   ├── Sprite2D
#   └── CollisionShape2D

# health_component.gd — Dimension-agnostic (extends Node, not Node2D)
class_name HealthComponent extends Node

signal health_changed(new_health: int)
signal died

@export var max_health: int = 100
var current_health: int

func _ready() -> void:
    current_health = max_health

func damage(amount: int) -> void:
    current_health = maxi(0, current_health - amount)
    health_changed.emit(current_health)
    if current_health == 0:
        died.emit()
```

### 3D Example
```gdscript
# Scene tree:
# Player (CharacterBody3D)
#   ├── HealthComponent       (same script — Node base, reusable)
#   ├── MovementComponent3D   (3D-specific)
#   ├── MeshInstance3D
#   └── CollisionShape3D

# movement_component_3d.gd
class_name MovementComponent3D extends Node

@export var speed: float = 5.0
@export var gravity: float = 9.8

var _body: CharacterBody3D

func _ready() -> void:
    _body = get_parent() as CharacterBody3D

func _physics_process(delta: float) -> void:
    if not _body:
        return
    var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    _body.velocity.x = input_dir.x * speed
    _body.velocity.z = input_dir.y * speed
    _body.velocity.y -= gravity * delta
    _body.move_and_slide()
```

**Key insight:** Components that don't need position (`HealthComponent`, `StateMachine`) should extend `Node` — this makes them reusable across 2D and 3D. Only extend `Node2D`/`Node3D` when the component needs its own transform.

**Common mistakes:**
- Over-engineering for small games (inheritance is fine for simple cases)
- Components that know too much about each other (use signals between siblings)
- Making dimension-agnostic components depend on 2D or 3D types

---

## Custom Resource Pattern (Data-Driven Design)

**When to use:** Item definitions, enemy stats, level configs, ability definitions — anything you'd put in a JSON file but want type-safe and Inspector-editable.

```gdscript
# weapon_data.gd
class_name WeaponData extends Resource

@export var weapon_name: String = ""
@export var damage: int = 10
@export var attack_speed: float = 1.0
@export var range_val: float = 1.5
@export var icon: Texture2D
@export_multiline var description: String = ""
@export var projectile_scene: PackedScene  # null for melee
```

Create `.tres` files in the editor for each weapon. Reference them:
```gdscript
@export var data: WeaponData  # Drag-and-drop in Inspector

# Or load from code:
var sword: WeaponData = preload("res://data/weapons/sword.tres")
```

**Common mistakes:**
- Mutating shared Resources at runtime (all references share the same instance — use `duplicate()` for mutable copies)
- Putting behavior in Resources (they're data; logic belongs in the node using them)
- Deeply nesting Resources (keep flat; compose in the Inspector)

---

## Object Pool

**When to use:** Frequently spawned/destroyed objects — bullets, particles, enemies. Reduces allocation overhead.

```gdscript
class_name ObjectPool extends Node

@export var scene: PackedScene
@export var initial_size: int = 10

var _pool: Array[Node] = []
var _active: Array[Node] = []

func _ready() -> void:
    for i: int in initial_size:
        var obj := scene.instantiate()
        obj.set_process(false)
        obj.visible = false
        add_child(obj)
        _pool.append(obj)

func acquire() -> Node:
    var obj: Node
    if _pool.is_empty():
        obj = scene.instantiate()
        add_child(obj)
    else:
        obj = _pool.pop_back()

    obj.set_process(true)
    obj.visible = true
    _active.append(obj)

    if obj.has_method("reset"):
        obj.reset()
    return obj

func release(obj: Node) -> void:
    if obj in _active:
        _active.erase(obj)
        obj.set_process(false)
        obj.visible = false
        _pool.append(obj)

func get_active_count() -> int:
    return _active.size()
```

**Common mistakes:**
- Forgetting to reset state when reusing objects (implement a `reset()` method on pooled scenes)
- Not releasing objects back to the pool (track with signals or timers)
- Pre-allocating too many objects (start small, grow as needed)
- Using pools for objects that rarely spawn (overhead not worth it)
