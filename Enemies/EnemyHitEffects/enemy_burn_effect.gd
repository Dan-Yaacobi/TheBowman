class_name BurnHitEffect extends EnemyHitEffect

const BURN_DEBUFF = preload("uid://caiebherwxilx")

@export var fire_damage: int
@export var duration: float = 6
@export var ticks: int = 3

func apply(_target: GameEntity) -> void:
	if not _target:
		return
	var burn_debuff: BurnDebuff = BURN_DEBUFF.instantiate()
	burn_debuff.fire_damage = fire_damage
	_target.debuff_handler.add_debuff(burn_debuff,CustomVariables.BURN_DEBUFF_ID, duration, ticks)
