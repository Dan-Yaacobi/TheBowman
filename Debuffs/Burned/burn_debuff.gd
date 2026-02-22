class_name BurnDebuff extends Debuff

var fire_damage: int = 1

func set_damage(_dmg: int) -> void:
	fire_damage = _dmg
	
func apply_debuff_effect() -> void:
	enemy.take_damage(fire_damage)
	enemy.show_damage(fire_damage,Color.RED)
