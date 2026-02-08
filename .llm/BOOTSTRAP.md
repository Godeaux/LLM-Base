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

- **Scope**: Intended to eventually ship as a playable product (even if small)
- **Workflow**: YOU (the AI) do 100% of the coding. Human(s) direct, review, and decide. This is always true regardless of team size.
- **Audience**: Intended for real players, not just a portfolio piece

These are not questions. These are facts about the context.

---

## Step 1: Acknowledge + Ask Vision Round

**This is a single message.** Read the user's message, then respond with all of the following in one output:

### Part A: Acknowledge (prose, 2-4 sentences)

1. Restate the user's idea back to confirm understanding.
2. Note anything you can already infer (art style, genre, perspective, etc.) so they know you listened.
3. Transition with: *"Before I write any code, I need to ask some questions across two rounds — vision/vibe, then gameplay details."*

### Part B: Vision Questions (numbered list)

Ask **all** of the following. Do not skip any, even if the user already addressed them — confirming is better than assuming.

1. **Timeline**: How long is this project? (hours-to-days sprint / weeks / months+)
2. **Team size**: How many people? (solo / 2-3 / 4+)
3. **Art direction**: What visual style? (pixel art, low-poly, stylized, realistic, geometric/abstract, hand-drawn)
4. **Audio direction**: What's the sound vibe? (retro, orchestral, electronic, ambient, none yet)
5. **Name**: Got a working title? (yes / pick one later)
6. **Inspirations**: Any games, movies, or aesthetics that capture the feel? (specific titles or "nothing specific")

**STOP. Wait for response.**

---

## Step 2: Summarize Vision + Ask Gameplay Round

**This is a single message.** After the user answers Step 1's questions:

### Part A: Summarize (prose, 2-4 sentences)

Restate what the user answered in the vision round. Use their words where possible. This is a checkpoint — if you misunderstood something, they'll correct it here.

### Part B: Gameplay Questions (numbered list)

Ask **all** of the following. Do not skip any.

1. **Dimension**: Is this a 2D game, 3D game, or 2.5D (3D graphics with constrained gameplay)? If unsure, describe the look and feel — we'll figure it out together. (2D / 3D / 2.5D / not sure)
2. **Perspective**: How does the player view the game? (top-down, side-scroll, isometric, first-person, third-person, fixed camera)
3. **Core verb**: What does the player actively DO most of the time? (move, build, shoot, manage, solve, survive)
4. **Pacing**: Is this lean-forward or lean-back? (constant decisions / intermittent decisions / mostly watching)
5. **Failure state**: Can the player lose? What happens? (restart, checkpoint, permadeath, no failure)
6. **Progression**: What changes between hour 1 and hour 10? (new abilities, harder levels, story, unlocks, nothing)
7. **Session length**: How long is a typical play session? (under 5 min, 5-30 min, 30-60 min, 60+ min)
8. **Complexity curve**: What starts simple and gets complex later? (specific mechanic or system)

**STOP. Wait for response.**

---

## Step 3: Summarize Gameplay + Present Tech Recommendation

**This is a single message.** After the user answers Step 2's questions:

### Part A: Summarize (prose, 2-4 sentences)

Restate what the user answered in the gameplay round. Confirm the core loop in one sentence.

### Part B: Engine Recommendation (prose + table)

Based on everything gathered, recommend **one** engine path. Present it as a decision, not a menu. Fill in the appropriate table below with **specific** choices — not option lists.

**Decision criteria for engine path:**
- Recommend **Web (TypeScript)** for: browser-first, rapid prototyping, web distribution, simpler 2D, 3D where Three.js/Babylon.js suffice.
- Recommend **Godot (GDScript)** for: built-in editor tooling, complex scene trees, physics with editor integration (Jolt default in 4.6), particle/shader editors, animation state machines, desktop/console distribution, both 2D and 3D with first-class support for each.
- Do NOT recommend Godot just because the game is 3D — Three.js handles plenty of 3D games.

#### If recommending Web (TypeScript):

| Decision | Choice | Why |
|----------|--------|-----|
| **Renderer** | _your specific pick_ | _one-sentence reason_ |
| **Physics** | _your specific pick or "none"_ | _one-sentence reason_ |
| **State management** | _your specific pick_ | _one-sentence reason_ |
| **Audio** | _your specific pick_ | _one-sentence reason_ |
| **Build tool** | _your specific pick_ | _one-sentence reason_ |
| **Networking** | _your specific pick or "none"_ | _one-sentence reason_ |

