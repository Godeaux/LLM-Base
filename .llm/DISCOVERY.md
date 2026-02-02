# Project Discovery

> Filled in during bootstrap conversation. This is the design document for **Idle TD**.

---

## Vision

| Field | Answer |
|-------|--------|
| **Pitch** | A 3D physics-based idle tower defense where a single central tower fends off waves of enemies approaching from all directions with elemental attacks |
| **References** | Heretic's Fork meets Bloons TD meets Megabonk — central tower vs. swarm, deep upgrade trees, physics-driven spectacle |
| **Hook** | Physics is the show — arcing projectiles, ragdoll knockback, flapping wings, bipedal walkers. It's fun just to watch |
| **Art direction** | Low-poly procedural geometry with enough detail for distinct enemy silhouettes (wings, spikes, shields). All assets generated in code via Three.js geometry |
| **Audio direction** | Not a priority yet. Will add later |

---

## Core Loop

| Field | Answer |
|-------|--------|
| **Core verb** | Upgrade the tower and watch it fight |
| **Perspective** | 3D free-fly camera — player can orbit/pan to watch from any angle |
| **30-second loop** | Enemies spawn in a ring, walk/fly toward the tower. Tower auto-attacks with equipped abilities. Enemies die with physics knockback. Wave ends, brief reprieve, next wave begins. Player upgrades between or during waves |
| **Failure mode** | Enemies that reach the tower beat on it. Tower has 10 HP. Lose all HP = game over, restart |
| **Progression** | Bloons-style upgrade menu — buy new attack types (chain lightning, fireballs, blizzard, arcing arrows, summonable minions) and upgrade existing ones. Separate power-up system: choose 1 of 3 stat boosts (attack speed %, projectile count, etc.) |
| **Session length** | Open-ended escalating waves — lean-back idle with occasional upgrade decisions |
| **Multiplayer** | None |

---

## First Playable

The smallest thing that's playable. Physics feel is the priority.

- [x] **Player can:** Watch the tower auto-fire arcing fireballs at approaching enemies, fly the camera around freely
- [x] **Challenge is:** Bipedal walker enemies spawn in a ring and march toward the tower with physics-driven gait
- [x] **Success means:** Fireballs arc through the air, collide with enemies, cause visible knockback. Enemies die after enough hits. Waves escalate
- [x] **Failure means:** Enemies reach the tower, beat on it, tower loses HP and eventually is destroyed

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

**Planned increments after first playable:**
1. Add flying enemy type with flapping wings and air-knockback physics
2. Add chain lightning attack type
3. Add upgrade menu UI (Bloons-style)
4. Add blizzard/frost attack type with slow effect
5. Add arcing arrow attack type
6. Add shielded tank enemy type
7. Add summonable minion attack type
8. Add wave reprieve system with escalation
9. Add boss/colossus enemy type
10. Performance optimization for 200+ entities
