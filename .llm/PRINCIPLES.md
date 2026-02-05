# Development Principles

Guidelines that inform decisions as the project grows. Not rigid rules—principles to reason from.

**Note:** This file contains universal principles. Engine-specific guidance lives in `PRINCIPLES-GODOT.md` or `PRINCIPLES-WEB.md` (whichever matches your chosen path).

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

### Grow structure, don't prescribe it
- Start flat. Add folders and reorganize when files naturally cluster.
- No empty folders. No placeholder files.
- Structure emerges from the game, not before it.
- Three files in a folder is a hint. Five is a signal. Act then.

### Small files, clear names
- One concept per file.
- Name describes content: `PlayerMovement`, `enemy_spawner`, `inventory_ui` — not `utils` or `helpers`.
- ~200 line soft limit. LLMs (and humans) work better with focused files.
- If a file does two things, it should be two files.

### Data over behavior
- Prefer plain data structures to complex class hierarchies.
- State should be serializable (enables save games, networking, debugging, replay).
- Logic lives in functions that operate on data.
- Avoid deep inheritance. Composition wins.

### Explicit over clever
- No magic. Name things verbosely if needed.
- Future-you (and the LLM) should understand at a glance.
- Boring code that works beats clever code that confuses.

### Types are documentation
- Function parameters and returns should be explicitly typed.
- Types tell the story of your data flow.
- Avoid escape hatches that bypass type checking.

### Threading is opt-in
- Main thread until proven slow.
- Always document WHY something runs off the main thread.
- Measure before optimizing.

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
- Good: `// Fixed timestep because physics was unstable at variable dt`
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
- Write tests alongside new systems—don't bolt them on later.

---

## Asset Principles

Assets (art, audio, models, etc.) often come later in development. These guidelines keep things flexible.

### Structure emerges from assets, not before
- Don't pre-create empty asset folders. Add them when you have assets.
- When assets arrive, organize by type first, then by context if needed:
  ```
  assets/
    sprites/       # 2D images, spritesheets, UI elements
    models/        # 3D models
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

### Keep assets out of version control (when large)
- Small assets (a few MB total) can stay in git.
- Large assets (hundreds of MB+) should use Git LFS or live outside the repo.
- Add large binary patterns to `.gitignore` if not using LFS.
