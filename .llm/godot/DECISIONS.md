# Technical Decisions — Godot / GDScript

> This document is filled in by the LLM after the bootstrap conversation. It records what was decided and WHY, so every future prompt has context. If this is still a template, the bootstrap hasn't happened yet.

---

## Engine Path

**Engine**: Godot 4.6 (GDScript)

---

## 2D vs 3D Decision Guide

This is the first and most consequential technical decision. Use this guide during bootstrap to help the user choose.

### Quick Decision Framework

| Factor | Choose 2D | Choose 3D | Choose 2.5D |
|--------|-----------|-----------|-------------|
| **Art style** | Pixel art, hand-drawn, sprites | Low-poly, realistic, voxel | 3D look with 2D gameplay constraints |
| **Camera** | Top-down, side-scroll, fixed | Free orbit, first-person, cinematic | Fixed-angle, isometric, locked axis |
| **Genre fit** | Platformer, puzzle, card game, visual novel, tower defense, top-down RPG | FPS, TPS, racing, flight sim, open-world | Diablo-like ARPG, side-scroll with depth, Paper Mario |
| **Physics needs** | Simple collision, raycasts | Full 3D collisions, joints, gravity | 3D physics on constrained axes |
| **Performance** | Very cheap — hundreds of sprites no problem | More expensive — lighting, shadows, meshes | Middle ground — 3D rendering costs, simpler gameplay physics |
| **Complexity** | Lower — fewer dimensions to manage | Higher — camera, lighting, materials, UV mapping | Medium — 3D rendering complexity, 2D gameplay simplicity |
| **Solo dev friendly** | Very — 2D art is faster to produce | Harder — 3D assets take longer (unless using asset packs) | Medium — 3D assets needed but gameplay is simpler |

### Rendering Method by Dimension

| Rendering Method | Best For | Notes |
|-----------------|----------|-------|
| **Forward+** | 3D games, 2.5D with dynamic lighting | Default in 4.6. Best 3D quality. Supports all features. |
| **Mobile** | Mobile targets, simpler 3D | Reduced feature set for performance. Good for low-end 3D. |
| **GL Compatibility** | 2D games, web export, low-end hardware | OpenGL 3.3 backend. Fastest for pure 2D. Best web compatibility. |

**Rule of thumb:** If your game is pure 2D → GL Compatibility. If 3D is involved → Forward+. Only use Mobile if targeting phones or very low-end hardware.

### Physics by Dimension

| Dimension | Recommended Physics | Why |
|-----------|-------------------|-----|
| **2D** | Godot Physics 2D | Mature, well-integrated, no reason to change |
| **3D** | Jolt (default in 4.6) | More stable than legacy Godot Physics 3D. Better collision handling. |
| **2.5D** | Jolt (3D physics on constrained axes) | Use 3D physics but constrain movement programmatically |

### What "2.5D" Means in Practice

2.5D isn't a Godot feature — it's a design pattern. You use 3D rendering and physics, but constrain gameplay to fewer axes:
- **Side-scrolling 2.5D**: Lock the Z-axis. Player moves on X/Y only. Camera is fixed. Examples: Trine, Little Nightmares.
- **Isometric 2.5D**: 3D world, fixed camera angle. Examples: Hades, Diablo.
- **Layered 2.5D**: 2D sprites in a 3D world with depth sorting. Example: Paper Mario.

---

## Tech Stack

| Category | Choice | Why |
|----------|--------|-----|
| **Dimension** | _TBD_ (2D / 3D / 2.5D) | _reasoning — see guide above_ |
| **Godot version** | _TBD_ (4.6 stable recommended) | _reasoning_ |
| **Rendering method** | _TBD_ (Forward+ / Mobile / GL Compatibility) | _reasoning — see rendering table above_ |
| **Physics** | _TBD_ (Jolt [default in 4.6] / Godot Physics) | _reasoning — see physics table above_ |
| **State management** | _TBD_ (Autoloads / signals / Resources) | _reasoning_ |
| **Scene structure** | _TBD_ (recommended scene tree layout) | _reasoning_ |
| **UI framework** | _TBD_ (Control nodes / custom / addon) | _reasoning_ |
| **Input scheme** | _TBD_ (Keyboard+mouse / controller / touch / hybrid) | _reasoning_ |
| **Networking** | _TBD_ (None / built-in MultiplayerAPI / ENet) | _reasoning_ |
| **GDExtension** | _TBD_ (only if needed for native performance) | _reasoning_ |

## Addons / Extensions

| Addon | Purpose | Alternatives Considered |
|-------|---------|------------------------|
| _TBD_ | _TBD_ | _TBD_ |

## Architecture Notes

_How do the major pieces connect? Scene tree structure, autoload layout, signal flow. Written after tech stack is confirmed._

## Rejected Alternatives

_Record what you decided NOT to do and why. This prevents revisiting the same discussions._

| Option | Rejected Because |
|--------|-----------------|
| _TBD_ | _TBD_ |
