class_name MachineElement
extends StaticBody2D
## Base class for static machine elements (pegs, bumpers, ramps, trampolines).
## Differentiated by collision shape, physics material, and hit response.

@export var element_type: String = "peg"

var _bumper_sound: AudioStream
var _trampoline_sound: AudioStream


func _ready() -> void:
	if element_type == "bumper":
		_bumper_sound = _generate_bumper_sound()
	elif element_type == "trampoline":
		_trampoline_sound = _generate_trampoline_sound()


func on_ball_hit(ball: CascadeBall) -> void:
	match element_type:
		"bumper":
			_bumper_hit(ball)
		"trampoline":
			_trampoline_hit(ball)
		_:
			VisualJuice.bounce(self, 1.15, 0.15)


func _bumper_hit(ball: CascadeBall) -> void:
	var direction := (ball.global_position - global_position).normalized()
	ball.apply_central_impulse(direction * 300.0)
	VisualJuice.bounce(self, 1.3, 0.2)
	if _bumper_sound:
		AudioManager.play_sfx(_bumper_sound, -8.0, randf_range(0.9, 1.1))


func _trampoline_hit(ball: CascadeBall) -> void:
	ball.apply_central_impulse(Vector2.UP * 400.0)
	VisualJuice.bounce(self, 1.4, 0.25)
	if _trampoline_sound:
		AudioManager.play_sfx(_trampoline_sound, -6.0, randf_range(0.9, 1.1))


static func _generate_bumper_sound() -> AudioStreamWAV:
	var sample_rate: int = 22050
	var duration: float = 0.12
	var samples: int = int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(samples * 2)
	for i: int in samples:
		var t: float = float(i) / sample_rate
		var envelope: float = exp(-t * 25.0)
		var vibrato: float = sin(t * TAU * 30.0) * 0.3
		var wave: float = sin(t * TAU * 600.0 * (1.0 + vibrato)) * envelope
		var sample_val: int = clampi(int(wave * 14000.0), -32768, 32767)
		data[i * 2] = sample_val & 0xFF
		data[i * 2 + 1] = (sample_val >> 8) & 0xFF
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	return stream


static func _generate_trampoline_sound() -> AudioStreamWAV:
	var sample_rate: int = 22050
	var duration: float = 0.15
	var samples: int = int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(samples * 2)
	for i: int in samples:
		var t: float = float(i) / sample_rate
		var envelope: float = exp(-t * 20.0)
		var freq: float = lerpf(400.0, 800.0, t / duration)
		var wave: float = sin(t * TAU * freq) * envelope
		var sample_val: int = clampi(int(wave * 14000.0), -32768, 32767)
		data[i * 2] = sample_val & 0xFF
		data[i * 2 + 1] = (sample_val >> 8) & 0xFF
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	return stream
