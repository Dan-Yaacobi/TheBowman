class_name WeaknessDebuff extends Debuff

func start_debuff_effect() -> void:
	if entity is Enemy:
		entity.modulate = Color("54009aff")
		one_shot = true
		entity.set_damage_dealt_multiplier(-0.5,Stat.buff_type.MULTIPLICATIVE)
		entity.set_damage_taken_multiplier(0.5,Stat.buff_type.MULTIPLICATIVE)

func extra_end_debuff_methods() -> void:
	entity.modulate = Color(1.0, 1.0, 1.0)
	entity.set_damage_dealt_multiplier(0.5,Stat.buff_type.MULTIPLICATIVE)
	entity.set_damage_taken_multiplier(-0.5,Stat.buff_type.MULTIPLICATIVE)
