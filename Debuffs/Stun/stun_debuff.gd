class_name StunDebuff extends Debuff

@onready var stunned_effect: CPUParticles2D = $StunnedEffect

func apply_debuff_effect() -> void:
	enemy.stunned_state = true
	stunned_effect.emitting = true
	
func extra_end_debuff_methods() -> void:
	enemy.stunned_state = false
