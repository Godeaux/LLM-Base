# Bootstrap Instructions

> **THIS FILE IS FOR THE LLM, NOT THE HUMAN.**

---

## ⚠️ CRITICAL: DO NOT WRITE CODE YET

**Read this entire file before responding to the user.**

When a user describes their game idea — no matter how detailed — you MUST complete the conversation steps below BEFORE writing any code, creating any files, or modifying any configs. Even if the user gives you a rich description, there are always gaps. Your job is to find them.

**The user's first message is a starting point, not a spec.** Acknowledge what they said, then ask about what they DIDN'T say.

---

## Default Assumptions

Assume these unless the user explicitly says otherwise. Do NOT ask about them:

- **Scope**: Intended to eventually ship as a real product
- **Timeline**: Months — treat this as a genuine, long-term project
- **Team**: Solo developer who is the project manager. YOU (the AI) do 100% of the coding. The user directs, reviews, and decides.
- **Platform**: Runs on localhost during development. Packageable for distribution later (browser, desktop, etc.) — don't lock in a distribution target now.
- **Audience**: Intended for real players, not just a portfolio piece

These are not questions. These are facts about the context. Move on.

---

## Step 1: Acknowledge and Understand

Read the user's message carefully. Respond by:

1. Restating their idea back in 2-3 sentences to show you understood
2. Listing what you CAN already infer from their description (so you don't waste time re-asking)
3. Saying something like:

> Before I write any code, I want to ask some questions to make sure I build the right foundation. I'll keep it to two quick rounds — art/vibe, then gameplay details.

Then ask the **first round only**. Do NOT dump all questions at once.

---

## Step 2: Art & Identity Round (ask these FIRST, wait for answers)

Skip anything the user already covered. Only ask what's actually missing:

- **Art direction**: What's the visual vibe? (Low-poly, stylized, pixel art, realistic, geometric/abstract, hand-drawn?) Do you have any art assets, or will everything be procedural/placeholder for now?
- **Audio vibe**: Any feel for the soundtrack / sound effects direction? (Retro, orchestral, electronic, ambient, none yet?)
- **Name / working title**: Got one, or should we pick something later?
- **Inspirations**: Any specific games, movies, or aesthetics that capture the feel you're going for?

These questions help the AI make better visual/aesthetic choices later. They're quick.

**WAIT for the user to respond before proceeding to Step 3.** Do not continue to gameplay questions in the same message.

---

## Step 3: Gameplay Round (ask AFTER Step 2 is answered)

Skip anything the user already covered. Only ask what's genuinely unclear:

- **Camera / perspective**: How does the player view the game? (top-down, orbital, first-person, fixed, etc.)
- **Core interaction**: What does the player actively DO vs. what happens automatically?
- **Pacing**: Is this a lean-forward game (constant decisions) or lean-back (watch and occasionally intervene)?
- **Failure state**: Can you lose? What happens? Restart, checkpoint, or no failure?
- **Progression arc**: What does hour 1 vs. hour 10 look like? What changes?
- **Session length**: 5-minute runs, 30-minute sessions, or endless?
- **Complexity curve**: What's simple at first and gets complex later?

**WAIT for the user to respond before proceeding to Step 4.**

---

## Step 4: Technical Recommendation (ask AFTER Step 3 is answered)

Now YOU present a recommended tech stack. Don't ask the user to choose from a menu — make a specific recommendation and explain why. The user can push back.

**First, determine the engine path.** Based on the game's needs, recommend one of:

### Path A: Web-based (TypeScript + libraries)
Best for: browser-first games, rapid prototyping, web distribution, simpler 2D games, or 3D games where Three.js/Babylon.js suffice.

| Decision | Your recommendation | Why |
|----------|-------------------|-----|
| **Renderer** | Three.js / Babylon.js / Phaser / PixiJS / etc. | Based on 2D/3D, complexity, features needed |
| **Physics** | Rapier / cannon-es / Ammo.js / built-in / none | Based on gameplay needs |
| **State management** | Simple objects / FSM / ECS | Based on entity complexity |
| **Audio** | Howler.js / Web Audio / framework built-in | Based on audio needs |
| **Build tool** | Vite (default) / other | Almost always Vite |
| **Networking** | None / Socket.io / Colyseus / WebRTC | Only if multiplayer |
| **Other deps** | Only what's needed | Justify each one |

### Path B: Godot (GDScript)
Best for: games needing a full engine (built-in physics, scene tree, animation, particles, lighting), desktop-first distribution, complex 3D, or when the user mentions Godot.

| Decision | Your recommendation | Why |
|----------|-------------------|-----|
| **Godot version** | 4.x (stable) | GDScript 2.0, improved 3D, typed syntax |
| **Rendering** | Forward+ / Mobile / Compatibility | Based on visual complexity and target platform |
| **Physics** | Built-in Godot physics / Jolt override | Based on simulation needs |
| **State management** | Autoloads / signals / Resources | Based on complexity |
| **Scene structure** | Recommended scene tree layout | Based on game architecture |
| **Networking** | None / built-in MultiplayerAPI / ENet | Only if multiplayer |
| **GDExtension** | Only if needed | For performance-critical native code |

**If recommending Godot, explain why it fits better than the web path (or vice versa).** Don't recommend Godot just because the game is 3D — Three.js handles plenty of 3D games. Recommend Godot when the user needs: built-in editor tooling, complex scene trees, built-in physics with editor integration, particle/shader editors, animation state machines, or plans to ship to desktop/console.

End with: *"Does this stack sound right to you, or do you have preferences I should know about?"*

**WAIT for confirmation before proceeding to Step 5.**

---

## Step 5: Rewrite the Foundation

Only after the user confirms (or adjusts) the tech stack, rewrite these files.

**⚠️ You MUST fill in `.llm/DISCOVERY.md` FIRST.** The pre-commit hook will block commits if it still contains template placeholders. `src/index.ts` also contains a blocker comment — only replace it after DISCOVERY.md is complete.

### If Path A (Web/TypeScript):

1. **`.llm/DISCOVERY.md`** — Fill in ALL blank fields with the user's actual answers. This unlocks everything else (the pre-commit hook checks for template placeholders like `_one-sentence description_`).

2. **`.llm/DECISIONS.md`** — Fill in the tech stack table with choices and reasoning. Fill in dependencies with alternatives that were considered. Add architecture notes.

3. **`package.json`** — Update `name` to match the game. Add chosen renderer/physics/audio as dependencies. Update `dev` script to actually start a Vite dev server (or whatever was chosen). Keep existing lint/format/test scripts.

4. **`tsconfig.json`** — Adjust for chosen framework (JSX if needed, path aliases, etc.)

5. **`eslint.config.js`** — Add framework-specific plugins if needed.

6. **`src/index.ts`** — NOW you can replace the blocker comment and empty export with a minimal "hello world" for the chosen renderer. Initialize the renderer, create a basic scene, show SOMETHING on screen. Keep it under 40 lines — this is proof-of-life, not the game.

7. **`README.md`** — Rewrite to describe THIS game, not the template. Keep the scripts table, update everything else.

### If Path B (Godot/GDScript):

1. **`.llm/DISCOVERY.md`** — Fill in ALL blank fields (same as Path A — this always comes first).

2. **`.llm/DECISIONS.md`** — Fill in with Godot-specific decisions (version, rendering method, physics approach, scene structure). Replace the web-centric dependencies table with Godot equivalents (addons, GDExtensions if any).

3. **Remove web-specific files** — Delete `package.json`, `tsconfig.json`, `eslint.config.js`, `.prettierrc`, `src/index.ts`, and `tests/.gitkeep`. These don't apply to a Godot project.

4. **Create `project.godot`** — Minimal Godot project file with the game name and basic settings.

5. **Create entry scene** — A `main.tscn` (or `.tres`) and `main.gd` that shows proof-of-life: a basic scene with a camera and something visible. Keep it minimal.

6. **Create `.gdlintrc`** — If gdlint/gdtoolkit is available, configure basic GDScript linting rules.

7. **Update `.husky/pre-commit`** — Replace npm-based checks with Godot-appropriate checks (or remove if not applicable).

8. **`README.md`** — Rewrite to describe the Godot project. Replace npm scripts table with Godot workflow (how to open in editor, how to run, how to export).

### Files to NOT touch (either path):
- `.llm/PERSONAS.md` — useful as-is for ongoing development
- `.llm/PRINCIPLES.md` — useful as-is for ongoing development
- `.llm/BOOTSTRAP.md` — this file; leave it for reference
- `CLAUDE.md` — project instructions; leave as-is
- Don't create game-specific folders or systems yet

---

## Step 6: Verify and Hand Off

After rewriting:

### Path A (Web/TypeScript):
1. Run `npm install`
2. Run `npm run build` — must pass
3. Run `npm run lint` — must pass
4. Tell the user: *"The foundation is configured. Run `npm run dev` to see it working. Now let's define your first playable — the smallest version where you can feel if the core is fun."*

### Path B (Godot/GDScript):
1. Confirm `project.godot` is valid and the entry scene exists
2. Tell the user: *"The foundation is configured. Open this folder in Godot 4.x and hit Play to see the base scene. Now let's define your first playable — the smallest version where you can feel if the core is fun."*

Then transition to normal development using the personas in `PERSONAS.md`.

---

## Rules (read these carefully)

1. **NEVER write code before completing Steps 1-4.** Even if the user says "just start coding." The questions take 5 minutes. Bad foundations waste days.

2. **Don't re-ask things the user already told you.** Parse their initial message carefully. Only ask about gaps.

3. **One round at a time.** Send vision questions → wait → send gameplay questions → wait → send tech recommendation → wait → then rewrite. Never combine rounds.

4. **Summarize before moving on.** After each round, restate what you understood. Let the user correct misunderstandings before they compound.

5. **Recommend, don't menu.** Don't say "would you like Three.js or Babylon.js?" Say "I recommend Three.js because [reason]. Here's what that means for your project."

6. **Keep it conversational.** These are questions, not a form. React to what the user says. Follow up on interesting details. Skip irrelevant questions.

7. **The user might not know the answer.** That's fine. If they say "I don't know," make a recommendation and explain it. Don't stall.

8. **Bias toward starting small.** When in doubt, recommend simpler tech, fewer dependencies, less architecture. It's easier to add than to remove.
