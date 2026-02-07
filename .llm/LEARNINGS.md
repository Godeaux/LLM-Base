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

<!-- Add new entries at the top. -->
