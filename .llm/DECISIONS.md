# Technical Decisions — Godot / GDScript

> Trojan Horse — 2.5D isometric payload escort tower defense.

---

## Engine Path

**Engine**: Godot 4.6 (GDScript)

---

## 2D vs 3D Decision

**Choice: 2.5D (3D rendering, isometric fixed camera)**

Rationale: The game needs an isometric perspective matching Kingdom Wars TD. 3D gives us free depth sorting, lighting, and shadows. The fixed camera angle keeps complexity manageable. Code-generated placeholder art uses 3D primitives (CSG/MeshInstance3D) with toon shaders, designed to be replaceable with real 3D assets later.

---

## Tech Stack

| Category | Choice | Why |
|----------|--------|-----|
| **Dimension** | 2.5D (3D rendering, fixed isometric camera) | Isometric view needs natural depth sorting; 3D gives free lighting/shadows; fixed camera reduces 3D complexity |
| **Godot version** | 4.6 stable | Latest stable, mature 3D pipeline, Jolt physics default, GDScript debugger improvements |
| **Rendering method** | Forward+ | Default and best option for 3D with dynamic lighting and shadows |
| **Physics** | Jolt (default in 4.6) | Stable 3D collision for units, projectiles, map geometry |
| **State management** | Autoloads + signals | Autoloads for global state (WaveManager, RunManager), signals for unit communication |
| **Scene structure** | Composition-based | Map tiles, units, Trojan Horse, and wizard as independent scenes composed at runtime |
| **UI framework** | Control nodes | Built-in Godot UI for HUD (minion commands, health bars, wave info) |
| **Input scheme** | Keyboard + mouse | Mouse for positioning minions, keyboard for summoning/toggling modes |
| **Networking** | None | Single player only |
| **GDExtension** | None | No native performance needs identified yet |

## Addons / Extensions

| Addon | Purpose | Alternatives Considered |
|-------|---------|------------------------|
| None yet | Will add as needs emerge (GdUnit4 for testing when ready) | — |

## Architecture Notes

**Core autoloads:**
- `EventBus` — Global signal hub for cross-system communication
- `WaveManager` — Controls wave spawning, checkpoint transitions, map progression
- `RunManager` — Tracks run state (current map, unlocked minions, Trojan Horse health)

**Scene composition:**
- Map tiles are independent scenes loaded and connected at runtime
- The Trojan Horse, wizard, minions, and enemies are each independent scenes
- Minions have a mode state (FOLLOW / STAY) that determines their behavior
- Placeholder art is encapsulated in visual child nodes that can be swapped for real assets

**Asset-swap pattern:**
- Every entity's visual representation lives in a child node/scene
- Gameplay code references the parent entity, never the visual directly
- Replacing placeholder geometry with real assets = swap the visual child scene

## Rejected Alternatives

| Option | Rejected Because |
|--------|-----------------|
| 2D isometric | Loses free lighting/shadows, requires manual depth sorting, harder to match Kingdom Wars TD reference |
| Web/TypeScript path | Game needs 3D rendering, scene tree for entity management, Godot's built-in physics |
| GL Compatibility renderer | Not suitable for 3D with dynamic lighting; Forward+ is the right choice |
| Godot Physics 3D | Jolt is default in 4.6 and more stable for 3D collision handling |
