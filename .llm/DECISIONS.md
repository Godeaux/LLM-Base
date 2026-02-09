# Technical Decisions — Godot / GDScript

---

## Engine Path

**Engine**: Godot 4.6 (GDScript)

---

## Tech Stack

| Category | Choice | Why |
|----------|--------|-----|
| **Dimension** | 2D | All three modes work in 2D; avoids LLM 3D spatial transform reliability issues |
| **Godot version** | 4.6 stable | Current stable release, template default |
| **Rendering method** | GL Compatibility | Pure 2D game; best performance for many physics bodies; widest compatibility |
| **Physics** | Godot Physics 2D | Mature, well-integrated; RigidBody2D handles Cascade and Tumble modes natively |
| **State management** | Autoloads (EventBus, GameState, SaveManager) + Custom Resources | Cross-mode state in autoloads; mode configs and entity data as Resources |
| **Scene structure** | One scene per game mode + shared autoloads + main menu scene | Clean separation; each mode is self-contained with shared infrastructure |
| **UI framework** | Built-in Control nodes | Simple HUD + upgrade panels; no addon needed |
| **Input scheme** | Mouse only (click menus/upgrades) | Game runs autonomously; minimal interaction needed |
| **Networking** | None | Single-player idle game |
| **GDExtension** | None | No native performance needs; GDScript handles everything |

## Addons / Extensions

| Addon | Purpose | Alternatives Considered |
|-------|---------|------------------------|
| GdUnit4 | Automated testing framework | Built-in assert (too basic for test suites) |

## Architecture Notes

Three game modes share a common infrastructure layer:

```
Autoloads (persist across all scenes):
  EventBus ──→ Decoupled signal communication
  AudioManager ──→ SFX pool + music fade
  SaveManager ──→ JSON persistence with version migration
  SceneManager ──→ Scene transitions with fade
  GameState ──→ Cross-mode currency, unlocks, prestige

Shared Components:
  ObjectPool ──→ Reusable pool for frequently spawned objects
  TrailRenderer ──→ Line2D trail behind moving objects
  VisualJuice ──→ Screen shake, flash, bounce, floating text
  StuckDetector ──→ Detects stuck physics bodies

Game Mode Scenes (one each):
  CascadeGame.tscn ──→ Marble machine (balls, pegs, elements)
  TumbleGame.tscn ──→ Block stacking (blocks, tower, environment)
  OrbitGame.tscn ──→ Gravitational playground (bodies, gravity, merging)

Main Menu:
  MainMenu.tscn ──→ Mode selection with currency display
```

Collision layers:
- Layer 1 "Walls": Static geometry (pegs, ramps, boundaries, floors)
- Layer 2 "PhysicsBodies": Moving objects (balls, blocks)
- Layer 3 "Collectors": Area2D scoring zones
- Layer 4 "ForceZones": Area2D force areas (gravity, magnets, wind)

## Rejected Alternatives

| Option | Rejected Because |
|--------|-----------------|
| 3D rendering | Documented LLM limitation with 3D spatial transforms; 2D is sufficient for all three modes |
| Forward+ renderer | Unnecessary for pure 2D; GL Compatibility is faster and more compatible |
| Jolt physics | 3D physics engine; Godot Physics 2D is the right choice for 2D |
| RigidBody2D for Orbit mode | Godot's physics solver would interfere with custom n-body gravity; using Node2D with manual velocity integration instead |
| Web/TypeScript path | Godot's built-in 2D physics, scene system, and particle editors are ideal for this project |
