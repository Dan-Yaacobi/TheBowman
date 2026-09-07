class_name PoisonDebuff extends Debuff

var poison_damage: int = 1

func start_debuff_effect() -> void:
	entity.modulate = Color(0.502, 0.82, 0.392)

func set_damage(_dmg: int) -> void:
	poison_damage = _dmg
	
func apply_debuff_effect() -> void:
	entity.take_damage(null, poison_damage)
	entity.show_damage(poison_damage,Color.GREEN)

func extra_end_debuff_methods() -> void:
	entity.modulate = Color(1.0, 1.0, 1.0)
