# Game Development Patterns

Reference implementations for common patterns. These aren't templates to copy verbatim — they're canonical examples that demonstrate correct structure. Adapt to your specific needs.

---

## Finite State Machine (FSM)

**When to use:** Player states (idle, running, jumping), enemy AI, UI screens, game phases. Any time an entity can be in exactly one state at a time.

### TypeScript

```typescript
type PlayerState = "idle" | "running" | "jumping" | "falling";

interface StateHandlers<S extends string> {
  enter?: () => void;
  update?: (dt: number) => void;
  exit?: () => void;
}

function createFSM<S extends string>(
  initialState: S,
  states: Record<S, StateHandlers<S>>
) {
  let current: S = initialState;
  states[current].enter?.();

  return {
    get state() { return current; },

    transition(next: S) {
      if (next === current) return;
      states[current].exit?.();
      current = next;
      states[current].enter?.();
    },

    update(dt: number) {
      states[current].update?.(dt);
    },
  };
}

// Usage
const playerFSM = createFSM<PlayerState>("idle", {
  idle: {
    enter: () => console.log("Now idle"),
    update: (dt) => { /* check for input */ },
  },
  running: {
    update: (dt) => { /* apply movement */ },
  },
  jumping: {
    enter: () => { /* apply jump force */ },
    update: (dt) => { /* check if landed */ },
  },
  falling: {
    update: (dt) => { /* check if landed */ },
  },
});
```

### GDScript

```gdscript
class_name StateMachine extends Node

var current_state: String
var states: Dictionary = {}

func _ready() -> void:
    # Override in subclass to define states
    pass

func add_state(name: String, handlers: Dictionary) -> void:
    states[name] = handlers

func transition(next_state: String) -> void:
    if next_state == current_state:
        return
    if current_state and states[current_state].has("exit"):
        states[current_state].exit.call()
    current_state = next_state
    if states[current_state].has("enter"):
        states[current_state].enter.call()

func _process(delta: float) -> void:
    if current_state and states[current_state].has("update"):
        states[current_state].update.call(delta)
```

**Common mistakes:**
- Forgetting to call exit/enter on transitions
- Allowing invalid state transitions (add validation if needed)
- Putting too much logic in states (keep them thin, delegate to systems)

---

## Event Bus / Signals

**When to use:** Decoupled communication between systems. UI reacting to game events. Achievements, analytics, audio triggers. Anywhere you'd otherwise pass callbacks through multiple layers.

### TypeScript

```typescript
type EventMap = {
  "player:damaged": { amount: number; source: string };
  "enemy:killed": { enemyId: string; position: { x: number; y: number } };
  "game:paused": undefined;
  "game:resumed": undefined;
};

function createEventBus<T extends Record<string, unknown>>() {
  const listeners = new Map<keyof T, Set<(data: unknown) => void>>();

  return {
    on<K extends keyof T>(event: K, callback: (data: T[K]) => void) {
      if (!listeners.has(event)) listeners.set(event, new Set());
      listeners.get(event)!.add(callback as (data: unknown) => void);

      // Return unsubscribe function
      return () => listeners.get(event)?.delete(callback as (data: unknown) => void);
    },

    emit<K extends keyof T>(event: K, data: T[K]) {
      listeners.get(event)?.forEach((cb) => cb(data));
    },

    clear() {
      listeners.clear();
    },
  };
}

// Usage
const events = createEventBus<EventMap>();

const unsubscribe = events.on("player:damaged", ({ amount, source }) => {
  console.log(`Took ${amount} damage from ${source}`);
});

events.emit("player:damaged", { amount: 10, source: "spike" });
unsubscribe(); // Clean up when done
```

### GDScript

```gdscript
# Autoload: EventBus.gd
extends Node

# Define signals
signal player_damaged(amount: int, source: String)
signal enemy_killed(enemy_id: String, position: Vector2)
signal game_paused
signal game_resumed

# Convenience methods (optional)
func emit_player_damaged(amount: int, source: String) -> void:
    player_damaged.emit(amount, source)

func emit_enemy_killed(enemy_id: String, position: Vector2) -> void:
    enemy_killed.emit(enemy_id, position)
```

