class_name Wizard
extends CharacterBody3D
## Player-controlled wizard that summons and commands minions.


# --- Constants ---
const ROTATION_OFFSET: float = -PI / 4.0
const GRAVITY: float = 9.8

# --- Exports ---
@export var speed: float = 6.0
@export var summon_radius: float = 4.0


# --- Built-in virtual methods ---
func _ready() -> void:
	add_to_group("wizard")


func _physics_process(delta: float) -> void:
	var raw_input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var rotated := raw_input.rotated(ROTATION_OFFSET)
	velocity.x = rotated.x * speed
	velocity.z = rotated.y * speed
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0.0
	move_and_slide()
