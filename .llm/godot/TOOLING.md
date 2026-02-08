# Godot Tooling & GDScript Best Practices

Engine-specific tooling and coding standards for the Godot/GDScript path. See `PRINCIPLES.md` for engine-agnostic guidelines.

---

## File Naming

- **Scripts**: `snake_case.gd` — name describes content: `player_movement.gd`, not `utils.gd` or `helpers.gd`
- **Scenes**: `PascalCase.tscn` (Godot convention): `Player.tscn`, `MainMenu.tscn`
- **Resources**: `snake_case.tres` — `sword_stats.tres`, `level_config.tres`
- **Folders**: `snake_case/` — `player/`, `ui/`, `enemies/`
- **Class names**: `PascalCase` via `class_name` — matches what you'd type in code: `class_name PlayerController`

---

## Project Structure

Organize files by **what they represent in the game**, not by file type. Scripts live alongside their scenes (Godot convention). Every folder name should tell an LLM or a new developer what's inside without opening it.

### Baseline layout

```
res://
  entities/                     # Things that exist in the game world
    player/                     #   Player.tscn, player_controller.gd
    enemies/                    #   Enemy.tscn, enemy_ai.gd, enemy_patrol.gd
    npcs/                       #   Merchant.tscn, merchant_dialogue.gd
    pickups/                    #   HealthPickup.tscn, health_pickup.gd

  components/                   # Reusable behaviors attached to entities
    health_component.gd         #   Damage, healing, death signal
    attack_component.gd         #   Damage dealing, cooldowns
    movement_component.gd       #   Velocity, acceleration, steering
    hitbox_component.gd         #   Collision detection areas

  systems/                      # Game-wide managers and logic
    wave_spawner.gd             #   Spawning waves of enemies
    map_manager.gd              #   Map generation, tile management
    score_manager.gd            #   Score tracking, high scores

  autoloads/                    # Singletons (registered in Project Settings)
    event_bus.gd                #   Global signal hub
    audio_manager.gd            #   Music/SFX playback, bus routing
    scene_manager.gd            #   Scene transitions, loading screens

  ui/                           # All user interface
    hud/                        #   In-game HUD (health bars, score, minimap)
    menus/                      #   Main menu, pause, settings, game over

  world/                        # Level and environment
    tiles/                      #   Tile scenes, tile definitions
    levels/                     #   Level scenes, level data
    environment/                #   Backgrounds, skyboxes, lighting setups

  data/                         # .tres Resource instances (configs, stats)
    enemies/                    #   enemy_goblin_stats.tres
    items/                      #   sword_stats.tres, potion_stats.tres
    levels/                     #   level_1_config.tres

  assets/                       # Raw art, audio, fonts
    sprites/                    #   2D images, spritesheets
    models/                     #   3D models (.gltf, .glb)
    audio/
      sfx/                      #   Sound effects
      music/                    #   Background music
    fonts/                      #   Font files

  tests/                        # GdUnit4 test files
    test_health_component.gd    #   Mirrors structure: components → tests
    test_wave_spawner.gd        #   Mirrors structure: systems → tests

  main.tscn                     # Entry scene (stays in root)
  main.gd                       # Entry script
  project.godot                 # Project config
```

### Rules

1. **Scripts and scenes stay together.** `entities/enemies/Enemy.tscn` and `entities/enemies/enemy_ai.gd` live in the same folder. Don't separate scripts into a `scripts/` folder and scenes into a `scenes/` folder.

2. **Create folders from the first file, not after the fifth.** When you write the first enemy, put it in `entities/enemies/`, not in the root "for now." Moving files later breaks resource paths and creates unnecessary churn.

3. **Folder names describe contents, not abstractions.** Use `entities/enemies/` not `game_objects/type_b/`. Use `components/health_component.gd` not `shared/modules/hp.gd`.

4. **Autoloads get their own folder.** They're special (singletons, persist across scenes) and should be visually separated. Register them in Project Settings from `autoloads/`.

5. **Data (`.tres`) is separate from code.** Resource *class definitions* (`.gd` scripts that extend `Resource`) live near the code that uses them. Resource *instances* (`.tres` files with actual values) live in `data/`.

6. **Tests mirror game structure.** A test for `components/health_component.gd` goes in `tests/test_health_component.gd`. This makes it obvious what's tested and what isn't.

7. **Don't create empty folders.** Only add a folder when you have a file for it. But when you do have the file, put it in the right place immediately.