```gdscript
# In any script that needs to listen:
func _ready() -> void:
    EventBus.player_damaged.connect(_on_player_damaged)

func _on_player_damaged(amount: int, source: String) -> void:
    print("Took %d damage from %s" % [amount, source])
```

**Common mistakes:**
- Forgetting to unsubscribe (causes memory leaks, stale references)
- Emitting events during iteration (use deferred emit if needed)
- Overusing events for everything (direct calls are fine for tightly coupled systems)

---

## Save/Load Serialization

**When to use:** Every game that needs to persist state. Start simple, add versioning when you ship.

### TypeScript

```typescript
interface SaveData {
  version: number;
  player: {
    position: { x: number; y: number };
    health: number;
    inventory: string[];
  };
  world: {
    unlockedAreas: string[];
    defeatedBosses: string[];
  };
  timestamp: number;
}

const SAVE_KEY = "game_save";
const CURRENT_VERSION = 1;

function save(data: Omit<SaveData, "version" | "timestamp">): void {
  const saveData: SaveData = {
    ...data,
    version: CURRENT_VERSION,
    timestamp: Date.now(),
  };
  localStorage.setItem(SAVE_KEY, JSON.stringify(saveData));
}

function load(): SaveData | null {
  const raw = localStorage.getItem(SAVE_KEY);
  if (!raw) return null;

  try {
    const data = JSON.parse(raw) as SaveData;
    return migrate(data);
  } catch {
    console.error("Failed to load save");
    return null;
  }
}

function migrate(data: SaveData): SaveData {
  // Handle version migrations
  if (data.version < CURRENT_VERSION) {
    // Transform old data to new format
    // data = migrateV0toV1(data);
  }
  return data;
}

function deleteSave(): void {
  localStorage.removeItem(SAVE_KEY);
}
```

### GDScript

```gdscript
class_name SaveManager extends Node

const SAVE_PATH := "user://save.json"
const CURRENT_VERSION := 1

static func save(data: Dictionary) -> void:
    data["version"] = CURRENT_VERSION
    data["timestamp"] = Time.get_unix_time_from_system()

    var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if file:
        file.store_string(JSON.stringify(data))
        file.close()

static func load() -> Dictionary:
    if not FileAccess.file_exists(SAVE_PATH):
        return {}

    var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
    if not file:
        return {}

    var content := file.get_as_text()
    file.close()

    var data = JSON.parse_string(content)
    if data is Dictionary:
        return _migrate(data)
    return {}

static func _migrate(data: Dictionary) -> Dictionary:
    # Handle version migrations here
    return data

static func delete_save() -> void:
    if FileAccess.file_exists(SAVE_PATH):
        DirAccess.remove_absolute(SAVE_PATH)
```

**Common mistakes:**
- Not versioning saves from day one (makes migration painful)
- Saving non-serializable data (functions, circular references)
- Saving too frequently (batch or debounce)
- Not handling corrupted saves gracefully

---

## Object Pool

**When to use:** Frequently spawned/destroyed objects — bullets, particles, enemies. Reduces garbage collection pressure and allocation overhead.

### TypeScript

```typescript
interface Poolable {
  active: boolean;
  reset(): void;
}

function createPool<T extends Poolable>(
  factory: () => T,
  initialSize: number = 10
) {
  const pool: T[] = Array.from({ length: initialSize }, factory);

  return {
    acquire(): T {
      let obj = pool.find((o) => !o.active);
      if (!obj) {
        obj = factory();
        pool.push(obj);
      }
      obj.active = true;
      obj.reset();
      return obj;
    },

    release(obj: T) {
      obj.active = false;
    },

    get activeCount() {
      return pool.filter((o) => o.active).length;
    },

    get totalSize() {
      return pool.length;
    },
  };
}

// Usage
interface Bullet extends Poolable {
  x: number;
  y: number;
  vx: number;
  vy: number;
}

const bulletPool = createPool<Bullet>(() => ({
  active: false,
  x: 0, y: 0, vx: 0, vy: 0,
  reset() {
    this.x = 0; this.y = 0;
    this.vx = 0; this.vy = 0;
  },
}));

const bullet = bulletPool.acquire();
bullet.x = playerX;
bullet.y = playerY;
bullet.vx = 10;
// When bullet is done:
bulletPool.release(bullet);
```

