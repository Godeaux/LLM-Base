# Godot Principles

Godot-specific philosophy, idioms, and best practices. This complements the universal principles in `PRINCIPLES.md`.

The goal here isn't just to tell you what to do—it's to explain *why* Godot works the way it does, so you can make good decisions on your own.

---

## The Godot Philosophy

### Scenes Are Your Building Blocks

In Godot, a "scene" isn't just a level—it's any reusable piece of your game. A player is a scene. A bullet is a scene. A health bar is a scene. A door is a scene.

**Why this matters:** Instead of writing code that constructs objects, you *compose* them visually in the editor, then instance them from code when needed. This means:
- You can see and tweak your game objects without running the game
- Non-programmers can adjust values via `@export` without touching code
- Complex objects are built from simple parts, not massive scripts

```gdscript
# Spawning is just instancing a scene
var bullet := bullet_scene.instantiate()
bullet.position = muzzle.global_position
get_parent().add_child(bullet)
```

### Nodes Do One Thing

Each node type has a single responsibility. A `Sprite2D` draws an image. An `AudioStreamPlayer` plays sound. A `CollisionShape2D` defines collision geometry.

**Why this matters:** You build complex behavior by combining simple nodes, not by cramming everything into one script. If your script is doing five different things, you probably need five child nodes with their own scripts.

```
# Good: Each concern is a separate node
Player (CharacterBody2D)
├── Sprite2D
├── CollisionShape2D
├── AnimationPlayer
├── HealthComponent      # Custom script
├── HurtboxArea2D
└── AudioStreamPlayer2D

# Bad: One node doing everything
Player (CharacterBody2D)
└── [500-line script handling movement, animation, health, audio, collision...]
```

### The Tree Is Your Architecture

The node tree isn't just organization—it's how your game runs. Parent nodes process before children. Signals flow through the tree. Physics bodies inherit transforms.

**Why this matters:** Where you place a node affects how it behaves. Understanding the tree helps you:
- Control processing order (parent `_process` runs before children)
- Manage transforms (child positions are relative to parent)
- Organize signals (children can easily signal to parents)

---

## Scene Composition

### Prefer Composition Over Inheritance

Godot supports class inheritance, but scene composition is almost always better.

**Inheritance** creates rigid hierarchies:
```gdscript
# Fragile: What if you want a flying enemy that doesn't walk?
class_name Enemy extends CharacterBody2D
class_name WalkingEnemy extends Enemy
class_name FlyingEnemy extends Enemy  # Duplicates code or breaks hierarchy
```

**Composition** creates flexible parts:
```
Enemy (CharacterBody2D)
├── MovementComponent     # Swap this for flying, walking, stationary
├── HealthComponent       # Reuse across player, enemies, destructibles
├── AIComponent           # Different AI scripts for different behaviors
└── ...
```

You can change an enemy's movement style by swapping one child node—no refactoring required.

### Pack Reusable Pieces as Scenes

If you build something once and might need it again, save it as a `.tscn` file.

```
scenes/
  components/
    health_component.tscn
    hitbox.tscn
    hurtbox.tscn
  enemies/
    slime.tscn
    bat.tscn
  player/
    player.tscn
```

Even if you only use it once *now*, making it a scene keeps your options open and forces clean boundaries.

---

## Signals and Communication

### Signals Decouple Systems

Signals let nodes communicate without knowing about each other directly.

```gdscript
# health_component.gd
signal health_changed(new_health: int, max_health: int)
signal died

func take_damage(amount: int) -> void:
    health = max(0, health - amount)
    health_changed.emit(health, max_health)
    if health == 0:
        died.emit()
```

The health component doesn't know what happens when you die—it just announces it. The parent scene connects that signal to whatever should happen (play animation, drop loot, respawn, show game over).

### When to Use What

| Situation | Use This | Why |
|-----------|----------|-----|
| Child notifies parent | Signal | Parent connects in `_ready`, clean dependency direction |
| Parent tells child | Direct call | Parent already has reference via `$ChildName` |
| Unrelated systems communicate | Autoload signal bus | No direct path in tree |
| One-to-many broadcast | Groups + `call_group` | Enemies, collectibles, anything with many instances |
| UI reacts to game state | Signal bus or direct bind | Keep UI decoupled from game logic |

