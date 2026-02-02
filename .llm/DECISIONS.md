# Technical Decisions

> Filled in after bootstrap conversation for **Idle TD**.

---

## Tech Stack

| Category | Choice | Why |
|----------|--------|-----|
| **Renderer** | Three.js | Industry-standard WebGL renderer. Excellent for procedural geometry, good ecosystem, strong community. Handles the low-poly aesthetic well |
| **State management** | Plain objects + functions | Simple data-driven approach per PRINCIPLES.md. ECS would be premature — add it if entity count demands it |
| **Physics** | cannon-es | Maintained fork of cannon.js. Rigid bodies, constraints (for joints/wings/gait), collision callbacks, reasonable performance. Lighter than Ammo.js, more capable than custom physics for what we need (knockback, arcing projectiles, ragdoll-like reactions). Can migrate to Rapier (WASM) later if 200+ entities need it |
| **Audio** | Deferred | Not a priority per user. Will evaluate Howler.js or Web Audio API when ready |
| **Build tool** | Vite | Fast HMR, native ESM, zero-config TypeScript support |
| **Networking** | None | Single-player idle game |

## Dependencies

| Package | Purpose | Alternatives Considered |
|---------|---------|------------------------|
| typescript | Type safety | — |
| eslint | Code quality | — |
| prettier | Formatting | — |
| vitest | Testing | Jest (heavier, slower for ESM) |
| three | 3D rendering | Babylon.js (heavier, more opinionated), PlayCanvas (editor-focused) |
| @types/three | TypeScript types for Three.js | — |
| cannon-es | Physics engine | Rapier (faster but WASM complexity), Ammo.js (heavy, Bullet port), custom (too much work for constraints/joints) |
| vite | Dev server + bundler | Webpack (slower), esbuild (less plugin ecosystem) |

## Architecture Notes

Main loop runs a fixed-timestep physics update with variable-rate rendering:

1. **Game state** — plain objects: tower, enemies[], projectiles[], wave info
2. **Physics world** (cannon-es) — mirrors game state with rigid bodies. Enemies have constraints for bipedal gait / wing flapping
3. **Render sync** — Three.js meshes sync position/rotation from physics bodies each frame
4. **Systems** — functions that operate on game state: `spawnWave()`, `updateTower()`, `fireProjectile()`, `checkDamage()`, `cleanupDead()`
5. **UI** — plain HTML overlay reads game state and renders HUD (HP, wave, gold, upgrade menu)

Camera is a free-fly controller (pointer lock or orbit controls).

## Rejected Alternatives

| Option | Rejected Because |
|--------|-----------------|
| Babylon.js | Heavier runtime, more opinionated. Three.js is lighter and sufficient for procedural low-poly |
| Rapier | WASM adds build complexity. cannon-es is simpler to start with and supports constraints we need for enemy locomotion. Can migrate later if perf demands |
| ECS (bitECS, etc.) | Premature for first playable. Plain objects + functions are simpler. Will adopt if entity count or system complexity demands it |
| React/Preact for UI | Overkill for an HP bar and upgrade menu. Plain HTML/CSS is sufficient and avoids framework overhead |
