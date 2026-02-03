# Game Foundation

Minimal starting point for LLM-assisted game development. Clone it, open your AI coding tool, and describe the game you want to build.

## How It Works

This repo is designed to be **rewritten by an LLM** based on your game idea. The `.llm/` folder contains instructions that guide the AI through a structured conversation:

1. **You describe your game** — even a rough idea is fine
2. **The AI asks clarifying questions** — vision, gameplay, technical scope
3. **You answer** — briefly, in your own words
4. **The AI rewrites this repo** — package.json, tsconfig, src/index.ts, and the docs all get tailored to your specific game
5. **You start building** — with a configured foundation instead of a blank slate

## Quick Start

1. Clone this repo
2. Open it in your AI coding editor (Windsurf, Cursor, VS Code + Claude, etc.)
3. Say: *"I want to build [your game idea]. Let's get started."*
4. Answer the questions
5. The AI configures everything, then you run `npm install && npm run dev`

That's it. The AI reads `.llm/BOOTSTRAP.md` and handles the rest.

## What's in the Box

```
.llm/
  BOOTSTRAP.md   → Instructions for the AI (drives the initial conversation)
  DISCOVERY.md   → Design document (filled in during bootstrap)
  DECISIONS.md   → Technical decisions log (filled in during bootstrap)
  PERSONAS.md    → Specialized roles the AI can adopt during development
  PRINCIPLES.md  → Development guidelines
src/
  index.ts       → Empty entry point (rewritten during bootstrap)
tests/           → Test suite directory
```

### Before bootstrap: a template
### After bootstrap: your game's foundation

## Auto-Persona System

The AI automatically adopts specialized expertise based on your request — no explicit invocation needed. It assesses each question and applies the relevant lens:

| Domain | Focus |
|--------|-------|
| **@architect** | Structure, performance, technical decisions |
| **@gameplay** | Core loop, fun, balance, progression |
| **@ui** | Interface, input, feedback, accessibility |
| **@systems** | Individual game systems, data design |
| **@network** | Multiplayer, synchronization, infrastructure |
| **@quality** | Testing, debugging, stability |

**Example:** *"The combat feels flat"* — AI automatically applies @gameplay lens (balance, pacing, "juice").

You can still force a specific persona with `@persona` if needed, but the AI will typically figure it out.

## Scripts

| Command | Purpose |
|---------|---------|
| `npm run dev` | Start dev server (configured during bootstrap) |
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
