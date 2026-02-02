# Project Instructions

> **READ THIS BEFORE DOING ANYTHING.**

## If this is a fresh clone (no game code yet):

1. **Read `.llm/BOOTSTRAP.md` in full** before responding to the user.
2. **DO NOT write code, create files, or modify configs** until all discovery rounds in BOOTSTRAP.md are complete.
3. The user will describe a game idea. Your job is to **ask questions first** — vision, gameplay, then technical — across multiple conversation turns.
4. Only after the user confirms the tech stack do you rewrite the foundation files.
5. **`.llm/DISCOVERY.md` must be filled in before any code is written.** A pre-commit hook enforces this.

## If the bootstrap is already complete (DISCOVERY.md is filled in):

1. Read `.llm/DECISIONS.md` for the tech stack and architecture context.
2. Read `.llm/DISCOVERY.md` for the game design context.
3. Use the personas in `.llm/PERSONAS.md` when the user invokes them.
4. Follow the principles in `.llm/PRINCIPLES.md`.

## Always:

- **Ask before assuming.** Ambiguity → questions, not guesses.
- **One step at a time.** Don't combine conversation rounds or skip ahead.
- **Iterate in playable increments.** Every change should leave the project buildable.
