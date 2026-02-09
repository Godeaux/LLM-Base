# LLM Limitations

Reference this when working with Claude to understand failure modes.

## Reliable Failures (Don't Trust)
- **Novel algorithms:** Will confidently produce broken implementations
- **Precise math:** Counting, arithmetic with large numbers, numerical precision
- **3D spatial transforms:** Camera angles, light directions, node positions, and Transform3D values computed through math alone are frequently wrong. Always flag LLM-generated transforms for editor review — don't assume the computed values are visually correct
- **Long-range state:** Tracking details across 50+ turns degrades
- **Knowing unknowns:** Cannot reliably say "I don't know"

## Performance Degradation
- **Context length:** Quality drops as conversation grows
- **Ambiguous requirements:** Will guess rather than ask (despite instructions)
- **Multiple concerns:** Single-focus tasks >> multi-part requests
- **Code not read:** Suggestions for code not in context are unreliable

## When These Apply (Examples)
- "Implement a novel pathfinding algorithm" → HIGH RISK, verify heavily
- "Position the camera at an isometric angle" → HIGH RISK, verify transforms in editor
- "Add a health bar using the existing UI pattern" → LOW RISK, pattern matching
- "Fix this bug" (without showing code) → MEDIUM RISK, may hallucinate

## Mitigations
- Break large tasks into single-concern pieces
- Ask LLM to explain reasoning before trusting
- Verify numerical work independently
- Start fresh sessions for unrelated topics
- Show relevant code before asking for changes