### GDScript

```gdscript
class_name ObjectPool extends Node

var _scene: PackedScene
var _pool: Array[Node] = []
var _active: Array[Node] = []

func _init(scene: PackedScene, initial_size: int = 10) -> void:
    _scene = scene
    for i in initial_size:
        var obj := _scene.instantiate()
        obj.set_process(false)
        obj.hide()
        _pool.append(obj)

func acquire() -> Node:
    var obj: Node
    if _pool.is_empty():
        obj = _scene.instantiate()
    else:
        obj = _pool.pop_back()

    obj.set_process(true)
    obj.show()
    _active.append(obj)

    if obj.has_method("reset"):
        obj.reset()

    return obj

func release(obj: Node) -> void:
    if obj in _active:
        _active.erase(obj)
        obj.set_process(false)
        obj.hide()
        _pool.append(obj)

func get_active_count() -> int:
    return _active.size()
```

**Common mistakes:**
- Forgetting to reset state when reusing objects
- Not releasing objects back to pool
- Pre-allocating too many objects (start small, grow as needed)
- Using pools for objects that rarely spawn (overhead not worth it)

---

## Fixed vs Variable Timestep

**When to use:** Fixed timestep for physics, AI, gameplay logic. Variable timestep for rendering, visual interpolation.

### TypeScript

```typescript
// Game loop with fixed timestep for logic, variable for rendering
const FIXED_DT = 1 / 60; // 60 updates per second
let accumulator = 0;
let lastTime = performance.now();

function gameLoop(currentTime: number) {
  const frameTime = (currentTime - lastTime) / 1000;
  lastTime = currentTime;

  // Cap frame time to avoid spiral of death
  accumulator += Math.min(frameTime, 0.25);

  // Fixed timestep updates
  while (accumulator >= FIXED_DT) {
    fixedUpdate(FIXED_DT);
    accumulator -= FIXED_DT;
  }

  // Variable timestep render with interpolation alpha
  const alpha = accumulator / FIXED_DT;
  render(alpha);

  requestAnimationFrame(gameLoop);
}

function fixedUpdate(dt: number) {
  // Physics, gameplay logic — always same dt
  updatePhysics(dt);
  updateAI(dt);
  updateGameLogic(dt);
}

function render(alpha: number) {
  // Interpolate positions for smooth rendering
  // alpha is 0..1 representing progress to next fixed update
  renderWorld(alpha);
}
```

### GDScript

```gdscript
# Godot handles this automatically:
# _physics_process(delta) = fixed timestep (default 60/sec)
# _process(delta) = variable timestep (every frame)

extends Node

func _physics_process(delta: float) -> void:
    # Physics, gameplay logic — consistent dt
    update_physics(delta)
    update_ai(delta)

func _process(delta: float) -> void:
    # Rendering, visual effects — variable dt
    update_visuals(delta)
```

**Common mistakes:**
- Using variable timestep for physics (causes inconsistent behavior)
- Not capping frame time (causes "spiral of death" on slow frames)
- Forgetting interpolation (causes visual stuttering at low framerates)

---

## Component Pattern

**When to use:** When entities need flexible, composable behaviors. Alternative to deep inheritance hierarchies.

### TypeScript

```typescript
interface Component {
  update?(dt: number): void;
  render?(): void;
}

interface Entity {
  id: string;
  components: Map<string, Component>;

  add<T extends Component>(name: string, component: T): T;
  get<T extends Component>(name: string): T | undefined;
  remove(name: string): void;
}

function createEntity(id: string): Entity {
  const components = new Map<string, Component>();

  return {
    id,
    components,

    add<T extends Component>(name: string, component: T): T {
      components.set(name, component);
      return component;
    },

    get<T extends Component>(name: string): T | undefined {
      return components.get(name) as T | undefined;
    },

    remove(name: string) {
      components.delete(name);
    },
  };
}

// Usage
const player = createEntity("player");

player.add("position", { x: 0, y: 0 });
player.add("velocity", { x: 0, y: 0 });
player.add("health", {
  current: 100,
  max: 100,
  damage(amount: number) { this.current = Math.max(0, this.current - amount); }
});
player.add("sprite", {
  texture: "player.png",
  render() { /* draw sprite */ }
});

// Systems operate on entities with specific components
function movementSystem(entities: Entity[], dt: number) {
  for (const entity of entities) {
    const pos = entity.get<{ x: number; y: number }>("position");
    const vel = entity.get<{ x: number; y: number }>("velocity");
    if (pos && vel) {
      pos.x += vel.x * dt;
      pos.y += vel.y * dt;
    }
  }
}
```