### Avoid Signal Spaghetti

Signals are powerful but can become tangled if overused. Guidelines:
- Signals flow UP (child to parent) or OUT (to unrelated systems)
- Direct calls flow DOWN (parent to child)
- If you're connecting signals in circles, step back and reconsider the architecture

---

## GDScript Idioms

### Use Static Typing

GDScript is optionally typed, but you should always use types. They catch bugs, improve autocomplete, and serve as documentation.

```gdscript
# Good: Types everywhere
var speed: float = 200.0
var direction: Vector2 = Vector2.ZERO
@onready var sprite: Sprite2D = $Sprite2D

func move(delta: float) -> void:
    position += direction * speed * delta

func take_damage(amount: int) -> bool:
    health -= amount
    return health <= 0
```

Enable "Unsafe Lines" warnings in Editor Settings → GDScript to catch untyped code.

### @onready for Node References

Use `@onready` to grab child nodes. It runs right before `_ready()`, so nodes exist but your setup code hasn't run yet.

```gdscript
# Good: Clean and typed
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var animation: AnimationPlayer = $AnimationPlayer

# Bad: String paths scattered through code
func _process(delta: float) -> void:
    get_node("Sprite2D").flip_h = velocity.x < 0  # Fragile, no autocomplete
```

### @export for Designer-Tweakable Values

Use `@export` for any value that might need tuning. It appears in the Inspector, so you (or a designer) can adjust without editing code.

```gdscript
@export var move_speed: float = 200.0
@export var jump_force: float = 400.0
@export var gravity_scale: float = 1.0
@export_range(0.0, 1.0) var friction: float = 0.8
@export var projectile_scene: PackedScene  # Drag-and-drop in editor
```

If you're hardcoding a number that affects gameplay feel, it should probably be `@export`.

### Enums for State

Use enums instead of strings or magic numbers for state.

```gdscript
enum State { IDLE, RUNNING, JUMPING, FALLING, ATTACKING }
var current_state: State = State.IDLE

func _physics_process(delta: float) -> void:
    match current_state:
        State.IDLE:
            handle_idle(delta)
        State.RUNNING:
            handle_running(delta)
        State.JUMPING:
            handle_jumping(delta)
        # ...
```

This gives you autocomplete, typo protection, and clear intent.

---

## Resources for Data

### Custom Resources Beat Dictionaries

For game data (items, stats, abilities, enemy definitions), use custom Resources instead of dictionaries.

```gdscript
# item_data.gd
class_name ItemData extends Resource

@export var name: String
@export var icon: Texture2D
@export var value: int
@export_multiline var description: String
@export var stackable: bool = true
@export var max_stack: int = 99
```

Then create `.tres` files in the editor for each item. Benefits:
- Editor support (Inspector, drag-and-drop)
- Type safety
- Autocomplete on properties
- Can be preloaded and shared

```gdscript
# Using a resource
@export var item: ItemData  # Drag .tres file here in Inspector

func pickup() -> void:
    inventory.add(item)
    print("Picked up: ", item.name)
```

### Resources Are Shared by Default

When you load a Resource, Godot caches it. Multiple references point to the same object.

```gdscript
var sword_a := preload("res://items/sword.tres")
var sword_b := preload("res://items/sword.tres")
# sword_a and sword_b are the SAME object

sword_a.damage = 999  # This affects sword_b too!
```

If you need independent copies, use `.duplicate()`:
```gdscript
var my_sword := preload("res://items/sword.tres").duplicate()
```

---

## Process Functions

### _process vs _physics_process

| Function | When It Runs | Use For |
|----------|--------------|---------|
| `_process(delta)` | Every frame (variable rate) | Visuals, UI, input polling, animations |
| `_physics_process(delta)` | Fixed interval (default 60/sec) | Movement, physics, gameplay logic |

**Why this matters:** Physics needs consistent timing to be deterministic. If you move a `CharacterBody2D` in `_process`, it'll behave differently at 30fps vs 144fps.

