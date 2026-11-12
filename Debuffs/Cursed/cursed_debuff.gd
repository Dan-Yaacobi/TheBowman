class_name CursedDebuff extends Debuff

## Extra damage the cursed enemy takes (0.5 = +50%). Cursed Skulls scales it by its color bonus.
var damage_taken_bonus: float = 0.5

func start_debuff_effect() -> void:
	if entity is Enemy:
		entity.modulate = Color("a86fffff")
		one_shot = true
		entity.set_damage_dealt_multiplier(1.0,Stat.buff_type.MULTIPLICATIVE)
		entity.set_damage_taken_multiplier(damage_taken_bonus,Stat.buff_type.MULTIPLICATIVE)
		
func extra_end_debuff_methods() -> void:
	entity.modulate = Color(1.0, 1.0, 1.0)
	entity.remove_damage_dealt_multiplier(1.0,Stat.buff_type.MULTIPLICATIVE)
	entity.remove_damage_taken_multiplier(damage_taken_bonus,Stat.buff_type.MULTIPLICATIVE)
