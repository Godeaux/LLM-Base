# Project Discovery

---

## Vision

| Field | Answer |
|-------|--------|
| **Pitch** | A physics-based idle screensaver with three mesmerizing game modes — marble machine, block stacking, and orbital mechanics |
| **References** | Marble It Up meets Universe Sandbox meets idle games, as a screensaver |
| **Hook** | Three distinct physics simulations that are endlessly fascinating to watch, each with idle progression |
| **Art direction** | Geometric/abstract, glowing particles, clean shapes, color-shifting palettes |
| **Audio direction** | Ambient/ASMR — soft plinks, thuds, whooshes; generative soundscape from physics interactions |

---

## Core Loop

| Field | Answer |
|-------|--------|
| **Core verb** | Watch (and occasionally upgrade) |
| **Perspective** | 2D side-view (Cascade, Tumble) / 2D top-down (Orbit) |
| **30-second loop** | Physics objects move, interact, and produce satisfying visual/audio feedback autonomously |
| **Failure mode** | None — idle game, no losing |
| **Progression** | Currency from physics interactions buys upgrades, new elements, new object types |
| **Session length** | Infinite — screensaver with idle progression |
| **Multiplayer** | None |

---

## First Playable

The smallest thing that's playable. Defined after the core loop is clear.

- [x] **Player can:** Watch balls cascade through a Plinko board and earn currency
- [x] **Challenge is:** Optimizing upgrades to maximize currency flow
- [x] **Success means:** Machine runs beautifully, new elements unlock
- [x] **Failure means:** N/A — idle game

---

## Incremental Build Plan

After first playable, grow iteratively:

1. Play it
2. Identify what feels worst
3. Fix or add ONE thing
4. Repeat

**Quality checks every increment:**
- Build passes with no errors
- Lint passes with no warnings
- Tests pass
- See `TOOLING.md` for engine-specific commands
- Add tests for new systems as you go
