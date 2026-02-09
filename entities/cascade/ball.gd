class_name CascadeBall
extends RigidBody2D
## A physics ball that cascades through the marble machine.
## Configured by BallData. Supports pooling via reset().

signal collected(score: int)

@export var data: BallData

var _physics_material: PhysicsMaterial
var _plink_sound: AudioStream
var _texture: Texture2D

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _collision: CollisionShape2D = $CollisionShape2D
@onready var _trail: TrailRenderer = $TrailRenderer
@onready var _stuck_detector: StuckDetector = $StuckDetector


func _ready() -> void:
	contact_monitor = true
	max_contacts_reported = 4
	body_entered.connect(_on_body_entered)
	_stuck_detector.stuck.connect(_on_stuck)
	_plink_sound = _generate_plink_sound()
	_apply_data()


func _apply_data() -> void:
	if not data:
		return
	mass = data.mass
	_physics_material = PhysicsMaterial.new()
	_physics_material.bounce = data.bounce
	physics_material_override = _physics_material

	var shape := _collision.shape as CircleShape2D
	if shape:
		shape.radius = data.radius

	if not _texture:
		_texture = _create_ball_texture()
	_sprite.texture = _texture
	_sprite.modulate = data.color
	_sprite.scale = Vector2.ONE * (data.radius / 16.0)

	_trail.default_color = data.trail_color


func reset() -> void:
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	_trail.reset()
	_stuck_detector.reset()
	_apply_data()


func _on_body_entered(body: Node) -> void:
	var speed := linear_velocity.length()
	var pitch := clampf(1.0 + (speed - 100.0) / 400.0, 0.8, 1.4)
	var volume := clampf(-20.0 + speed / 20.0, -30.0, 0.0)

	if body.has_method("on_ball_hit"):
		body.on_ball_hit(self)

	if speed > 30.0 and _plink_sound:
		AudioManager.play_sfx(_plink_sound, volume, pitch)


func _on_stuck() -> void:
	EventBus.ball_stuck.emit(self)


static func _create_ball_texture() -> Texture2D:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var center := Vector2(16, 16)
	for x: int in 32:
		for y: int in 32:
			var dist := Vector2(x, y).distance_to(center)
			if dist <= 15.0:
				var alpha: float = clampf(16.0 - dist, 0.0, 1.0)
				img.set_pixel(x, y, Color(1, 1, 1, alpha))
	return ImageTexture.create_from_image(img)


static func _generate_plink_sound() -> AudioStreamWAV:
	var sample_rate: int = 22050
	var duration: float = 0.08
	var samples: int = int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(samples * 2)
	for i: int in samples:
		var t: float = float(i) / sample_rate
		var envelope: float = exp(-t * 40.0)
		var wave: float = sin(t * TAU * 2200.0) * envelope
		var sample_val: int = clampi(int(wave * 16000.0), -32768, 32767)
		data[i * 2] = sample_val & 0xFF
		data[i * 2 + 1] = (sample_val >> 8) & 0xFF
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	return stream
