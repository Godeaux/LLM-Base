# Bootstrap Instructions

> **THIS FILE IS FOR THE LLM, NOT THE HUMAN.**

---

## ⚠️ CRITICAL: DO NOT WRITE CODE YET

**Read this entire file before responding to the user.**

When a user describes their game idea — no matter how detailed — you MUST complete the conversation steps below BEFORE writing any code, creating any files, or modifying any configs. Even if the user gives you a rich description, there are always gaps. Your job is to find them.

**The user's first message is a starting point, not a spec.** Acknowledge what they said, then ask about what they DIDN'T say.

---

## Step 1: Acknowledge and Reframe

Read the user's message carefully. Respond by:

1. Restating their idea back in 2-3 sentences to show you understood
2. Noting what you CAN already infer (so you don't re-ask things they covered)
3. Saying something like:

> Before I write any code, I want to ask some questions to make sure I build the right foundation. This will go in three rounds — you can answer as briefly as you want.

Then ask the **first round only**. Do NOT dump all questions at once.

---

## Step 2: Vision Round (ask these FIRST, wait for answers)

Look at what the user already told you. Skip questions they already answered. Ask what's missing from this list:

- **Scope**: Weekend jam, vertical slice, or something you want to ship?
- **Timeline**: How much time are you giving this? Days, weeks, months?
- **Team**: Solo or collaborators? Are you the programmer, or are you non-technical using AI to build?
- **Platform**: Where does this run? Browser, desktop (Electron/Steam), mobile?
- **Art direction**: Do you have art assets, or does everything need to be placeholder/procedural?
- **Monetization / audience**: Just for fun, portfolio piece, or intended for players?

**WAIT for the user to respond before proceeding to Step 3.** Do not continue to gameplay questions in the same message.

---

## Step 3: Gameplay Round (ask AFTER Step 2 is answered)

Again, skip anything the user already covered. Ask what's missing:

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

Cover these:

| Decision | Your recommendation | Why |
|----------|-------------------|-----|
| **Renderer** | Three.js / Babylon.js / Phaser / PixiJS / etc. | Based on 2D/3D, complexity, features needed |
| **Physics** | Rapier / cannon-es / Ammo.js / built-in / none | Based on gameplay needs |
| **State management** | Simple objects / FSM / ECS | Based on entity complexity |
| **Audio** | Howler.js / Web Audio / framework built-in | Based on audio needs |
| **Build tool** | Vite (default) / other | Almost always Vite |
| **Networking** | None / Socket.io / Colyseus / WebRTC | Only if multiplayer |
| **Other deps** | Only what's needed | Justify each one |

End with: *"Does this stack sound right to you, or do you have preferences I should know about?"*

**WAIT for confirmation before proceeding to Step 5.**

---

## Step 5: Rewrite the Foundation

Only after the user confirms (or adjusts) the tech stack, rewrite these files:

### Files to rewrite:

1. **`package.json`**
   - Update `name` to match the game
   - Add chosen renderer/physics/audio as dependencies
   - Update `dev` script to actually start a Vite dev server (or whatever was chosen)
   - Keep existing lint/format/test scripts

2. **`tsconfig.json`**
   - Adjust for chosen framework (JSX if needed, path aliases, etc.)

3. **`eslint.config.js`**
   - Add framework-specific plugins if needed

4. **`src/index.ts`**
   - Replace empty export with a minimal "hello world" for the chosen renderer
   - Initialize the renderer, create a basic scene, show SOMETHING on screen
   - Keep it under 40 lines — this is proof-of-life, not the game

5. **`.llm/DECISIONS.md`**
   - Fill in the tech stack table with choices and reasoning
   - Fill in dependencies with alternatives that were considered
   - Add architecture notes

6. **`.llm/DISCOVERY.md`**
   - Fill in all the blank fields with the user's actual answers

7. **`README.md`**
   - Rewrite to describe THIS game, not the template
   - Keep the scripts table, update everything else

### Files to NOT touch:
- `.llm/PERSONAS.md` — useful as-is for ongoing development
- `.llm/PRINCIPLES.md` — useful as-is for ongoing development
- `.llm/BOOTSTRAP.md` — this file; leave it for reference
- Don't create game-specific folders or systems yet

---

## Step 6: Verify and Hand Off

After rewriting:

1. Run `npm install`
2. Run `npm run build` — must pass
3. Run `npm run lint` — must pass
4. Tell the user: *"The foundation is configured. Run `npm run dev` to see it working. Now let's define your first playable — the smallest version where you can feel if the core is fun."*

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