```gdscript
# Good: Physics in physics_process
func _physics_process(delta: float) -> void:
    velocity.y += gravity * delta
    move_and_slide()

# Good: Visuals in process
func _process(delta: float) -> void:
    sprite.rotation = velocity.angle()  # Visual polish, doesn't affect physics
```

### Disable Processing When Not Needed

Nodes process every frame by default. For objects that don't need it (static decorations, pooled objects waiting to spawn), disable processing:

```gdscript
func deactivate() -> void:
    set_process(false)
    set_physics_process(false)
    hide()

func activate() -> void:
    set_process(true)
    set_physics_process(true)
    show()
```

---

## Common Anti-Patterns

### God Nodes

**Problem:** One node with a massive script that handles everything.

**Solution:** Split into child nodes with focused scripts. If a script has regions like `# MOVEMENT`, `# COMBAT`, `# INVENTORY`, those should be separate nodes.

### Autoload Soup

**Problem:** Everything is a global autoload, everything references everything.

**Solution:** Autoloads are for truly global systems (event bus, save manager, audio manager). Most game logic should live in the scene tree with proper signal flow.

### get_node() String Spaghetti

**Problem:** `get_node("../../../Game/UI/HealthBar")` scattered everywhere.

**Solution:**
- Child nodes: `@onready var thing := $Thing`
- Siblings/parents: Pass references via signals or `@export`
- Unrelated systems: Signal bus autoload

### Checking Input in Multiple Places

**Problem:** Multiple scripts all checking `Input.is_action_pressed("jump")`.

**Solution:** Centralize input handling in one place (usually the player controller), then call methods or emit signals to other systems.

---

## Testing in Godot

### Test Scenes

Create simple scenes that test one system in isolation:

```
test_scenes/
  test_player_movement.tscn   # Just player + flat ground
  test_combat.tscn            # Player + dummy enemy
  test_inventory.tscn         # Inventory UI + some items
```

Run these directly (F6 on the scene) to iterate fast without loading the full game.

### GdUnit4 for Automated Tests

For logic-heavy code (damage calculations, state machines, inventory management), use GdUnit4:

```gdscript
# test/test_health_component.gd
extends GdUnitTestSuite

var health: HealthComponent

func before_test() -> void:
    health = HealthComponent.new()
    health.max_health = 100
    health.health = 100

func test_take_damage_reduces_health() -> void:
    health.take_damage(30)
    assert_int(health.health).is_equal(70)

func test_cannot_go_below_zero() -> void:
    health.take_damage(999)
    assert_int(health.health).is_equal(0)
```

### What to Test

- State transitions (FSM, game phases)
- Calculations (damage, economy, cooldowns)
- Save/load serialization
- Edge cases (empty inventory, zero health, max stack)

### What NOT to Test

- Rendering (you'll see if it's broken)
- Node tree structure (test behavior, not implementation)
- Simple getters/setters

---

## Tooling

### gdlint and gdformat

Use `gdtoolkit` to enforce consistent style:

```bash
pip install gdtoolkit
gdlint .           # Check for issues
gdformat .         # Auto-format code
gdformat --check . # Check without modifying (for CI)
```

Configure via `.gdlintrc` in your project root.

### Editor Settings Worth Changing

- **Text Editor → Completion → Add Type Hints:** Enable
- **Text Editor → Editor → Line Numbers:** Relative (easier navigation)
- **Debug → Settings → Unsafe Lines:** Enable (shows untyped code)
- **Filesystem → Import → Deduplicate On Import:** Consider for large projects

---

## Asset Formats for Godot

| Type | Format | Notes |
|------|--------|-------|
| 2D Sprites | PNG | Transparency support, lossless |
| Spritesheets | PNG | Use Godot's AtlasTexture or AnimatedSprite2D |
| 3D Models | glTF/GLB | Best Godot support, includes materials |
| 3D Models (alt) | .blend | Godot 4 imports Blender files directly |
| Audio (music) | OGG Vorbis | Good compression, looping support |
| Audio (SFX) | WAV | Low latency, small files |
| Data | .tres | Custom Resources, editor-friendly |
| Scenes | .tscn | Text format, git-friendly |
