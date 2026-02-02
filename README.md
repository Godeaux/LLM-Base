# Game Foundation

Minimal starting point for LLM-assisted game development.

## Philosophy

This repo contains almost no code. Instead, it provides:

- **Personas** — Specialized roles the LLM can adopt
- **Discovery process** — Structured conversation before code
- **Principles** — Guidelines that inform decisions as the project grows

## Quick Start

1. Fork or clone this repo
2. Read `.llm/DISCOVERY.md`
3. Start a conversation: *"I want to build [concept]. Let's start with @architect to scope it."*
4. Answer the discovery questions
5. Build incrementally

## Personas

Prefix requests to invoke specialized expertise:

| Persona | Focus |
|---------|-------|
| `@architect` | Structure, performance, technical decisions |
| `@gameplay` | Core loop, fun, balance, progression |
| `@ui` | Interface, input, feedback, accessibility |
| `@systems` | Individual game systems, data design |
| `@network` | Multiplayer, synchronization, infrastructure |
| `@quality` | Testing, debugging, stability |

**Example:** *"@gameplay The combat feels flat. How do we add more impact?"*

## Structure

```
.llm/           → LLM collaboration docs (start here)
src/index.ts    → Empty entry point
tests/          → Test suite (mirrors src/ structure)
```

Everything else emerges from your game's needs.

## Scripts

| Command | Purpose |
|---------|---------|
| `npm run dev` | Start dev server (after configuring renderer) |
| `npm run build` | Type-check with TypeScript |
| `npm run lint` | Lint with ESLint |
| `npm run lint:fix` | Auto-fix lint issues |
| `npm run format` | Format with Prettier |
| `npm run format:check` | Check formatting |
| `npm test` | Run tests with Vitest |
| `npm run test:watch` | Run tests in watch mode |

## Principles (summary)

- Grow structure, don't prescribe it
- Small files, clear names
- Data over behavior
- Explicit over clever
- Ask before building
- Iterate in playable increments
- Make it work, make it right, make it fast (in that order)

See `.llm/PRINCIPLES.md` for full details.
