# Patterns: State Machines, Scene Flow & Coroutines

How to manage game states, transition between scenes, and sequence events over time.

All examples target **Godot 4.6** with static typing.

---

## Finite State Machine (Node-Based)

**When to use:** Player states (idle, running, jumping), enemy AI, UI screens, game phases. Any time an entity can be in exactly one state at a time.

Godot's idiomatic FSM uses individual State nodes as children of a StateMachine node — leveraging the scene tree and the Inspector.

```
# Scene tree layout:
# Player (CharacterBody2D)
#   ├── StateMachine
#   │   ├── IdleState
#   │   ├── RunState
#   │   └── JumpState
#   ├── Sprite2D
#   └── CollisionShape2D
```

```gdscript
# state.gd — Base class. Each state is its own node and script.
class_name State extends Node

## Called when this state becomes active.
func enter() -> void:
    pass

## Called when leaving this state.
func exit() -> void:
    pass

## Called every frame while active (maps to _process).
func update(_delta: float) -> void:
    pass

## Called every physics tick while active (maps to _physics_process).
func physics_update(_delta: float) -> void:
    pass

## Called for unhandled input while active.
func handle_input(_event: InputEvent) -> void:
    pass
```

```gdscript
# state_machine.gd — Manages child State nodes.
class_name StateMachine extends Node

## Assign the starting state in the Inspector (drag a child State here).
@export var initial_state: State

var current_state: State

func _ready() -> void:
    await owner.ready  # Wait for the owning scene to be ready
    if initial_state:
        initial_state.enter()
        current_state = initial_state

func _process(delta: float) -> void:
    if current_state:
        current_state.update(delta)

func _physics_process(delta: float) -> void:
    if current_state:
        current_state.physics_update(delta)

func _unhandled_input(event: InputEvent) -> void:
    if current_state:
        current_state.handle_input(event)

func transition_to(target_state: State) -> void:
    if not target_state or target_state == current_state:
        return
    current_state.exit()
    target_state.enter()
    current_state = target_state
```

```gdscript
# player_idle_state.gd — Example concrete state.
class_name PlayerIdleState extends State

@onready var player: CharacterBody2D = owner as CharacterBody2D
@onready var fsm: StateMachine = get_parent() as StateMachine

func enter() -> void:
    player.velocity = Vector2.ZERO

func update(_delta: float) -> void:
    var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
    if input != Vector2.ZERO:
        fsm.transition_to($"../RunState")

func handle_input(event: InputEvent) -> void:
    if event.is_action_pressed("jump"):
        fsm.transition_to($"../JumpState")
```

**Why nodes:** States are visible in the Inspector, reorderable, and can hold child nodes (timers, particles, audio). The `@export var initial_state` lets you change the starting state without touching code.

**Common mistakes:**
- Putting too much logic in states (states decide WHEN to act; delegate HOW to the entity)
- Forgetting `await owner.ready` in the state machine (states can't access siblings during `_ready`)
- Creating states for things that aren't mutually exclusive (use flags instead)

---

## Scene Transition Manager

**When to use:** Any game with multiple scenes (levels, menus, game over). Manages loading, transitions, and state preservation.

```gdscript
# Autoload: SceneManager.gd
extends Node

signal scene_changed(scene_path: String)

var _current_scene_path: String = ""
var _is_transitioning: bool = false

func change_scene(path: String, fade: bool = true) -> void:
    if _is_transitioning:
        return  # Guard against double-taps
    _is_transitioning = true

    if fade:
        await _fade_out()

    get_tree().change_scene_to_file(path)
    _current_scene_path = path

    # Scene change is deferred — wait one frame for it to take effect
    await get_tree().process_frame

    if fade:
        await _fade_in()

    _is_transitioning = false
    scene_changed.emit(path)

func reload_current() -> void:
    if _current_scene_path:
        change_scene(_current_scene_path)

func _fade_out() -> void:
    var tween := create_tween()
    tween.tween_interval(0.3)  # Replace with your transition effect
    await tween.finished

func _fade_in() -> void:
    var tween := create_tween()
    tween.tween_interval(0.3)
    await tween.finished
```

**Common mistakes:**
- Not guarding against double-taps (calling `change_scene` while already transitioning)
- Losing state between scenes (use autoloads or Resources to persist cross-scene data)
- Blocking with heavy scene loading (use `ResourceLoader.load_threaded_request` for large scenes)

---

## Fixed vs Variable Timestep

**When to use:** Fixed for physics/gameplay logic. Variable for rendering/visuals.

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
- Using `_process` for physics (causes inconsistent behavior at varying framerates)
- Forgetting interpolation between physics steps (causes visual stuttering)

---

## Await / Coroutine Patterns

**When to use:** Sequencing gameplay events, cutscenes, timed effects — anything "do X, wait, then do Y" without a state machine.

```gdscript
# Wait for a duration
func spawn_wave() -> void:
    for i: int in 5:
        spawn_enemy()
        await get_tree().create_timer(0.5).timeout

# Wait for a signal
func open_door() -> void:
    $AnimationPlayer.play("door_open")
    await $AnimationPlayer.animation_finished
    $CollisionShape2D.set_deferred("disabled", true)

# Wait for a tween
func dramatic_entrance(node: Node2D) -> void:
    node.modulate.a = 0.0
    var tween := create_tween()
    tween.tween_property(node, "modulate:a", 1.0, 1.0)
    await tween.finished

# Combining awaits for a sequence
func intro_sequence() -> void:
    await dramatic_entrance($Player)
    $DialogueBox.show_text("Welcome, hero.")
    await $DialogueBox.dialogue_finished
```

**Common mistakes:**
- Awaiting a signal that never fires (coroutine hangs forever — add timeouts)
- Modifying node state after the node was freed during the await (check `is_instance_valid()`)
- Using await for per-frame logic (use `_process` instead — await is for event sequences)
