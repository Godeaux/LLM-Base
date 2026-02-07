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

### 7. Update `.husky/pre-commit`

The hook already supports Godot projects. If `gdlint` is installed locally, it will run on commit. Otherwise, CI handles linting.

### 8. Rewrite `README.md`

Rewrite to describe the Godot project. Replace npm scripts table with Godot workflow:
```markdown
## Running the Game
1. Open this folder in Godot 4.6+
2. Press F5 (or Play button) to run

## Linting
Install gdtoolkit: `pip install gdtoolkit`
Run: `gdlint .`
```

### 9. Clean up `.godot-template/`

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
2. Tell the user: *"The foundation is configured. Open this folder in Godot 4.6 and hit Play to see the base scene. Now let's define your first playable — the smallest version where you can feel if the core is fun."*

Then transition to normal development using the personas in `PERSONAS.md`.
