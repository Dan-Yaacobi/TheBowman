class_name BleedDebuff extends Debuff

@onready var bleed_effect: CPUParticles2D = $BleedEffect
@export var max_stacks: int = 5

var stacks: int = 1
var bleed_damage: int

func set_damage(_dmg: int) -> void:
	bleed_damage = _dmg

func apply_debuff_effect() -> void:
	entity.take_damage(null, bleed_damage,null,Color.DARK_RED)
	if entity is Enemy:
		EventBus.dealt_bleed_damage.emit(bleed_damage, entity)

func merge(incoming: Debuff, incoming_ticks: int) -> void:
	ticks = maxi(ticks, incoming_ticks)
	if stacks >= max_stacks:
		return
	stacks += 1
	bleed_damage += (incoming as BleedDebuff).bleed_damage
