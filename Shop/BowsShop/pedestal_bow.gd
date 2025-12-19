extends Node2D

var float_amplitude: float = 3.0
var float_speed: float = 2.0
var base_height: float

func _ready() -> void:
	base_height = global_position.y


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	global_position.y = base_height + sin(Time.get_ticks_msec() * 0.001 * float_speed) * float_amplitude
