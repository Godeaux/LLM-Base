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

**Note on shared configuration files:** The `.github/workflows/ci.yml` and `.husky/pre-commit` files contain conditional logic supporting both web and Godot paths. After deleting `package.json` above, the web-specific steps become inert — CI checks for `package.json` and skips web steps when it's absent. The unused web steps are harmless and can optionally be removed for tidiness.

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

### 8. Locate the Godot executable

**Ask the user (use this phrasing or similar):**

> *"One more thing — I need to know where Godot is installed on your machine. After I write code, I'll automatically run Godot in the background (headless, no window) to make sure there are no script errors or broken references before anything gets committed. This catches problems immediately instead of you finding them later when you hit Play.*
>
> *Can you give me the full file path to your Godot executable? For example:*
> - *Windows: `C:\Users\YourName\Godot\Godot_v4.6-stable_win64.exe`*
> - *macOS: `/Applications/Godot.app/Contents/MacOS/Godot`*
> - *Linux: `/home/yourname/Godot/Godot_v4.6-stable_linux.x86_64`*
>
> *If you're not sure, check where you downloaded or extracted Godot."*

**After the user provides the path**, create a `.gdenv` file in the project root:

```bash
# .gdenv — Machine-specific Godot binary path (not committed to git)
GODOT_BIN="/full/path/to/godot"
```

Replace the path with whatever the user provided. This file is gitignored (machine-specific), so each developer sets their own.

**Then verify it works:**

```bash
"$(grep GODOT_BIN .gdenv | cut -d= -f2 | tr -d '"')" --version
```

If the path is wrong or Godot doesn't run, ask the user to double-check and try again.

### 9. Verify headless validation

The repository includes `scripts/godot_validate.sh` which reads the Godot path from `.gdenv` and runs validation automatically. Test it:

```bash
chmod +x scripts/godot_validate.sh
./scripts/godot_validate.sh
```

This script:
- Reads `GODOT_BIN` from `.gdenv` (falls back to `godot` in PATH if `.gdenv` is missing)
- Runs `gdlint` on all `.gd` files
- Runs `gdformat --check` on all `.gd` files
- Runs Godot in headless mode to load the project and catch parse/load errors

The pre-commit hook uses the same `.gdenv` lookup. If `.gdenv` doesn't exist and `godot` isn't in PATH, the hook will warn but still enforce linting. CI always runs the full validation (it installs its own Godot).

### 10. Update `.husky/pre-commit`

The hook is already configured to:
- **Require** `gdlint` on all staged `.gd` files (blocks commit if not installed)
- **Read** `GODOT_BIN` from `.gdenv` for headless validation (falls back to PATH)
- **Run** headless Godot validation if the binary is found
- **Warn** if Godot binary is not found anywhere (CI will still catch errors)

No manual changes needed — just confirm `.gdenv` exists (Step 8) and `gdlint` is installed (Step 7).

### 11. Rewrite `README.md`

Rewrite to describe the Godot project. Replace npm scripts table with Godot workflow:
```markdown
## Running the Game
1. Open this folder in Godot 4.6+
2. Press F5 (or Play button) to run

## Prerequisites
- Python 3.x with pip (for gdtoolkit)
- Godot 4.6+

## Setup
Install linting tools (required — pre-commit hook enforces this):
```
pip install gdtoolkit
```

Set up headless validation (tells the project where Godot is on your machine):
```
echo 'GODOT_BIN="/path/to/your/godot"' > .gdenv
```

## Validation

Validation runs **automatically on every commit** via the pre-commit hook:
- `gdlint` on all staged `.gd` files
- `gdformat --check` for formatting
- Headless Godot to catch parse/load errors (requires `.gdenv`)

To validate manually before committing:
```
./scripts/godot_validate.sh
```
```

### 12. Clean up `.godot-template/`

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
