# Web Path Setup — TypeScript

> **Instructions for the LLM during Bootstrap Step 5.**
> This file describes how to configure the project after the user confirms the Web/TypeScript path.

---

## Prerequisites

The user has confirmed Path A (Web/TypeScript) in Bootstrap Step 4. Now rewrite the foundation.

**Fill in `.llm/DISCOVERY.md` FIRST.** The pre-commit hook blocks commits if it still contains template placeholders. `src/index.ts` also contains a blocker comment — only replace it after DISCOVERY.md is complete.

---

## Setup Steps

### 1. Fill in `.llm/DISCOVERY.md`

Fill in ALL blank fields with the user's actual answers from the bootstrap conversation. This unlocks everything else (the pre-commit hook checks for template placeholders like `_one-sentence description_`).

### 2. Fill in `.llm/DECISIONS.md`

This file was promoted from `.llm/web/DECISIONS.md` during cleanup. Fill in the tech stack table with choices and reasoning. Fill in dependencies with alternatives that were considered. Add architecture notes.

### 3. Update `package.json`

- Update `name` to match the game
- Add chosen renderer/physics/audio as dependencies
- Update `dev` script to actually start a Vite dev server (or whatever was chosen)
- Keep existing lint/format/test scripts

### 4. Configure `tsconfig.json`

Adjust for chosen framework (JSX if needed, path aliases, etc.)

### 5. Configure `eslint.config.js`

Add framework-specific plugins if needed.

### 6. Replace `src/index.ts`

NOW you can replace the blocker comment and empty export with a minimal "hello world" for the chosen renderer. Initialize the renderer, create a basic scene, show SOMETHING on screen. Keep it under 40 lines — this is proof-of-life, not the game.

### 7. Rewrite `README.md`

Rewrite to describe THIS game, not the template. Keep the scripts table, update everything else.

### 8. Delete Godot template files

Remove the `.godot-template/` directory entirely.

---

## Files to NOT Touch

- `.llm/PERSONAS.md` — useful as-is for ongoing development
- `.llm/PRINCIPLES.md` — useful as-is for ongoing development
- `.llm/BOOTSTRAP.md` — leave for reference
- `CLAUDE.md` — project instructions; leave as-is
- Don't create game-specific folders or systems yet

---

## Verification

After setup is complete:

1. Run `npm install`
2. Run `npm run build` — must pass
3. Run `npm run lint` — must pass
4. Tell the user: *"The foundation is configured. Run `npm run dev` to see it working. Now let's define your first playable — the smallest version where you can feel if the core is fun."*

Then transition to normal development using the personas in `PERSONAS.md`.
