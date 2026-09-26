class_name BleedDebuff extends Debuff

@onready var bleed_effect: CPUParticles2D = $BleedEffect

var bleed_damage: int

func set_damage(_dmg: int) -> void:
	bleed_damage = _dmg

func apply_debuff_effect() -> void:
	entity.take_damage(null, bleed_damage,null,Color.DARK_RED)
	if entity is Enemy:
		EventBus.dealt_bleed_damage.emit(bleed_damage)
