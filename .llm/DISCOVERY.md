# Project Discovery

> Trojan Horse — a wizard-led payload escort tower defense with Pikmin-style minions across Greek mythological locations.

---

## Vision

| Field | Answer |
|-------|--------|
| **Pitch** | Escort a Trojan Horse through Greek mythological locations by summoning and positioning Pikmin-style minions to defend against waves of enemies |
| **References** | Pikmin (minion command), Into the Breach (isometric tactical), Left 4 Dead (wave-based checkpoint pacing), Kingdom Wars TD (visual perspective) |
| **Hook** | Dual minion command modes (pin in place vs. follow wizard) create constant tactical repositioning as the payload advances |
| **Art direction** | 3D geometric/stylized with toon shaders, fixed isometric camera, Greek palette (golds, marble whites, deep Mediterranean blues, olive greens). Code-generated placeholder art designed for eventual asset replacement |
| **Audio direction** | Deferred — no audio in initial development |

---

## Core Loop

| Field | Answer |
|-------|--------|
| **Core verb** | Summon and position minions |
| **Perspective** | Fixed isometric (2.5D — 3D rendering with fixed camera angle) |
| **30-second loop** | Summon minions near the Trojan Horse, position them to intercept incoming enemies, reposition as the payload advances and new threats emerge from different directions |
| **Failure mode** | Trojan Horse destroyed — return to last checkpoint |
| **Progression** | Unlock new minion types, enemies develop new abilities, maps become more complex. Details beyond run 1 deferred |
| **Session length** | ~20 minutes for a full run (5 maps) |
| **Multiplayer** | None (single player) |

---

## First Playable

The smallest thing that's playable. Defined after the core loop is clear.

- [x] **Player can:** Move wizard around the map, summon one minion type, toggle minion between stay/follow modes
- [x] **Challenge is:** Enemies attack the Trojan Horse as it moves along a predefined path
- [x] **Success means:** Trojan Horse reaches the end of the path intact
- [x] **Failure means:** Trojan Horse health reaches zero

---

## Map Design

Maps are procedurally assembled from pre-built tile pieces. Key concepts:

- **Tile-based assembly:** Each map is built from interconnected tile segments with standardized entry/exit points
- **Branching paths:** Paths may fork, giving the player route choices
- **Greek locations:** 5 distinct mythological locations per run (River Styx, Mount Olympus, the Labyrinth, Elysian Fields, Gates of Troy)
- **Procedural variety:** A sufficient set of tile variants per location ensures maps feel unique across runs

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
