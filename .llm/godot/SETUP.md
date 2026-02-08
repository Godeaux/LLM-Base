# Godot Path Setup — GDScript

> **Instructions for the LLM during Bootstrap Step 5.**
> This file describes how to configure the project after the user confirms the Godot/GDScript path.

---

## Prerequisites

The user has confirmed Path B (Godot/GDScript) in Bootstrap Step 4. Now rewrite the foundation.

**Fill in `.llm/DISCOVERY.md` FIRST.** The pre-commit hook blocks commits if it still contains template placeholders.

**Templates available:** The `.godot-template/` folder contains starter files. Copy and customize them — don't start from scratch.

---

## Setup Steps

### 1. Fill in `.llm/DISCOVERY.md`

Fill in ALL blank fields with the user's actual answers from the bootstrap conversation. This unlocks everything else.

### 2. Fill in `.llm/DECISIONS.md`

This file was promoted from `.llm/godot/DECISIONS.md` during cleanup. Fill in with Godot-specific decisions (version, rendering method, physics approach, scene structure). Replace the web-centric dependencies table with Godot equivalents (addons, GDExtensions if any).

### 3. Delete web-specific files

Remove these files entirely:
- `package.json`
- `package-lock.json` (if exists)
- `tsconfig.json`
- `eslint.config.js`
- `.prettierrc`
- `src/` directory
- `tests/` directory
- `node_modules/` (if exists)

These are not archived. To switch to web path later, clone fresh and re-run bootstrap.

### 4. Copy and customize `project.godot`

Start from `.godot-template/project.godot`:
```ini
config_version=5

[application]
config/name="Your Game Name"        ; ← Update this
config/features=PackedStringArray("4.6")
run/main_scene="res://main.tscn"

[rendering]
renderer/rendering_method="forward_plus"  ; ← Or "mobile" / "gl_compatibility"
                                          ; forward_plus is best for 3D
                                          ; gl_compatibility is best for 2D or low-end targets
```

### 5. Copy and customize entry scene

Start from `.godot-template/main.tscn` and `.godot-template/main.gd`. Customize based on the dimension choice from DECISIONS.md:

#### For 2D games:
```gdscript
extends Node2D

func _ready() -> void:
    print("Game started. 2D foundation is working.")
```
Scene structure: `Node2D` root + `Camera2D` child.

#### For 3D games:
```gdscript
extends Node3D

func _ready() -> void:
    print("Game started. 3D foundation is working.")
```
Scene structure: `Node3D` root + `Camera3D` child. Consider adding a `DirectionalLight3D` and `WorldEnvironment` so the user sees something immediately.

#### For 2.5D games (3D rendering, 2D gameplay):
Use the 3D scene structure above, but add a note in the script:
```gdscript
extends Node3D
## 2.5D setup: 3D rendering with constrained gameplay axes.
## Camera is typically fixed-angle orthographic or limited-perspective.

func _ready() -> void:
    print("Game started. 2.5D foundation is working.")
```

**In all cases:** The entry scene should display *something* on first run — even a colored background or a label. "It works" confirmation on first Play press builds confidence.

### 6. Copy `.gdlintrc`

Copy `.godot-template/.gdlintrc` to the project root. This configures GDScript linting (enforces naming conventions, line length, etc.).

### 7. Install gdtoolkit (MANDATORY)

Install the GDScript linting and formatting toolkit immediately:

```bash
pip install gdtoolkit
```

Verify the installation:
```bash
gdlint --version
gdformat --version
```

**This is not optional.** The pre-commit hook requires `gdlint` to be installed locally and will block commits if it is missing. Do not proceed until this is confirmed working.

### 8. Verify headless Godot validation

The repository includes `scripts/godot_validate.sh` which runs Godot in headless mode to catch runtime errors without opening the editor. Verify it works:

```bash
chmod +x scripts/godot_validate.sh
./scripts/godot_validate.sh
```

This script:
- Runs `gdlint` on all `.gd` files
- Runs `gdformat --check` on all `.gd` files
- Runs `godot --headless --quit` to load the project and catch parse/load errors

The pre-commit hook calls this script automatically. If the `godot` binary is not in PATH, the hook will warn but still enforce linting. CI always runs the full validation including headless Godot.

**Tell the user:** *"Make sure the `godot` command is accessible from your terminal. On Linux, this usually means adding Godot to your PATH. On macOS, you can symlink the binary. The pre-commit hook and CI both use headless Godot to catch errors automatically."*

### 9. Update `.husky/pre-commit`

The hook is already configured to:
- **Require** `gdlint` on all staged `.gd` files (blocks commit if not installed)
- **Run** headless Godot validation if the `godot` binary is in PATH
- **Warn** if `godot` is not in PATH (CI will still catch errors)

No manual changes needed — just confirm `gdlint` is installed (Step 7).

### 10. Rewrite `README.md`

Rewrite to describe the Godot project. Replace npm scripts table with Godot workflow:
```markdown
## Running the Game
1. Open this folder in Godot 4.6+
2. Press F5 (or Play button) to run

## Prerequisites
- Python 3.x with pip (for gdtoolkit)
- Godot 4.6+ CLI accessible as `godot` in PATH (for headless validation)

## Setup
Install linting tools (required — pre-commit hook enforces this):
```
pip install gdtoolkit
```

## Validation
Run the full validation suite manually:
```
./scripts/godot_validate.sh
```

This runs gdlint, gdformat --check, and headless Godot to catch errors.
```

### 11. Clean up `.godot-template/`

After copying the files you need, delete the `.godot-template/` folder. It won't interfere with Godot if left, but it's cleaner to remove.

---

## Files to NOT Touch

- `.llm/PERSONAS.md` — useful as-is for ongoing development
- `.llm/PRINCIPLES.md` — useful as-is for ongoing development
- `.llm/BOOTSTRAP.md` — leave for reference
- `CLAUDE.md` — project instructions; leave as-is
- Don't create game-specific folders or systems yet

---

## Verification

After setup is complete:

1. Confirm `project.godot` is valid and the entry scene exists
2. Confirm `gdlint --version` runs successfully
3. Run `./scripts/godot_validate.sh` and confirm it passes (or passes lint with a warning about missing `godot` binary)
4. Make a test commit to confirm the pre-commit hook fires and enforces linting
5. Tell the user: *"The foundation is configured with enforced linting and headless validation. Open this folder in Godot 4.6 and hit Play to see the base scene. Every commit will auto-check for lint errors and runtime issues. Now let's define your first playable — the smallest version where you can feel if the core is fun."*

Then transition to normal development using the personas in `PERSONAS.md`.
