class_name MagneticField
extends Area2D
## Applies radial attraction or repulsion to balls in range.

@export var strength: float = 200.0
@export var is_repulsive: bool = false

var _pulse_tween: Tween


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	_start_pulse()


func _physics_process(_delta: float) -> void:
	for body: Node2D in get_overlapping_bodies():
		if body is CascadeBall:
			var offset := global_position - body.global_position
			var distance := offset.length()
			if distance < 1.0:
				continue
			var direction := offset.normalized()
			if is_repulsive:
				direction = -direction
			var force := direction * strength / maxf(distance, 10.0)
			(body as CascadeBall).apply_central_force(force * 60.0)


func _start_pulse() -> void:
	_pulse_tween = create_tween().set_loops()
	_pulse_tween.tween_property(self, "modulate:a", 0.4, 0.8)
	_pulse_tween.tween_property(self, "modulate:a", 0.8, 0.8)
