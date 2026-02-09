# Tooling: Linting, Testing & Validation

Quality enforcement pipeline: gdtoolkit linting, GdUnit4 testing, headless Godot validation, and per-increment quality checks.

All standards target **Godot 4.6** with static typing.

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
- Enable the static typing warnings listed in `TOOLING-types-nodes-and-resources.md` in Project Settings for additional safety.

> **Important limitation:** `gdlint` uses its own standalone parser and does **not** resolve cross-file types. It catches style issues (naming conventions, line length, formatting) but completely misses engine-level errors like "Could not find type 'X' in 'Y'" or broken `preload()` paths. Only `godot --headless --quit` validates the full type system and resource graph. **Both tools are necessary** — gdlint for style, headless Godot for correctness. Also note: `.gdlintrc` must be YAML format (not INI) despite some older documentation suggesting otherwise.

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

> **After renaming a `class_name`**, you must run `godot --headless --import --quit` first to rebuild the `.godot/global_script_class_cache.cfg`, then `--headless --quit` to validate. Without the import step, the cache still maps the old name and validation may silently pass or give misleading errors. The CI workflow and validation script handle this automatically.

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

### Troubleshooting: "missing dependencies" after file moves

When scripts or scenes are moved via git, CLI, or file explorer (not through Godot's editor), the `.godot/uid_cache.bin` still maps UIDs to old paths. Godot resolves `ext_resource` entries by UID first, path second — so even if the `.tscn` has the correct new path, the stale UID wins and loading fails with "missing dependencies."

**Fix:** Delete the `.godot/` folder and reopen the project. Godot regenerates the cache on next launch. This commonly happens after `git pull` or branch switches that reorganize files.

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
