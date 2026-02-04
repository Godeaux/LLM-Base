# LLM Limitations

Reference this when working with Claude to understand failure modes.

## Reliable Failures (Don't Trust)
- **Novel algorithms:** Will confidently produce broken implementations
- **Precise math:** Counting, arithmetic with large numbers, numerical precision
- **Long-range state:** Tracking details across 50+ turns degrades
- **Knowing unknowns:** Cannot reliably say "I don't know"

## Performance Degradation
- **Context length:** Quality drops as conversation grows
- **Ambiguous requirements:** Will guess rather than ask (despite instructions)
- **Multiple concerns:** Single-focus tasks >> multi-part requests
- **Code not read:** Suggestions for code not in context are unreliable

## When These Apply (Examples)
- "Implement a novel pathfinding algorithm" → HIGH RISK, verify heavily
- "Add a health bar using the existing UI pattern" → LOW RISK, pattern matching
- "Fix this bug" (without showing code) → MEDIUM RISK, may hallucinate

## Mitigations
- Break large tasks into single-concern pieces
- Ask LLM to explain reasoning before trusting
- Verify numerical work independently
- Start fresh sessions for unrelated topics
- Show relevant code before asking for changes
