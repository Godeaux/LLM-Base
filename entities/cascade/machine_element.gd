class_name MachineElement
extends StaticBody2D
## Base class for static machine elements (pegs, bumpers, ramps, trampolines).
## Differentiated by collision shape and physics material.

@export var element_type: String = "peg"


func on_ball_hit(_ball: CascadeBall) -> void:
	VisualJuice.bounce(self, 1.15, 0.15)
