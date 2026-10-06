class_name EnemyAbilityCurse extends ChallengeCurse

enum Slot { DEATH, INITIAL, SPECIAL }

@export var ability: EnemyAbility
@export var slot: Slot = Slot.DEATH

func on_enemy_spawned(_challenge: ChallengeStoneEvent, enemy: Enemy) -> void:
	var property: String = ["death_ability", "initial_ability", "special_ability"][slot]
	var abilities: Array[EnemyAbility] = enemy.stats.get(property).duplicate()
	abilities.append(ability)
	enemy.stats.set(property, abilities)
