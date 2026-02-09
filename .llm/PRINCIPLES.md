# Development Principles

Guidelines that inform decisions as the project grows. Not rigid rules—principles to reason from.

---

## Implementation Difficulty Reference

When recommending or discussing features, communicate expected complexity so the dev can plan accordingly.

| Difficulty | What it means | Examples |
|------------|---------------|----------|
| **Trivial** | Minutes. Single file, obvious implementation. | Config tweaks, simple UI text, color changes |
| **Easy** | Hours. Well-understood patterns, minimal dependencies. | Basic movement, simple collision, static UI screens |
| **Moderate** | Day(s). Multiple files, some coordination, testable edge cases. | Inventory system, basic enemy AI, save/load, audio manager |
| **Complex** | Days to a week. Architectural decisions, state management, potential iteration. | Procedural generation, multiplayer sync, animation state machines, physics-heavy mechanics |
| **Hard** | Week(s). Novel problems, significant research, multiple subsystem integration. | Custom shaders, networked real-time combat, complex AI behaviors, optimization passes |

**How to use this:**
- When presenting implementation options, note difficulty: *"Adding pathfinding is moderate complexity — expect a day or two."*
- When a feature seems simple but isn't, flag it: *"Sounds easy, but multiplayer turns this into complex territory."*
- Helps devs prioritize and set realistic expectations.

---

## Code Principles

### Start organized, grow organically
- Begin with the baseline folder structure from `TOOLING-project-structure-and-naming.md`. This gives the project a skeleton that both humans and LLMs can navigate from day one.
- Don't create empty folders — only add folders when you have files for them. But DO create the right folder from the first file (e.g., the first enemy script goes in `entities/enemies/`, not in the root).
- As the project grows, subdivide folders that get crowded. Three files is fine. Ten files is a signal to split by context.
- The goal: an LLM (or a new team member) should be able to understand what a folder contains just from its name and path. `entities/enemies/wave_spawner.gd` tells a story. `wave_spawner.gd` in the root does not.

### Small files, descriptive names
- One concept per file.
- Name describes content — not `utils`, `helpers`, `common`, or `misc`. See `TOOLING-project-structure-and-naming.md` for naming conventions.
- **Prefer verbose names over ambiguous ones.** `player_movement_controller.gd` beats `move.gd`. `enemy_health_component.gd` beats `hp.gd`. The LLM searches by name — descriptive names mean it finds the right file on the first try.
- ~200 line soft limit. LLMs (and humans) work better with focused files.
- If a file does two things, it should probably be turned into two files.

### Composition over deep inheritance
- Prefer composing small, focused pieces over deep class hierarchies.
- State should be serializable (enables save games, networking, debugging, replay).
- In **Godot**: Use the node tree as your composition system. Build entities from small component nodes. Use `Resource` subclasses for pure data (item stats, configs, level definitions) — they're serializable, Inspector-editable, and shareable. Keep `Node` subclasses focused on behavior. See `TOOLING-types-nodes-and-resources.md` for the Node Type Selection Guide.
- In **Web/TypeScript**: Prefer plain objects and interfaces over classes. Logic lives in functions that operate on data.
- In both: Avoid inheritance deeper than 2 levels. If you need a third level, rethink the design.

### Explicit over clever
- No magic. Name things verbosely if needed.
- Future-you (and the LLM) should understand at a glance.
- Boring code that works beats clever code that confuses.

### Types are documentation
- Use static typing everywhere. No escape hatches unless absolutely necessary.
- Function parameters and returns explicitly typed. The types should tell the story of your data.
- See `TOOLING-types-nodes-and-resources.md` for engine-specific typing guidance.

### Threading is opt-in
- Main thread until proven slow.
- Only offload to background threads when profiling shows a bottleneck.
- Always document WHY something runs off the main thread.
- Measure before optimizing.
- See `TOOLING-editor-workflow.md` for engine-specific threading APIs.

---

## Collaboration Principles

### Ask before building
- Personas ask scoping questions before generating code.
- Ambiguity leads to conversation, not assumptions.
- Five minutes of questions saves hours of rework.

### Iterate in playable increments
- Every increment should be runnable.
- "I'll make it work later" is a trap.
- Compiling isn't enough—it should be testable/playable.

### Document decisions, not descriptions
- Comments explain WHY, not WHAT.
- Good: `// WHY: Fixed timestep because physics was unstable at variable dt`
- Bad: `// Updates the physics`
- Decisions are valuable. Descriptions are noise.

### Delete aggressively
- Dead code is worse than no code.
- Commented-out code gets deleted, not preserved.
- Git remembers. You don't need to.

---

## Quality Principles

### Make it work, make it right, make it fast
- In that order. Always.
- "Right" means: readable, maintainable, tested where it matters.
- "Fast" comes last and only where measured.

### Errors should help
- Error messages say what happened AND what to do.
- Fail fast and loud in development.
- Fail gracefully and recoverably in production.

### Test the scary parts
- Not everything needs tests.
- Test: state transitions, save/load, calculations, networking.
- Skip: rendering, UI layout, things you'll see immediately.
- Write tests alongside new systems — don't bolt them on later.
- See `TOOLING-linting-testing-and-validation.md` for engine-specific test framework and conventions.

### Lint and format consistently
- Use the engine's linting and formatting tools. Run them before every commit.
- Consistent formatting removes style debates from code review.
- See `TOOLING-linting-testing-and-validation.md` for engine-specific linting and formatting commands.

---

## Asset Principles

Assets (art, audio, models, etc.) often come later in development. These guidelines keep things flexible.

### Structure emerges from assets, not before
- Don't pre-create empty asset folders. Add them when you have assets.
- When assets arrive, organize by type first, then by context if needed:
  ```
  assets/
    sprites/       # 2D images, spritesheets, UI elements
    models/        # 3D models (.gltf, .glb, .obj, .fbx)
    audio/
      sfx/         # Sound effects
      music/       # Background music, ambient
    fonts/
    shaders/       # Custom shaders if any
  ```
- This structure works for 2D, 3D, or hybrid. Delete what you don't use.

### Placeholder-first development
- Use primitives (colored boxes, circles, procedural shapes) until real assets exist.
- Code should never assume specific asset dimensions or formats.
- Design systems to swap assets easily (data-driven references, not hardcoded paths).

### Asset formats
- **2D**: PNG for sprites (transparency), WebP for compressed, SVG for scalable UI.
- **3D**: glTF/GLB preferred (widely supported, compact). Use engine-native formats where applicable.
- **Audio**: MP3/OGG for music (compressed), WAV for short SFX (low latency).

### Keep assets out of version control (when large)
- Small assets (a few MB total) can stay in git.
- Large assets (hundreds of MB+) should use Git LFS or live outside the repo.
- Add large binary patterns to `.gitignore` if not using LFS.
