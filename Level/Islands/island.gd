class_name Island extends StaticBody2D

@export var start_island: bool = false
@export var floating: bool
var float_amplitude: float = 3.0
var float_speed: float = 2.0
var base_height: float

func _ready() -> void:
	base_height = global_position.y
	float_speed *= randf_range(0.5,1.5)
	float_amplitude *= randf_range(0.5,1.5)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if floating:
		global_position.y = base_height + sin(Time.get_ticks_msec() * 0.001 * float_speed) * float_amplitude

func disable() -> void:
	set_collision_layer_value(5,false)
	set_collision_mask_value(1,false)

func enable() -> void:
	set_collision_layer_value(5,true)
	set_collision_mask_value(1,true)
	pass
