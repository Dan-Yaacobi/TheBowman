class_name StunDebuff extends Debuff

@onready var stunned_effect: CPUParticles2D = $StunnedEffect

func start_debuff_effect() -> void:
	one_shot = true
	apply_debuff_effect()
	
func apply_debuff_effect() -> void:
	enemy.stun(true)
	stunned_effect.emitting = true
	
func extra_end_debuff_methods() -> void:
	enemy.stun(false)
