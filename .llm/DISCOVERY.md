# Project Discovery Process

When starting a new game from this foundation, work through these phases before writing game code.

---

## Phase 1: Vision

Establish the creative direction. Don't write code yet.

**Questions to answer:**

1. **Concept**: One-sentence pitch. What is this game?
2. **References**: Plays like X meets Y? What games inspire this?
3. **Hook**: What makes it interesting? Why this game?
4. **Scope**: Jam prototype, vertical slice, or full release?
5. **Timeline**: Days, weeks, months?
6. **Team**: Solo or collaborators?

---

## Phase 2: Core Loop

Define what the player actually DOES before building systems.

**Questions to answer:**

1. What does the player DO moment-to-moment?
2. What do they DECIDE?
3. What do they FEEL? (tension, satisfaction, curiosity)
4. How do they FAIL?
5. How do they IMPROVE / PROGRESS?
6. What ends a session? What brings them back?

---

## Phase 3: Technical Scope

Now @architect can make informed recommendations.

**Decisions to make:**

1. **Renderer**: Three.js, Babylon.js, Phaser, PixiJS, or custom?
2. **State approach**: Simple objects, state machine, ECS?
3. **Threading**: Workers needed? For what?
4. **Networking**: None, simple, or complex?
5. **Platforms**: Web, Electron, mobile, Steam?
6. **Initial folder structure**: Based on actual needs

---

## Phase 4: First Playable

Define the smallest thing that's "playable."

**Criteria:**
- Core verb works (you can DO the thing)
- One obstacle or challenge exists
- Win/lose or success/failure is possible
- NOT feature complete
- NOT pretty
- But: you can feel if it's fun

**Define yours:**
- [ ] Player can: ___
- [ ] Challenge is: ___
- [ ] Success means: ___
- [ ] Failure means: ___

---

## Phase 5: Incremental Build

From first playable, grow the game iteratively:

1. Play it
2. Identify what feels worst
3. Fix or add ONE thing
4. Repeat

Each increment should be runnable. Broken builds block everything.

**Quality checks every increment:**
- `npm run build` — no type errors
- `npm run lint` — no lint warnings
- `npm test` — no test failures
- Add tests for new systems in `tests/` as you go
