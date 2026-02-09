class_name TumbleBlock
extends RigidBody2D
## A physics block that stacks in the Tumble game mode.
## Configured by BlockData. Supports pooling via reset().

@export var data: BlockData

var _physics_material: PhysicsMaterial
var _clunk_sound: AudioStream
var _texture: Texture2D

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _collision: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	freeze = true
	contact_monitor = true
	max_contacts_reported = 4
	body_entered.connect(_on_body_entered)
	_clunk_sound = _generate_clunk_sound()
	_apply_data()


func _apply_data() -> void:
	if not data:
		return
	mass = data.mass
	_physics_material = PhysicsMaterial.new()
	_physics_material.friction = data.friction
	_physics_material.bounce = data.bounce
	physics_material_override = _physics_material
	linear_damp = data.linear_damp
	angular_damp = data.angular_damp
	continuous_cd = RigidBody2D.CCD_MODE_CAST_SHAPE

	var shape := _collision.shape as RectangleShape2D
	if shape:
		shape.size = data.size

	if not _texture:
		_texture = _create_block_texture()
	_sprite.texture = _texture
	_sprite.modulate = data.color
	_sprite.scale = data.size / Vector2(32.0, 32.0)


func deactivate() -> void:
	freeze = true


func reset() -> void:
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	rotation = 0.0
	_apply_data()


func activate() -> void:
	freeze = false


func _on_body_entered(body: Node) -> void:
	var speed := linear_velocity.length()
	if speed < 20.0:
		return
	var pitch := clampf(0.8 + (speed - 50.0) / 300.0, 0.6, 1.2)
	var volume := clampf(-25.0 + speed / 15.0, -30.0, -5.0)
	if _clunk_sound:
		AudioManager.play_sfx(_clunk_sound, volume, pitch)
	if body is StaticBody2D and speed > 50.0:
		VisualJuice.bounce(_sprite, 1.15, 0.15)


static func _create_block_texture() -> Texture2D:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	for x: int in 32:
		for y: int in 32:
			if x == 0 or x == 31 or y == 0 or y == 31:
				img.set_pixel(x, y, Color(0.8, 0.8, 0.8, 0.8))
			else:
				img.set_pixel(x, y, Color(1, 1, 1, 1))
	return ImageTexture.create_from_image(img)


static func _generate_clunk_sound() -> AudioStreamWAV:
	var sample_rate: int = 22050
	var duration: float = 0.12
	var samples: int = int(sample_rate * duration)
	var wav_data := PackedByteArray()
	wav_data.resize(samples * 2)
	for i: int in samples:
		var t: float = float(i) / sample_rate
		var envelope: float = exp(-t * 25.0)
		var wave: float = sin(t * TAU * 180.0) * envelope
		wave += sin(t * TAU * 90.0) * envelope * 0.5
		var sample_val: int = clampi(int(wave * 12000.0), -32768, 32767)
		wav_data[i * 2] = sample_val & 0xFF
		wav_data[i * 2 + 1] = (sample_val >> 8) & 0xFF
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = wav_data
	return stream
