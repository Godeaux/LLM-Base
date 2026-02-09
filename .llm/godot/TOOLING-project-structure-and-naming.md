# Tooling: Project Structure & Naming

How to name files, organize folders, and order code within GDScript files.

All standards target **Godot 4.6** with static typing.

---

## File Naming

- **Scripts**: `snake_case.gd` — name describes content: `player_movement.gd`, not `utils.gd` or `helpers.gd`
- **Scenes**: `PascalCase.tscn` (Godot convention): `Player.tscn`, `MainMenu.tscn`
- **Resources**: `snake_case.tres` — `sword_stats.tres`, `level_config.tres`
- **Folders**: `snake_case/` — `player/`, `ui/`, `enemies/`
- **Class names**: `PascalCase` via `class_name` — matches what you'd type in code: `class_name PlayerController`

> **class_name gotcha:** Never use a `class_name` that shadows a built-in Godot class. For example, `class_name TileData` silently collides with Godot's native `TileData` (TileMap system). The engine resolves the name to the built-in class, so `TileData.MyEnum` fails with a cryptic "Could not find type" error — no hint about the collision. Before choosing a `class_name`, check the [Godot class list](https://docs.godotengine.org/en/stable/classes/index.html). When in doubt, prefix with your project's domain: `MyTileData`, `GameCamera`, etc.

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
