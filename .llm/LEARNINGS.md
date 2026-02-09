# Learnings

> Non-obvious findings that contradict assumptions or common expectations.
> Not for documenting basic behavior — only surprises, gotchas, and "I thought X but actually Y."

## Format

```
### [Category] Short description
**Date:** YYYY-MM-DD
What was expected vs. what actually happens. Keep it to 2-3 sentences max.
```

---

### [Animation] Three-tier animation strategy — ask before choosing
**Date:** 2026-02-08
Not all animations need hand-keying, and not all should be automated. **Ask the user which tier** when an animation is needed, presenting trade-offs:

**Tier 1 — Automated (Claude writes full track data in .tscn).** Best for mechanical/mathematical motions: sine bobs, constant spins, uniform scale pulses, color cycles. Pros: instant, no editor labor, reproducible. Cons: hand-written .tscn tracks lack full editor Value editing (only Time/Easing appear in Inspector) — so later tweaking requires deleting and re-keying through the GUI. Easy to change: timing, amplitude (edit numbers). Hard to change: easing feel, complex choreography.

**Tier 2 — Editor keyframed (Claude sets up AnimationPlayer + empty animations, user keys in editor).** Best for animations that need to "feel" right: attack swings, hit reactions, death anims, anything subjective. Pros: full visual control, preview/scrub, easing curves. Cons: requires editor time. Workflow: select node → pose with gizmo (E=rotate, W=move) → click key icon next to property in Inspector → Godot auto-creates track.

**Tier 3 — Code tweens (runtime procedural).** Best for transient reactive effects: damage flash, UI popups, pickup feedback. Pros: procedural, reacts to game state, parameterizable. Cons: invisible in editor, can't preview or scrub.

### [Spatial] Path3D curve endpoints must be explicitly placed at tile edge positions
**Date:** 2026-02-06
LLM-generated Curve3D points defaulted to tile center `(0,0,0)` instead of the actual edge midpoints (`±5` on X or Z). This caused the horse to "skip" between tiles because the exit of one curve didn't meet the entry of the next. Curves also clipped below the ground plane (Y=0) making them invisible in the editor. **Rules:** (1) Every curve's first point must be at the entry edge position and last point at the exit edge position per `TileDefs.EDGE_POSITIONS`. (2) Raise the Path3D node's Y slightly (~0.1) so curves are visible above the ground. (3) The horse code must apply the Path3D's `Transform3D` when sampling curves, since `Curve3D.sample_baked()` returns Path3D-local coordinates. Validation now warns at runtime if endpoints drift more than 1.0 unit from expected edges.

### [GDScript] Never use class_name that shadows a built-in Godot class
**Date:** 2026-02-06
`class_name TileData` silently collides with Godot's built-in `TileData` (TileMap system). The engine resolves the name to the native class, so `TileData.Edge` fails with "Could not find type 'Edge' in 'TileData'." The error message gives no hint about the collision. Before choosing a `class_name`, check the Godot docs class list. Renamed to `TileDefs`.

### [Tooling] Godot headless needs `--import` after class_name changes
**Date:** 2026-02-06
The `.godot/global_script_class_cache.cfg` is not rebuilt by `--headless --quit` alone. After renaming a `class_name`, you must run `godot --headless --import --quit` first to rebuild the cache, then `--headless --quit` to validate. The CI workflow handles this with a separate import step.

### [Tooling] gdlint does NOT catch type/parse errors — only Godot headless does
**Date:** 2026-02-06
`gdlint` (gdtoolkit) uses its own standalone parser that doesn't resolve cross-file types. It catches style issues (naming, line length) but completely misses engine-level errors like "Could not find type 'Edge' in 'TileData'". Only `godot --headless --quit` can validate the full type system. The `.gdlintrc` config must be YAML format (not INI) despite older docs suggesting otherwise. Godot headless returns exit code 0 even when scripts have errors — must grep output for "SCRIPT ERROR" patterns.

### [Visual/Spatial] LLM-generated 3D transforms are unreliable — always flag for editor review
**Date:** 2026-02-06
Computing Transform3D values (camera angles, light directions, node positions) through math alone is error-prone. The Phase 1 isometric camera transform was pointing in the wrong direction and had to be manually repositioned in the editor. **Rule:** When writing .tscn files with spatial transforms, explicitly tell the user to verify and adjust the camera, light, and entity positions in the Godot editor. Don't assume the computed values are visually correct.

### [Tooling] Godot rewrites project.godot and .tscn files on open
**Date:** 2026-02-06
When Godot opens a project, it reformats project.godot (reorders sections, adds comments) and .tscn files (adds uid values, unique_id attributes, recalculates load_steps). This is normal and expected — don't fight it. Write files with correct structure and let Godot normalize the format on first open.

### [Tooling] Stale UID cache causes "missing dependencies" after file moves outside Godot
**Date:** 2026-02-08
When scripts or scenes are moved via git/CLI/file explorer (not through Godot's editor), the `.godot/uid_cache.bin` still maps UIDs to old paths. Godot resolves ext_resources by UID first, path second — so even if the .tscn has the correct path, the stale UID wins and loading fails. **Fix:** Delete the `.godot/` folder and reopen the project. Godot regenerates the cache on next launch. This commonly happens after `git pull` or branch switches that reorganize files.

### [Physics] New collision layers must be masked by ALL relevant entities, not just the obvious ones
**Date:** 2026-02-08
When adding a new collision layer (e.g., "Payload" for the Trojan Horse), it's easy to only update the most obvious consumer (enemies) and forget other entities that also need to collide with it (wizard, minions). **Rule:** When adding a new collision layer, grep for every `collision_mask` assignment in the project and evaluate each one — does this entity need to collide with the new layer? Don't stop at the first obvious fix.

### [Editor UX] Always name collision layers for human readability
**Date:** 2026-02-08
Godot's collision layer checkboxes in the inspector only show "Layer 1, Bit 0, value 1" by default — meaningless to a human. **Rule:** Whenever adding or using collision layers, immediately add named labels in `project.godot` under `[layer_names]` (e.g., `3d_physics/layer_1="Ground"`). These names appear as tooltips in the editor, making layer/mask assignment far less error-prone. Do this proactively — don't wait to be asked.

<!-- Add new entries at the top. -->
