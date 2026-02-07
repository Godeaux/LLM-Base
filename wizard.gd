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
	_add_summon_radius_indicator()


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


# --- Private methods ---
func _add_summon_radius_indicator() -> void:
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = summon_radius - 0.1
	torus.outer_radius = summon_radius
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.3, 1.0, 0.3, 0.3)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	torus.material = material
	ring.mesh = torus
	$Visual.add_child(ring)
