class_name BleedDebuff extends Debuff

@onready var bleed_effect: CPUParticles2D = $BleedEffect

var bleed_damage: int = 1

func set_damage(_dmg: int) -> void:
	bleed_damage = _dmg

func apply_debuff_effect() -> void:
	enemy.take_damage(bleed_damage)
	enemy.show_damage(bleed_damage,Color.DARK_RED)
	pass
