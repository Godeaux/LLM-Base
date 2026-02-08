# Web Tooling — TypeScript

Engine-specific tooling configuration for the Web/TypeScript path. See `PRINCIPLES.md` for engine-agnostic guidelines.

---

## File Naming

- **Files**: `PascalCase.ts` for classes/components, `camelCase.ts` for utilities
- Name describes content: `PlayerMovement.ts`, not `utils.ts` or `helpers.ts`

## Static Typing

- **No `any`.** Ever. Use `unknown` + type guards when the type is genuinely uncertain.
- `interface` for data shapes. `type` for unions, primitives, and mapped types.
- Function parameters and returns explicitly typed. The types should tell the story of your data.

## Threading

- Main thread until proven slow via profiling.
- Use Web Workers for: physics, pathfinding, procedural generation, heavy AI computation.
- Always document WHY something runs off the main thread.
- Communicate with workers via `postMessage` / `onmessage`. Keep the serialization boundary clean.

## Linting & Formatting

- **ESLint** enforces code quality. **Prettier** enforces style.
- Run before committing:
  ```bash
  npm run lint        # ESLint
  npm run format:check  # Prettier (check mode)
  npm run format      # Prettier (fix mode)
  ```
- Consistent formatting removes style debates from code review.

## Testing

- **Framework**: Vitest (fast, TypeScript-native, Vite-compatible).
- Tests live in `tests/` mirroring the `src/` directory structure.
- Run tests:
  ```bash
  npm test            # Run all tests
  npm test -- --watch # Watch mode
  ```
- **Test the scary parts**: state transitions, save/load, calculations, networking.
- **Skip**: rendering, UI layout, things you'll see immediately.
- Write tests alongside new systems — don't bolt them on later.

## Build & Dev Server

- **Build tool**: Vite (default). Fast HMR, native ESM, TypeScript out of the box.
- Dev commands:
  ```bash
  npm run dev         # Start dev server with HMR
  npm run build       # Production build
  npm run preview     # Preview production build locally
  ```

## Quality Checks (Every Increment)

Run these before each commit:
```bash
npm run build       # No type errors
npm run lint        # No lint warnings
npm test            # No test failures
```
