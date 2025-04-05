class_name SummonAbility extends Boss2Ability

@export var summon_amount: int

func activate_ability() -> void:
	summon_amount = randi_range(3,6)
	for i in range(summon_amount):
		boss.summon()
		await get_tree().create_timer(0.5).timeout
	ended.emit()
	
