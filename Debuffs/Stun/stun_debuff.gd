class_name StunDebuff extends Debuff

@onready var stun_arrow_effect: CPUParticles2D = $StunArrowEffect
@onready var stunned_effect: CPUParticles2D = $StunnedEffect

var temp_enemy_speed: int

func apply_debuff_effect() -> void:
	temp_enemy_speed = enemy.stats.move_speed
	enemy.stats.move_speed = 0
	enemy.stunned_state = true
	stun_arrow_effect.emitting = true
	stunned_effect.emitting = true
	
func extra_end_debuff_methods() -> void:
	enemy.stats.move_speed = temp_enemy_speed
	enemy.stunned_state = false
