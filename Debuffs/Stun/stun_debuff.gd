class_name StunDebuff extends Debuff

@onready var stunned_effect: CPUParticles2D = $StunnedEffect

func start_debuff_effect() -> void:
	apply_debuff_effect()
	
func apply_debuff_effect() -> void:
	
	enemy.alter_moving(true)
	stunned_effect.emitting = true
	
func extra_end_debuff_methods() -> void:
	enemy.alter_moving(false)
