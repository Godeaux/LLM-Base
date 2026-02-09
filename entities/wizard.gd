class_name Wizard
extends CharacterBody3D
## Player-controlled wizard that summons and commands minions.


# --- Constants ---
const ROTATION_OFFSET: float = -PI / 4.0
const GRAVITY: float = 9.8
const FLOAT_MAX_HEIGHT: float = 2.0
const FLOAT_RISE_SPEED: float = 2.0
const KILL_FLOOR_Y: float = -5.0

# --- Exports ---
@export var speed: float = 6.0
@export var summon_radius: float = 4.0

# --- Private variables ---
var _float_height: float = 0.0


# --- Built-in virtual methods ---
func _ready() -> void:
	add_to_group("wizard")
	collision_mask = 9  # Ground (1) + Payload (8)
	_add_summon_radius_indicator()


func _physics_process(delta: float) -> void:
	var raw_input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var rotated := raw_input.rotated(ROTATION_OFFSET)
	velocity.x = rotated.x * speed
	velocity.z = rotated.y * speed

	var wants_float := Input.is_action_pressed("float")
	if wants_float:
		if _float_height < FLOAT_MAX_HEIGHT:
			_float_height = minf(_float_height + FLOAT_RISE_SPEED * delta, FLOAT_MAX_HEIGHT)
			velocity.y = FLOAT_RISE_SPEED
		else:
			velocity.y = 0.0
	else:
		if _float_height > 0.0:
			velocity.y -= GRAVITY * delta
			_float_height = maxf(_float_height + velocity.y * delta, 0.0)
			if _float_height <= 0.0:
				_float_height = 0.0
				velocity.y = 0.0
		elif not is_on_floor():
			velocity.y -= GRAVITY * delta
		else:
			velocity.y = 0.0
	move_and_slide()

	if global_position.y < KILL_FLOOR_Y:
		_respawn_at_horse()


# --- Private methods ---
func _respawn_at_horse() -> void:
	var horse := get_tree().get_first_node_in_group("trojan_horse") as Node3D
	if horse:
		global_position = horse.global_position + Vector3(0.0, 1.0, 0.0)
	else:
		global_position.y = 1.0
	velocity = Vector3.ZERO
	_float_height = 0.0


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