### Why this matters for LLM-assisted development

When an LLM searches the codebase, it navigates by file and folder names. A well-organized project means:
- **Faster lookups**: searching for "enemy" finds `entities/enemies/` immediately
- **Less context needed**: the folder path tells the LLM what role a file plays
- **Fewer mistakes**: the LLM won't accidentally modify `health_component.gd` when it meant to change `enemy_health_display.gd` because they're in different folders with clear purposes
- **Better new code placement**: the LLM knows where to put a new file because the structure makes the answer obvious

---

## GDScript File Ordering

Follow this ordering within every `.gd` file. Consistency across the project makes LLM-assisted editing reliable.

```gdscript
class_name MyClass          # 1. Class name (if needed)
extends Node2D              # 2. Extends

## Brief description of what this class does.   # 3. Docstring

# --- Signals ---           # 4. Signals
signal health_changed(new_value: int)
signal died

# --- Enums ---             # 5. Enums
enum State { IDLE, RUNNING, JUMPING }

# --- Constants ---         # 6. Constants
const MAX_SPEED: float = 200.0

# --- Exports ---           # 7. Exported variables (inspector-visible)
@export var speed: float = 100.0
@export var jump_force: float = 300.0

# --- Public variables ---  # 8. Public variables
var current_state: State = State.IDLE
var velocity_override: Vector2 = Vector2.ZERO

# --- Private variables --- # 9. Private variables (underscore prefix)
var _gravity: float = 980.0
var _is_grounded: bool = false

# --- Onready variables --- # 10. @onready (right before _ready)
@onready var _sprite: Sprite2D = $Sprite2D
@onready var _anim: AnimationPlayer = $AnimationPlayer

# --- Built-in virtual methods --- # 11. Lifecycle methods
func _ready() -> void:
    pass

func _process(delta: float) -> void:
    pass

func _physics_process(delta: float) -> void:
    pass

func _input(event: InputEvent) -> void:
    pass

# --- Public methods ---    # 12. Public methods
func take_damage(amount: int) -> void:
    pass

# --- Private methods ---   # 13. Private methods
func _apply_gravity(delta: float) -> void:
    pass
```

**Why this order matters:** The LLM reads top-to-bottom. Signals and exports at the top give immediate context about the class's interface. Onready vars near `_ready()` makes initialization scannable.

---

## Static Typing

### The basics
- Type **all** variables: `var speed: float = 10.0`
- Type **all** function parameters and return values: `func move(dir: Vector2) -> void:`
- Type **all** arrays: `var enemies: Array[Enemy] = []`
- Type **all** dictionaries (4.4+): `var scores: Dictionary[String, int] = {}`
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

# GOOD — use typed Dictionary (4.4+)
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
@export_enum("Common", "Uncommon", "Rare", "Epic") var rarity: String = "Common"
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

---

## Signal Conventions

- **Name signals in past tense** — they announce something that happened:
  `signal health_changed`, `signal enemy_killed`, `signal level_loaded`
- **Include relevant data as typed parameters:**
  `signal damage_taken(amount: int, source: Node)`
- **Connect in `_ready()`, disconnect if the listener is freed before the emitter:**
  ```gdscript
  func _ready() -> void:
      EventBus.player_damaged.connect(_on_player_damaged)

  # Godot auto-disconnects when the listener is freed IF using the default flags.
  # Manual disconnect is needed only for cross-scene persistent connections.
  ```
- **Prefer signals over direct method calls** for communication between siblings or unrelated nodes.
- **Prefer direct method calls** for parent-to-child or tightly coupled components.

---

## Autoload Architecture

Autoloads are singleton nodes that persist across scene changes. They're Godot's answer to "where does global state live?"

**When to use autoloads:**
- Global services that every scene needs: `EventBus`, `AudioManager`, `SceneManager`, `SaveManager`
- Cross-scene state: player inventory, settings, score
- Each autoload should have a single, clear responsibility

**When NOT to use autoloads:**
- Game-specific logic (belongs in the current scene)
- Anything that should reset when the scene changes
- Data that only one scene cares about

**How many is too many:** Keep it under 5-6 autoloads. If you have more, some probably belong as scene-local nodes or Resources instead.

**Common anti-patterns:**
- **God autoload**: One massive `GameManager` that does everything. Split it up.
- **Storing all game state in one autoload**: Use Resources or scene-local state for scene-specific data.
- **Autoloads calling each other in circles**: Keep the dependency direction clear (one-way, or use signals).

