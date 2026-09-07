class_name BleedDebuff extends Debuff

@onready var bleed_effect: CPUParticles2D = $BleedEffect

var bleed_damage: int = 1

func set_damage(_dmg: int) -> void:
	bleed_damage = _dmg

func apply_debuff_effect() -> void:
	entity.take_damage(null, bleed_damage)
	entity.show_damage(bleed_damage,Color.DARK_RED)
