# Project Discovery

> This document starts as a questionnaire. After the bootstrap conversation, the LLM rewrites it into a filled-in design document for your specific game. If the fields below are still blank, the bootstrap hasn't happened yet — start by describing your game idea.

---

## Vision

| Field | Answer |
|-------|--------|
| **Pitch** | _one-sentence description_ |
| **References** | _plays like X meets Y_ |
| **Hook** | _what makes it interesting_ |
| **Art direction** | _visual style and vibe_ |
| **Audio direction** | _soundtrack and SFX feel_ |

---

## Core Loop

| Field | Answer |
|-------|--------|
| **Core verb** | _what the player DOES_ |
| **Perspective** | _2D top-down / side-scroller / 3D first-person / etc._ |
| **30-second loop** | _what a typical moment looks like_ |
| **Failure mode** | _how the player loses_ |
| **Progression** | _how the player advances_ |
| **Session length** | _target play session_ |
| **Multiplayer** | _none / local / online_ |

---

## First Playable

The smallest thing that's playable. Defined after the core loop is clear.

- [ ] **Player can:** ___
- [ ] **Challenge is:** ___
- [ ] **Success means:** ___
- [ ] **Failure means:** ___

---

## Incremental Build Plan

After first playable, grow iteratively:

1. Play it
2. Identify what feels worst
3. Fix or add ONE thing
4. Repeat

**Quality checks every increment:**
- `npm run build` — no type errors
- `npm run lint` — no lint warnings
- `npm test` — no test failures
- Add tests for new systems in `tests/` as you go