**Registering autoloads:** Project Settings → Autoload tab. Order matters — autoloads listed first are ready first.

---

## Editor vs Code Workflow

Godot is an editor-centric engine. Knowing when to use the editor vs code makes development faster.

| Task | Use the Editor | Use Code |
|------|---------------|----------|
| **Scene composition** | Arrange nodes, set transforms, parent/child structure | Only when generating scenes procedurally |
| **Property tuning** | `@export` vars in the Inspector — iterate without touching code | Only for values that must be computed |
| **Animations** | `AnimationPlayer` for authored keyframe sequences | `Tween` for procedural/runtime animation |
| **Signals** | Connect simple signals in the editor (Node → Signals tab) | Connect in code when dynamic or when crossing scene boundaries |
| **UI layout** | `Control` nodes in the editor with anchors/containers | Code for dynamic UI (inventory grids, chat windows) |
| **Materials/Shaders** | Visual shader editor for prototyping, StandardMaterial3D in Inspector | Code shaders for custom effects, procedural materials |
| **Particle effects** | `GPUParticles2D/3D` in editor with visual tuning | Code only for runtime parameter changes |
| **Collision shapes** | Draw them in the editor | Code only for procedural/runtime generation |

**Key principle for LLM-assisted development:** The LLM writes `.gd` scripts and can create `.tscn` files in text format. But the user should do final scene composition, visual tuning, and signal wiring in the editor. Design scripts to be editor-friendly:
- Use `@export` for every tunable value (speed, health, colors, sounds)
- Use `@export_group` to organize the Inspector
- Use `@tool` scripts when you want editor-time previews
- Test with the editor's Play button, not just from code

---

## Threading

- Main thread until proven slow via profiling.
- Use `Thread`, `Mutex`, or `WorkerThreadPool` only when profiling shows a bottleneck.
- Common candidates: procedural generation, pathfinding, heavy AI computation.
- Always document WHY something runs off the main thread.
- Use `call_deferred()` to safely interact with the scene tree from threads.

---

## Linting & Formatting (MANDATORY)

- **gdtoolkit** provides `gdlint` (linting) and `gdformat` (formatting).
- **Install is required during bootstrap:** `pip install gdtoolkit`
- The pre-commit hook **blocks commits** if `gdlint` is not installed. This is not optional.
- Run:
  ```bash
  gdlint .            # Lint all GDScript files
  gdformat .          # Format all GDScript files
  gdformat --check .  # Check formatting without modifying files
  ```
- Configuration lives in `.gdlintrc` at the project root.
- Enable the static typing warnings listed above in Project Settings for additional safety.

---

## Testing

**Framework:** GdUnit4, installed as a git submodule at `addons/gdunit4/` during bootstrap.

### Setup (handled by bootstrap)

GdUnit4 is added automatically during bootstrap Step 10:
```bash
git submodule add https://github.com/MikeSchulze/gdUnit4.git addons/gdunit4
```

Anyone cloning the bootstrapped project gets it with:
```bash
git clone --recurse-submodules <repo-url>
```

If already cloned without `--recurse-submodules`:
```bash
git submodule update --init --recursive
```

### Running tests

| Method | Command |
|--------|---------|
| **Script (recommended)** | `./scripts/godot_test.sh` |
| **Specific test file** | `./scripts/godot_test.sh res://tests/test_health.gd` |
| **Inside Godot editor** | GdUnit4 panel → Run Tests |
| **Raw command** | `godot --headless -s addons/gdunit4/bin/GdUnitCmdTool.gd --add res://tests --run-tests` |
| **CI** | Runs automatically on every push |

### File conventions
- Test files live in `tests/` directory, mirroring the game's script structure
- Test class name: `Test` + class under test: `TestHealthComponent`
- Every test method starts with `test_`: `func test_damage_reduces_health()`

### What a good test looks like

