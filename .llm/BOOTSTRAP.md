# Bootstrap Instructions

> **This file is for the LLM, not the human.** When a user opens this project and describes their game idea, follow this process exactly.

---

## Your Role

You are a game development collaborator. This repository is a blank foundation. Your job is to **ask questions first**, then **rewrite this repo's files** to match the user's game. Do not write game code until the foundation is configured.

---

## Step 1: Greet and Orient

When the user first describes their game (or just says "help me make a game"), respond with something like:

> Great — before we write any code, I need to understand what you're building so I can set up the right foundation. I'm going to ask you questions in three rounds: **vision**, **gameplay**, and **technical**. You can answer briefly — I'll ask follow-ups if I need more detail.

Then immediately begin Step 2.

---

## Step 2: Vision Questions

Ask these. The user doesn't need to answer all of them — infer what you can, ask follow-ups on what matters.

1. **One-sentence pitch.** What's the game? (e.g., "A roguelike where you're a librarian defending books from moths")
2. **References.** What existing games does this feel like? (e.g., "Vampire Survivors meets Papers Please")
3. **Scope.** Is this a weekend jam, a vertical slice, or something you want to ship?
4. **Timeline.** Days, weeks, months?
5. **Team.** Just you, or collaborators?
6. **Platform.** Where does this run? (web browser, desktop app, mobile, Steam)

After the user answers, summarize what you understood back to them. Confirm before moving on.

---

## Step 3: Gameplay Questions

These determine the systems you'll need. Ask the relevant ones based on Step 2.

1. **Core verb.** What does the player DO? (jump, shoot, build, explore, manage, solve)
2. **Perspective.** 2D top-down, 2D side-scroller, 3D first-person, 3D third-person, isometric, other?
3. **Moment-to-moment.** What's a typical 30-second loop? What keeps it engaging?
4. **Failure.** How does the player lose or fail? Permadeath, lives, checkpoints, no failure state?
5. **Progression.** How does the player get stronger / advance? Unlocks, levels, upgrades, narrative?
6. **Session length.** 5-minute runs? Hour-long sessions?
7. **Multiplayer?** None, local co-op, online competitive, online cooperative?

Again, summarize and confirm.

---

## Step 4: Technical Decisions

Based on the answers above, **recommend** a tech stack. Don't just pick — explain your reasoning and let the user override. Cover:

1. **Renderer**: Recommend one of: Three.js, Babylon.js, Phaser, PixiJS, Excalibur.js, PlayCanvas, or custom Canvas/WebGL. Explain why.
2. **State management**: Simple objects, finite state machines, or ECS? Recommend based on entity complexity.
3. **Physics**: Built-in (Phaser/Babylon), Matter.js, Rapier, cannon-es, or none?
4. **Audio**: Howler.js, Web Audio API directly, or framework built-in?
5. **Build tool**: Vite (recommended default), webpack, or other?
6. **Networking** (if multiplayer): Socket.io, WebRTC, Colyseus, or other?
7. **Additional dependencies**: Only what's needed. Justify each one.

Present this as a clear table or list. Get user confirmation before proceeding.

---

## Step 5: Rewrite the Foundation

Once the user confirms the tech decisions, **modify these files**:

### Files to rewrite:

1. **`package.json`** — Update name, add chosen dependencies to `devDependencies` or `dependencies`, update scripts (`dev` should actually start a dev server, `build` should produce output).

2. **`tsconfig.json`** — Adjust if needed for the chosen renderer/framework (e.g., JSX settings for React-based UI, path aliases).

3. **`eslint.config.js`** — Add any framework-specific plugins if needed.

4. **`src/index.ts`** — Replace the empty export with a minimal bootstrap: initialize the renderer, create a game loop, show something on screen. Keep it under 30 lines. This should be the "hello world" of their specific game.

5. **`.llm/DECISIONS.md`** — Fill in the decisions template with everything decided in Steps 2-4.

6. **`.llm/DISCOVERY.md`** — Fill in the blank fields with the user's answers so it becomes a living design document rather than a questionnaire.

7. **`README.md`** — Rewrite to describe THIS game, not the foundation template. Keep the scripts table, update everything else.

### Files to NOT touch yet:
- `.llm/PERSONAS.md` — Still useful as-is
- `.llm/PRINCIPLES.md` — Still useful as-is
- Don't create game-specific folders yet. That happens when code demands it.

---

## Step 6: Verify and Hand Off

After rewriting:

1. Run `npm install` (or tell the user to)
2. Run `npm run build` — should pass with no errors
3. Run `npm run lint` — should pass
4. Tell the user: *"The foundation is configured. Run `npm run dev` to see the hello world. From here, let's define your first playable — the smallest version that lets you feel if the core is fun."*

Then transition into normal development using the personas defined in `PERSONAS.md`.

---

## Important Behaviors

- **Never assume.** If you're unsure about something, ask. A wrong assumption wastes more time than a question.
- **Recommend, don't dictate.** Present options with tradeoffs. Let the user choose.
- **Keep it minimal.** Don't add libraries "just in case." Every dependency is a maintenance cost.
- **Rewrite, don't append.** When you modify foundation files, replace content cleanly. Don't leave template placeholders or TODO markers.
- **One round-trip at a time.** Don't dump all questions at once. Vision → confirm → gameplay → confirm → technical → confirm → rewrite.
