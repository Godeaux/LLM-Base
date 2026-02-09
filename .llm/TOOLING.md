# Godot Tooling & GDScript Best Practices

Engine-specific tooling and coding standards for the Godot/GDScript path. See `PRINCIPLES.md` for engine-agnostic guidelines.

This document is split into focused files for easier reference:

| File | Covers |
|------|--------|
| `TOOLING-project-structure-and-naming.md` | File naming conventions, project folder layout, GDScript file ordering |
| `TOOLING-types-nodes-and-resources.md` | Static typing, node base class selection, custom Resources, export organization |
| `TOOLING-signals-autoloads-and-physics.md` | Signal conventions, autoload architecture, collision layer naming & masking |
| `TOOLING-editor-workflow.md` | Editor vs code decisions, three-tier animation strategy, Godot file behavior, threading |
| `TOOLING-linting-testing-and-validation.md` | gdtoolkit linting, GdUnit4 testing, headless Godot validation, quality checks |

All standards target **Godot 4.6** with static typing.
