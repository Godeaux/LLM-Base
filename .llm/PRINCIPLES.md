# Development Principles

Guidelines that inform decisions as the project grows. Not rigid rules—principles to reason from.

---

## Code Principles

### Grow structure, don't prescribe it
- Start flat. Add folders when files naturally cluster.
- No empty folders. No placeholder files.
- Structure emerges from the game, not before it.
- Three files in a folder is a hint. Five is a signal. Act then.

### Small files, clear names
- One concept per file.
- Name describes content: `PlayerMovement.ts` not `utils.ts` or `helpers.ts`
- ~200 line soft limit. LLMs (and humans) work better with focused files.
- If a file does two things, it's probably two files.

### Data over behavior
- Prefer plain objects to classes.
- State should be serializable (enables save games, networking, debugging, replay).
- Logic lives in functions that operate on data.
- Avoid inheritance hierarchies. Composition and functions.

### Explicit over clever
- No magic. Name things verbosely if needed.
- Future-you (and the LLM) should understand at a glance.
- Boring code that works beats clever code that confuses.

### Types are documentation
- No `any`. Ever.
- Function parameters and returns explicitly typed.
- Interfaces for data shapes. Types for unions/primitives.
- The types should tell the story of your data.

### Threading is opt-in
- Main thread until proven slow.
- Workers for: physics, pathfinding, procedural generation, heavy AI.
- Always document WHY something runs in a worker.
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
