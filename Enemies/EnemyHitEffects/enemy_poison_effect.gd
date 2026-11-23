class_name PoisonHitEffect extends EnemyHitEffect
## Poisons what the enemy hits, with the shared PoisonDebuff (GDD rule 8: one DoT model).

const POISON_PATH: String = "res://Debuffs/Poisoned/PoisonDebuff.tscn"

@export var poison_damage: int = 1
@export var duration: float = 3.0
@export var ticks: int = 3


func apply(_target: GameEntity) -> void:
	if not _target:
		return
	var poison: PoisonDebuff = load(POISON_PATH).instantiate()
	poison.set_damage(poison_damage)
	_target.debuff_handler.add_debuff(poison, CustomVariables.POISON_DEBUFF_ID, duration, ticks)
