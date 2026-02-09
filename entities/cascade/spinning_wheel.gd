class_name SpinningWheel
extends AnimatableBody2D
## A rotating wheel that deflects balls with its paddles.

@export var rotation_speed: float = 2.0
@export var paddle_count: int = 4

var _hit_sound: AudioStream


func _ready() -> void:
	sync_to_physics = true
	_hit_sound = _generate_hit_sound()


func _physics_process(delta: float) -> void:
	rotate(rotation_speed * delta)


func on_ball_hit(ball: CascadeBall) -> void:
	var offset := ball.global_position - global_position
	var tangent := Vector2(-offset.y, offset.x).normalized()
	var spin_sign: float = signf(rotation_speed)
	var impulse_dir := (tangent * spin_sign + offset.normalized()) * 0.5
	ball.apply_central_impulse(impulse_dir.normalized() * 250.0)
	VisualJuice.bounce(self, 1.15, 0.15)
	if _hit_sound:
		AudioManager.play_sfx(_hit_sound, -10.0, randf_range(0.85, 1.15))


static func _generate_hit_sound() -> AudioStreamWAV:
	var sample_rate: int = 22050
	var duration: float = 0.1
	var samples: int = int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(samples * 2)
	for i: int in samples:
		var t: float = float(i) / sample_rate
		var envelope: float = exp(-t * 30.0)
		var wave: float = sin(t * TAU * 300.0) * envelope
		var sample_val: int = clampi(int(wave * 12000.0), -32768, 32767)
		data[i * 2] = sample_val & 0xFF
		data[i * 2 + 1] = (sample_val >> 8) & 0xFF
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	return stream
