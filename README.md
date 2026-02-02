# Idle TD

A 3D physics-based idle tower defense game. A central tower defends against waves of enemies approaching from all directions using elemental attacks — chain lightning, fireballs, blizzard gusts, arcing arrows, and summonable minions. Built with Three.js and cannon-es for physics-driven spectacle: arcing projectiles, ragdoll knockback, bipedal walkers, and flapping flyers.

## Quick Start

```bash
npm install
npm run dev
```

Open `http://localhost:5173` in your browser. Orbit the camera with mouse drag.

## Scripts

| Command | Purpose |
|---------|---------|
| `npm run dev` | Start Vite dev server |
| `npm run build` | Type-check + production build |
| `npm run lint` | Lint with ESLint |
| `npm run lint:fix` | Auto-fix lint issues |
| `npm run format` | Format with Prettier |
| `npm run format:check` | Check formatting |
| `npm test` | Run tests with Vitest |
| `npm run test:watch` | Run tests in watch mode |

## Tech Stack

- **Three.js** — 3D rendering, procedural low-poly geometry
- **cannon-es** — Physics (rigid bodies, constraints, collision)
- **TypeScript** + **Vite** — Build tooling
- **Plain HTML/CSS** — UI overlay

## Project Structure

See `.llm/DISCOVERY.md` for design details and `.llm/DECISIONS.md` for technical rationale.
