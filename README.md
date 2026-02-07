# Trojan Horse

A wizard-led payload escort tower defense set in Greek mythology. Summon and command Pikmin-style minions to protect the Trojan Horse as it moves through mythological locations.

## Running the Game

1. Open this folder in Godot 4.6+
2. Press F5 (or Play button) to run

## Linting

Install gdtoolkit: `pip install gdtoolkit`
Run: `gdlint .`

## Project Structure

```
main.tscn / main.gd    — Entry scene (3D isometric)
.llm/                   — AI development context
  DISCOVERY.md          — Game design document
  DECISIONS.md          — Technical decisions
  PERSONAS.md           — AI persona definitions
  PRINCIPLES.md         — Development guidelines
  PATTERNS-*.md         — Reference implementations
  TOOLING.md            — Engine-specific tooling guide
```

## Design Summary

- **Genre:** Payload escort tower defense
- **Perspective:** Fixed isometric (2.5D)
- **Core mechanic:** Summon minions, choose pin-in-place or follow mode
- **Theme:** Greek mythology (River Styx, Mount Olympus, the Labyrinth, etc.)
- **Session:** ~20 minutes per full run (5 maps)
- **Engine:** Godot 4.6, GDScript, Forward+ rendering, Jolt physics

See `.llm/DISCOVERY.md` for full design details and `.llm/DECISIONS.md` for technical architecture.