#### If recommending Godot (GDScript):

Use the 2D vs 3D decision guide in `.llm/godot/DECISIONS.md` to inform the dimension, rendering, and physics choices below. The user's answers to the dimension and perspective questions should make this straightforward.

| Decision | Choice | Why |
|----------|--------|-----|
| **Dimension** | _2D / 3D / 2.5D_ | _one-sentence reason based on their art style, perspective, and genre_ |
| **Godot version** | _4.6 stable unless they have a reason otherwise_ | _one-sentence reason_ |
| **Rendering method** | _Forward+ for 3D, GL Compatibility for 2D_ | _one-sentence reason_ |
| **Physics** | _Jolt for 3D (default), Godot Physics for 2D_ | _one-sentence reason_ |
| **State management** | _your specific pick_ | _one-sentence reason_ |
| **Scene structure** | _your specific pick_ | _one-sentence reason_ |
| **Networking** | _your specific pick or "none"_ | _one-sentence reason_ |

### Part C: Closing (exact format)

End with exactly this structure:

> I recommend **[Web/Godot]** because [1-2 sentence reason]. This will configure your project for [path] and **permanently remove the [other path] files** — you can always clone fresh if you change your mind later.
>
> Does this sound right, or would you change anything?

**STOP. Wait for response.**

---

## Step 4: Handle Confirmation or Pushback

**This step has two possible flows:**

### If the user confirms (says yes, looks good, etc.):
Proceed directly to Step 5.

### If the user pushes back (wants changes):

**First pushback:** Explain your reasoning in 1-2 sentences. Then present the adjusted recommendation. Ask for confirmation again.

**Second pushback (or if the user insists):** Accept unconditionally. Update the table with their preference and proceed to Step 5. Do not argue further.

---

## Step 5: Rewrite the Foundation

Only after the user confirms (or adjusts) the tech stack, rewrite the project files.

**Follow the setup instructions in the chosen engine's folder:**

- **Path A (Web/TypeScript):** Follow `.llm/web/SETUP.md`
- **Path B (Godot/GDScript):** Follow `.llm/godot/SETUP.md`

Those files contain the complete, step-by-step instructions for configuring the project, including which files to create, modify, and delete.

---

## Step 6: Promote and Clean Up

After completing the engine-specific setup from Step 5, clean up the engine folders:

1. **Delete the non-chosen engine folder entirely:**
   - If Web was chosen: delete `.llm/godot/`
   - If Godot was chosen: delete `.llm/web/`

2. **Promote the chosen engine's files to `.llm/` root:**
   - Move all files from `.llm/<chosen>/` up to `.llm/`
   - For example, `.llm/web/PATTERNS.md` becomes `.llm/PATTERNS.md`
   - This applies to: `PATTERNS.md`, `SETUP.md`, `DECISIONS.md`, `TOOLING.md`

3. **Delete the now-empty engine subfolder.**

After this step, the `.llm/` directory should contain only engine-agnostic files plus the chosen engine's promoted files. No trace of the rejected engine remains.

---

## Step 7: Verify and Hand Off

Follow the verification steps in the `SETUP.md` (now promoted to `.llm/SETUP.md`).

Then transition to normal development using the personas in `PERSONAS.md`.

---

## Rules (read these carefully)

1. **NEVER write code before completing Steps 1-4.** Even if the user says "just start coding." The questions take 5 minutes. Bad foundations waste days.

2. **Ask every question.** Even if the user already addressed it in their opening message. Confirming is fast; assuming is risky. The user can say "already answered above" — that's fine.

3. **One round at a time.** Vision questions → STOP → gameplay questions → STOP → tech recommendation → STOP. Never combine rounds in a single message.

4. **Summarize at every transition.** Before asking the next round, restate what the user answered. Use their words. This catches misunderstandings before they compound.

5. **Recommend, don't menu.** Fill in the tech stack table with specific choices. Don't say "would you like Three.js or Babylon.js?" Say "I recommend Three.js because [reason]."

6. **Numbered lists for questions.** Every question round uses a numbered list with bold labels. Not prose, not bullets, not conversational paragraphs.

7. **The user might not know the answer.** That's fine. If they say "I don't know," make a recommendation and note it. Don't stall.

8. **Bias toward starting small.** When in doubt, recommend simpler tech, fewer dependencies, less architecture. It's easier to add than to remove.

9. **Two-strike pushback rule.** If the user disagrees with a tech recommendation: explain your reasoning once, then accept their preference unconditionally on the second pushback.