### GDScript

```gdscript
# Godot's node system IS the component pattern
# Compose behaviors by adding child nodes

# Player.tscn structure:
# - Player (CharacterBody2D)
#   - HealthComponent
#   - MovementComponent
#   - WeaponComponent
#   - Sprite2D

# HealthComponent.gd
class_name HealthComponent extends Node

@export var max_health: int = 100
var current_health: int

func _ready() -> void:
    current_health = max_health

func damage(amount: int) -> void:
    current_health = max(0, current_health - amount)
    if current_health == 0:
        get_parent().queue_free()  # Or emit signal

# In Player.gd, access components:
func _ready() -> void:
    var health := $HealthComponent as HealthComponent
    health.damage(10)
```

**Common mistakes:**
- Over-engineering for small games (inheritance is fine for simple cases)
- Components that know too much about each other (use events/signals)
- Creating components that are too granular (balance flexibility vs simplicity)

---

## Command Pattern

**When to use:** Input handling, undo/redo, replays, AI action queues, networked actions.

### TypeScript

```typescript
interface Command {
  execute(): void;
  undo?(): void;
}

// Input commands
const createMoveCommand = (entity: Entity, dx: number, dy: number): Command => ({
  execute() {
    entity.x += dx;
    entity.y += dy;
  },
  undo() {
    entity.x -= dx;
    entity.y -= dy;
  },
});

// Command history for undo/redo
function createCommandHistory() {
  const history: Command[] = [];
  let index = -1;

  return {
    execute(command: Command) {
      // Remove any undone commands
      history.splice(index + 1);
      command.execute();
      history.push(command);
      index++;
    },

    undo() {
      if (index >= 0) {
        history[index].undo?.();
        index--;
      }
    },

    redo() {
      if (index < history.length - 1) {
        index++;
        history[index].execute();
      }
    },
  };
}

// Input mapping
const inputMap: Record<string, () => Command> = {
  ArrowUp: () => createMoveCommand(player, 0, -1),
  ArrowDown: () => createMoveCommand(player, 0, 1),
  ArrowLeft: () => createMoveCommand(player, -1, 0),
  ArrowRight: () => createMoveCommand(player, 1, 0),
};

document.addEventListener("keydown", (e) => {
  const commandFactory = inputMap[e.key];
  if (commandFactory) {
    const command = commandFactory();
    commandHistory.execute(command);
  }
});
```

### GDScript

```gdscript
class_name Command extends RefCounted

func execute() -> void:
    pass

func undo() -> void:
    pass

# MoveCommand.gd
class_name MoveCommand extends Command

var _entity: Node2D
var _delta: Vector2

func _init(entity: Node2D, delta: Vector2) -> void:
    _entity = entity
    _delta = delta

func execute() -> void:
    _entity.position += _delta

func undo() -> void:
    _entity.position -= _delta

# CommandHistory.gd
class_name CommandHistory extends RefCounted

var _history: Array[Command] = []
var _index: int = -1

func execute(command: Command) -> void:
    _history.resize(_index + 1)
    command.execute()
    _history.append(command)
    _index += 1

func undo() -> void:
    if _index >= 0:
        _history[_index].undo()
        _index -= 1

func redo() -> void:
    if _index < _history.size() - 1:
        _index += 1
        _history[_index].execute()
```

**Common mistakes:**
- Commands that capture mutable state by reference (capture values, not references)
- Not all commands are undoable (that's fine, mark them clearly)
- Storing too much history (cap it or clear periodically)