```gdscript
# test_health_component.gd
class_name TestHealthComponent extends GdUnitTestSuite

var _health: HealthComponent

func before_test() -> void:
    _health = HealthComponent.new()
    _health.max_health = 100
    add_child(_health)  # Triggers _ready(), sets current_health

func after_test() -> void:
    _health.queue_free()

func test_initial_health_equals_max() -> void:
    assert_int(_health.current_health).is_equal(100)

func test_damage_reduces_health() -> void:
    _health.damage(30)
    assert_int(_health.current_health).is_equal(70)

func test_damage_cannot_go_below_zero() -> void:
    _health.damage(999)
    assert_int(_health.current_health).is_equal(0)

func test_died_signal_emitted_at_zero() -> void:
    # Monitor the signal before the action
    var monitor := monitor_signals(_health)
    _health.damage(100)
    await await_signal_on(_health, "died", [], 1000)
    # Verify signal was emitted
    verify(_health, 1).died.emit()
```

### What to test vs skip

| Test | Skip |
|------|------|
| State transitions (FSM enter/exit) | Visual appearance |
| Save/load round-trip | UI layout positioning |
| Damage calculations, health clamping | Animation playback |
| Inventory add/remove/stack logic | Particle effects |
| Score counting, progression math | Sound playing |
| Signal emission (verify connections fire) | Camera smoothing |

### Quick validation without GdUnit4

For simpler checks during development, use `assert()` in `_ready()` of a test scene:
```gdscript
# test_scene.gd — attached to a scene you run manually
extends Node

func _ready() -> void:
    var health := HealthComponent.new()
    health.max_health = 50
    add_child(health)
    assert(health.current_health == 50, "Initial health should equal max")
    health.damage(60)
    assert(health.current_health == 0, "Health should not go below zero")
    print("All tests passed.")
```

---

## Running the Game

- Open the project folder in Godot 4.6
- Press F5 (or the Play button) to run
- Use the Godot debugger for breakpoints, inspection, and **Step Out** (new in 4.6)
- Use **Tracy/Perfetto profiling** (4.6) for GDScript performance analysis

---

## Headless Godot Validation

The project enforces headless Godot testing to catch runtime errors automatically — no manual editor checks needed.

### What it does

Running `godot --headless --quit` loads the project, parses all scripts, initializes autoloads, loads the main scene, and exits. Any GDScript parse errors, missing references, broken signals, or load failures are caught and reported.

### How it runs

| Context | Behavior |
|---------|----------|
| **Pre-commit hook** | Runs automatically using `.gdenv` path. Warns if Godot not configured. |
| **CI** | Always runs. Godot is installed via `chickensoft-games/setup-godot`. |
| **Manual** | Run `./scripts/godot_validate.sh` (lint + headless in one command) |
| **Lint only** | Run `./scripts/godot_validate.sh --lint` |
| **Headless only** | Run `./scripts/godot_validate.sh --headless` |

### Configuring the Godot binary path (`.gdenv`)

During bootstrap, the LLM asks the user for their Godot executable path and creates a `.gdenv` file in the project root. This file is gitignored (machine-specific).

**Format:**
```bash
# .gdenv — Machine-specific Godot binary path
GODOT_BIN="/full/path/to/godot"
```

**Lookup order** (used by both the pre-commit hook and `scripts/godot_validate.sh`):
1. `GODOT_BIN` from `.gdenv` file in project root
2. `GODOT_BIN` environment variable (if set)
3. `godot` command in PATH (fallback)

**Common paths by platform:**
- **Windows**: `C:\Users\YourName\Godot\Godot_v4.6-stable_win64.exe`
- **macOS**: `/Applications/Godot.app/Contents/MacOS/Godot`
- **Linux**: `/home/yourname/Godot/Godot_v4.6-stable_linux.x86_64`

If the bootstrap didn't create `.gdenv` (e.g., cloning an existing project), create it manually:
```bash
echo 'GODOT_BIN="/path/to/your/godot"' > .gdenv
```

### What errors it catches

- GDScript parse errors (syntax, missing references)
- Missing autoload scripts
- Broken scene resource paths
- Invalid node references in `@onready` vars
- Missing class_name dependencies

### What it does NOT catch

- Logic bugs (use GdUnit4 tests for those)
- Visual issues (requires editor or running the game)
- Input handling (requires player interaction)

---

## Quality Checks (Every Increment)

The pre-commit hook and `scripts/godot_validate.sh` automate these, but you can also run them manually:

```bash
gdlint .                        # No lint warnings (MANDATORY)
gdformat --check .              # Formatting is consistent (MANDATORY)
godot --headless --quit          # No parse/load errors (auto in hook + CI)
./scripts/godot_validate.sh     # All of the above in one command
```
- Test new systems with GdUnit4 or test scenes
- Check for `UNSAFE_*` warnings in the editor output panel
