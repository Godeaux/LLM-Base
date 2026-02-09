# Tooling: Signals, Autoloads & Physics Layers

Communication patterns between nodes, singleton architecture, and collision layer management.

All standards target **Godot 4.6** with static typing.

---

## Signal Conventions

- **Name signals in past tense** — they announce something that happened:
  `signal health_changed`, `signal enemy_killed`, `signal level_loaded`
- **Include relevant data as typed parameters:**
  `signal damage_taken(amount: int, source: Node)`
- **Connect in `_ready()`, disconnect if the listener is freed before the emitter:**
  ```gdscript
  func _ready() -> void:
      EventBus.player_damaged.connect(_on_player_damaged)

  # Godot auto-disconnects when the listener is freed IF using the default flags.
  # Manual disconnect is needed only for cross-scene persistent connections.
  ```
- **Prefer signals over direct method calls** for communication between siblings or unrelated nodes.
- **Prefer direct method calls** for parent-to-child or tightly coupled components.

---

## Autoload Architecture

Autoloads are singleton nodes that persist across scene changes. They're Godot's answer to "where does global state live?"

**When to use autoloads:**
- Global services that every scene needs: `EventBus`, `AudioManager`, `SceneManager`, `SaveManager`
- Cross-scene state: player inventory, settings, score
- Each autoload should have a single, clear responsibility

**When NOT to use autoloads:**
- Game-specific logic (belongs in the current scene)
- Anything that should reset when the scene changes
- Data that only one scene cares about

**How many is too many:** Keep it under 5-6 autoloads. If you have more, some probably belong as scene-local nodes or Resources instead.

**Common anti-patterns:**
- **God autoload**: One massive `GameManager` that does everything. Split it up.
- **Storing all game state in one autoload**: Use Resources or scene-local state for scene-specific data.
- **Autoloads calling each other in circles**: Keep the dependency direction clear (one-way, or use signals).

**Registering autoloads:** Project Settings → Autoload tab. Order matters — autoloads listed first are ready first.

---

## Collision Layers

Collision layers control which physics objects interact. Getting these right is critical — mistakes cause invisible bugs (objects that silently pass through each other).

### Always name your layers

Godot's collision layer checkboxes default to "Layer 1, Bit 0, value 1" — meaningless to a human. **Whenever adding or using collision layers**, immediately add named labels in `project.godot` under `[layer_names]`:

```ini
[layer_names]
3d_physics/layer_1="Ground"
3d_physics/layer_2="Player"
3d_physics/layer_3="Enemies"
3d_physics/layer_4="Projectiles"
```

For 2D projects, use `2d_physics/layer_1` etc. These names appear as tooltips in the editor inspector, making layer/mask assignment far less error-prone. Do this proactively — don't wait to be asked.

### Masking checklist: new layers affect more than you think

When adding a new collision layer, it's easy to only update the most obvious consumer and forget other entities that also need to interact with it.

**Rule: When adding a new collision layer, audit EVERY `collision_mask` in the project.**

1. Grep for every `collision_mask` and `collision_layer` assignment (both in scripts and `.tscn` files)
2. For each entity, ask: "Does this entity need to collide with the new layer?"
3. Don't stop at the first obvious fix — check player, enemies, projectiles, areas, triggers, and any other physics bodies

Common example: Adding a "Payload" layer for a special object. You update enemies to detect it, but forget that the player, allied minions, and area triggers also need the new mask bit. The result is objects silently passing through each other with no error message.
