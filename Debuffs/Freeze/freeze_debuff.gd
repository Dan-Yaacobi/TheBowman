class_name FreezeDebuff extends Debuff

func start_debuff_effect() -> void:
	one_shot = true
	apply_debuff_effect()
	
func apply_debuff_effect() -> void:
	entity.stun()
	
func extra_end_debuff_methods() -> void:
	entity.end_stun()
