class_name EnemyHitEffect extends CPUParticles2D

var initial_color: Color = Color("ba0000")

func _ready() -> void:
	set_effect_color(initial_color)

func set_effect_color(_color: Color) -> void:
	color_ramp.set_color(0,_color)
	color_ramp.set_color(1,_color)

func hit() -> void:
	emitting = true
