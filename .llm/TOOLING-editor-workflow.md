# Tooling: Editor Workflow

When to use the Godot editor vs code, animation strategy, file behavior expectations, and threading guidance.

All standards target **Godot 4.6** with static typing.

---

## Editor vs Code Workflow

Godot is an editor-centric engine. Knowing when to use the editor vs code makes development faster.

| Task | Use the Editor | Use Code |
|------|---------------|----------|
| **Scene composition** | Arrange nodes, set transforms, parent/child structure | Only when generating scenes procedurally |
| **Property tuning** | `@export` vars in the Inspector — iterate without touching code | Only for values that must be computed |
| **Animations** | `AnimationPlayer` for keyframed sequences that need to "feel" right (attacks, reactions, deaths) | `Tween` for procedural effects (damage flash, UI popups). LLM can write mechanical .tscn track data (sine bobs, spins, scale pulses) — see three-tier guide below |
| **Signals** | Connect simple signals in the editor (Node → Signals tab) | Connect in code when dynamic or when crossing scene boundaries |
| **UI layout** | `Control` nodes in the editor with anchors/containers | Code for dynamic UI (inventory grids, chat windows) |
| **Materials/Shaders** | Visual shader editor for prototyping, StandardMaterial3D in Inspector | Code shaders for custom effects, procedural materials |
| **Particle effects** | `GPUParticles2D/3D` in editor with visual tuning | Code only for runtime parameter changes |
| **Collision shapes** | Draw them in the editor | Code only for procedural/runtime generation |

### Three-tier animation strategy

Not all animations need hand-keying, and not all should be automated. **Ask the user which tier** when an animation is needed, presenting trade-offs:

| Tier | Method | Best for | Pros | Cons |
|------|--------|----------|------|------|
| **1 — Automated** | LLM writes full track data in `.tscn` | Mechanical/mathematical motions: sine bobs, constant spins, uniform scale pulses, color cycles | Instant, no editor labor, reproducible | Hand-written tracks lack full editor editing (only Time/Easing in Inspector) — later tweaking requires deleting and re-keying through the GUI |
| **2 — Editor keyframed** | LLM sets up `AnimationPlayer` + empty animations; user keys in editor | Animations that need to "feel" right: attack swings, hit reactions, death anims, anything subjective | Full visual control, preview/scrub, easing curves | Requires editor time |
| **3 — Code tweens** | Runtime procedural via `create_tween()` | Transient reactive effects: damage flash, UI popups, pickup feedback | Procedural, reacts to game state, parameterizable | Invisible in editor, can't preview or scrub |

**Tier 2 editor workflow:** Select node → pose with gizmo (E=rotate, W=move) → click key icon next to property in Inspector → Godot auto-creates track.

---

## Godot File Behavior

**Godot rewrites files on open.** When Godot opens a project, it reformats `project.godot` (reorders sections, adds comments) and `.tscn` files (adds `uid` values, `unique_id` attributes, recalculates `load_steps`). This is normal — don't fight it. Write files with correct structure and let Godot normalize the format on first open. Expect git diffs after the first editor launch.

---

## Key Principle for LLM-Assisted Development

The LLM writes `.gd` scripts and can create `.tscn` files in text format. But the user should do final scene composition, visual tuning, and signal wiring in the editor. Design scripts to be editor-friendly:
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
