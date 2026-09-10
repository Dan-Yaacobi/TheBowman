class_name FrostBiteDebuff extends Debuff

@onready var frostbite_effect: CPUParticles2D = $FrostbiteEffect

var slow_multiplier: float = 0.5

func set_slow_strength(_amount: float = 0.5) -> void:
	slow_multiplier = _amount

func start_debuff_effect() -> void:
	one_shot = true
	frostbite_effect.emitting = true
	apply_debuff_effect()
	
func apply_debuff_effect() -> void:
	var entity_speed: Stat = entity.stats.move_speed
	entity_speed.add_buff(ID,-slow_multiplier,Stat.buff_type.MULTIPLICATIVE)
	
func extra_end_debuff_methods() -> void:
	var entity_speed: Stat = entity.stats.move_speed
	entity_speed.remove_buff_stack(ID,Stat.buff_type.MULTIPLICATIVE)
