# Patterns: Input Handling & Camera Systems

How the player interacts with the game and sees the world. Covers both 2D and 3D.

All examples target **Godot 4.6** with static typing.

---

## Input Handling

**When to use:** Every game. Use Godot's InputMap system — never hardcode key checks.

### 2D Movement
```gdscript
# Define actions in Project Settings → Input Map:
#   "move_left", "move_right", "move_up", "move_down"
#   "jump", "attack", "interact", "pause"

extends CharacterBody2D

@export var speed: float = 200.0

func _physics_process(_delta: float) -> void:
    var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
    velocity = direction * speed
    move_and_slide()

# For one-shot actions, use _unhandled_input to respect UI focus:
func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("jump"):
        _jump()
    if event.is_action_pressed("interact"):
        _interact()
```

### 3D First-Person Movement
```gdscript
extends CharacterBody3D

@export var speed: float = 5.0
@export var mouse_sensitivity: float = 0.002

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseMotion:
        rotate_y(-event.relative.x * mouse_sensitivity)
        $Camera3D.rotate_x(-event.relative.y * mouse_sensitivity)
        $Camera3D.rotation.x = clampf($Camera3D.rotation.x, -PI / 2.0, PI / 2.0)

func _physics_process(delta: float) -> void:
    var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
    velocity.x = direction.x * speed
    velocity.z = direction.z * speed
    velocity.y -= 9.8 * delta
    move_and_slide()
```

**Key rules:**
- Use `_unhandled_input` for gameplay (respects UI focus). Use `_input` only for UI or global hotkeys.
- Use `Input.get_vector()` for movement (handles diagonal normalization automatically).
- Use `is_action_pressed` / `is_action_just_pressed` — never check raw keycodes.
- Define all actions in InputMap — makes remapping trivial.

---

## Camera Systems

**When to use:** Almost every game. Choose based on dimension and genre.

### 2D Follow Camera

Godot's `Camera2D` has excellent built-in smoothing. Start with editor settings before writing code:

```
# In your Player.tscn, add a Camera2D child with:
#   Position Smoothing → Enabled = true
#   Position Smoothing → Speed = 5.0
#   Limit → Left/Right/Top/Bottom = your level bounds
#   Drag → Horizontal/Vertical Enabled = true (for deadzone)
```

For more control — a standalone script:
```gdscript
class_name FollowCamera2D extends Camera2D

@export var target: Node2D
@export var follow_speed: float = 5.0
@export var offset: Vector2 = Vector2.ZERO
@export var look_ahead: float = 50.0

func _process(delta: float) -> void:
    if not target:
        return
    var target_pos := target.global_position + offset
    if target is CharacterBody2D:
        target_pos += target.velocity.normalized() * look_ahead
    global_position = global_position.lerp(target_pos, follow_speed * delta)
```

### 3D Third-Person Camera
```gdscript
class_name ThirdPersonCamera extends Node3D
## Orbits around a target. Attach to the player scene as a child.

@export var target: Node3D
@export var distance: float = 5.0
@export var mouse_sensitivity: float = 0.003
@export var min_pitch: float = -80.0
@export var max_pitch: float = 60.0

var _yaw: float = 0.0
var _pitch: float = -20.0

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        _yaw -= event.relative.x * mouse_sensitivity
        _pitch -= event.relative.y * mouse_sensitivity
        _pitch = clampf(_pitch, deg_to_rad(min_pitch), deg_to_rad(max_pitch))

func _process(_delta: float) -> void:
    if not target:
        return
    var cam_offset := Vector3(0, 0, distance)
    var rotated := cam_offset.rotated(Vector3.RIGHT, _pitch).rotated(Vector3.UP, _yaw)
    global_position = target.global_position + rotated
    look_at(target.global_position)
```

**Common mistakes:**
- Camera jitter from updating in `_process` while target moves in `_physics_process` (match the update method, or use interpolation)
- Not clamping pitch (camera flips at poles)
- Hardcoding values that should be `@export` (every tuning value should be Inspector-editable)
