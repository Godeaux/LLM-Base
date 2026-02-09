# Idle Physics

A physics-based idle screensaver with three mesmerizing game modes:

- **The Cascade** — Marble machine: balls cascade through pegs, bumpers, spinning wheels, gravity zones, and magnetic fields
- **Tumble** — Block stacking: shapes auto-stack into towers that wobble and topple in satisfying physics cascades
- **Orbit** — Gravitational playground: celestial bodies spawn, orbit, collide, and merge

Each mode runs autonomously with idle game progression (currency, upgrades, unlocks).

## Running the Game

1. Open this folder in Godot 4.6+
2. Press F5 (or Play button) to run

## Prerequisites

- Python 3.x with pip (for gdtoolkit)
- Godot 4.6+

## Cloning

This project uses git submodules (GdUnit4 testing framework). Clone with:
```
git clone --recurse-submodules <repo-url>
```

If you already cloned without `--recurse-submodules`:
```
git submodule update --init --recursive
```

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

## Testing

Run GdUnit4 tests:
```
./scripts/godot_test.sh
```

Tests also run automatically in CI on every push.
